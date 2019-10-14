-- A set of support functions currently aimed at dtgbot,
-- but probably more general

function form_device_name(parsed_cli)
    -- joins together parameters after the command name to form the full "device name"
    command = parsed_cli[2]
    DeviceName = parsed_cli[3]
    len_parsed_cli = #parsed_cli
    if len_parsed_cli > 3 then
        for i = 4, len_parsed_cli do
            DeviceName = DeviceName .. ' ' .. parsed_cli[i]
        end
    end
    return DeviceName
end

-- returns list of all user variables - called early by dtgbot
-- in case Domoticz is not running will retry
-- allowing Domoticz time to start
function domoticz_getVariableFullList()
    local t, jresponse, status, decoded_response
    t = g_DomoticzServeUrl .. "/json.htm?type=command&param=getuservariables"
    jresponse = nil
    local domoticz_tries = 1
    -- Domoticz seems to take a while to respond to getuservariables after start-up
    -- So just keep trying after 1 second sleep
    while (jresponse == nil) do
        print_info_to_log(1, "JSON request <" .. t .. ">");
        jresponse, status = http.request(t)
        if (jresponse == nil) then
            socket.sleep(1)
            domoticz_tries = domoticz_tries + 1
            if domoticz_tries > 20 then
                print_info_to_log(0, 'Domoticz not sending back user variable list')
                break
            end
        end
    end
    print_info_to_log(0, 'Domoticz returned getuservariables after ' .. domoticz_tries .. ' attempts')
    if jresponse ~= nil then
        decoded_response = JSON:decode(jresponse)
    else
        decoded_response = {}
        decoded_response["result"] = "{}"
    end
    return decoded_response
end

-- returns idx of a user variable from name
function domoticz_getVariableIdxPerNameList()
    local idx, k, record, decoded_response
    decoded_response = domoticz_getVariableFullList()
    local result = decoded_response["result"]
    local variables = {}
    for i = 1, #result do
        record = result[i]
        if type(record) == "table" then
            variables[record['Name']] = record['idx']
        end
    end
    return variables
end

-- returns idx of a user variable from name
function domoticz_getVariableTypePerIdxList()
    local idx, k, record, decoded_response
    decoded_response = domoticz_getVariableFullList()
    local result = decoded_response["result"]
    local variables = {}
    for i = 1, #result do
        record = result[i]
        if type(record) == "table" then
            variables[record['idx']] = record['Type']
        end
    end
    return variables
end

function domoticz_cache_getVariableIdxByName(DeviceName)
    return g_DomoticzVariableIdxPerNameList[DeviceName]
end

-- returns the value of the variable from the idx
function domoticz_getVariableValueByIdx(idx)
    local t, jresponse, decoded_response
    if idx == nil then
        return ""
    end
    t = g_DomoticzServeUrl .. "/json.htm?type=command&param=getuservariable&idx=" .. tostring(idx)
    print_info_to_log(1, "domoticz_getVariableValueByIdx: JSON request <" .. t .. ">");
    jresponse, status = http.request(t)
    local returnValue = ""
    if (jresponse ~= nil) then
        decoded_response = JSON:decode(jresponse)
        returnValue = decoded_response["result"][1]["Value"]
        print_info_to_log(1, 'domoticz_getVariableValueByIdx: Decoded ' .. returnValue)
    else
        print_error_to_log(0, 'domoticz_getVariableValueByIdx(' .. idx .. ') return nil value. Assume empty value')
    end
    return returnValue
end

function domoticz_setVariableValueByIdx(idx, name, Type, value)
    -- store the value of a user variable
    local t, jresponse, decoded_response
    t = g_DomoticzServeUrl .. "/json.htm?type=command&param=updateuservariable&idx=" .. idx .. "&vname=" .. name .. "&vtype=" .. Type .. "&vvalue=" .. tostring(value)
    print_info_to_log(1, "domoticz_setVariableValueByIdx: JSON request <" .. t .. ">");
    jresponse, status = http.request(t)
    return
