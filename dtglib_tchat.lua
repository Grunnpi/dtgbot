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
    print_info_to_log(0, 'Tchat mode activated : [' .. ReceivedText .. ']')

    -- split all word in sentence
    for idx, oneWord in string.gmatch(example, "%S+") do
        print_info_to_log(0, 'word[' .. tostring(idx) .. '] : [' .. string.upper(oneWord) .. ']')
    end

    telegram_SendMsg(telegramMsg_ReplyToId, "Ok " .. g_currentUserName .. ", j'ai compris que tu as dit : '" .. ReceivedText .. "'", telegramMsg_MsgId)
end


okMessage = {
    "c'est fait"
    , "ok"
    , "hop"
    , "et voilà"
    , "d'accord"
    , "hmm hmm"
    , "trop facile"
    , "à vos ordre"
    , "yep"
}

rafMessage = {
    "oui oui"
    , "ah bon ?"
    , "ahhh ouais"
    , "je vois le genre"
    , "tout à fait"
    , "j'allais le dire"
    , "c'est pas faux"
    , "rien compris moi"
    , "ah, ok ok ok. Ben pourquoi ?"
}


function randomMessage(tableMessage)
    local randomIdx = math.random(1,#tableMessage)
    return tableMessage[randomIdx]
end

function randomOkMessage()
    return randomMessage(okMessage)
end

function randomRAFMessage()
    return randomMessage(rafMessage)
end