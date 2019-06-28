#!/bin/bash

# Settings
ReplyTo=$1
MessageId=$2

# array of icons
declare -a icons=("smiley 😀" "crying smiley 😢" "sleeping smiley 😴" "beer 🍺" "double beer 🍻"\
 "wine 🍷" "double red excam ‼️" "yellow sign exclamation mark ⚠️ " "camera 📷" "light(on) 💡"\
 "open sun 🔆" "battery 🔋" "plug 🔌" "film 🎬" "music 🎶" "moon 🌙" "sun ☀️" "sun behind some clouds ⛅️"\
 "clouds ☁️" "lightning ⚡️" "umbrella ☔️" "snowflake ❄️")

## now loop through the above array of icons
for icon in "${icons[@]}"
do
   curl --data 'chat_id='$ReplyTo --data 'reply_to_message_id='$MessageId --data-urlencode 'text='"$icon" 'https://api.telegram.org/bot'$TelegramBotToken'/sendMessage'
done

