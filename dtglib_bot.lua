-- initialise room, device, scene and variable list from Domoticz
function dtgbot_initialise()

    print_info_to_log(0,"-----------------------------------------")
    print_info_to_log(0,"Starting Telegram api Bot message handler")
    print_info_to_log(0,"-----------------------------------------")

    -- Load the configuration file this file contains the list of commands
    -- used to define the external files with the command function to load.
    local config = ""
    if (file_exists(BotHomePath .. "dtgbot-user.cfg")) then
        config = assert(loadfile(BotHomePath .. "dtgbot-user.cfg"))();
        print_info_to_log(0,"Using DTGBOT config file:" .. BotHomePath .. "dtgbot-user.cfg")
    else
        config = assert(loadfile(BotHomePath .. "dtgbot.cfg"))();
        print_info_to_log(0,"Using DTGBOT config file:" .. BotHomePath .. "dtgbot.cfg")
    end

    Variablelist = variable_list_names_idxs()
    Devicelist = device_list_names_idxs("devices")
    Scenelist, Sceneproperties = device_list_names_idxs("scenes")
    Roomlist   = device_list_names_idxs("plans")

    -- Get language from Domoticz
    language = domoticz_language()

    -- get the required loglevel
    local dtgbotLogLevelidx = idx_from_variable_name("TelegramBotLoglevel")
    if dtgbotLogLevelidx ~= nil then
        dtgbotLogLevel = tonumber(get_variable_value(dtgbotLogLevelidx))
        if dtgbotLogLevel == nil then
            dtgbotLogLevel = 0
        end
    end

    print_info_to_log(0, '** dtgbotLogLevel set to: ' .. tostring(dtgbotLogLevel) .. ' (0 is minimum / 2 is usually max)')

    print_info_to_log(0, "Loading command modules...")
    for i, m in ipairs(command_modules) do
        print_info_to_log(2, "* Loading module <" .. m .. ">");
        local t = assert(loadfile(BotLuaScriptPath .. m .. ".lua"))();
        cl = t:get_commands();
        for c, r in pairs(cl) do
            print_info_to_log(1, "** found command [" .. m .. "]::<" .. c .. ">");
            commands[c] = r;
        end
    end

    -- Initialise and populate dtgmenu tables in case the menu is switched on
    local Menuidx = idx_from_variable_name("TelegramBotMenu")
    if Menuidx ~= nil then
        Menuval = get_variable_value(Menuidx)
        if Menuval == "On" then
            -- initialise
            -- define the menu table and initialize the table first time
            PopulateMenuTab(1, "")
        end
    end

    local TelegramBotNameIdx = idx_from_variable_name("TelegramBotName")
    if TelegramBotNameIdx ~= nil then
        TelegramBotName = get_variable_value(TelegramBotNameIdx)
    else
        TelegramBotName = "bot"
    end

    local TelegramBotLuaExcludeIdx = idx_from_variable_name("TelegramBotLuaExclude")
    if TelegramBotLuaExcludeIdx ~= nil then
        TelegramBotLuaExclude = get_variable_value(TelegramBotLuaExcludeIdx)
    else
        TelegramBotLuaExclude = ""
    end

    local TelegramBotBashExcludeIdx = idx_from_variable_name("TelegramBotBashExclude")
    if TelegramBotBashExcludeIdx ~= nil then
        TelegramBotBashExclude = get_variable_value(TelegramBotBashExcludeIdx)
    else
        TelegramBotBashExclude = ""
    end

    -- Retrieve id white list
    local WLidx = idx_from_variable_name(WLName)
    if WLidx == nil then
        print_warning_to_log(0, WLName .. ' user variable does not exist in Domoticz')
        print_warning_to_log(0, 'So will allow any id to use the bot')
    else
        print_info_to_log(1, 'idx_from_variable_name: WLidx ' .. WLidx)
        local WLString = get_variable_value(WLidx)
        print_info_to_log(1, 'idx_from_variable_name: WLString: ' .. WLString)
        WhiteList = get_names_from_variable(WLString)
    end

    -- Get the updates
    print_info_to_log(0, 'Getting [' .. TBOName .. '] the previous Telegram bot message offset from Domoticz')
    TBOidx = idx_from_variable_name(TBOName)
    if TBOidx == nil then
        print_error_to_log(0, TBOName .. ' user variable does not exist in Domoticz so can not continue')
        os.exit()
    else
        print_info_to_log(2, '[' .. TBOName .. ']>idx(TBOidx)=' .. TBOidx)
    end
    TelegramBotOffset = get_variable_value(TBOidx)
    print_info_to_log(2, '[' .. TBOName .. ']>TBO=' .. TelegramBotOffset)
    print_info_to_log(2, 'TelegramUrl=[' .. telegram_url .. ']')


    -- check current OS
    TelegramBotIsOnWindows = isWindowsOS()
    if ( TelegramBotIsOnWindows ) then
        if ( string.sub(BotBashScriptPath,-1) == '/' ) then
            BotBashScriptPath = string.sub(BotBashScriptPath,1, string.len(BotBashScriptPath)-1);
        end
    end

    -- Not quite sure what this is here for
    started = 1
    return
