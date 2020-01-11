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
    local normalizedWords = {}
    for oneWord in string.gmatch(ReceivedText, "%S+") do
        local oneWordNormalized = stripChars(oneWord)
        oneWordNormalized = string.upper(oneWordNormalized)
        idx_oneWord = idx_oneWord + 1

        normalizedWords[#normalizedWords + 1] = oneWordNormalized
        print_info_to_log(0, 'word[' .. tostring(idx_oneWord) .. '] : [' .. oneWord .. '][' .. oneWordNormalized ..']')
    end

    -- search ACTION
    local MY_ACTION
    local MY_ACTION_FOUND = false
    local MY_OBJECT
    local MY_OBJECT_FOUND = false
    local MY_PARAM
    local MY_PARAM_FOUND = false

    MY_ACTION, MY_ACTION_FOUND = searchInVector( ACTION_LIST, normalizedWords)
    MY_OBJECT, MY_OBJECT_FOUND = searchInVector( OBJECT_LIST, normalizedWords)
    MY_PARAM, MY_PARAM_FOUND = searchInVector( PARAMETER_LIST, normalizedWords)

    local feedbackMessage = ""
    if (not isUnderstood( telegramMsg_ReplyToId, telegramMsg_MsgId, MY_ACTION, MY_ACTION_FOUND, MY_OBJECT, MY_OBJECT_FOUND, MY_PARAM, MY_PARAM_FOUND )) then
        -- RAF message
        feedbackMessage = randomRAFMessage()
        telegram_SendMsg(telegramMsg_ReplyToId,feedbackMessage, telegramMsg_MsgId)
    end
end


function searchInVector( VECTOR_LIST, normalizedWords )
    local MY_STUFF = ''
    local MY_STUFF_FOUND = false
    for idx, neWordNormalized in pairs(normalizedWords) do
        for vIdx, oneVectorList in pairs(VECTOR_LIST) do
            local vectorKeyWord = ''
            for vectorIndex, oneStuff in pairs(oneVectorList) do
                if ( vectorIndex == 0 ) then
                    vectorKeyWord = oneStuff
                end
                if ( oneStuff == oneWordNormalized ) then
                    -- found it
                    MY_STUFF = vectorKeyWord
                    MY_STUFF_FOUND = true
                    break
                end
                if ( MY_STUFF_FOUND ) then
                    break
                end
            end
        end
        if ( MY_STUFF_FOUND ) then
            break
        end
    end
    return MY_STUFF, MY_STUFF_FOUND
end

ACTION_LIST = {
      { "OUVRIR", "OUVRE", "FERME", "FERMER", "ACTION" }
    , { "ECRIRE", "ECRIT", "AFFICHE", "LCD" }
    , { "DONNE" }
}

OBJECT_LIST = {
      { "GARAGE", "PORTE" }
    , { "LCD", "ECRAN", "" }
    , { "VARIABLE" }
    , { "VARIABLES" }
}

PARAMETER_LIST = {
      { "UN", "1" }
    , { "DEUX", "2" }
    , { "VARIABLE" }
}

okMessage = {
    "c'est fait #USER_NAME#"
    , "#USER_NAME#, c'est fait"
    , "#USER_NAME#, oui, #USER_NAME#"
    , "ok #USER_NAME#"
    , "hop"
    , "et voilà #USER_NAME#"
    , "d'accord #USER_NAME#"
    , "hmm hmm"
    , "et paf #USER_NAME# !"
    , "trop facile"
    , "à vos ordre #USER_NAME#"
    , "yep"
    , "#USER_NAME#, no problemo"
}

rafMessage = {
    "oui oui"
    , "ah bon ?"
    , "ahhh ouais"
    , "je vois le genre"
    , "tout à fait"
    , "j'allais le dire"
    , "c'est pas faux"
    , "qu'est ce que tu racontes #USER_NAME# ?"
    , "rien compris moi"
    , "ah, ok ok ok. Ben pourquoi ?"
    , "#USER_NAME# : je ne comprend pas..."
}

function isUnderstood( telegramMsg_ReplyToId, telegramMsg_MsgId, MY_ACTION, MY_ACTION_FOUND, MY_OBJECT, MY_OBJECT_FOUND, MY_PARAM, MY_PARAM_FOUND )

    if ( MY_ACTION_FOUND and MY_OBJECT_FOUND and MY_PARAM_FOUND ) then
        if ( MY_ACTION == "OUVRIR" and MY_OBJECT == "GARAGE" ) then
            if ( MY_PARAM == "UN" ) then
                telegram_SendMsg(telegramMsg_ReplyToId,"je vais actionner le garage 1", telegramMsg_MsgId)
                return true
            elseif ( MY_PARAM == "DEUX" ) then
                telegram_SendMsg(telegramMsg_ReplyToId,"je vais actionner le garage 2", telegramMsg_MsgId)
                return true
            else
                telegram_SendMsg(telegramMsg_ReplyToId,"Je n'ai pas compris quel garage : UN ou DEUX ?", telegramMsg_MsgId)
            end
        end

        if ( MY_ACTION == "ECRIRE" ) then
            telegram_SendMsg(telegramMsg_ReplyToId,"je vais écrire un truc sur le LCD", telegramMsg_MsgId)
            return true
        end
    end

    return false
end

function randomMessage(tableMessage)
    local randomIdx = math.random(1,#tableMessage)

    local returnMessage = tableMessage[randomIdx]
    returnMessage = string.gsub (returnMessage, "#USER_NAME#", g_currentUserName)

    return returnMessage
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