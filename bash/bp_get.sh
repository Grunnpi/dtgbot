#!/bin/sh

ReplyTo=$1
MessageId=$2

curl -s -X POST "https://api.telegram.org/bot"$TelegramBotToken"/sendPhoto" -F chat_id=$ReplyTo -F reply_to_message_id=$MessageId -F photo="@"$TempFileDir"/bp.csv" -F caption="BankPerfect cash"
rm /var/tmp/toto.jpg




