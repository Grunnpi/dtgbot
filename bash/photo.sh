#!/bin/sh

curl -s -o /var/tmp/toto.jpg http://$DomoticzIP:8765/picture/1/current
curl -s -X POST "https://api.telegram.org/bot"$TelegramBotToken"/sendPhoto" -F chat_id=$TelegramChatId -F photo="@/var/tmp/toto.jpg" -F caption="Photo de BOB"
rm /var/tmp/toto.jpg




