#!/bin/sh

ReplyTo=$1
MessageId=$2

current_time=$(date "+%Y%m%d-%H%M%S")
curl -s -X POST "https://api.telegram.org/bot"$TelegramBotToken"/sendDocument" -F chat_id=$ReplyTo -F reply_to_message_id=$MessageId -F document="@"$TempFileDir"/bp.csv" -F filename=$current_time"_bp.csv" -F caption="BankPerfect cash"

