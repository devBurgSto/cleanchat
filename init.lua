
-- Define the path to your local word list file
local wordListFilePath = minetest.get_modpath("cleanchat") .. "/curselist.txt"

-- Initialize a variable to track the filtering status
local filteringEnabled = true

-- Function to read the word list file
local function readWordList()
   local file = io.open(wordListFilePath, "r")
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

-- Register an event handler to listen for chat messages
minetest.register_on_chat_message(function(name, message)
   if filteringEnabled then
       local wordList = readWordList()

       -- Iterate through the word list and replace whole words (case-insensitive)
       for _, word in ipairs(wordList) do
           local pattern = "%f[%a]%s*(" .. word:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1") .. ")%s*%f[%A]"
           message = message:gsub(pattern, function(match)
               -- Preserve the original case of the matched word
               return "@!##%&@!!"
           end)
       end
   end

   -- Send the modified message to the player
   minetest.chat_send_player(name, message)

   -- Return true to prevent the original message from being displayed
   return true
end)

-- Register a chat command to toggle the filtering on or off
minetest.register_chatcommand("cleanchat", {
   params = "<on|off>",
   description = "Toggle clean chat on or off.",
   func = function(name, param)
       if param == "on" then
           filteringEnabled = true
           minetest.chat_send_player(name, "Clean chat filtering is now enabled.")
       elseif param == "off" then
           filteringEnabled = false
           minetest.chat_send_player(name, "Clean chat is now disabled.")
       else
           minetest.chat_send_player(name, "Usage: /cleanchat <on|off>")
       end
   end,
})

