--~ added replymarkup to allow for custom keyboard
function send_msg(SendTo, Message, MessageId, replymarkup)
    if replymarkup == nil or replymarkup == "" then
        print_info_to_log(1, telegram_url .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. url_encode(Message))
        response, status = https.request(telegram_url .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. url_encode(Message))
    else
        print_info_to_log(1, telegram_url .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. url_encode(Message) .. '&reply_markup=' .. url_encode(replymarkup))
        response, status = https.request(telegram_url .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. url_encode(Message) .. '&reply_markup=' .. url_encode(replymarkup))
    end
    print_info_to_log(0,'Message sent status='..status)
    return
end
