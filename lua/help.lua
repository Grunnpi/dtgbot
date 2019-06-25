local help_module = {};
--local http = require "socket.http";

--- the handler for the list commands. a module can have more than one handler. in this case the same handler handles two commands
function help_module.handler(parsed_cli)
    local response = "", status;

    command = parsed_cli[3]
    if (command ~= "" and command ~= nil) then
        command_dispatch = commands[string.lower(command)];
        if command_dispatch then
            if (ChkInTable(TelegramBotLuaExclude, command)) then
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
    local DotPos = 0

    HelpText = 'Version=' .. dtgbot_version .. '\n'
    HelpText = HelpText .. '⚠️ Available Lua commands ⚠️ \n'
    for i, help in pairs(commands) do
        newCommand = string.gmatch(help.description, "%S+") [[1]] .. ''
        -- filter TelegramBotBashExclude
        if (ChkInTable(TelegramBotLuaExclude, newCommand)) then
            print_info_to_log(2, 'WARN help::list lua command:' .. newCommand .. ' filtered')
        else
            newCommandHelper = TelegramBotName .. '_' .. newCommand
            print_info_to_log(2, 'help::list lua command:' .. newCommandHelper)
            HelpText = HelpText .. "/" .. newCommandHelper .. '\n'
        end
    end

    HelpText = string.sub(HelpText, 1, -2) .. '\n<help command> - gives usage information, i.e. "help list" \n\n'

    if (TelegramBotIsOnWindows) then
        cmdListDir = 'dir /B'
    else
        cmdListDir = 'ls'
    end

    local Functions = io.popen(cmdListDir .. " " .. BotBashScriptPath)
    HelpText = HelpText .. '⚠️ Available Shell commands ⚠️ \n'
    for line in Functions:lines() do
        DotPos = string.find(line, "%.")
        newCommand = string.sub(line, 0, DotPos - 1)

        -- filter TelegramBotBashExclude
        if (ChkInTable(TelegramBotBashExclude, newCommand)) then
            print_info_to_log(2, 'WARN help::list bash command:' .. newCommand .. ' filtered')
        else
            newCommandHelper = TelegramBotName .. '_' .. newCommand
            print_info_to_log(2, 'help::list bash command:' .. newCommandHelper)
            HelpText = HelpText .. "/" .. newCommandHelper .. '\n'
        end
    end

    print_info_to_log(1, '[help:global]=['.. HelpText..']')
    return status, HelpText;
end

local help_commands = {
    ["help"] = { handler = help_module.handler, description = "help - list all help information" },
    ["start"] = { handler = help_module.handler, description = "start - list all help information" }
}

function help_module.get_commands()
    return help_commands;
end

return help_module;
