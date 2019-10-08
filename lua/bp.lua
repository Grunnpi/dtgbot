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
        local file = io.open(bp_file, "a")
        file:write("Hello World\n")
        file:close()
        response = 'ajout ok'
        return status, response
    elseif command == 'bp_list' then

        if ( file_exists(bp_file) ) then
            local lines = lines_from(bp_file)
            -- print all line numbers and their contents
            response = 'liste moi ok'
            for k,v in pairs(lines) do
                --print('line[' .. k .. ']', v)
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
