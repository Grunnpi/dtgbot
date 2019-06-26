#!/bin/sh

ReplyTo=$1
MessageId=$2

curl -s -o /var/tmp/toto.jpg http://$DomoticzIP:8765/picture/1/current
curl -s -X POST "https://api.telegram.org/bot"$TelegramBotToken"/sendPhoto" -F chat_id=$ReplyTo -F reply_to_message_id=$MessageId -F photo="@/var/tmp/toto.jpg" -F caption="Photo"
rm /var/tmp/toto.jpg




