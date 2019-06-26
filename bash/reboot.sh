#!/bin/sh

ReplyTo=$1
MessageId=$2

curl -s -X POST "https://api.telegram.org/bot"$TelegramBotToken"/sendMessage" -F chat_id=$ReplyTo -F reply_to_message_id=$MessageId -F text="⚠️ reboot now ⚠️"
reboot




