-- initialise room, device, scene and variable list from Domoticz
function dtgbot_initialise()

    print_info_to_log(0,"-----------------------------------------")
    print_info_to_log(0,"Starting Telegram api Bot message handler")
    print_info_to_log(0,"-----------------------------------------")


    -- Load the configuration file this file contains the list of commands
    -- used to define the external files with the command function to load.
    local config = ""
    if (file_exists(g_BotHomePath .. "dtgbot-user.cfg")) then
        config = assert(loadfile(g_BotHomePath .. "dtgbot-user.cfg"))();
        print_info_to_log(0,"Using DTGBOT config file:" .. g_BotHomePath .. "dtgbot-user.cfg")
    else
        config = assert(loadfile(g_BotHomePath .. "dtgbot.cfg"))();
        print_info_to_log(0,"Using DTGBOT config file:" .. g_BotHomePath .. "dtgbot.cfg")
    end

    -- Initialize stuff from Domoticz
    g_DomoticzVariableList  = variable_list_names_idxs()
    g_DomoticzDeviceList    = device_list_names_idxs("devices")
    g_DomoticzSceneList, g_DomoticzSceneProperties = device_list_names_idxs("scenes")
    g_DomoticzRoomList      = device_list_names_idxs("plans")

    -- Get language from Domoticz
    g_DomoticzLanguage      = domoticz_language()

    -- get the required loglevel
    local dtgbotLogLevelidx = idx_from_variable_name("TelegramBotLoglevel")
    if dtgbotLogLevelidx ~= nil then
        g_dtgbotLogLevel = tonumber(get_variable_value(dtgbotLogLevelidx))
        if g_dtgbotLogLevel == nil then
            g_dtgbotLogLevel = 0
        end
    end

    local TelegramBotNameIdx = idx_from_variable_name("TelegramBotName")
    if TelegramBotNameIdx ~= nil then
        g_TelegramBotName = get_variable_value(TelegramBotNameIdx)
    else
        g_TelegramBotName = "bot"
    end

    print_info_to_log(0, '** g_dtgbotLogLevel set to: ' .. tostring(g_dtgbotLogLevel) .. ' (0 is minimum / 2 is usually max)')
    print_info_to_log(0, "Loading command modules...")
    local i
    local m
    for i, m in ipairs(command_modules) do
        print_info_to_log(2, "* Loading module <" .. m .. ">");
        local t = assert(loadfile(g_BotLuaScriptPath .. m .. ".lua"))();
        local cl = t:get_commands();
        for c, r in pairs(cl) do
            print_info_to_log(1, "** found command [" .. m .. "]::<" .. c .. ">");
            g_commandsLua[c] = r;
        end
    end

    -- Initialise and populate dtgmenu tables in case the menu is switched on
    local Menuidx = idx_from_variable_name("TelegramBotMenu")
    if Menuidx ~= nil then
        g_TelegramMenuStatus = get_variable_value(Menuidx)
        if g_TelegramMenuStatus == "On" then
            -- initialise
            -- define the menu table and initialize the table first time
            PopulateMenuTab(1, "")
        end
    end

    local TelegramBotLuaExcludeIdx = idx_from_variable_name("TelegramBotLuaExclude")
    if TelegramBotLuaExcludeIdx ~= nil then
        g_TelegramBotLuaExclude = get_variable_value(TelegramBotLuaExcludeIdx)
    else
        g_TelegramBotLuaExclude = ""
    end

    local TelegramBotBashExcludeIdx = idx_from_variable_name("TelegramBotBashExclude")
    if TelegramBotBashExcludeIdx ~= nil then
        g_TelegramBotBashExclude = get_variable_value(TelegramBotBashExcludeIdx)
    else
        g_TelegramBotBashExclude = ""
    end

    -- Retrieve id white list
    local WLidx = idx_from_variable_name("TelegramBotWhiteListedIDs")
    if WLidx == nil then
        print_warning_to_log(0, 'TelegramBotWhiteListedIDs user variable does not exist in Domoticz')
        print_warning_to_log(0, 'So will allow any id to use the bot')
    else
        print_info_to_log(1, 'idx_from_variable_name: WLidx ' .. WLidx)
        local WLString = get_variable_value(WLidx)
        print_info_to_log(1, 'idx_from_variable_name: WLString: ' .. WLString)
        g_TelegramBotWhiteListedIDs = get_names_from_variable(WLString)
    end

    -- Get the updates
    print_info_to_log(0, 'Getting [' .. g_TBotOffsetName .. '] the previous Telegram bot message offset from Domoticz')
    g_TBotOffsetIdx = idx_from_variable_name(g_TBotOffsetName)
    if g_TBotOffsetIdx == nil then
        print_error_to_log(0, g_TBotOffsetName .. ' user variable does not exist in Domoticz so can not continue')
        os.exit()
    else
        print_info_to_log(2, '[' .. g_TBotOffsetName .. ']>idx(g_TBotOffsetIdx)=' .. g_TBotOffsetIdx)
    end
    g_TelegramBotOffset = get_variable_value(g_TBotOffsetIdx)
    print_info_to_log(2, '[' .. g_TBotOffsetName .. ']>TBO=' .. g_TelegramBotOffset)
    print_info_to_log(2, 'TelegramUrl=[' .. g_TelegramApiUrl .. ']')


    -- check current OS
    g_TelegramBotIsOnWindows = isWindowsOS()
    if ( g_TelegramBotIsOnWindows ) then
        if ( string.sub(g_BotBashScriptPath,-1) == '/' ) then
            g_BotBashScriptPath = string.sub(g_BotBashScriptPath,1, string.len(g_BotBashScriptPath)-1);
        end
    end

    -- Not quite sure what this is here for
    g_BotStarted = 1
    return
