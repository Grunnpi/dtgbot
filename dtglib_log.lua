-- print to log with time and date
function print_to_console(logType, loglevel, logmessage, ...)
    -- when only one parameter is provided => set the loglevel to 0 and assume the parameter is the messagetext
    if tonumber(loglevel) == nil or logmessage == nil then
        logmessage = loglevel
        loglevel = 0
    end
    if loglevel > 0 and logType == ' INFO' then
        logType = 'DEBUG'
    end
    if loglevel <= g_dtgbotLogLevel then
        local logcount = #{ ... }
        if logcount > 0 then
            for i, v in pairs({ ... }) do
                logmessage = logmessage .. ' (' .. tostring(i) .. ') ' .. tostring(v)
            end
            logmessage = tostring(logmessage):gsub(" (.+) nil", "")
        end
        print(os.date("%Y-%m-%d %H:%M:%S") .. ' - [' .. logType .. ':' .. loglevel .. '] ' .. tostring(logmessage))
    end
end

-- print to log with time and date
function print_info_to_log(loglevel, logmessage, ...) -- #########################################################
    print_to_console(" INFO", loglevel, logmessage, ...)
end

function print_error_to_log(loglevel, logmessage, ...) -- #########################################################
    print_to_console("ERROR", loglevel, logmessage, ...)
end

function print_warning_to_log(loglevel, logmessage, ...) -- #########################################################
    print_to_console(" WARN", loglevel, logmessage, ...)
end

function errorHandling(err)
    local current_func = debug.getinfo(1)
    local calling_func = debug.getinfo(2)
    print_error_to_log(0,current_func.name.. " was called by ".. calling_func.name.. "!")
    print_error_to_log(0, err)
end




