local _M = _G
local JSON = require("JSON")

function mockHttp(u)
	print("**MOCK** http.get["..u.."]")
	
	
    --local code, headers, status = socket.skip(1, trequest(reqt))
	local code = 200
	local status = 200
	local headers = ""
	
	if ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariables' ) then
		jsonString = '{"result":[{ "Name": "TelegramBotOffset", "idx": "1" },{ "Name":"TelegramBotWhiteListedIDs", "idx":"2" },{ "Name":"TelegramBotLoglevel", "idx":"3" },{ "Name":"TelegramBotName", "idx":"4" }]}'
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=1' ) then
		jsonString = '{"result":[{ "Value": "0", "idx": "1" }]}'
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=2' ) then
		jsonString = '{"result":[{ "Value": "123456", "idx": "1" }]}'
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=3' ) then
		jsonString = '{"result":[{ "Value": "1", "idx": "1" }]}'
	elseif ( u == 'http://127.0.0.1:8080/json.htm?type=command&param=getuservariable&idx=4' ) then
		jsonString = '{"result":[{ "Value": "bob", "idx": "1" }]}'
	end
	
	jsonEncoded = JSON:encode(jsonString)
	return jsonString, code, headers, status
end

_M.request = mockHttp

return _M
