-- activation function
function isTchat()
    local isTchatBool = true
    if ( g_TelegramBotTchat == nil or g_TelegramBotTchat == 'no') then
        isTchatBool = false
    end
    return isTchatBool
end

-- main handle function
function handleTchat(telegramMsg_ReplyToId, telegramMsg_MsgId, ReceivedText)
    telegram_SendMsg(telegramMsg_ReplyToId, "Ok " .. g_currentUserName .. ", j'ai compris que tu as dit : '" .. ReceivedText .. "'", telegramMsg_MsgId)
end
