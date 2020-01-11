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
    g_DomoticzVariableIdxPerNameList  = domoticz_getVariableIdxPerNameList()
    g_DomoticzVariableTypePerIdxList  = domoticz_getVariableTypePerIdxList()
    g_DomoticzDeviceList              = domoticz_getDeviceAndPropertiesListByType("devices")
    g_DomoticzSceneList, g_DomoticzSceneProperties = domoticz_getDeviceAndPropertiesListByType("scenes")
    g_DomoticzRoomList                = domoticz_getDeviceAndPropertiesListByType("plans")

    -- Get language from Domoticz
    g_DomoticzLanguage      = domoticz_language()

    -- get the required loglevel
    local dtgbotLogLevelidx = domoticz_cache_getVariableIdxByName("TelegramBotLoglevel")
    if dtgbotLogLevelidx ~= nil then
        g_dtgbotLogLevel = tonumber(domoticz_getVariableValueByIdx(dtgbotLogLevelidx))
        if g_dtgbotLogLevel == nil then
            g_dtgbotLogLevel = 0
        end
    end

    local TelegramBotNameIdx = domoticz_cache_getVariableIdxByName("TelegramBotName")
    if TelegramBotNameIdx ~= nil then
        g_TelegramBotName = domoticz_getVariableValueByIdx(TelegramBotNameIdx)
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

        -- sort commands for nicer result
        table.sort(g_commandsLua)
    end

    -- Initialise and populate dtgmenu tables in case the menu is switched on
    local Menuidx = domoticz_cache_getVariableIdxByName("TelegramBotMenu")
    if Menuidx ~= nil then
        g_TelegramMenuStatus = domoticz_getVariableValueByIdx(Menuidx)
        if g_TelegramMenuStatus == "On" then
            -- initialise
            -- define the menu table and initialize the table first time
            PopulateMenuTab(1, "")
        end
    end

    local TelegramBotLuaExcludeIdx = domoticz_cache_getVariableIdxByName("TelegramBotLuaExclude")
    if TelegramBotLuaExcludeIdx ~= nil then
        g_TelegramBotLuaExclude = domoticz_getVariableValueByIdx(TelegramBotLuaExcludeIdx)
        if ( g_TelegramBotLuaExclude == nil ) then
            g_TelegramBotLuaExclude = ""
        end
    else
        g_TelegramBotLuaExclude = ""
    end

    local TelegramBotBashExcludeIdx = domoticz_cache_getVariableIdxByName("TelegramBotBashExclude")
    if TelegramBotBashExcludeIdx ~= nil then
        g_TelegramBotBashExclude = domoticz_getVariableValueByIdx(TelegramBotBashExcludeIdx)
        if ( g_TelegramBotBashExclude == nil ) then
            g_TelegramBotBashExclude = ""
        end
    else
        g_TelegramBotBashExclude = ""
    end

    local TelegramBotTchatIdx = domoticz_cache_getVariableIdxByName("TelegramBotTchat")
    if TelegramBotTchatIdx ~= nil then
        g_TelegramBotTchat = domoticz_getVariableValueByIdx(TelegramBotTchatIdx)
        if ( g_TelegramBotBashExclude == nil ) then
            g_TelegramBotTchat = ""
        end
    else
        g_TelegramBotTchat = ""
    end
    print_info_to_log(0, 'Tchat Mode : ' .. g_TelegramBotTchat)

    -- Retrieve id white list
    local WLidx = domoticz_cache_getVariableIdxByName("TelegramBotWhiteListedIDs")
    if WLidx == nil then
        print_warning_to_log(0, 'TelegramBotWhiteListedIDs user variable does not exist in Domoticz')
        print_warning_to_log(0, 'So will allow any id to use the bot')
    else
        print_info_to_log(1, 'domoticz_cache_getVariableIdxByName: WLidx ' .. WLidx)
        local WLString = domoticz_getVariableValueByIdx(WLidx)
        print_info_to_log(1, 'domoticz_cache_getVariableIdxByName: WLString: ' .. WLString)
        g_TelegramBotWhiteListedIDs = get_names_from_variable(WLString)
    end

    -- Retrieve id white list Names
    local WLNameIdx = domoticz_cache_getVariableIdxByName("TelegramBotWhiteListedNames")
    if WLNameIdx == nil then
        print_warning_to_log(0, 'TelegramBotWhiteListedNames user variable does not exist in Domoticz')
        print_warning_to_log(0, 'So will allow any id to use the bot')
    else
        print_info_to_log(1, 'domoticz_cache_getVariableIdxByName: WLNameIdx ' .. WLNameIdx)
        local WLNamesString = domoticz_getVariableValueByIdx(WLNameIdx)
        print_info_to_log(1, 'domoticz_cache_getVariableIdxByName: WLNamesString: ' .. WLNamesString)
        g_TelegramBotWhiteListedNames = get_names_from_variable(WLNamesString)
    end

    -- Get the updates
    print_info_to_log(0, 'Getting [' .. g_TBotOffsetName .. '] the previous Telegram bot message offset from Domoticz')
    g_TBotOffsetIdx = domoticz_cache_getVariableIdxByName(g_TBotOffsetName)
    if g_TBotOffsetIdx == nil then
        print_error_to_log(0, g_TBotOffsetName .. ' user variable does not exist in Domoticz so can not continue')
        os.exit()
    else
        print_info_to_log(2, '[' .. g_TBotOffsetName .. ']>idx(g_TBotOffsetIdx)=' .. g_TBotOffsetIdx)
    end
    g_TelegramBotOffset = domoticz_getVariableValueByIdx(g_TBotOffsetIdx)
    print_info_to_log(2, '[' .. g_TBotOffsetName .. ']>TBO=' .. g_TelegramBotOffset)
    print_info_to_log(2, 'TelegramUrl=[' .. g_TelegramApiUrl .. ']')


    -- check current OS
    g_TelegramBotIsOnWindows = isWindowsOS()
    if ( g_TelegramBotIsOnWindows ) then
        if ( string.sub(g_BotBashScriptPath,-1) == '/' ) then
            g_BotBashScriptPath = string.sub(g_BotBashScriptPath,1, string.len(g_BotBashScriptPath)-1)
            g_BotBashScriptPath = g_BotBashScriptPath.."\\"
        end
    end

    -- Not quite sure what this is here for
    g_BotStarted = 1
    return
