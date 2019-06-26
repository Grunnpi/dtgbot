local _M = _G
local JSON = require("JSON")

mock_TelegramBotOffset = 0
mock_TelegramBotMenu = "Off"

function printLog(msg)
	print(os.date("%Y-%m-%d %H:%M:%S")..' - [DEBUG:8] **MOCK** '..msg)
end

function mockHttp(u)
	printLog('http.get['..u..']')
	
	
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
		jsonString = '{"result":[{ "Value": "'..tostring(mock_TelegramBotOffset)..'", "idx": "1" }]}'
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
		jsonString = '{"result":[{ "Value": "'..mock_TelegramBotMenu..'", "idx": "1" }]}'
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=6' ) then
		-- TelegramBotLuaExclude
		jsonString = '{"result":[{ "Value": "bp|temperatures", "idx": "1" }]}'
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=7' ) then
		-- TelegramBotBashExclude
		jsonString = '{"result":['
		jsonString = jsonString..'{ "Value": "mode_mvt", "idx": "1" }'
		jsonString = jsonString..']}'
		
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=devices&order=name&used=true' ) then
		-- device_list
		jsonString = '{"result":['
		jsonString = jsonString..'{ "Name": "MyDevice", "idx": "987" }'
		jsonString = jsonString..']}'
		--jsonString = nil


	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=updateuservariable&idx=5&vname=TelegramBotMenu&vtype=2&vvalue=On' ) then
		printLog('UPDATE MENU to On')
		mock_TelegramBotMenu = 'On'
		jsonEncoded = nil
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=updateuservariable&idx=5&vname=TelegramBotMenu&vtype=2&vvalue=Off' ) then
		printLog('UPDATE MENU to Off')
		mock_TelegramBotMenu = 'Off'
		jsonEncoded = nil

	elseif ( string.sub(u,1,string.len(u)-1) == 'http://127.0.0.1:8080/json.htm?type=command&param=updateuservariable&idx=1&vname=TelegramBotOffset&vtype=0&vvalue=') then
		mock_TelegramBotOffset = mock_TelegramBotOffset + 1
		printLog('UPDATE OFFSET to '..tostring(mock_TelegramBotOffset))
		jsonEncoded = nil
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
