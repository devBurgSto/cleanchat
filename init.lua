-- Define the path to your universal wordlist file (editable by server operators)
local universalWordListFilePath = minetest.get_modpath("cleanchat") .. "/curselist.txt"

-- Define a module-level variable to store the universal word list
local universal_wordlist = {}


-- Function to determine if word filtering should be applied
local function shouldFilter(player_name)
   local player = minetest.get_player_by_name(player_name)
   if player then
       local player_meta = player:get_meta()
       return player_meta:get_int("word_filtering_enabled") == 1
   end
   return false
end

-- Function to read the universal wordlist file
local function readUniversalWordList()
   local file = io.open(universalWordListFilePath, "r")
   if not file then
       return {} -- Return an empty list if the file doesn't exist
   end

   local wordList = {}
   for line in file:lines() do
       table.insert(wordList, line:lower()) -- Convert words to lowercase for case-insensitive matching
   end

   file:close()
   return wordList
end

-- Initialize a variable to track the filtering status
local filteringEnabled = true

-- Function to get or create a player's personal wordlist
local function getPlayerWordList(player_name)
   local player = minetest.get_player_by_name(player_name)
   if player then
       local player_meta = player:get_meta()
       local wordlist_str = player_meta:get_string("wordlist")

       -- Convert the stored string to a table
       local wordlist = {}
       if wordlist_str ~= "" then
           wordlist = minetest.deserialize(wordlist_str) or {}
       end

       return wordlist
   end
   return {}
end

-- Function to save a player's personal wordlist
local function savePlayerWordList(player_name, wordlist)
   local player = minetest.get_player_by_name(player_name)
   if player then
       local player_meta = player:get_meta()
       local wordlist_str = minetest.serialize(wordlist)
       player_meta:set_string("wordlist", wordlist_str)
   end
end

-- Function to toggle the filtering status for a player
local function toggleFiltering(player_name)
   local player = minetest.get_player_by_name(player_name)
   if player then
       local player_meta = player:get_meta()
       local current_status = player_meta:get_int("word_filtering_enabled") or 0

       -- Toggle the status (0 -> 1 or 1 -> 0)
       local new_status = 1 - current_status

       -- Update the player's metadata with the new status
       player_meta:set_int("word_filtering_enabled", new_status)

       return new_status == 1 and "on" or "off"
   end
   return "off" -- Default to "off" if the player is not found
end

-- Register the 'togglefilter' subcommand
minetest.register_chatcommand("onoff", {
   description = "Toggle clean chat on or off.",
   func = function(name)
       local player_name = name
       local status = toggleFiltering(player_name)
       minetest.chat_send_player(player_name, "Clean chat is now " .. (status == 1 and "enabled" or "disabled"))
   end,
})

-- Function to handle the 'addword' subcommand
local function handleAddWord(player_name, param)
   local wordlist = getPlayerWordList(player_name)
   table.insert(wordlist, param)
   savePlayerWordList(player_name, wordlist)
   minetest.chat_send_player(player_name, "Word added to your personal clean chat: " .. param)
end

-- Function to handle the 'removeword' subcommand
local function handleRemoveWord(player_name, param)
   local wordlist = getPlayerWordList(player_name)
   local removed = false
   for i, word in ipairs(wordlist) do
       if word == param then
           table.remove(wordlist, i)
           removed = true
           break
       end
   end
   if removed then
       savePlayerWordList(player_name, wordlist)
       minetest.chat_send_player(player_name, "Word removed from your personal clean chat: " .. param)
   else
       minetest.chat_send_player(player_name, "Word not found in your personal clean chat: " .. param)
   end
end

-- Function to handle the 'listwords' subcommand
local function handleListWords(player_name)
   local wordlist = getPlayerWordList(player_name)
   local wordlist_str = table.concat(wordlist, ", ")
   if wordlist_str == "" then
       minetest.chat_send_player(player_name, "Your personal clean chat is empty.")
   else
       minetest.chat_send_player(player_name, "Your personal clean chat: " .. wordlist_str)
   end
end

-- Function to handle the 'listwords' subcommand
local function toggleonoff(player_name)
   local wordlist = getPlayerWordList(player_name)
   local wordlist_str = table.concat(wordlist, ", ")
   if wordlist_str == "" then
       minetest.chat_send_player(player_name, "Your personal clean chat is empty.")
   else
       minetest.chat_send_player(player_name, "Your personal clean chat: " .. wordlist_str)
   end
end


-- Function to read the UniversalWordList and store it in the variable
local function loadUniversalWordList()
    universal_wordlist = readUniversalWordList()
end

-- Call the function to load the UniversalWordList at mod startup
loadUniversalWordList()

-- Register an event handler to listen for chat messages
minetest.register_on_chat_message(function(name, message)
   if shouldFilter(name) then
       local player_wordlist = getPlayerWordList(name)
       --local universal_wordlist = readUniversalWordList()

       -- Combine the player's personal wordlist and the universal wordlist
       local combined_wordlist = {}
       for _, word in ipairs(universal_wordlist) do
           table.insert(combined_wordlist, word)
       end
       for _, word in ipairs(player_wordlist) do
           table.insert(combined_wordlist, word)
       end

       -- Iterate through the word list and replace whole words (case-insensitive)
       -- switched from regex to using find as regex was having problems with case insensitive
       for _, word in ipairs(combined_wordlist) do
           local pattern = word:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
           local match_start, match_end = message:lower():find(pattern:lower())
           if match_start then
               local word_length = match_end - match_start + 1
               local replacement = "@!##%&@!!"
               --local replacement = string.rep("*", word_length) -- Replace with asterisks of the same length as the word
               message = message:sub(1, match_start - 1) .. replacement .. message:sub(match_end + 1)
           end
       end
   end

   -- Send the modified message to the player
   minetest.chat_send_player(name, message)

   -- Return true to prevent the original message from being displayed
   return true
end)

-- Register the 'cleanchat' chat command with subcommands
minetest.register_chatcommand("cleanchat", {
   params = "<subcommand> [word]",
   description = "Manage your personal wordlist and filtering status for chat filtering.",
   func = function(name, param)
       local player_name = name
       local subcommand, word = param:match("^(%S+)%s*(.*)")

       if subcommand == "addword" then
           handleAddWord(player_name, word)
       elseif subcommand == "removeword" then
           handleRemoveWord(player_name, word)
       elseif subcommand == "listwords" then
           handleListWords(player_name)
       elseif subcommand == "onoff" then
           local status = toggleFiltering(player_name)
           minetest.chat_send_player(player_name, "Clean chat is now " .. status)
       else
           minetest.chat_send_player(player_name, "Usage: /cleanchat <addword|removeword|listwords|onoff> [word]")
       end
   end,
})
