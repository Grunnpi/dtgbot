function ok_cb(extra, success, result)
end

function vardump(value, depth, key)
    local linePrefix = ""
    local spaces = ""

    if key ~= nil then
        linePrefix = "[" .. key .. "] = "
    end

    if depth == nil then
        depth = 0
    else
        depth = depth + 1
        for i = 1, depth do spaces = spaces .. "  " end
    end

    if type(value) == 'table' then
        mTable = getmetatable(value)
        if mTable == nil then
            print_info_to_log(1, spaces .. linePrefix .. "(table) ")
        else
            print_info_to_log(1, spaces .. "(metatable) ")
            value = mTable
        end
        for tableKey, tableValue in pairs(value) do
            vardump(tableValue, depth, tableKey)
        end
    elseif type(value) == 'function' or
            type(value) == 'thread' or
            type(value) == 'userdata' or
            value == nil then
        print_info_to_log(1, spaces .. tostring(value))
    else
        print_info_to_log(1, spaces .. linePrefix .. "(" .. type(value) .. ") " .. tostring(value))
    end
end


function timedifference(s)
    year = string.sub(s, 1, 4)
    month = string.sub(s, 6, 7)
    day = string.sub(s, 9, 10)
    hour = string.sub(s, 12, 13)
    minutes = string.sub(s, 15, 16)
    seconds = string.sub(s, 18, 19)
    t1 = os.time()
    t2 = os.time { year = year, month = month, day = day, hour = hour, min = minutes, sec = seconds }
    difference = os.difftime(t1, t2)
    return difference
end

--function on_our_id (id)
--  our_id = id
--end

function on_secret_chat_created(peer)
    --vardump (peer)
end

function on_user_update(user)
    --vardump (user)
end

function on_chat_update(user)
    --vardump (user)
end

function on_get_difference_end()
end

function on_binlog_replay_end()
    started = 1
end


function id_check_for_function(SendTo, FunctionName)
    FunctionWhiteList = 'TelegramWhiteListFor' .. FunctionName

    -- Retrieve id white list
    FunctionWhiteListIdx = idx_from_variable_name(FunctionWhiteList)
    if FunctionWhiteListIdx == nil then
        print_info_to_log(0, FunctionWhiteList .. ' user variable does not exist in Domoticz')
        print_info_to_log(0, 'So will allow any id to use the bot')
    else
        print_info_to_log(0, 'FunctionWhiteListIdx ' .. FunctionWhiteListIdx)
        FunctionWhiteListName = get_variable_value(FunctionWhiteListIdx)
        print_info_to_log(0, 'FunctionWhiteListValue: ' .. FunctionWhiteListName)
        FunctionWhiteListValue = get_names_from_variable(FunctionWhiteListName)
    end

    --Check if whitelist empty then let any message through
    if FunctionWhiteListValue == nil then
        return true
    else
        SendTo = tostring(SendTo)
        --Check id against whitelist
        for i = 1, #FunctionWhiteListValue do
            print_info_to_log(0, 'WhiteList: ' .. FunctionWhiteListValue[i])
            if SendTo == FunctionWhiteListValue[i] then
                return true
            end
        end
        -- Checked WhiteList no match
        print_info_to_log(0, 'Not on WhiteList: ' .. SendTo)
        return false
    end
end