end


-- Main function to handle command and feedback
function HandleCommand(cmd, ReplyTo, MessageId, channelmsg)
    print_info_to_log(0,"HandleCommand: [" .. cmd .. "]")

    local text
    local handleCommandReplyMarkup -- HandleCommand return reply
    local commandLua_dispatchHandler
    local parsed_command = { "Stuff" } -- to make compatible with Hangbot with password
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
        status, text, handleCommandReplyMarkup, cmd = commandLua_dispatchHandler.handler(menu_cli, ReplyTo);
        if status ~= 0 then
            -- stop the process when status is not 0
            if text ~= "" then
                while string.len(text) > 0 do
                    telegram_SendMsg(ReplyTo, string.sub(text, 1, 4000), MessageId, handleCommandReplyMarkup)
                    text = string.sub(text, 4000, -1)
                end
            end
            print_info_to_log(0, "dtgbot: dtgmenu ended and text send ...return:" .. status)
            -- no need to process anything further
            return 1
        end
        print_info_to_log(1, "dtgbot:continue regular processing. cmd =>", cmd)
    else
        print_info_to_log(3, "dtgbot:no menu activated...")
    end
    ---------------------------------------------------------------------------
    -- End change for menu.lua option
    ---------------------------------------------------------------------------

    -- push all words in parser command table
    --~	added "-_"to allowed characters a command/word
    --for w in string.gmatch(cmd, "([%w-_\";|<>.,]+)") do
    for w in string.gmatch(cmd, "%S+") do
        table.insert(parsed_command, w)
    end

    if (parsed_command[2] ~= nil) then
        -- is this a LUA command ?
        commandLua_dispatchHandler = g_commandsLua[string.lower(parsed_command[2])];
        local savereplymarkup = handleCommandReplyMarkup
        local status
        if commandLua_dispatchHandler then
            status, text, handleCommandReplyMarkup = commandLua_dispatchHandler.handler(parsed_command, ReplyTo);
            if ( text == nil) then
                print_info_to_log(1,"commandLua.nil=["..tostring(status).."][nil]")
            else
                print_info_to_log(1,"commandLua.text=["..tostring(status).."]["..text.."]")
            end
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
                if ( commandFound ~= 1 ) then
                    print_info_to_log(1, "checking line " .. line)
                    if (line:match(cmda)) then
                        print_info_to_log(1, "line=["..line.."] found")
                        os.execute(g_BotBashScriptPath .. line .. ' ' .. ReplyTo .. ' ' .. MessageId .. ' ' .. stuff)
                        commandFound = 1
                    end
                end
            end
        end

        if handleCommandReplyMarkup == nil or handleCommandReplyMarkup == "" then
            -- restore the menu supplied replymarkup in case the shelled LUA didn't provide one
            handleCommandReplyMarkup = savereplymarkup
        end
        if commandFound == 0 then
            text = "commande <" .. tostring(parsed_command[2]) .. "> non trouvée";
        end
    else
        text = 'je ne trouve pas de commande'
    end

    -- final feedback status (ok or not)
    if text ~= "" and text ~= nil then
        while string.len(text) > 0 do
            telegram_SendMsg(ReplyTo, string.sub(text, 1, 4000), MessageId, handleCommandReplyMarkup)
            text = string.sub(text, 4000, -1)
        end
    elseif handleCommandReplyMarkup ~= "" then
        local randomOkMessage = randomOkMessage()
        telegram_SendMsg(ReplyTo, randomOkMessage, MessageId, handleCommandReplyMarkup)
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

    ---------------------------------------------------------------------------
    -- Reply back preparation to avoid duplicate logic
    ---------------------------------------------------------------------------
    local telegramMsg_FromId    = msg.from.id
    local telegramMsg_ChatId    = msg.chat.id
    local telegramMsg_MsgId     = msg.message_id
    local telegramMsg_IsChannel = false
    if msg.chat.type == "channel" then
        telegramMsg_IsChannel = true
    end

    local telegramMsg_ReplyToId
    if telegramMsg_IsChannel then
        telegramMsg_ReplyToId = telegramMsg_ChatId
    elseif telegramMsg_ChatId ~= "" then
        telegramMsg_ReplyToId = telegramMsg_ChatId
    else
        telegramMsg_ReplyToId = telegramMsg_FromId
    end

    --Check to see if id is whitelisted, if not record in log and exit
    if id_check(telegramMsg_FromId) then
        g_currentUserName = id_domoticzName(telegramMsg_FromId)

        -- filter command for bot only : for now, only text message
        if msg.text then
            ReceivedText = msg.text

            -- start with a /
            local SlashPos = string.find(ReceivedText, "/")
            if (SlashPos ~= 1) then
                -- check if tchat mode
                if ( isTchat() ) then
                    handleTchat(telegramMsg_ReplyToId, telegramMsg_MsgId, ReceivedText)
                    return
                else
                    return
                end
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
                        --ReceivedText = string.gsub(ReceivedText, "_", " ")
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


        if msg.text then -- check if message is text
            --ReceivedText = msg.text -- I dont read it again
            if HandleCommand(ReceivedText, tostring(telegramMsg_ReplyToId), telegramMsg_MsgId, telegramMsg_IsChannel) == 1 then
                print_info_to_log(0, "Succesfully handled incoming request")
            else
                print_info_to_log(0, "Invalid command received from:["..telegramMsg_FromId.."]")
                telegram_SendMsg(telegramMsg_ReplyToId, '⚡️Commande invalide ⚡️', telegramMsg_MsgId)
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
                if HandleCommand(ReceivedText, tostring(telegramMsg_ReplyToId), telegramMsg_MsgId, telegramMsg_IsChannel) == 1 then
                    print_info_to_log(0, "Succesfully handled incoming voice request")
                else
                    print_info_to_log(0, "Voice file received but voice.sh or lua not found to process it. skipping the message.")
                    print_info_to_log(1, "telegramMsg_FromId:"..telegramMsg_FromId)
                    telegram_SendMsg(telegramMsg_ReplyToId, '⚡️Commande invalide ⚡️', telegramMsg_MsgId)
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
                if HandleCommand(ReceivedText, tostring(telegramMsg_ReplyToId), telegramMsg_MsgId, telegramMsg_IsChannel) == 1 then
                    print_info_to_log(0, "Succesfully handled incoming video request")
                else
                    print_info_to_log(0, "Video file received but video_note.sh or lua not found to process it. Skipping the message.")
                    print_info_to_log(0, "telegramMsg_FromId:"..telegramMsg_FromId)
                    telegram_SendMsg(telegramMsg_ReplyToId, '⚡️Commande invalide ⚡️', telegramMsg_MsgId)
                end
            end
        end
    else
        print_warning_to_log(0, 'id['..telegramMsg_FromId..'] not on white list, command ignored')
        --telegram_SendMsg(telegramMsg_ReplyToId, '⚡️Votre identité est invalide : je vous ignore ⚡️', telegramMsg_MsgId)
    end