end


-- Main function to handle command and feedback
function HandleCommand(cmd, SendTo, Group, MessageId, channelmsg)
    if channelmsg then
        channelmsgString = 'true'
    else
        channelmsgString = 'false'
    end
    print_info_to_log(0, "HandleCommand: started with [" .. cmd .. "] sendTo[" .. SendTo .. "] Group[" .. Group .. "] channelmsg:" .. channelmsgString)

    --- parse the command
    if command_prefix == "" then
        -- Command prefix is not needed, as can be enforced by Telegram api directly
        parsed_command = { "Stuff" } -- to make compatible with Hangbot with password
    else
        parsed_command = {}
    end
    local commandFound = 0

    ---------------------------------------------------------------------------
    -- Change for menu.lua option
    -- When LastCommand starts with menu then assume the rest is for menu.lua
    ---------------------------------------------------------------------------
    if Menuval == "On" and not channelmsg then
        print_info_to_log(0, "dtgbot: Start DTGMENU ...", cmd)
        local menu_cli = {}
        table.insert(menu_cli, "") -- make it compatible
        table.insert(menu_cli, cmd)
        -- send whole cmd line instead of first word
        command_dispatch = commands["dtgmenu"];
        status, text, replymarkup, cmd = command_dispatch.handler(menu_cli, SendTo);
        if status ~= 0 then
            -- stop the process when status is not 0
            if text ~= "" then
                while string.len(text) > 0 do
                    if Group ~= "" then
                        send_msg(Group, string.sub(text, 1, 4000), MessageId, replymarkup)
                    else
                        send_msg(SendTo, string.sub(text, 1, 4000), MessageId, replymarkup)
                    end
                    text = string.sub(text, 4000, -1)
                end
            end
            print_info_to_log(0, "dtgbot: dtgmenu ended and text send ...return:" .. status)
            -- no need to process anything further
            return 1
        end
        print_info_to_log(0, "dtgbot:continue regular processing. cmd =>", cmd)
    end
    ---------------------------------------------------------------------------
    -- End change for menu.lua option
    ---------------------------------------------------------------------------

    --~	added "-_"to allowed characters a command/word
    for w in string.gmatch(cmd, "([%w-_]+)") do
        table.insert(parsed_command, w)
    end
    if command_prefix ~= "" then
        if parsed_command[1] ~= command_prefix then -- command prefix has not been found so ignore message
            print_info_to_log(1,"WARN **** ignore this command "..parsed_command[1])
            return 1 -- not a command so successful but nothing done
        end
    end

    if (parsed_command[2] ~= nil) then
        -- is this a LUA command ?
        command_dispatch = commands[string.lower(parsed_command[2])];
        local savereplymarkup = replymarkup
        if command_dispatch then
            status, text, replymarkup = command_dispatch.handler(parsed_command, SendTo);
            commandFound = 1
        else
            -- is this a BASH command ?
            text = ""
            if (TelegramBotIsOnWindows) then
                cmdListDir = 'dir /B'
                cmdListDirSuffix = ''
            else
                cmdListDir = 'ls'
                cmdListDirSuffix = ''
            end

            local commandList = cmdListDir.." " .. BotBashScriptPath.." "..cmdListDirSuffix
            print_info_to_log(1,"commandList=["..commandList.."]")
            local f = io.popen(commandList)
            cmda = string.lower(tostring(parsed_command[2]))
            len_parsed_command = #parsed_command
            stuff = string.sub(cmd, string.len(cmda) + 1)
            for line in f:lines() do
                print_info_to_log(0, "checking line " .. line)
                if (line:match(cmda)) then
                    print_info_to_log(1, "line=["..line.."]")
                    os.execute(BotBashScriptPath .. line .. ' ' .. SendTo .. ' ' .. stuff)
                    commandFound = 1
                end
            end
        end

        --~ replymarkup
        if replymarkup == nil or replymarkup == "" then
            -- restore the menu supplied replymarkup in case the shelled LUA didn't provide one
            replymarkup = savereplymarkup
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
                send_msg(Group, string.sub(text, 1, 4000), MessageId, replymarkup)
            else
                send_msg(SendTo, string.sub(text, 1, 4000), MessageId, replymarkup)
            end
            text = string.sub(text, 4000, -1)
        end
    elseif replymarkup ~= "" then
        if channelmsg then
            send_msg(Group, "done", MessageId)
        elseif Group ~= "" then
            send_msg(Group, "done", MessageId, replymarkup)
        else
            send_msg(SendTo, "done", MessageId, replymarkup)
        end
    end
    return commandFound
