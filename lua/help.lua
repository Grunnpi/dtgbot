local help_module = {};

--- the handler for the list commands. a module can have more than one handler. in this case the same handler handles two commands
function help_module.handler(parsed_cli)
    local response = ""
    local status = 0

    local command = parsed_cli[3]
    if (command ~= "" and command ~= nil) then
        local command_dispatch = g_commandsLua[string.lower(command)];
        if command_dispatch then
            if (ChkInTable(g_TelegramBotLuaExclude, command)) then
                response = command .. ' filtered in your list of command'
            else
                response = command_dispatch.description;
            end
        else
            response = command .. ' was not found - check spelling and capitalisation - Help for list of commands'
        end
        print_info_to_log(0, '[help:specific]=' .. response)
        return status, response
    end

    local HelpText = 'Version=' .. g_dtgbot_version .. '\n'
    HelpText = HelpText .. '⚠️ Available Lua commands ⚠️ \n'
    local commandLuaOrdered = {}
    for i, help in pairs(g_commandsLua) do
        local newCommand = string.gmatch(help.description, "%S+") [[1]] .. ''
        -- filter g_TelegramBotBashExclude
        if (ChkInTable(g_TelegramBotLuaExclude, newCommand)) then
            print_info_to_log(2, 'WARN help::list lua command:' .. newCommand .. ' filtered')
        else
            table.insert(commandLuaOrdered, newCommand)
--            newCommandHelper = g_TelegramBotName .. '_' .. newCommand
--            print_info_to_log(2, 'help::list lua command:' .. newCommandHelper)
--            HelpText = HelpText .. "/" .. newCommandHelper .. '\n'
        end
    end
    table.sort(commandLuaOrdered)
    for i = 1, #commandLuaOrdered do
        local newCommandHelper = g_TelegramBotName .. '_' .. commandLuaOrdered[i]
        print_info_to_log(2, 'help::list lua command:' .. newCommandHelper)
        HelpText = HelpText .. "/" .. newCommandHelper .. '\n'
    end

    HelpText = string.sub(HelpText, 1, -2) .. '\n<help command> - gives usage information, i.e. "help list" \n\n'
    local cmdListDir = ""
    if (g_TelegramBotIsOnWindows) then
        cmdListDir = 'dir /B'
    else
        cmdListDir = 'ls'
    end

    local Functions = io.popen(cmdListDir .. " " .. g_BotBashScriptPath)
    HelpText = HelpText .. '⚠️ Available Shell commands ⚠️ \n'
    for line in Functions:lines() do
        local DotPos = string.find(line, "%.")
        local newCommand = string.sub(line, 0, DotPos - 1)
        -- filter g_TelegramBotBashExclude
        if (ChkInTable(g_TelegramBotBashExclude, newCommand)) then
            print_info_to_log(2, 'WARN help::list bash command:' .. newCommand .. ' filtered')
        else
            local newCommandHelper = g_TelegramBotName .. '_' .. newCommand
            print_info_to_log(2, 'help::list bash command:' .. newCommandHelper)
            HelpText = HelpText .. "/" .. newCommandHelper .. '\n'
        end
    end

    print_info_to_log(1, '[help:global]=['.. HelpText..']')
    return status, HelpText;
end

local help_commands = {
    ["help"] = { handler = help_module.handler, description = "help - list all help information" }
}

function help_module.get_commands()
    return help_commands;
end

return help_module;
