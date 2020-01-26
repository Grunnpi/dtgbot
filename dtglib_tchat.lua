-- activation function
function isTchat()
    local isTchatBool = true
    if ( g_TelegramBotTchat == nil or g_TelegramBotTchat == 'no') then
        isTchatBool = false
    end
    return isTchatBool
end

-- search ACTION
local MY_ACTION
local MY_ACTION_FOUND = false
local MY_ACTION_POSITION = -1
local MY_OBJECT
local MY_OBJECT_FOUND = false
local MY_OBJECT_POSITION = -1
local MY_PARAM
local MY_PARAM_FOUND = false
local MY_PARAM_POSITION = -1

-- main handle function
function handleTchat(telegramMsg_ReplyToId, telegramMsg_MsgId, ReceivedText)
    print_info_to_log(0, 'Tchat mode activated : [' .. ReceivedText .. ']')

    local returnCommandString = nil

    -- split all word in sentence
    local idx_oneWord = 0
    local normalizedWords = {}
    local allWords = {}
    for oneWord in string.gmatch(ReceivedText, "%S+") do
        local oneWordNormalized = stripChars(oneWord)
        oneWordNormalized = string.upper(oneWordNormalized)
        idx_oneWord = idx_oneWord + 1

        normalizedWords[#normalizedWords + 1] = oneWordNormalized
        allWords[#allWords + 1] = oneWord
        print_info_to_log(0, 'word[' .. tostring(idx_oneWord) .. '] : [' .. oneWord .. '][' .. oneWordNormalized ..']')
    end

    MY_ACTION, MY_ACTION_FOUND, MY_ACTION_POSITION = searchInVector( "ACTION", ACTION_LIST, normalizedWords)
    print_info_to_log(0, 'MY_ACTION[' .. MY_ACTION .. '] : [' .. tostring(MY_ACTION_FOUND) .. ']')
    MY_OBJECT, MY_OBJECT_FOUND, MY_OBJECT_POSITION = searchInVector( "OBJECT", OBJECT_LIST, normalizedWords)
    print_info_to_log(0, 'MY_OBJECT[' .. MY_OBJECT .. '] : [' .. tostring(MY_OBJECT_FOUND) .. ']')
    MY_PARAM, MY_PARAM_FOUND, MY_PARAM_POSITION = searchInVector( "PARAMETER", PARAMETER_LIST, normalizedWords)
    print_info_to_log(0, 'MY_PARAM[' .. MY_PARAM .. '] : [' .. tostring(MY_PARAM_FOUND) .. ']')

    local isUnderstoodFlag = false
    returnCommandString, isUnderstoodFlag = isUnderstood( telegramMsg_ReplyToId, telegramMsg_MsgId, normalizedWords, allWords )
    if (not isUnderstoodFlag) then
        -- RAF message
        local feedbackMessage = randomMessage(rafMessage)
        telegram_SendMsg(telegramMsg_ReplyToId,feedbackMessage, telegramMsg_MsgId)
    end

    return returnCommandString
end


function searchInVector( VECTOR_TYPE, VECTOR_LIST, normalizedWords )
    local MY_STUFF = ''
    local MY_STUFF_FOUND = false
    local MY_POSITION = -1
    for idxNormalized, oneWordNormalized in pairs(normalizedWords) do
        for vIdx, oneVectorList in pairs(VECTOR_LIST) do
            local vectorKeyWord = ''
            for vectorIndex, oneStuff in pairs(oneVectorList) do
                if ( vectorIndex == 1 ) then
                    vectorKeyWord = oneStuff
                end
                if ( oneStuff == oneWordNormalized ) then
                    -- found it
                    print_info_to_log(0, 'Trouve[' .. oneWordNormalized ..'][' .. tostring(vectorIndex) .. '] dans [' .. VECTOR_TYPE .. ']')
                    MY_STUFF = vectorKeyWord
                    MY_STUFF_FOUND = true
                    MY_POSITION = idxNormalized
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
    return MY_STUFF, MY_STUFF_FOUND, MY_POSITION
end

ACTION_LIST = {
      { "OUVRIR", "OUVRE", "FERME", "FERMER", "ACTION" }
    , { "ECRIRE", "ECRIT", "AFFICHE", "LCD" }
    , { "DONNE" }
    , { "RASOIR" }
    , { "COMMENT", "QUEL", "QUELLE", "C'EST", "CA" }
}

OBJECT_LIST = {
      { "GARAGE", "PORTE" }
    , { "LCD", "ECRAN", "" }
    , { "VARIABLE" }
    , { "VARIABLE" }
    , { "VARIABLES" }
    , { "COMBIEN", "ETAT", "STATUT" }
    , { "HUMEUR", "VA", "SENS", "FORME", "ETAT", "VAS", "ROULE", "BOUM", "FARTE" }
}

PARAMETER_LIST = {
      { "UN", "1" }
    , { "DEUX", "2" }
    , { "VARIABLE" }
    , { "QUESTION" , "?" }
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

myNameIsMessage = {
    "Je m'appel #BOT_NAME#"
    , "mon nom c'est #BOT_NAME#"
    , "#BOT_NAME#"
    , "Tu peux m'appeler #BOT_NAME#"
    , "Je suis #BOT_NAME#"
    , "#BOT_NAME#, pour vous servir"
    , "Tout puissant, mais tu peux m'appeler #BOT_NAME#"
    , "#BOT_NAME#zore ou #BOT_NAME#ovscky, mais on m'appel plutôt #BOT_NAME# tout court"
}

myMoodMessage = {
    "Ca flotte"
    , "Plutôt bien"
    , "Cool"
    , "Ca farte"
    , "J'ai la forme"
    , "Super cool"
    , "Au top de moi même"
    , "Je suis bien et ça se voit"
    , "ça roulasse"
    , "tip top"
}

ackMessage = {
      "A bon"
    , "D'accord"
    , "Je vois"
    , "Hm hm"
    , "Et ouais."
}

myNameAnswer = {
      "Enchanté"
    , "Content de te rencontre"
    , "Salut"
}

function isUnderstood( telegramMsg_ReplyToId, telegramMsg_MsgId, normalizedWords, allWords )

    if ( MY_ACTION_FOUND and MY_OBJECT_FOUND and MY_PARAM_FOUND ) then
        if ( MY_ACTION == "OUVRIR" and MY_OBJECT == "GARAGE" ) then
            if ( MY_PARAM == "UN" ) then
                telegram_SendMsg(telegramMsg_ReplyToId,"je vais actionner le garage 1", telegramMsg_MsgId)
                return nil, true
            elseif ( MY_PARAM == "DEUX" ) then
                telegram_SendMsg(telegramMsg_ReplyToId,"je vais actionner le garage 2", telegramMsg_MsgId)
                return nil, true
            else
                telegram_SendMsg(telegramMsg_ReplyToId,"Je n'ai pas compris quel garage : UN ou DEUX ?", telegramMsg_MsgId)
                return nil, true
            end
        end
    end

    if ( MY_ACTION_FOUND and MY_ACTION == "ECRIRE" ) then
        local message = ""
        for idx, oneWord in pairs(allWords) do
            if (idx > MY_ACTION_POSITION ) then
                message = message .. " " .. oneWord
            end
        end
        telegram_SendMsg(telegramMsg_ReplyToId,"je vais écrire sur le LCD : [" .. message .. "]", telegramMsg_MsgId)
        return "/" .. g_TelegramBotName .. " lcd " .. message, true
    end

    if ( MY_PARAM == "QUESTION" ) then
        if ( MY_ACTION == "RASOIR" and MY_OBJECT == "COMBIEN" ) then
            telegram_SendMsg(telegramMsg_ReplyToId,"alors, on en est où avec le rasoir ?", telegramMsg_MsgId)
            return "/bob rasoir status", true
        end

        if ( MY_ACTION == "COMMENT" and MY_OBJECT == "APPEL" ) then
            telegram_SendMsg(telegramMsg_ReplyToId,randomMessage(myNameIsMessage), telegramMsg_MsgId)
            return nil, true
        end

        if ( MY_ACTION == "COMMENT" and MY_OBJECT == "HUMEUR" ) then
            telegram_SendMsg(telegramMsg_ReplyToId,randomMessage(myMoodMessage), telegramMsg_MsgId)
            return nil, true
        end
    else
        if ( MY_ACTION == "COMMENT" and MY_OBJECT == "APPEL" ) then
            telegram_SendMsg(telegramMsg_ReplyToId,randomMessage(myNameAnswer), telegramMsg_MsgId)
            return nil, true
        end

        if ( MY_ACTION == "COMMENT" and MY_OBJECT == "HUMEUR" ) then
            telegram_SendMsg(telegramMsg_ReplyToId,randomMessage(ackMessage), telegramMsg_MsgId)
            telegram_SendMsg(telegramMsg_ReplyToId,randomMessage(myMoodMessage), telegramMsg_MsgId)
            return nil, true
        end
    end

    return nil, false
end

function randomMessage(tableMessage)
    local randomIdx = math.random(1,#tableMessage)

    local returnMessage = tableMessage[randomIdx]
    returnMessage = string.gsub (returnMessage, "#USER_NAME#", g_currentUserName)
    returnMessage = string.gsub (returnMessage, "#BOT_NAME#", g_TelegramBotName)

    return returnMessage
end

function randomOkMessage()
    return randomMessage(okMessage)
end

