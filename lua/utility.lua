local utility_module = {};
local http = require "socket.http";
--JSON = assert(loadfile "JSON.lua")() -- one-time load of the routines

--- the handler for the list commands. a module can have more than one handler. in this case the same handler handles two commands
function utility_module.handler(parsed_cli)
    local response = ""
    local status = 0

    local command = parsed_cli[2]
    command = string.lower(command)
    if command == 'refresh' then
        dtgbot_initialise()
        response = 'Global device, scene and room variables updated from Domoticz and modules code reloaded'
        return status, response
    elseif command == 'lcd' then
        local lcdMessage
        if ( #parsed_cli >= 3 ) then
            for idx = 3, #parsed_cli do
                if ( lcdMessage == nil ) then
                    lcdMessage = parsed_cli[idx]
                else
                    lcdMessage = lcdMessage ..' '..parsed_cli[idx]
                end
            end
            local lcdMessageEncoded = url_encode(lcdMessage)
            print_info_to_log(1,"utility.lua/lcd=msg[".. lcdMessage .."]")
            io.popen('/usr/bin/curl -s "http://192.168.1.110:8180/json.htm?type=command&param=updateuservariable&vname=LCD_Message&vtype=2&vvalue='.. lcdMessageEncoded ..'"')

            if ( string.len(lcdMessage) > 16 ) then
                lcdMessage = string.sub(lcdMessage,1,16)
                response = 'message ['.. lcdMessage ..'] sent (truncated:16 char max)'
            else
                response = 'message ['.. lcdMessage ..'] sent'
            end
        else
            status = 1
            response = "Missing parameter ! (no message)"
        end
        return status, response
    elseif command == 'get_variables' then
        response = "Variables <name>(idx)[type]\n"
        for name, idx in pairs(g_DomoticzVariableIdxPerNameList) do
            if ( name == nil ) then
                name = 'nil'
            end
            if ( idx == nil ) then
                idx = -1
            end
            local variableType = g_DomoticzVariableTypePerIdxList[idx]
            if ( variableType == nil ) then
                variableType = '-1'
            end
            response = response.."<"..name..">(idx:"..tostring(idx)..")["..tostring(variableType).."]\n"
        end
        --0 = Integer, e.g. -1, 1, 0, 2, 10
        --1 = Float, e.g. -1.1, 1.2, 3.1
        --2 = String
        --3 = Date in format DD/MM/YYYY
        --4 = Time in 24 hr format HH:MM
        response = response.."*types: 0=int(42),1=float(3.4),2=string(yo),4=date(dd/mm/yyyy),4=time 24h(hh:mm)*"
        print_info_to_log(0,"utility.lua/get_variables=["..response.."]")
        return status, response
    elseif ( command == 'get_variable' or command == 'set_variable' ) then
        local variableValueNew
        local variableTypeNew
        if ( command == 'set_variable' ) then
            if ( #parsed_cli >= 4 ) then
                variableValueNew = parsed_cli[4]
            else
                response = 'missing parameter <variableValue>'
                status = 1
                return status, response
            end
        end
        if ( #parsed_cli >= 3 ) then
            local variableName = parsed_cli[3]
            for name, idx in pairs(g_DomoticzVariableIdxPerNameList) do
                if ( name == nil ) then
                    name = 'nil'
                end
                if ( idx == nil ) then
                    idx = -1
                end
                if ( name == variableName ) then
                    local variableType = g_DomoticzVariableTypePerIdxList[idx]
                    if ( variableType == nil ) then
                        variableType = '-1'
                    end

                    local variableValue = domoticz_getVariableValueByIdx(idx)
                    if ( variableValue == nil ) then
                        variableValue = 'nil'
                    end

                    if ( command == 'set_variable') then
                        if ( #parsed_cli >= 5 ) then
                            variableType = parsed_cli[5]
                        end
                        domoticz_setVariableValueByIdx(idx, variableName, variableType, variableValueNew)
                        response = "set.<"..name..">(idx:"..tostring(idx)..")["..tostring(variableType).."] = ["..tostring(variableValueNew).."]"
                        print_info_to_log(0,"utility.lua/set_variable=["..response.."]")
                        return status, response
                    else
                        response = "get.<"..name..">(idx:"..tostring(idx)..")["..tostring(variableType).."] = ["..tostring(variableValue).."]"
                        print_info_to_log(0,"utility.lua/get_variable=["..response.."]")
                        return status, response
                    end
                end
            end
            response = "variable <"..variableName.."> not found"
            status = 1
            return status, response
        else
            response = 'missing parameter <variableName>'
            status = 1
            return status, response
        end
    else
        response = 'Wrong command'
        return status, response
    end
end

local utility_commands = {
    ["refresh"] = { handler = utility_module.handler, description = "refresh - reloads global variables and modules code" },
    ["lcd"] = { handler = utility_module.handler, description = "lcd - message to LCD" },
    ["get_variables"] = { handler = utility_module.handler, description = "get_variables - list all variables name" },
    ["get_variable"] = { handler = utility_module.handler, description = "get_variable - parameter=variableName return variable value" },
    ["set_variable"] = { handler = utility_module.handler, description = "set_variable - parameter=variableName,variableValue set variable value (optional variableType)" }
}

function utility_module.get_commands()
    return utility_commands;
end

return utility_module;
