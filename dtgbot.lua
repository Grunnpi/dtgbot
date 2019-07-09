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
g_dtgbot_version = 'v0.9.8'

function environmentVariableDomoticz(envvar)
    -- loads get environment variable and prints in log
    local localvar = os.getenv(envvar)
    if localvar ~= nil then
        print(envvar .. ": " .. localvar)
    else
        print(envvar .. " not found check /etc/profile.d/DomoticzData.sh")
    end
    return localvar
end

function checkpath(envpath)
    if string.sub(envpath, -1, -1) ~= "/" then
        envpath = envpath .. "/"
    end
    return envpath
end

-- set default loglevel which will be retrieve later from the domoticz user variable TelegramBotLoglevel
g_dtgbotLogLevel = 0
-- loglevel 0 - Always shown
-- loglevel 1 - only shown when TelegramBotLoglevel >= 1

-- All these values are set in /etc/profile.d/DomoticzData.sh
local DomoticzIP        = environmentVariableDomoticz("DomoticzIP")
local DomoticzPort      = environmentVariableDomoticz("DomoticzPort")
local TelegramChatId    = environmentVariableDomoticz("TelegramChatId")
local TelegramBotToken  = environmentVariableDomoticz("TelegramBotToken")
g_BotTempFileDir        = environmentVariableDomoticz("TempFileDir")
g_BotHomePath           = environmentVariableDomoticz("BotHomePath")
g_BotLuaScriptPath      = environmentVariableDomoticz("BotLuaScriptPath")
g_BotBashScriptPath     = environmentVariableDomoticz("BotBashScriptPath")
g_TBotOffsetName        = environmentVariableDomoticz("TelegramBotOffset")

-- Constants derived from environment variables
g_DomoticzServeUrl      = "http://" .. DomoticzIP .. ":" .. DomoticzPort
g_TelegramApiUrl        = "https://api.telegram.org/bot" .. TelegramBotToken .. "/"

-- Check paths end in / and add if not present
g_BotHomePath       = checkpath(g_BotHomePath)
g_BotLuaScriptPath  = checkpath(g_BotLuaScriptPath)
g_BotBashScriptPath = checkpath(g_BotBashScriptPath)

-- log/debug function
local support = assert(loadfile(g_BotHomePath .. "dtglib_log.lua"))();
-- utilz
support = assert(loadfile(g_BotHomePath .. "dtglib_utils.lua"))();
-- telegram related
support = assert(loadfile(g_BotHomePath .. "dtglib_telegram.lua"))();
-- main bot function
support = assert(loadfile(g_BotHomePath .. "dtglib_bot.lua"))();
-- domoticz api
support = assert(loadfile(g_BotHomePath .. "dtglib_domoticz.lua"))();

-- -------------------------------------------------------

-- Array to store device list rapid access via index number (lua:devices/scenes for usage in lua:on/off)
g_DomoticzDeviceOrSceneStoredType = "None"
g_DomoticzDeviceOrSceneStoredList = {}

-- Table to store functions for commands plus descriptions used by help function
g_commandsLua = {};

-- Stuff from Domoticz
g_DomoticzVariableIdxPerNameList = {}
g_DomoticzVariableTypePerIdxList = {}
g_DomoticzDeviceList = {}
g_DomoticzSceneList = {}
g_DomoticzSceneProperties = {}
g_DomoticzRoomList = {}
g_DomoticzLanguage = 'UK'

g_BotStarted = 0
g_TelegramMenuStatus = ""
g_TelegramBotIsOnWindows = false

g_TelegramBotLuaExclude = ""
g_TelegramBotBashExclude = ""

-- Main bot init full variables
dtgbot_initialise()

--############################################################################################################
-- MAIN LOOP
--############################################################################################################

--Update monitorfile before loop
local telegram_connected = false

os.execute("echo " .. os.date("%Y-%m-%d %H:%M:%S") .. " >> " .. g_BotTempFileDir .. "/dtgloop.txt")

-- startup notification
telegram_SendMsg(TelegramChatId, "🔌 I'm alive ! ["..g_dtgbot_version.."]",'')
while file_exists(dtgbot_pid) do
    local response
    local status

    response, status = https.request(g_TelegramApiUrl .. 'getUpdates?timeout=60&offset=' .. g_TelegramBotOffset)
    if status == 200 then
        if not telegram_connected then
            print_info_to_log(0, '########################################')
            print_info_to_log(0, '### In contact with Telegram servers ###')
            print_info_to_log(0, '########################################')
            telegram_connected = true
        end
        if response ~= nil then
            print_info_to_log(1, "loop.response=["..response.."]")
            local decoded_response = JSON:decode(response)
            local result_table = decoded_response['result']
            tc = #result_table
            for i = 1, tc do
                print_info_to_log(1, 'Message:' .. i)
                local tt = table.remove(result_table, 1)
                print_info_to_log(1, 'update_id:', tt.update_id)
                g_TelegramBotOffset = tt.update_id + 1
                print_info_to_log(1, 'TelegramBotOffset:' .. g_TelegramBotOffset)
                domoticz_setVariableValueByIdx(g_TBotOffsetIdx, g_TBotOffsetName, 0, g_TelegramBotOffset)

                -- get message from Json result
                local msg = tt['message']
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
            print_info_to_log(2, 'Updates retrieved', status)
        end
    else
        if telegram_connected then
            print_info_to_log(0, '### Lost contact with Telegram servers, received Non 200 status - returned - ', status)
            telegram_connected = false
        end
        -- sleep a little to slow donw the loop
        os.execute("sleep 5")
    end
    --Update monitorfile each loop
    os.execute("echo " .. os.date("%Y-%m-%d %H:%M:%S") .. " >> " .. g_BotTempFileDir .. "/dtgloop.txt")
end
print_error_to_log(0, dtgbot_pid .. ' does not exist, so exiting')
