local bp_module = {};
local http = require "socket.http";
--JSON = assert(loadfile "JSON.lua")() -- one-time load of the routines

function bp_module.handler(parsed_cli)
    local response = ""
    local status = 0

    local bp_file = g_BotTempFileDir .. "/bp.csv"
    print_info_to_log(1,"file bp_file=["..bp_file.."]")

    local command = parsed_cli[2]
    command = string.lower(command)
    if command == 'bp' then

        local bp_command = ''
        for i, v in ipairs(parsed_cli) do
            if ( i == 3 ) then
                bp_command = v
            elseif ( i > 3 ) then
                bp_command = bp_command .. ' ' .. v
            end
        end
        print_info_to_log(1,"bp_command=["..bp_command.."]")

        local split_bp = split_string(bp_command,";")
        for i, v in ipairs(split_bp) do
            print_info_to_log(1,"bp["..i.."]=["..v.."]")
        end

        if ( #split_bp < 2 ) then
            status = 1
            response = '2 infos séparées par des ;, ce n\'est pas assez'
        elseif ( #split_bp > 4) then
            status = 1
            response = 'plus que 4 infos séparées par des ;, c\'est trop'
        else
            local montant = split_bp[1]
            local tier = split_bp[2]
            local commentaire = ""
            local date = os.date("%Y-%m-%d")

            montant = montant:gsub(",", ".")
            if ( #split_bp > 2 ) then
                commentaire = split_bp[3]
            end
            if ( #split_bp > 3 ) then
                date = split_bp[4]
            end

            if ( string.len(date) ~= 10 ) then
                status = 1
                response = 'la date doit être formattée AAAA-MM-JJ (ie 2019-07-26)'
            end

            if ( status == 0 ) then
                local file = io.open(bp_file, "a")
                file:write("bot;421421;555666;10101010101;".. date .. ";" .. tier .. ";" .. commentaire .. ";-" .. montant .. "\n")
                file:close()
                response = 'c\'est noté !'
            end
        end
        return status, response
    elseif command == 'bp_list' then
        if ( file_exists(bp_file) ) then
            local lines = lines_from(bp_file)
            response = ''
            for k,v in pairs(lines) do
                print_info_to_log(0,'bp[' .. k .. ']['.. v .. ']')
                response = response .. v .. "\n"
            end
        else
            response = 'pas de fichier'
        end
        return status, response
    elseif command == 'bp_clean' then
        if ( file_exists(bp_file) ) then
            os.remove(bp_file)
        else
            response = "pas de fichier"
        end
        return status, response
    else
        response = 'Wrong command'
        return status, response
    end
end

local bp_commands = {
    ["bp"] = { handler = bp_module.handler, description = "bp - ajoute une ligne de dépense\n* format simple: montant en euro (virgule separateur);nature\n* format complet: montant;nature;commentaire;date (AAAA-MM-JJ)" },
    ["bp_list"] = { handler = bp_module.handler, description = "bp_list - liste les dépenses déjà enregistrées" },
    ["bp_clean"] = { handler = bp_module.handler, description = "bp_clean - supprime la liste" }
}

function bp_module.get_commands()
    return bp_commands;
end

return bp_module;
