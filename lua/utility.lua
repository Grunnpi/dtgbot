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
    elseif command == 'rasoir' then
        local v_rasoir_compteur_name = 'Rasoir_compteur'
        local v_rasoir_face_name = 'Rasoir_face'

        local v_rasoir_endroit = "Endroit"
        local v_rasoir_envers = "Envers"

        local v_rasoir_compteur_name_idx = domoticz_cache_getVariableIdxByName(v_rasoir_compteur_name)
        if v_rasoir_compteur_name_idx == nil then
            print_error_to_log(0, '"'.. v_rasoir_compteur_name..'" n\'exite pas. Creation')
            domoticz_createVariable(v_rasoir_compteur_name,0,0)
            v_rasoir_compteur_name_idx = domoticz_cache_getVariableIdxByName(v_rasoir_compteur_name)
        end

        local v_rasoir_face_name_idx = domoticz_cache_getVariableIdxByName(v_rasoir_face_name)
        if v_rasoir_face_name_idx == nil then
            print_error_to_log(0, '"'.. v_rasoir_face_name..'" n\'exite pas. Creation')
            domoticz_createVariable(v_rasoir_face_name,2,v_rasoir_endroit)
            v_rasoir_face_name_idx = domoticz_cache_getVariableIdxByName(v_rasoir_face_name)
        end

        if v_rasoir_compteur_name_idx == nil then
            status = 1
            response = "Variable [" .. v_rasoir_compteur_name .. "] pas trouvée"
        else
            if v_rasoir_face_name_idx == nil then
                status = 1
                response = "Variable [" .. v_rasoir_face_name .. "] pas trouvée"
            else
                local v_rasoir_face = domoticz_getVariableValueByIdx(v_rasoir_face_name_idx)
                local v_rasoir_compteur = tonumber(domoticz_getVariableValueByIdx(v_rasoir_compteur_name_idx))
                if ( #parsed_cli >= 3 and parsed_cli[3] == 'status') then
                    response = "Rasoir en face [".. v_rasoir_face .. "], utilisé " .. tostring(v_rasoir_compteur) .. " fois"
                else
                    v_rasoir_compteur = v_rasoir_compteur + 1
                    if v_rasoir_compteur > 4 then
                        -- quelle face ? on retourne ou on change la lame !
                        if ( v_rasoir_face == v_rasoir_endroit ) then
                            v_rasoir_face = v_rasoir_envers
                            v_rasoir_compteur = 1
                            response = "Il faut retourner la lame vers l\'envers et utiliser pour la 1er fois"
                        else
                            v_rasoir_face = v_rasoir_endroit
                            v_rasoir_compteur = 1
                            response = "Il faut changer la lame et utiliser pour la 1er fois"
                        end
                        domoticz_setVariableValueByIdx(v_rasoir_face_name_idx, v_rasoir_face_name, 2, v_rasoir_face)
                        domoticz_setVariableValueByIdx(v_rasoir_compteur_name_idx, v_rasoir_compteur_name, 0, v_rasoir_compteur)
                    else
                        response = "Face [" .. v_rasoir_face .. "], utilisée mainenant pour la " .. tostring(v_rasoir_compteur) .. " fois"
                        domoticz_setVariableValueByIdx(v_rasoir_compteur_name_idx, v_rasoir_compteur_name, 0, v_rasoir_compteur)
                    end
                end
            end
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
    elseif command == 'écran' then
        local v_ecran_compteur_jeremie = 'TempsEcranJeremie'
        local v_ecran_actif_jeremie = 'TempsEcranJeremie'

        local v_ecran_compteur_matthieu = 'TempsEcranMatthieu'
        local v_ecran_actif_matthieu = 'TempsEcranMatthieu'

        local v_ecran_compteur_jeremie_idx = domoticz_cache_getVariableIdxByName(v_ecran_compteur_jeremie)
        if v_ecran_compteur_jeremie_idx == nil then
            print_error_to_log(0, '"'.. v_ecran_compteur_jeremie..'" n\'exite pas. Creation')
            domoticz_createVariable(v_ecran_compteur_jeremie,0,0)
            v_ecran_compteur_jeremie_idx = domoticz_cache_getVariableIdxByName(v_ecran_compteur_jeremie)
        end

        local v_ecran_compteur_matthieu_idx = domoticz_cache_getVariableIdxByName(v_ecran_compteur_matthieu)
        if v_ecran_compteur_matthieu_idx == nil then
            print_error_to_log(0, '"'.. v_ecran_compteur_matthieu..'" n\'exite pas. Creation')
            domoticz_createVariable(v_ecran_compteur_matthieu,0,0)
            v_ecran_compteur_matthieu_idx = domoticz_cache_getVariableIdxByName(v_ecran_compteur_matthieu)
        end

        if v_ecran_compteur_jeremie_idx == nil then
            status = 1
            response = "Variable [" .. v_ecran_compteur_jeremie .. "] pas trouvée"
            return status, response
        end
        if v_ecran_compteur_matthieu_idx == nil then
            status = 1
            response = "Variable [" .. v_ecran_compteur_matthieu .. "] pas trouvée"
            return status, response
        end

        local v_tempsEcranJeremie = tonumber(domoticz_getVariableValueByIdx(v_ecran_compteur_jeremie_idx))
        local v_tempsEcranMatthieu = tonumber(domoticz_getVariableValueByIdx(v_ecran_compteur_matthieu_idx))

        if ( #parsed_cli >= 3 and parsed_cli[3] == 'status') then
            response = "Jérémie reste [".. tostring(v_tempsEcranJeremie) .. "]min\nMatthieu reste [" .. tostring(v_tempsEcranMatthieu) .. "]min"
            return status, response
        end

        if ( #parsed_cli >= 4 ) then
            local action = string.lower(parsed_cli[3])
            local enfant = string.lower(parsed_cli[4])

            action = stripChars(action)
            enfant = stripChars(enfant)

            if ( (enfant == "jeremie") or (enfant == "matthieu") ) then
                if (action == "debut") then
                    if (enfant == "jeremie") then
                        local DeviceID = domoticz_cache_getDeviceIdxByNameByType(v_ecran_actif_jeremie, 'devices')
                        local switchtype = 'light'
                        response = SwitchID(v_ecran_actif_jeremie, DeviceID, switchtype, "on", SendTo)
                    else
                        local DeviceID = domoticz_cache_getDeviceIdxByNameByType(v_ecran_actif_matthieu, 'devices')
                        local switchtype = 'light'
                        response = SwitchID(v_ecran_actif_jeremie, DeviceID, switchtype, "on", SendTo)
                    end
                elseif (action == "fin") then
                    if (enfant == "jeremie") then
                        local DeviceID = domoticz_cache_getDeviceIdxByNameByType(v_ecran_actif_jeremie, 'devices')
                        local switchtype = 'light'
                        response = SwitchID(v_ecran_actif_jeremie, DeviceID, switchtype, "off", SendTo)
                    else
                        local DeviceID = domoticz_cache_getDeviceIdxByNameByType(v_ecran_actif_matthieu, 'devices')
                        local switchtype = 'light'
                        response = SwitchID(v_ecran_actif_jeremie, DeviceID, switchtype, "off", SendTo)
                    end
                elseif (action == "plus") then
                    if (enfant == "jeremie") then
                        if ( #parsed_cli >= 5 ) then
                            v_tempsEcranJeremie = v_tempsEcranJeremie + tonumber(parsed_cli[5])
                            domoticz_setVariableValueByIdx(v_ecran_compteur_jeremie_idx, v_ecran_compteur_jeremie, 0, v_tempsEcranJeremie)
                        else
                            response = "Il faut un chiffre pour [".. action .."]"
                            status = -1
                            return status, response
                        end
                    else
                        if ( #parsed_cli >= 5 ) then
                            v_tempsEcranMatthieu = v_tempsEcranMatthieu + tonumber(parsed_cli[5])
                            domoticz_setVariableValueByIdx(v_ecran_compteur_matthieu_idx, v_ecran_compteur_matthieu, 0, v_tempsEcranMatthieu)
                        else
                            response = "Il faut un chiffre pour [".. action .."]"
                            status = -1
                            return status, response
                        end
                    end
                elseif (action == "moins") then
                    if (enfant == "jeremie") then
                        if ( #parsed_cli >= 5 ) then
                            v_tempsEcranJeremie = v_tempsEcranJeremie - tonumber(parsed_cli[5])
                            domoticz_setVariableValueByIdx(v_ecran_compteur_jeremie_idx, v_ecran_compteur_jeremie, 0, v_tempsEcranJeremie)
                        else
                            response = "Il faut un chiffre pour [".. action .."]"
                            status = -1
                            return status, response
                        end
                    else
                        if ( #parsed_cli >= 5 ) then
                            v_tempsEcranMatthieu = v_tempsEcranMatthieu - tonumber(parsed_cli[5])
                            domoticz_setVariableValueByIdx(v_ecran_compteur_matthieu_idx, v_ecran_compteur_matthieu, 0, v_tempsEcranMatthieu)
                        else
                            response = "Il faut un chiffre pour [".. action .."]"
                            status = -1
                            return status, response
                        end
                    end
                elseif (action == "change") then
                    if (enfant == "jeremie") then
                        if ( #parsed_cli >= 5 ) then
                            v_tempsEcranJeremie = tonumber(parsed_cli[5])
                            domoticz_setVariableValueByIdx(v_ecran_compteur_jeremie_idx, v_ecran_compteur_jeremie, 0, v_tempsEcranJeremie)
                        else
                            response = "Il faut un chiffre pour [".. action .."]"
                            status = -1
                            return status, response
                        end
                    else
                        if ( #parsed_cli >= 5 ) then
                            v_tempsEcranMatthieu = tonumber(parsed_cli[5])
                            domoticz_setVariableValueByIdx(v_ecran_compteur_matthieu_idx, v_ecran_compteur_matthieu, 0, v_tempsEcranMatthieu)
                        else
                            response = "Il faut un chiffre pour [".. action .."]"
                            status = -1
                            return status, response
                        end
                    end
                else
                    response = "Commande toute pourrie, action [".. action .."] existe même pas"
                    status = -1
                    return status, response
                end
            else
                response = "4eme position doit être 'jeremie' ou 'matthieu' : je ne reconnais pas [".. enfant .. "]"
                status = -1
                return status, response
            end
        end
        return status, response
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
    ["set_variable"] = { handler = utility_module.handler, description = "set_variable - parameter=variableName,variableValue set variable value (optional variableType)" },
    ["rasoir"] = { handler = utility_module.handler, description = "rasoir - incrémente le compteur" },

    ["écran"] = { handler = utility_module.handler, description = "écran - synthese des temps d'écran" }
}

function utility_module.get_commands()
    return utility_commands;
end

return utility_module;
