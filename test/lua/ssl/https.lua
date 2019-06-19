--
-- Module
--
local _M = {
  _VERSION   = "0.8",
  _COPYRIGHT = "LuaSec 0.8 - Copyright (C) 2009-2019 PUC-Rio",
  PORT       = 443,
  TIMEOUT    = 60
}


function mockHttp(u)
	print("**MOCK** https.get["..u.."]")
		
    --local code, headers, status = socket.skip(1, trequest(reqt))
	local code = 200
	local status = 200
	local headers = ""
	
	if ( u == 'https://api.telegram.org/botxxxxTOKENxxx/getUpdates?timeout=60&offset=0' ) then
		jsonString = '{ 	"ok": true, 	"result": [{ 		"update_id": 1, 		"message": { 			"message_id": 2, 			"from": { 				"id": 123456, 				"first_name": "Moi", 				"last_name": "X", 				"username": "UserID" 			}, 			"chat": { 				"id": 987654, 				"first_name": "NotMe", 				"last_name": "Y", 				"username": "UserIdChat" 			}, 			"date": 1, 			"text": "/bob bp" 		} 		}] 	}'
	elseif ( u == 'https://api.telegram.org/botxxxxTOKENxxx/getUpdates?timeout=60&offset=1' ) then
		jsonString = nil
	else
		jsonString = nil
		os.exit(-666)
	end
	
	return jsonString, code, headers, status
end

_M.request = mockHttp
_M.tcp = tcp

return _M