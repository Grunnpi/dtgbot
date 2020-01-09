local ssh_module = {};
local http = require "socket.http";
--JSON = assert(loadfile "JSON.lua")() -- one-time load of the routines

local SSH_BOT_START = 'sudo service dtgbot start'
local SSH_CD_DIRECTORY = 'cd dtgbot'
local SSH_GIT_PULL = 'git pull --force'
local SSH_GIT_PULL_RESET = 'git fetch --all;git reset --hard origin/master'
local SSH_KILL_BOT = 'sudo service dtgbot stop;sleep 5;sudo pkill -f dtgbot/dtgbot.lua'
local SSH_RM_LOGS = 'sudo cp /dev/null /var/tmp/dtb.log;sudo cp /dev/null /var/tmp/dtb.log.errors;sudo cp /dev/null /var/tmp/dtgloop.txt;sudo cp /dev/null /var/tmp/ssh_cmd.log'

function fetchDomoticzParameter(parameter_name)
    local status
    local response
    local parameter_value

    local parameter_idx = domoticz_cache_getVariableIdxByName(parameter_name)
    if ( parameter_idx ~= nil ) then
        parameter_value = domoticz_getVariableValueByIdx(parameter_idx)
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
    print_info_to_log(1,"ssh me ! ("..tostring(#parsed_cli)..")")

    local customResponse
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
                response = "‼️missing parameter(s) : ssh <host> <commands>"
            end
        else
            if ( starts_with(this_command,"ssh_bil") ) then
                ssh_host_parameter = 'bil'
            elseif ( starts_with(this_command,"ssh_bob") ) then
                ssh_host_parameter = 'bob'
            elseif ( starts_with(this_command,"ssh_eve") ) then
                ssh_host_parameter = 'eve'
            elseif ( starts_with(this_command,"ssh_hal") ) then
                ssh_host_parameter = 'hal'
            else
                ssh_host_parameter = 'local'
            end


            if (     ends_with(this_command,"_bot_start") ) then
                ssh_command = SSH_BOT_START
                customResponse = ":robot: revived !"
            elseif ( ends_with(this_command,"_bot_pull") ) then
                ssh_command = '"'.. SSH_CD_DIRECTORY ..';'.. SSH_GIT_PULL ..'"'
            elseif ( ends_with(this_command,"_bot_pull_reset") ) then
                ssh_command = '"'.. SSH_CD_DIRECTORY ..';'.. SSH_GIT_PULL_RESET ..'"'
            elseif ( ends_with(this_command,"_bot_checkout") ) then
                if ( #parsed_cli >= 3 ) then
                    ssh_command = '"'.. SSH_CD_DIRECTORY ..';git fetch;git checkout ' .. parsed_cli[3] ..'"'
                else
                    ssh_command = '"'.. SSH_CD_DIRECTORY ..';git fetch;git checkout master"'
                end
            elseif ( ends_with(this_command,"_bot_rmlogs") ) then
                ssh_command = '"'.. SSH_RM_LOGS ..'"'
            elseif ( ends_with(this_command,"_bot_stop") ) then
                ssh_command = '"'.. SSH_KILL_BOT ..'"'
                customResponse = "bot killed ☠️"
            elseif ( ends_with(this_command,"_bot_logs") ) then
                ssh_command = '"sudo tail -5 /var/tmp/dtgloop.txt;sudo tail -30 /var/tmp/dtb.log;sudo tail -30 /var/tmp/dtb.log.errors;sudo tail -30 /var/tmp/ssh_cmd.log"'
            elseif ( ends_with(this_command,"_bot_upgrade") ) then
                ssh_command = '"' .. SSH_KILL_BOT .. ';' .. SSH_GIT_PULL .. ';' .. SSH_RM_LOGS .. ';' .. SSH_BOT_START .. '"'
            elseif ( ends_with(this_command,"_restart_domoticz") ) then
                ssh_command = 'sudo service domoticz restart'
            elseif ( ends_with(this_command,"_crotte_purge") ) then
                ssh_command = 'sudo rm -rf /var/lib/motioneye/Camera1/*'
            else
                ssh_command = "zob"
            end
        end

        if (status == 0) then
            if ( ssh_host_parameter ~= 'local') then
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
            end

            print_info_to_log(2,"ssh parsed")
            print_info_to_log(2,ssh_host_ip)
            print_info_to_log(2,ssh_host_user)
            print_info_to_log(2,ssh_host_pwd)
            print_info_to_log(2,ssh_command)

            if ( status == 0 ) then
                local os_ssh_logfile = g_BotTempFileDir..'/ssh_cmd.log'
                local os_ssh_command
                if ( ssh_host_parameter ~= 'local') then
                    os_ssh_command = "sshpass -p "..ssh_host_pwd.." ssh -o StrictHostKeyChecking=no "..ssh_host_user.."@"..ssh_host_ip..' '..ssh_command..' > '..os_ssh_logfile..' 2>&1'
                else
                    os_ssh_command = ssh_command ..' > '..os_ssh_logfile..' 2>&1'
                end
                print_info_to_log(0,"os.execute('"..os_ssh_command.."') > ")
                if ( g_TelegramBotIsOnWindows ) then
                    status = 1
                    response = "‼️ no ssh on window$"
                else
                    -- run & check log file
                    os.execute(os_ssh_command)

                    response = "command["..ssh_command.."] executed\n"
                    if ( customResponse ~= nil ) then
                        response = response..customResponse..'\n'
                    end
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
    ["ssh_bil_bot_checkout"] = { handler = ssh_module.handler, description = "ssh_bil_bot_checkout - checkout + optional tag parameter (master default)" },
    ["ssh_bil_bot_upgrade"] = { handler = ssh_module.handler, description = "ssh_bil_bot_upgrade - upgrade to last version" },
    ["ssh_bil_bot_pull"] = { handler = ssh_module.handler, description = "ssh_bil_bot_pull - pull last git version" },
    ["ssh_bil_bot_pull_reset"] = { handler = ssh_module.handler, description = "ssh_bil_bot_pull_reset - fetch and reset last git master" },
    ["ssh_bil_bot_start"] = { handler = ssh_module.handler, description = "ssh_bil_bot_start - start bil bot" },
    ["ssh_bil_bot_logs"] = { handler = ssh_module.handler, description = "ssh_bil_bot_logs - cat log/error" },
    ["ssh_bil_bot_rmlogs"] = { handler = ssh_module.handler, description = "ssh_bil_bot_rmlogs - empty log/error" },

    ["ssh_eve_crotte_purge"] = { handler = ssh_module.handler, description = "ssh_eve_crotte_purge - supprimer les photos de la CamCrotte" },

    ["ssh_bob_bot_stop"] = { handler = ssh_module.handler, description = "ssh_bob_bot_stop - start bil bot" },
    ["ssh_bob_bot_checkout"] = { handler = ssh_module.handler, description = "ssh_bob_bot_checkout - checkout + optional tag parameter (master default)" },
    ["ssh_bob_bot_upgrade"] = { handler = ssh_module.handler, description = "ssh_bob_bot_upgrade - upgrade to last version" },
    ["ssh_bob_bot_pull"] = { handler = ssh_module.handler, description = "ssh_bob_bot_pull - pull last git version" },
    ["ssh_bob_bot_pull_reset"] = { handler = ssh_module.handler, description = "ssh_bob_bot_pull_reset - fetch and reset last git master" },
    ["ssh_bob_bot_start"] = { handler = ssh_module.handler, description = "ssh_bob_bot_start - start bil bot" },
    ["ssh_bob_bot_logs"] = { handler = ssh_module.handler, description = "ssh_bob_bot_logs - cat log/error" },
    ["ssh_bob_bot_rmlogs"] = { handler = ssh_module.handler, description = "ssh_bob_bot_rmlogs - empty log/error" },

    ["ssh_restart_domoticz"] = { handler = ssh_module.handler, description = "ssh_restart_domoticz - restart service" }
}

function ssh_module.get_commands()
    return ssh_commands;
end

return ssh_module;
