-- other functions
function isWindowsOS()
    local current_dir = io.popen "cd":read '*l'
    if (current_dir == nil) then
        current_dir = ''
    else
        current_dir = string.sub(current_dir, 2, 2)
    end
    return (current_dir == ':')
end

function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then io.close(f) return true else return false end
end

function url_encode(str)
    if (str) then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w %-%_%.%~])",
            function(c) return string.format("%%%02X", string.byte(c)) end)
        str = string.gsub(str, " ", "+")
    end
    return str
end

-- SCAN through provided delimited string for the second parameter
function ChkInTable(itab, idev)
    local cnt = 0
    if itab ~= nil then
        for dev in string.gmatch(itab, "[^|,]+") do
            cnt = cnt + 1
            if dev == idev then
                print_info_to_log(3, "-< ChkInTable found: " .. idev, cnt, itab)
                return true, cnt
            end
        end
    end
    print_info_to_log(3, "-< ChkInTable not found: " .. idev, cnt, itab)
    return false, 0
end

function readFileToString(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end