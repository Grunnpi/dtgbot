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