end

function id_check(telegramUserId)
    --Check if whitelist empty then let any message through
    if g_TelegramBotWhiteListedIDs == nil then
        return true
    else
        telegramUserId = tostring(telegramUserId)
        --Check id against whitelist
        for i = 1, #g_TelegramBotWhiteListedIDs do
            print_info_to_log(2, 'id_check: WhiteList[' .. g_TelegramBotWhiteListedIDs[i] .. '] ?')
            if telegramUserId == g_TelegramBotWhiteListedIDs[i] then
                print_info_to_log(1, 'id_check: WhiteList[' .. g_TelegramBotWhiteListedIDs[i] .. '] ok ')
                return true
            end
        end
        -- Checked WhiteList no match
        print_warning_to_log(0, 'id_check: WhiteList[' .. telegramUserId .. '] not allowed')
        return false
    end
end

function id_domoticzName(telegramUserId)
    --Check if whitelist empty then let any message through
    if g_TelegramBotWhiteListedIDs == nil or g_TelegramBotWhiteListedNames == nil then
        return "inconnu"
    else
        telegramUserId = tostring(telegramUserId)
        --Check id against whitelist
        for i = 1, #g_TelegramBotWhiteListedIDs do
            print_info_to_log(2, 'id_domoticzName:WhiteList[' .. g_TelegramBotWhiteListedIDs[i] .. '] ?')
            if telegramUserId == g_TelegramBotWhiteListedIDs[i] then
                local userName = g_TelegramBotWhiteListedNames[i]
                print_info_to_log(1, 'id_domoticzName:WhiteList[' .. g_TelegramBotWhiteListedIDs[i] .. ']:['..userName..']')
                return userName
            end
        end
        -- Checked WhiteList no match
        print_warning_to_log(0, 'id_check: WhiteList[' .. telegramUserId .. '] not allowed')
        return "non autorisé"
    end
end