end


-- Main function to handle command and feedback
function HandleCommand(cmd, SendTo, Group, MessageId, channelmsg)

    local text
    local channelmsgString
    local handleCommandReplyMarkup -- HandleCommand return reply
    local commandLua_dispatchHandler
    local parsed_command = { "Stuff" } -- to make compatible with Hangbot with password

    if channelmsg then
        channelmsgString = 'true'
    else
        channelmsgString = 'false'
    end
    print_info_to_log(0, "HandleCommand: started with [" .. cmd .. "] sendTo[" .. SendTo .. "] Group[" .. Group .. "] channelmsg:" .. channelmsgString)

    local commandFound = 0

    ---------------------------------------------------------------------------
    -- Change for menu.lua option
    -- When LastCommand starts with menu then assume the rest is for menu.lua
    ---------------------------------------------------------------------------
    if g_TelegramMenuStatus == "On" and not channelmsg then
        print_info_to_log(0, "dtgbot: Start DTGMENU ...", cmd)
        local menu_cli = {}
        table.insert(menu_cli, "") -- make it compatible
        table.insert(menu_cli, cmd)

        -- send whole cmd line instead of first word
        commandLua_dispatchHandler = g_commandsLua["dtgmenu"];
        local status
        status, text, handleCommandReplyMarkup, cmd = commandLua_dispatchHandler.handler(menu_cli, SendTo);
        if status ~= 0 then
            -- stop the process when status is not 0
            if text ~= "" then
                while string.len(text) > 0 do
                    if Group ~= "" then
                        send_msg(Group, string.sub(text, 1, 4000), MessageId, handleCommandReplyMarkup)
                    else
                        send_msg(SendTo, string.sub(text, 1, 4000), MessageId, handleCommandReplyMarkup)
                    end
                    text = string.sub(text, 4000, -1)
                end
            end
            print_info_to_log(0, "dtgbot: dtgmenu ended and text send ...return:" .. status)
            -- no need to process anything further
            return 1
        end
        print_info_to_log(0, "dtgbot:continue regular processing. cmd =>", cmd)
    else
        print_info_to_log(0, "dtgbot:no menu activated...")
    end
    ---------------------------------------------------------------------------
    -- End change for menu.lua option
    ---------------------------------------------------------------------------

    -- push all words in parser command table
    --~	added "-_"to allowed characters a command/word
    for w in string.gmatch(cmd, "([%w-_]+)") do
        table.insert(parsed_command, w)
    end

    if (parsed_command[2] ~= nil) then
        -- is this a LUA command ?
        commandLua_dispatchHandler = g_commandsLua[string.lower(parsed_command[2])];
        local savereplymarkup = handleCommandReplyMarkup
        local status
        if commandLua_dispatchHandler then
            status, text, handleCommandReplyMarkup = commandLua_dispatchHandler.handler(parsed_command, SendTo);
            commandFound = 1
        else
            -- is this a BASH command ?
            text = ""
            local cmdListDir
            local cmdListDirSuffix
            if (g_TelegramBotIsOnWindows) then
                cmdListDir = 'dir /B'
                cmdListDirSuffix = ''
            else
                cmdListDir = 'ls'
                cmdListDirSuffix = ''
            end

            local commandList = cmdListDir.." " .. g_BotBashScriptPath.." "..cmdListDirSuffix
            print_info_to_log(1,"commandList=["..commandList.."]")
            local f = io.popen(commandList)
            local cmda = string.lower(tostring(parsed_command[2]))
            --local len_parsed_command = #parsed_command
            local stuff = string.sub(cmd, string.len(cmda) + 1)
            for line in f:lines() do
                print_info_to_log(0, "checking line " .. line)
                if (line:match(cmda)) then
                    print_info_to_log(1, "line=["..line.."]")
                    os.execute(g_BotBashScriptPath .. line .. ' ' .. SendTo .. ' ' .. stuff)
                    commandFound = 1
                end
            end
        end

        if handleCommandReplyMarkup == nil or handleCommandReplyMarkup == "" then
            -- restore the menu supplied replymarkup in case the shelled LUA didn't provide one
            handleCommandReplyMarkup = savereplymarkup
        end
        if commandFound == 0 then
            text = "command <" .. tostring(parsed_command[2]) .. "> not found";
        end
    else
        text = 'No command found'
    end

    -- final feedback status (ok or not)
    if text ~= "" then
        while string.len(text) > 0 do
            if channelmsg then
                send_msg(Group, string.sub(text, 1, 4000), MessageId) -- channel messages on support inline menus
            elseif Group ~= "" then
                send_msg(Group, string.sub(text, 1, 4000), MessageId, handleCommandReplyMarkup)
            else
                send_msg(SendTo, string.sub(text, 1, 4000), MessageId, handleCommandReplyMarkup)
            end
            text = string.sub(text, 4000, -1)
        end
    elseif handleCommandReplyMarkup ~= "" then
        if channelmsg then
            send_msg(Group, "done", MessageId)
        elseif Group ~= "" then
            send_msg(Group, "done", MessageId, handleCommandReplyMarkup)
        else
            send_msg(SendTo, "done", MessageId, handleCommandReplyMarkup)
        end
    end
    return commandFound