end


function on_msg_receive(msg)
    -- is bot well started ?
    if started == 0 then
        return
    end
    if msg.out then
        return
    end

    -- filter command for bot only : for now, only text message
    if msg.text then
        ReceivedText = msg.text

        -- start with a /
        SlashPos = string.find(ReceivedText, "/")
        if (SlashPos ~= 1) then
            return
        end

        -- remove slash
        ReceivedText = string.sub(ReceivedText, 2, string.len(ReceivedText))
        ReceivedTextFull = ReceivedText

        commandValidated = false
        -- command with "/bot cmd option" style
        SpacePos = string.find(ReceivedText, "% ")
        if (SpacePos == nil) then
            print_info_to_log(3, 'Received[' .. ReceivedText .. '] not with [botName<space>]')
        else
            botPrefix = string.sub(ReceivedText, 1, SpacePos - 1)
            ReceivedText = string.sub(ReceivedText, SpacePos + 1, string.len(ReceivedText))
            if (botPrefix == 'all' or botPrefix == TelegramBotName) then
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
                botPrefix = string.sub(ReceivedText, 1, SpacePos - 1)
                ReceivedText = string.sub(ReceivedText, SpacePos + 1, string.len(ReceivedText))
                if (botPrefix == 'all' or botPrefix == TelegramBotName) then
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
    if id_check(msg.from.id) then
        grp_from   = msg.chat.id
        msg_from   = msg.from.id
        msg_id     = msg.message_id
        channelmsg = false
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
            responsev, statusv = https.request(telegram_url .. 'getFile?file_id=' .. msg.voice.file_id)
            if statusv == 200 then
                print_info_to_log(1, "responsev:", responsev)
                decoded_responsev = JSON:decode(responsev)
                result = decoded_responsev["result"]
                filelink = result["file_path"]
                print_info_to_log(1, "filelink:", filelink)
                ReceivedText = "voice " .. filelink
                if HandleCommand(ReceivedText, tostring(msg_from), tostring(grp_from), msg_id, channelmsg) == 1 then
                    print_info_to_log(0, "Succesfully handled incoming voice request")
                else
                    print_info_to_log(0, "Voice file received but voice.sh or lua not found to process it. skipping the message.")
                    print_info_to_log(0, "msg_from:"..msg_from)
                    send_msg(msg_from, '⚡️ INVALID COMMAND ⚡️', msg_id)
                end
            end
        elseif msg.video_note then -- check if message is videofile
            print_info_to_log(0, "msg.video_note.file_id:", msg.video_note.file_id)
            responsev, statusv = https.request(telegram_url .. 'getFile?file_id=' .. msg.video_note.file_id)
            if statusv == 200 then
                print_info_to_log(1, "responsev:", responsev)
                decoded_responsev = JSON:decode(responsev)
                result = decoded_responsev["result"]
                filelink = result["file_path"]
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
    if WhiteList == nil then
        return true
    else
        SendTo = tostring(SendTo)
        --Check id against whitelist
        for i = 1, #WhiteList do
            print_info_to_log(2, 'id_check: WhiteList[' .. WhiteList[i] .. '] ?')
            if SendTo == WhiteList[i] then
                print_info_to_log(1, 'id_check: WhiteList[' .. WhiteList[i] .. '] ok ')
                return true
            end
        end
        -- Checked WhiteList no match
        print_warning_to_log(0, 'id_check: WhiteList[' .. SendTo .. '] not allowed')
        return false
    end
end