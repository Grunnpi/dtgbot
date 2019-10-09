--~ added pReplyMarkup to allow for custom keyboard
function telegram_SendMsg(SendTo, Message, MessageId, pReplyMarkup)
    local response
    local status
    if pReplyMarkup == nil or pReplyMarkup == "" then
        print_info_to_log(1, g_TelegramApiUrl .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. url_encode(Message))
        response, status = https.request(g_TelegramApiUrl .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. url_encode(Message))
    else
        print_info_to_log(1, g_TelegramApiUrl .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. url_encode(Message) .. '&reply_markup=' .. url_encode(pReplyMarkup))
        response, status = https.request(g_TelegramApiUrl .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. url_encode(Message) .. '&reply_markup=' .. url_encode(pReplyMarkup))
    end
    print_info_to_log(1,'telegram:msg sent status='..status)
    return
end

function telegram_SendFile(SendTo, Message, MessageId, pReplyMarkup)
    local response
    local status
    if pReplyMarkup == nil or pReplyMarkup == "" then
        print_info_to_log(1, g_TelegramApiUrl .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. url_encode(Message))
        response, status = https.request(g_TelegramApiUrl .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. url_encode(Message))
    else
        print_info_to_log(1, g_TelegramApiUrl .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. url_encode(Message) .. '&reply_markup=' .. url_encode(pReplyMarkup))
        response, status = https.request(g_TelegramApiUrl .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. url_encode(Message) .. '&reply_markup=' .. url_encode(pReplyMarkup))
    end
    print_info_to_log(1,'telegram:msg sent status='..status)
    return
end
