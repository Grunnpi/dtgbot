local list_module = {};
local http = require "socket.http";
--JSON = assert(loadfile "JSON.lua")() -- one-time load of the routines

--- the handler for the list commands. a module can have more than one handler. in this case the same handler handles two commands
function list_module.handler(parsed_cli)
    local response = "", jresponse, decoded_response, status;

    local match_type, mode;
    local i;

    if parsed_cli[2] == "dump" then
        mode = "full";
    else
        mode = "brief";
    end
    if parsed_cli[3] then
        match_type = string.lower(parsed_cli[3]);
    else
        match_type = "";
    end

    jresponse, status = http.request(g_DomoticzServeUrl .. "/json.htm?type=devices")
    if (jresponse ~= nil) then
        decoded_response = JSON:decode(jresponse)
        for k, record in pairs(decoded_response) do
            print_info_to_log(1,"list.lua",k, type(record))
            if type(record) == "table" then
                for k1, v1 in pairs(record) do
                    if string.find(string.lower(v1.Type), match_type) then
                        response = response .. list_device_attr(v1, mode) .. "\n";
                    end
                end
            else
                print_info_to_log(1, "list.lua/record:"..record)
            end
        end
    else
        print_warning_to_log(0, 'list.lua/No devices detected')
    end

    print_info_to_log(1, 'list.lua/response:[' .. response .. ']')
    return status, response;
end

local list_commands = {
    ["list"] = { handler = list_module.handler, description = "list devices, either all or specific type" },
    ["dump"] = { handler = list_module.handler, description = "list all information about devices, either all or specific type" }
}

function list_module.get_commands()
    return list_commands;
end

return list_module;
