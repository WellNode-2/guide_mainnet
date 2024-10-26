#!/bin/bash

# Параметри Telegram
TELEGRAM_BOT_TOKEN=""
CHAT_ID=""

# URL для запиту JSON-RPC
URL="http://127.0.0.1:9944"
JSON_DATA='{"jsonrpc":"2.0","method":"bioauth_status","params":[],"id":1}'

# Функція для надсилання повідомлення в Telegram
send_telegram_message() {
  echo "$1"
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="$1"
}

# Основна функція
check_bioauth_status() {
  # Запит до сервера
  response=$(curl -s -X POST -H "Content-Type: application/json" -d "${JSON_DATA}" "${URL}")
    # {"jsonrpc":"2.0","result":{"Active":{"expires_at":1724876958000}},"id":1}
    # {"jsonrpc":"2.0","result":"Inactive","id":1}

  # Перевірка на відповідь сервера
  if [ -z "$response" ]; then
    send_telegram_message "⛔ HumaNode is not answer!!!"
    return
  fi

  # Перевірка статусу в відповіді
  status=$(echo "$response" | jq -r '.result | if type=="object" then "Active" else . end')

  if [ "$status" == "Inactive" ]; then
    send_telegram_message "⛔ HumaNode - Bioauth status is Inactive"
  elif [ "$status" == "Active" ]; then
    expires_at=$(echo "$response" | jq -r '.result.Active.expires_at')
    current_time=$(date +%s%3N)
    time_diff=$((expires_at - current_time))
    time_diff_minutes=$((time_diff / 60000))
    
    if [ "$time_diff_minutes" -lt 60 ]; then
      send_telegram_message "⚠️ HumaNode - Bioauth will expire in ${time_diff_minutes} minutes!"
    else
        echo "✅ HumaNode - Bioauth status is Active and will expire in ${time_diff_minutes} minutes!"
    fi
  else
    send_telegram_message "⛔ HumaNode is not answer!!!"
  fi
}

# Перевірка логів на наявність помилок
check_logs_for_errors() {
  if tail -n 3 /root/.humanode/workspaces/default/tunnel/logs.txt | grep -q "ERROR"; then
    send_telegram_message "⛔ HumaNode - Error found in RPC logs!"
  fi
}

# Основний цикл з відліком
while true; do
  echo "=== $(date) ==="
  check_bioauth_status
  check_logs_for_errors

  for ((i=600; i>0; i--)); do
    echo -ne "Наступна перевірка через: $i секунд\r"
    sleep 1
  done

  echo "" # Перенос рядка після завершення відліку
done
