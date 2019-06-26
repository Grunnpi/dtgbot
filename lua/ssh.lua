local ssh_module = {};
local http = require "socket.http";
--JSON = assert(loadfile "JSON.lua")() -- one-time load of the routines

function fetchDomoticzParameter(parameter_name)
    local status
    local response
    local parameter_value

    local parameter_idx = idx_from_variable_name(parameter_name)
    if ( parameter_idx ~= nil ) then
        parameter_value = get_variable_value(parameter_idx)
        if ( parameter_value ~= nil ) then
            -- ready to to
            status = 0
            response = ""
        else
            status = 1
            response = "‼️ Cannot find parameter value for ["..tostring(parameter_idx).."]"
        end
    else
        status = 1
        response = "‼️ Cannot find parameter Domoticz variable for ["..parameter_name.."]"
    end

    return status, response, parameter_value
end

function ssh_module.handler(parsed_cli)
    print_info_to_log(0,"ssh me ! ("..tostring(#parsed_cli)..")")

    local response = ""
    local status = 0

    -- command type
    local this_command = string.lower(parsed_cli[2])
    if ( #parsed_cli >= 2 ) then
        local ssh_host_parameter
        local ssh_command = nil
        if ( this_command == 'ssh' ) then
            if ( #parsed_cli >= 4 ) then
                ssh_host_parameter = string.lower(parsed_cli[3])
                for idx = 4, #parsed_cli do
                    if ( ssh_command == nil ) then
                        ssh_command = parsed_cli[idx]
                    else
                        ssh_command = ssh_command..' '..parsed_cli[idx]
                    end
                end
            else
                status = 1
                response = "‼️ missing parameter(s) : ssh <host> <commands>"
            end

        elseif ( this_command == 'ssh_bil_bot_start' ) then
            ssh_host_parameter = 'bil'
            ssh_command = 'sudo service dtgbot start'
        elseif ( this_command == 'ssh_bil_bot_pull' ) then
            ssh_host_parameter = 'bil'
            ssh_command = 'cd dtgbot;git pull'
        elseif ( this_command == 'ssh_bil_bot_stop' ) then
            ssh_host_parameter = 'bil'
            ssh_command = 'sudo service dtgbot stop'

        elseif ( this_command == 'ssh_bob_bot_start' ) then
            ssh_host_parameter = 'bob'
            ssh_command = 'sudo service dtgbot start'
        elseif ( this_command == 'ssh_bob_bot_pull' ) then
            ssh_host_parameter = 'bob'
            ssh_command = 'cd dtgbot;git pull'
        elseif ( this_command == 'ssh_bob_bot_stop' ) then
            ssh_host_parameter = 'bob'
            ssh_command = 'sudo service dtgbot stop'

        else
            ssh_host_parameter = "paf"
            ssh_command = "zob"
            print_info_to_log(0,"ssh["..ssh_command.."]")
        end

        if (status == 0) then
            -- find setup regarding host
            local ssh_host_ip
            local ssh_host_user
            local ssh_host_pwd

            status, response, ssh_host_user = fetchDomoticzParameter("TelegromBotSshUser"..ssh_host_parameter)
            if ( status == 0 ) then
                status, response, ssh_host_pwd = fetchDomoticzParameter("TelegromBotSshPwd"..ssh_host_parameter)
            end
            if ( status == 0 ) then
                status, response, ssh_host_ip = fetchDomoticzParameter("TelegromBotSshIp"..ssh_host_parameter)
            end

            if ( status == 0 ) then
                local os_ssh_logfile = g_BotTempFileDir..'/ssh_cmd.log'
                local os_ssh_command = "sshpass -p "..ssh_host_pwd.." ssh -o StrictHostKeyChecking=no "..ssh_host_user.."@"..ssh_host_ip..' '..ssh_command..' > '..os_ssh_logfile..' 2>&1'
                print_info_to_log(0,"os.execute('"..os_ssh_command.."') > ")
                if ( not g_TelegramBotIsOnWindows ) then
                    status = 1
                    response = "‼️ no ssh on window$"
                else
                    -- run & check log file
                    os.execute(os_ssh_command)

                    response = "command["..ssh_command.."] executed\n"
                    if (file_exists(os_ssh_logfile)) then
                        -- log ! grep it
                        local fullLog = readFileToString(os_ssh_logfile)
                        status = 0
                        response = response.."😀 output=["..fullLog.."]"
                    else
                        -- no log, raise error
                        status = 1
                        response = response.."😢 but no output log. Might have still run ok ?"
                    end
                end
            end
        end
    else
        status = 1
        response = "‼️ missing parameter(s) : check help "
    end

    print_info_to_log(0,"ssh.lua/response=["..response.."]")
    return status, response;
end

local ssh_commands = {
    ["ssh"] = { handler = ssh_module.handler, description = "ssh - remote stuff" },

    ["ssh_bil_bot_stop"] = { handler = ssh_module.handler, description = "ssh_bil_bot_stop - stop bil bot" },
    ["ssh_bil_bot_pull"] = { handler = ssh_module.handler, description = "ssh_bil_bot_pull - pull last git version" },
    ["ssh_bil_bot_start"] = { handler = ssh_module.handler, description = "ssh_bil_bot_stop - start bil bot" },

    ["ssh_bob_bot_stop"] = { handler = ssh_module.handler, description = "ssh_bob_bot_stop - start bil bot" },
    ["ssh_bob_bot_pull"] = { handler = ssh_module.handler, description = "ssh_bob_bot_pull - pull last git version" },
    ["ssh_bob_bot_start"] = { handler = ssh_module.handler, description = "ssh_bob_bot_stop - start bil bot" }
}

function ssh_module.get_commands()
    return ssh_commands;
end

return ssh_module;
