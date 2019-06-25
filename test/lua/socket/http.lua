local _M = _G
local JSON = require("JSON")

function mockHttp(u)
	print(os.date("%Y-%m-%d %H:%M:%S")..' - [DEBUG:8] **MOCK** http.get['..u..']')
	
	
    --local code, headers, status = socket.skip(1, trequest(reqt))
	local code = 200
	local status = 200
	local headers = ""
	local jsonString = nil
	
	if ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariables' ) then
		jsonString = '{"result":['
		jsonString = jsonString..'{ "Name": "TelegramBotOffset", "idx": "1" }'
		jsonString = jsonString..',{ "Name":"TelegramBotWhiteListedIDs", "idx":"2" }'
		jsonString = jsonString..',{ "Name":"TelegramBotLoglevel", "idx":"3" }'
		jsonString = jsonString..',{ "Name":"TelegramBotName", "idx":"4" }'
		jsonString = jsonString..',{ "Name":"TelegramBotMenu", "idx":"5" }'
		jsonString = jsonString..',{ "Name":"TelegramBotLuaExclude", "idx":"6" }'
		jsonString = jsonString..',{ "Name":"TelegramBotBashExclude", "idx":"7" }'
		jsonString = jsonString..']}'
		
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=1' ) then
		-- TelegramBotOffset
		jsonString = '{"result":[{ "Value": "0", "idx": "1" }]}'
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=2' ) then
		-- TelegramBotWhiteListedIDs
		jsonString = '{"result":[{ "Value": "123456", "idx": "1" }]}'
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=3' ) then
		-- TelegramBotLoglevel
		jsonString = '{"result":[{ "Value": "4", "idx": "1" }]}'
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=4' ) then
		-- TelegramBotName
		jsonString = '{"result":[{ "Value": "bob", "idx": "1" }]}'
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=5' ) then
		-- TelegramBotMenu
		jsonString = nil
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=6' ) then
		-- TelegramBotLuaExclude
		jsonString = '{"result":[{ "Value": "bp|temperatures", "idx": "1" }]}'
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=7' ) then
		-- TelegramBotBashExclude
		jsonString = '{"result":[{ "Value": "mode_mvt", "idx": "1" }]}'
	end
	
	if ( jsonString ~= nil ) then
		jsonEncoded = JSON:encode(jsonString)
	else
		jsonEncoded = nil
	end
	
	return jsonString, code, headers, status
end

_M.request = mockHttp

return _M
