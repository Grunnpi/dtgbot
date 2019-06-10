#!/bin/sh

curl -s -X POST "https://api.telegram.org/bot"$TelegramBotToken"/sendMessage" -F chat_id=$TelegramChatId -F text="⚠️ reboot now ⚠️"
reboot




