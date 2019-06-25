-- ~/tg/scripts/generic/domoticz2telegram.lua
-- Version 0.6 180809
-- Automation bot framework for telegram to control Domoticz
-- dtgbot.lua does not require any customisation (see below)
-- and does not require any telegram client to be installed
-- all communication is via authenticated https
-- Extra functions can be added by replicating list.lua,
-- replacing list with the name of your new command see list.lua
-- Based on test.lua from telegram-cli from
-- Adapted to abstract functions into external files using
-- the framework of the XMPP bot, so allowing functions to
-- shared between the two bots.
-- -------------------------------------------------------
-- Load necessary Lua libraries
http   = require "socket.http";
socket = require "socket";
https  = require "ssl.https";
JSON   = require "JSON";
mime   = require("mime")


-- version
dtgbot_version = 'v0.8.0'

function environmentVariableDomoticz(envvar)
    -- loads get environment variable and prints in log
    localvar = os.getenv(envvar)
    if localvar ~= nil then
        print_info_to_log(0,envvar .. ": " .. localvar)
    else
        print_info_to_log(0,envvar .. " not found check /etc/profile.d/DomoticzData.sh")
    end
    return localvar
end

-- set default loglevel which will be retrieve later from the domoticz user variable TelegramBotLoglevel
dtgbotLogLevel = 0
-- loglevel 0 - Always shown
-- loglevel 1 - only shown when TelegramBotLoglevel >= 1

-- All these values are set in /etc/profile.d/DomoticzData.sh
DomoticzIP        = environmentVariableDomoticz("DomoticzIP")
DomoticzPort      = environmentVariableDomoticz("DomoticzPort")
BotHomePath       = environmentVariableDomoticz("BotHomePath")
TempFileDir       = environmentVariableDomoticz("TempFileDir")
BotLuaScriptPath  = environmentVariableDomoticz("BotLuaScriptPath")
BotBashScriptPath = environmentVariableDomoticz("BotBashScriptPath")
TelegramBotToken  = environmentVariableDomoticz("TelegramBotToken")
TBOName           = environmentVariableDomoticz("TelegramBotOffset")

-- log/debug function
support = assert(loadfile(BotHomePath .. "dtglib_log.lua"))();
-- utilz
support = assert(loadfile(BotHomePath .. "dtglib_utils.lua"))();
-- telegram related
support = assert(loadfile(BotHomePath .. "dtglib_telegram.lua"))();
-- main bot function
support = assert(loadfile(BotHomePath .. "dtglib_bot.lua"))();



-- -------------------------------------------------------

-- Constants derived from environment variables
server_url        = "http://" .. DomoticzIP .. ":" .. DomoticzPort
telegram_url      = "https://api.telegram.org/bot" .. TelegramBotToken .. "/"

-- Check paths end in / and add if not present
BotHomePath       = checkpath(BotHomePath)
BotLuaScriptPath  = checkpath(BotLuaScriptPath)
BotBashScriptPath = checkpath(BotBashScriptPath)

support           = assert(loadfile(BotHomePath .. "dtglib_domoticz.lua"))();
-- Should end up a library - require("dtglib_domoticz.lua")

-- GLOBAL VARIABLES

-- Array to store device list rapid access via index number (lua:devices/scenes for usage in lua:on/off)
StoredType = "None"
StoredList = {}

-- Table to store functions for commands plus descriptions used by help function
commands = {};

-- Stuff from Domoticz
Variablelist = {}
Devicelist = {}
Scenelist = {}
Sceneproperties = {}
Roomlist = {}
language = 'ULK'
telegram_connected = false

-- is bot ready to process msg
started = 0



-- Main bot init full variables
dtgbot_initialise()

--############################################################################################################
-- MAIN LOOP
--############################################################################################################

--Update monitorfile before loop
os.execute("echo " .. os.date("%Y-%m-%d %H:%M:%S") .. " >> " .. TempFileDir .. "/dtgloop.txt")
while file_exists(dtgbot_pid) do
    response, status = https.request(telegram_url .. 'getUpdates?timeout=60&offset=' .. TelegramBotOffset)
    if status == 200 then
        if not telegram_connected then
            print_info_to_log(0, '########################################')
            print_info_to_log(0, '### In contact with Telegram servers ###')
            print_info_to_log(0, '########################################')
            telegram_connected = true
        end
        if response ~= nil then
            io.write('.')
            print_info_to_log(1, "loop.response=["..response.."]")
            decoded_response = JSON:decode(response)
            result_table = decoded_response['result']
            tc = #result_table
            for i = 1, tc do
                print_info_to_log(1, 'Message:' .. i)
                tt = table.remove(result_table, 1)
                print_info_to_log(1, 'update_id:', tt.update_id)
                TelegramBotOffset = tt.update_id + 1
                print_info_to_log(1, 'TelegramBotOffset:' .. TelegramBotOffset)
                set_variable_value(TBOidx, TBOName, 0, TelegramBotOffset)

                -- get message from Json result
                msg = tt['message']
                -- checking for channel message
                if tt['channel_post'] ~= nil then
                    print_info_to_log(3, '<== received channel message, reformating result to be able to process.')
                    msg = tt['channel_post']
                    msg.from = {}
                    msg.from.id = msg.chat.id
                end

                -- processing message
                -- Offset updated before processing in case of crash allows clean restart
                if (msg ~= nil and (msg.text ~= nil or msg.voice ~= nil or msg.video_note ~= nil)) then
                    print_info_to_log(1,"msg.text=["..msg.text.."]")
                    on_msg_receive(msg)
                end
            end
        else
            io.write('X')
            print_info_to_log(2, 'Updates retrieved', status)
        end
    else
        io.write('?')
        if telegram_connected then
            print_info_to_log(0, '### Lost contact with Telegram servers, received Non 200 status - returned - ', status)
            telegram_connected = false
        end
        -- sleep a little to slow donw the loop
        os.execute("sleep 5")
    end
    --Update monitorfile each loop
    os.execute("echo " .. os.date("%Y-%m-%d %H:%M:%S") .. " >> " .. TempFileDir .. "/dtgloop.txt")
end
print_error_to_log(0, dtgbot_pid .. ' does not exist, so exiting')