end


-- entry point to handle msg in MAIN LOOP
function on_msg_receive(msg)
    local ReceivedText

    -- is bot well started ?
    if g_BotStarted == 0 then
        return
    end
    if msg.out then
        return
    end

    -- filter command for bot only : for now, only text message
    if msg.text then
        ReceivedText = msg.text

        -- start with a /
        local SlashPos = string.find(ReceivedText, "/")
        if (SlashPos ~= 1) then
            return
        end

        -- remove slash
        ReceivedText = string.sub(ReceivedText, 2, string.len(ReceivedText))
        local ReceivedTextFull = ReceivedText

        local commandValidated = false
        -- command with "/bot cmd option" style
        local SpacePos = string.find(ReceivedText, "% ")
        if (SpacePos == nil) then
            print_info_to_log(3, 'Received[' .. ReceivedText .. '] not with [botName<space>]')
        else
            local botPrefix = string.sub(ReceivedText, 1, SpacePos - 1)
            ReceivedText = string.sub(ReceivedText, SpacePos + 1, string.len(ReceivedText))
            if (botPrefix == 'all' or botPrefix == g_TelegramBotName) then
                print_info_to_log(3, 'Received[' .. ReceivedText .. '] okay with [' .. botPrefix .. ']')
                commandValidated = true
            else
                print_info_to_log(3, 'Received[' .. ReceivedText .. '] not good bot name [' .. botPrefix .. ']')
            end
        end

        if (not commandValidated) then
            ReceivedText = ReceivedTextFull
            SpacePos = string.find(ReceivedText, "%_")
            if (SpacePos == nil) then
                print_info_to_log(3, 'Received[' .. ReceivedText .. '] not with [botName_]')
            else
                local botPrefix = string.sub(ReceivedText, 1, SpacePos - 1)
                ReceivedText = string.sub(ReceivedText, SpacePos + 1, string.len(ReceivedText))
                if (botPrefix == 'all' or botPrefix == g_TelegramBotName) then
                    ReceivedText = string.gsub(ReceivedText, "_", " ")
                    print_info_to_log(3, 'Received[' .. ReceivedText .. '] okay with [' .. botPrefix .. ']')
                    commandValidated = true
                else
                    print_info_to_log(3, 'Received[' .. ReceivedText .. '] not good bot name [' .. botPrefix .. ']')
                end
            end
        end
        if (not commandValidated) then
            return
        end
    end

    --Check to see if id is whitelisted, if not record in log and exit
    local msg_from   = msg.from.id
    if id_check(msg_from) then
        local grp_from   = msg.chat.id
        local msg_id     = msg.message_id
        local channelmsg = false
        if msg.chat.type == "channel" then
            channelmsg = true
        end

        if msg.text then -- check if message is text
            --ReceivedText = msg.text -- I dont read it again
            if HandleCommand(ReceivedText, tostring(msg_from), tostring(grp_from), msg_id, channelmsg) == 1 then
                print_info_to_log(0, "Succesfully handled incoming request")
            else
                print_info_to_log(0, "Invalid command received from:["..msg_from.."]")
                send_msg(msg_from, '⚡️ INVALID COMMAND ⚡️', msg_id)
            end
            -- check for received voicefiles
        elseif msg.voice then -- check if message is voicefile
            print_info_to_log(0, "msg.voice.file_id:", msg.voice.file_id)
            local responsev
            local statusv
            responsev, statusv = https.request(g_TelegramApiUrl .. 'getFile?file_id=' .. msg.voice.file_id)
            if statusv == 200 then
                print_info_to_log(1, "responsev:", responsev)
                local decoded_responsev = JSON:decode(responsev)
                local result = decoded_responsev["result"]
                local filelink = result["file_path"]
                print_info_to_log(1, "filelink:", filelink)
                ReceivedText = "voice " .. filelink
                if HandleCommand(ReceivedText, tostring(msg_from), tostring(grp_from), msg_id, channelmsg) == 1 then
                    print_info_to_log(0, "Succesfully handled incoming voice request")
                else
                    print_info_to_log(0, "Voice file received but voice.sh or lua not found to process it. skipping the message.")
                    print_info_to_log(1, "msg_from:"..msg_from)
                    send_msg(msg_from, '⚡️ INVALID COMMAND ⚡️', msg_id)
                end
            end
        elseif msg.video_note then -- check if message is videofile
            print_info_to_log(0, "msg.video_note.file_id:", msg.video_note.file_id)
            local responsev
            local statusv
            responsev, statusv = https.request(g_TelegramApiUrl .. 'getFile?file_id=' .. msg.video_note.file_id)
            if statusv == 200 then
                print_info_to_log(1, "responsev:", responsev)
                local decoded_responsev = JSON:decode(responsev)
                local result = decoded_responsev["result"]
                local filelink = result["file_path"]
                print_info_to_log(1, "filelink:", filelink)
                ReceivedText = "video " .. filelink
                if HandleCommand(ReceivedText, tostring(msg_from), tostring(grp_from), msg_id, channelmsg) == 1 then
                    print_info_to_log(0, "Succesfully handled incoming video request")
                else
                    print_info_to_log(0, "Video file received but video_note.sh or lua not found to process it. Skipping the message.")
                    print_info_to_log(0, "msg_from:"..msg_from)
                    send_msg(msg_from, '⚡️ INVALID COMMAND ⚡️', msg_id)
                end
            end
        end
    else
        print_warning_to_log(0, 'id['..msg_from..'] not on white list, command ignored')
        send_msg(msg_from, '⚡️ ID Not Recognised - Command Ignored ⚡️', msg_id)
    end
end

function id_check(SendTo)
    --Check if whitelist empty then let any message through
    if g_TelegramBotWhiteListedIDs == nil then
        return true
    else
        SendTo = tostring(SendTo)
        --Check id against whitelist
        for i = 1, #g_TelegramBotWhiteListedIDs do
            print_info_to_log(2, 'id_check: WhiteList[' .. g_TelegramBotWhiteListedIDs[i] .. '] ?')
            if SendTo == g_TelegramBotWhiteListedIDs[i] then
                print_info_to_log(1, 'id_check: WhiteList[' .. g_TelegramBotWhiteListedIDs[i] .. '] ok ')
                return true
            end
        end
        -- Checked WhiteList no match
        print_warning_to_log(0, 'id_check: WhiteList[' .. SendTo .. '] not allowed')
        return false
    end
end