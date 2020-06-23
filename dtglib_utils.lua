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

function split_string(theString, theSeparator)
    local result, i = {}, 1
    for word in theString:gmatch('[^'..theSeparator..']+') do
        word = string.gsub(word, '^%s*(.-)%s*$', '%1')
        result[i] = word
        i=i+1
    end
    return result
end

function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then io.close(f) return true else return false end
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
function lines_from(file)
    if not file_exists(file) then return {} end
    lines = {}
    for line in io.lines(file) do
        lines[#lines + 1] = line
    end
    return lines
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

-- SCAN through provided delimited string for the second parameter
function ChkInTableMatch(itab, idev)
    local cnt = 0
    if itab ~= nil then
        for dev in string.gmatch(itab, "[^|,]+") do
            cnt = cnt + 1
            if string.match(dev,idev) then
                print_info_to_log(3, "-< ChkInTableMatch found: [" .. idev .. '] match(' .. dev .. ')')
                return true, cnt
            end
        end
    end
    print_info_to_log(3, "-< ChkInTableMatch NOT found: [" .. idev .. '] match(' .. dev .. ')')
    return false, 0
end

function get_names_from_variable(DividedString)
    local Names = {}
    for Name in string.gmatch(DividedString, "[^|]+") do
        Names[#Names + 1] = Name
        print_info_to_log(1, 'get_names_from_variable: Name =' .. Name)
    end
    if Names == {} then
        Names = nil
    end
    return Names
end

function readFileToString(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

function starts_with(str, start)
    if ( str == nil or start == nil ) then
        return false
    else
        return str:sub(1, #start) == start
    end
end

function ends_with(str, ending)
    if ( str == nil or ending == nil ) then
        return false
    else
        return ending == "" or str:sub(-#ending) == ending
    end
end

function stripChars(str)
    local tableAccents = {}
    tableAccents["À"] = "A"
    tableAccents["Á"] = "A"
    tableAccents["Â"] = "A"
    tableAccents["Ã"] = "A"
    tableAccents["Ä"] = "A"
    tableAccents["Å"] = "A"
    tableAccents["Æ"] = "AE"
    tableAccents["Ç"] = "C"
    tableAccents["È"] = "E"
    tableAccents["É"] = "E"
    tableAccents["Ê"] = "E"
    tableAccents["Ë"] = "E"
    tableAccents["Ì"] = "I"
    tableAccents["Í"] = "I"
    tableAccents["Î"] = "I"
    tableAccents["Ï"] = "I"
    tableAccents["Ð"] = "D"
    tableAccents["Ñ"] = "N"
    tableAccents["Ò"] = "O"
    tableAccents["Ó"] = "O"
    tableAccents["Ô"] = "O"
    tableAccents["Õ"] = "O"
    tableAccents["Ö"] = "O"
    tableAccents["Ø"] = "O"
    tableAccents["Ù"] = "U"
    tableAccents["Ú"] = "U"
    tableAccents["Û"] = "U"
    tableAccents["Ü"] = "U"
    tableAccents["Ý"] = "Y"
    tableAccents["Þ"] = "P"
    tableAccents["ß"] = "s"
    tableAccents["à"] = "a"
    tableAccents["á"] = "a"
    tableAccents["â"] = "a"
    tableAccents["ã"] = "a"
    tableAccents["ä"] = "a"
    tableAccents["å"] = "a"
    tableAccents["æ"] = "ae"
    tableAccents["ç"] = "c"
    tableAccents["è"] = "e"
    tableAccents["é"] = "e"
    tableAccents["ê"] = "e"
    tableAccents["ë"] = "e"
    tableAccents["ì"] = "i"
    tableAccents["í"] = "i"
    tableAccents["î"] = "i"
    tableAccents["ï"] = "i"
    tableAccents["ð"] = "eth"
    tableAccents["ñ"] = "n"
    tableAccents["ò"] = "o"
    tableAccents["ó"] = "o"
    tableAccents["ô"] = "o"
    tableAccents["õ"] = "o"
    tableAccents["ö"] = "o"
    tableAccents["ø"] = "o"
    tableAccents["ù"] = "u"
    tableAccents["ú"] = "u"
    tableAccents["û"] = "u"
    tableAccents["ü"] = "u"
    tableAccents["ý"] = "y"
    tableAccents["þ"] = "p"
    tableAccents["ÿ"] = "y"
    local normalisedString = ''
    local normalisedString = str: gsub("[%z\1-\127\194-\244][\128-\191]*", tableAccents)
    return normalisedString
end