end

function domoticz_createVariable(name, Type, value)
    -- creates user variable
    local t, jresponse, decoded_response, status
    t = g_DomoticzServeUrl .. "/json.htm?type=command&param=saveuservariable&vname=" .. name .. "&vtype=" .. Type .. "&vvalue=" .. tostring(value)
    print_info_to_log(1, "JSON request <" .. t .. ">");
    jresponse, status = http.request(t)
    print_info_to_log(1, "JSON status:"..status .. "/response <" .. jresponse .. ">");
    return
end

function get_names_from_variable(DividedString)
    Names = {}
    for Name in string.gmatch(DividedString, "[^|]+") do
        Names[#Names + 1] = Name
        print_info_to_log(1, 'get_names_from_variable: Name =' .. Name)
    end
    if Names == {} then
        Names = nil
    end
    return Names
end

-- returns a device table of Domoticz items based on type i.e. devices or scenes
function domoticz_getDeviceListByType(DeviceType)
    local t, jresponse, status, decoded_response
    t = g_DomoticzServeUrl .. "/json.htm?type=" .. DeviceType .. "&order=name&used=true"
    print_info_to_log(1, "domoticz_getDeviceListByType:JSON request <" .. t .. ">");
    jresponse, status = http.request(t)
    if jresponse ~= nil then
        decoded_response = JSON:decode(jresponse)
    else
        print_info_to_log(3, "domoticz_getDeviceListByType:nil assume empty table");
        decoded_response = {}
        decoded_response["result"] = {}
    end
    return decoded_response
end

-- returns a list of Domoticz items based on type i.e. devices or scenes
function domoticz_getDeviceAndPropertiesListByType(DeviceType)
    --returns a devcie idx based on its name
    local idx, k, record, decoded_response
    decoded_response = domoticz_getDeviceListByType(DeviceType)
    local result = decoded_response['result']
    local devices = {}
    local devicesproperties = {}
    if result ~= nil then
        for i = 1, #result do
            record = result[i]
            if type(record) == "table" then
                if DeviceType == "plans" then
                    devices[record['Name']] = record['idx']
                else
                    devices[string.lower(record['Name'])] = record['idx']
                    devices[record['idx']] = record['Name']
                    if DeviceType == 'scenes' then
                        devicesproperties[record['idx']] = { Type = record['Type'], SwitchType = record['Type'] }
                    end
                end
            end
        end
    else
        print_info_to_log(0, " !!!! domoticz_getDeviceAndPropertiesListByType(): nothing found for ", DeviceType)
    end
    return devices, devicesproperties
end

function domoticz_cache_getDeviceIdxByNameByType(DeviceName, DeviceType)
    --returns a devcie idx based on its name
    if DeviceType == "devices" then
        return g_DomoticzDeviceList[string.lower(DeviceName)]
    elseif DeviceType == "scenes" then
        return g_DomoticzSceneList[string.lower(DeviceName)]
    else
        return g_DomoticzRoomList[DeviceName]
    end
end

function domoticz_getDeviceStatusByIdxByType(idx, DeviceType)
    local t, jresponse, status, decoded_response
    t = g_DomoticzServeUrl .. "/json.htm?type=" .. DeviceType .. "&rid=" .. tostring(idx)
    print_info_to_log(2, "JSON request <" .. t .. ">");
    jresponse, status = http.request(t)
    if jresponse ~= nil then
        decoded_response = JSON:decode(jresponse)
    else
        decoded_response = {}
        decoded_response['result'] = ""
    end
    return decoded_response
end

-- support function to scan through the Devices and Scenes idx tables and retrieve the required information for it
function devinfo_from_name(idx, DeviceName, DeviceScene)
    local k, record, Type, DeviceType, SwitchType
    local found = 0
    local rDeviceName = ""
    local status = ""
    local LevelNames = ""
    local LevelInt = 0
    local MaxDimLevel = 100
    local ridx = 0
    local tvar
    if DeviceScene ~= "scenes" then
        -- Check for Devices
        -- Have the device name
        if DeviceName ~= "" then
            idx = domoticz_cache_getDeviceIdxByNameByType(DeviceName, 'devices')
        end
        print_info_to_log(2, "==> start devinfo_from_name", idx, DeviceName)
        if idx ~= nil then
            tvar = domoticz_getDeviceStatusByIdxByType(idx, "devices")['result']
            if tvar == nil then
                found = 9
            else
                record = tvar[1]
                if record ~= nil and record.Name ~= nil and record.idx ~= nil then
                    print_info_to_log(2, 'device ', DeviceName, record.Name, idx, record.idx)
                end
                if type(record) == "table" then
                    ridx = record.idx
                    rDeviceName = record.Name
                    DeviceType = "devices"
                    Type = record.Type
                    LevelInt = record.LevelInt
                    if LevelInt == nil then LevelInt = 0 end
                    LevelNames = record.LevelNames
                    if LevelNames == nil then LevelNames = "" end
                    -- as default simply use the status field
                    -- use the dtgbot_type_status to retrieve the status from the "other devices" field as defined in the table.
                    print_info_to_log(2, 'Type ', Type)
                    if dtgbot_type_status[Type] ~= nil then
                        print_info_to_log(2, 'dtgbot_type_status[Type] ', dtgbot_type_status[Type])
                        if dtgbot_type_status[Type].Status ~= nil then
                            status = ''
                            CurrentStatus = dtgbot_type_status[Type].Status
                            print_info_to_log(2, 'CurrentStatus ', CurrentStatus)
                            for i = 1, #CurrentStatus do
                                if status ~= '' then
                                    status = status .. ' - '
                                end
                                cindex, csuffix = next(CurrentStatus[i])
                                status = status .. tostring(record[cindex]) .. tostring(csuffix)
                                print_info_to_log(2, 'status ', status)
                            end
                        end
                    else
                        SwitchType = record.SwitchType
                        -- Check for encoded selector LevelNames
                        if SwitchType == "Selector" then
                            if string.find(LevelNames, "[|,]+") then
                                print_info_to_log(2, "--  < 4.9700 selector switch levelnames: ", LevelNames)
                            else
                                LevelNames = mime.unb64(LevelNames)
                                print_info_to_log(2, "--  >= 4.9700  decoded selector switch levelnames: ", LevelNames)
                            end
                        end
                        MaxDimLevel = record.MaxDimLevel
                        status = tostring(record.Status)
                    end
                    found = 1
                    --~         print_info_to_log(2," !!!! found device",record.Name,rDeviceName,record.idx,ridx)
                end
            end
        end
        --~     print_info_to_log(2," !!!! found device",rDeviceName,ridx)
    end
    -- Check for Scenes
    if found == 0 then
        if DeviceName ~= "" then
            idx = domoticz_cache_getDeviceIdxByNameByType(DeviceName, 'scenes')
        else
            DeviceName = domoticz_cache_getDeviceIdxByNameByType(idx, 'scenes')
        end
        if idx ~= nil then
            DeviceName = g_DomoticzSceneList[idx]
            DeviceType = "scenes"
            ridx = idx
            rDeviceName = DeviceName
            SwitchType = g_DomoticzSceneProperties[tostring(idx)]['SwitchType']
            Type = g_DomoticzSceneProperties[tostring(idx)]['Type']
            found = 1
        end
    end
    -- Check for Scenes
    if found == 0 or found == 9 then
        ridx = 9999
        DeviceType = "command"
        Type = "command"
        SwitchType = "command"
    end
    print_info_to_log(2, " --< devinfo_from_name:", found, ridx, rDeviceName, DeviceType, Type, SwitchType, status, LevelNames, LevelInt)
    return ridx, rDeviceName, DeviceType, Type, SwitchType, MaxDimLevel, status, LevelNames, LevelInt
end

-- Switch functions
function SwitchID(DeviceName, idx, DeviceType, state, SendTo)
    if string.lower(state) == "on" then
        state = "On";
    elseif string.lower(state) == "off" then
        state = "Off";
    else
        return "state must be on or off!";
    end
    t = g_DomoticzServeUrl .. "/json.htm?type=command&param=switch" .. DeviceType .. "&idx=" .. idx .. "&switchcmd=" .. state;
    print_info_to_log(1, "JSON request <" .. t .. ">");
    jresponse, status = http.request(t)
    print_info_to_log(1, "raw jason", jresponse)
    response = 'Switched ' .. DeviceName .. ' ' .. command
    return response
end

function sSwitchName(DeviceName, DeviceType, SwitchType, idx, state)
    local status
    if idx == nil then
        response = 'Device ' .. DeviceName .. '  not found.'
    else
        local subgroup = "light"
        if DeviceType == "scenes" then
            subgroup = "scene"
        end
        if string.lower(state) == "on" then
            state = "On";
            t = g_DomoticzServeUrl .. "/json.htm?type=command&param=switch" .. subgroup .. "&idx=" .. idx .. "&switchcmd=" .. state;
        elseif string.lower(state) == "off" then
            state = "Off";
            t = g_DomoticzServeUrl .. "/json.htm?type=command&param=switch" .. subgroup .. "&idx=" .. idx .. "&switchcmd=" .. state;
        elseif string.lower(string.sub(state, 1, 9)) == "set level" then
            t = g_DomoticzServeUrl .. "/json.htm?type=command&param=switch" .. subgroup .. "&idx=" .. idx .. "&switchcmd=Set%20Level&level=" .. string.sub(state, 11)
        else
            return "state must be on, off or Set Level!";
        end
        print_info_to_log(3, "JSON request <" .. t .. ">");
        jresponse, status = http.request(t)
        print_info_to_log(3, "JSON feedback: ", jresponse)
        response = dtgmenu_lang[g_DomoticzLanguage].text["Switched"] .. ' ' .. DeviceName .. ' => ' .. state
    end
    print_info_to_log(0, "   -< sSwitchName:", DeviceName, idx, status, response)
    return response, status
end


-- Original XMPP function to list device properties
function list_device_attr(dev, mode)
    local result = "";
    local exclude_flag;
    -- Don't dump these fields as they are boring. Name data and idx appear anyway to exclude them
    local exclude_fields = { "Name", "Data", "idx", "SignalLevel", "CustomImage", "Favorite", "HardwareID", "HardwareName", "HaveDimmer", "HaveGroupCmd", "HaveTimeout", "Image", "IsSubDevice", "Notifications", "PlanID", "Protected", "ShowNotifications", "StrParam1", "StrParam2", "SubType", "SwitchType", "SwitchTypeVal", "Timers", "TypeImg", "Unit", "Used", "UsedByCamera", "XOffset", "YOffset" };
    result = "<" .. dev.Name .. ">, Data: " .. dev.Data .. ", Idx: " .. dev.idx;
    if mode == "full" then
        for k, v in pairs(dev) do
            exclude_flag = 0;
            for i, k1 in ipairs(exclude_fields) do
                if k1 == k then
                    exclude_flag = 1;
                    break;
                end
            end
            if exclude_flag == 0 then
                result = result .. k .. "=" .. tostring(v) .. ", ";
            else
                exclude_flag = 0;
            end
        end
    end
    return result;
end

function domoticz_language()
    local t, jresponse, status, decoded_response
    t = g_DomoticzServeUrl .. "/json.htm?type=command&param=getlanguage"
    jresponse = nil
    print_info_to_log(1, "JSON request <" .. t .. ">");
    jresponse, status = http.request(t)
    if jresponse ~= nil then
        decoded_response = JSON:decode(jresponse)
    else
        decoded_response = {}
        decoded_response["result"] = "{}"
    end
    local language = decoded_response['language']
    if language ~= nil then
        return language
    else
        return 'en'
    end
end

