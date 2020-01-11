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
    local idx_oneWord = 0
    for oneWord in string.gmatch(ReceivedText, "%S+") do
        local oneWordNormalized = stripChars(oneWord)
        oneWordNormalized = string.upper(oneWordNormalized)
        print_info_to_log(0, 'word[' .. tostring(idx_oneWord) .. '] : [' .. oneWord .. '][' .. oneWordNormalized ..']')
        idx_oneWord = idx_oneWord + 1
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

function stripChars(str)
    local tableAccents = {}
    tableAccents["À"] = "A"
    tableAccents["Á"] = "A"
    tableAccents["Â"] = "A"
    tableAccents["Ã"] = "A"
    tableAccents["Ä"] = "A"
    tableAccents["Å"] = "A"
    tableAccents["Æ"] = "AE"
    tableAccents["Ç"] = "C"
    tableAccents["È"] = "E"
    tableAccents["É"] = "E"
    tableAccents["Ê"] = "E"
    tableAccents["Ë"] = "E"
    tableAccents["Ì"] = "I"
    tableAccents["Í"] = "I"
    tableAccents["Î"] = "I"
    tableAccents["Ï"] = "I"
    tableAccents["Ð"] = "D"
    tableAccents["Ñ"] = "N"
    tableAccents["Ò"] = "O"
    tableAccents["Ó"] = "O"
    tableAccents["Ô"] = "O"
    tableAccents["Õ"] = "O"
    tableAccents["Ö"] = "O"
    tableAccents["Ø"] = "O"
    tableAccents["Ù"] = "U"
    tableAccents["Ú"] = "U"
    tableAccents["Û"] = "U"
    tableAccents["Ü"] = "U"
    tableAccents["Ý"] = "Y"
    tableAccents["Þ"] = "P"
    tableAccents["ß"] = "s"
    tableAccents["à"] = "a"
    tableAccents["á"] = "a"
    tableAccents["â"] = "a"
    tableAccents["ã"] = "a"
    tableAccents["ä"] = "a"
    tableAccents["å"] = "a"
    tableAccents["æ"] = "ae"
    tableAccents["ç"] = "c"
    tableAccents["è"] = "e"
    tableAccents["é"] = "e"
    tableAccents["ê"] = "e"
    tableAccents["ë"] = "e"
    tableAccents["ì"] = "i"
    tableAccents["í"] = "i"
    tableAccents["î"] = "i"
    tableAccents["ï"] = "i"
    tableAccents["ð"] = "eth"
    tableAccents["ñ"] = "n"
    tableAccents["ò"] = "o"
    tableAccents["ó"] = "o"
    tableAccents["ô"] = "o"
    tableAccents["õ"] = "o"
    tableAccents["ö"] = "o"
    tableAccents["ø"] = "o"
    tableAccents["ù"] = "u"
    tableAccents["ú"] = "u"
    tableAccents["û"] = "u"
    tableAccents["ü"] = "u"
    tableAccents["ý"] = "y"
    tableAccents["þ"] = "p"
    tableAccents["ÿ"] = "y"
    local normalisedString = ''
    local normalisedString = str: gsub("[%z\1-\127\194-\244][\128-\191]*", tableAccents)
    return normalisedString
end