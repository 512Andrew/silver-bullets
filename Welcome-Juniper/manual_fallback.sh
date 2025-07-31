mkdir -p ~/.gpt_terminal/scripts ~/.gpt_terminal/config
touch ~/.gpt_terminal/ai_history.log ~/.gpt_terminal/ai_shell.log

cat <<EOF > ~/.gpt_terminal/config/settings.json
{
  "model": "gpt-4",
  "temperature": 0.7,
  "max_tokens": 1024,
  "use_clipboard": true
}
EOF

cat <<'EOF' > ~/.gpt_terminal/scripts/ai.sh
#!/bin/bash

CONFIG_FILE="$HOME/.gpt_terminal/config/settings.json"
API_URL="https://api.openai.com/v1/chat/completions"
API_KEY="${OPENAI_API_KEY}"

if [[ -z "$API_KEY" ]]; then
  echo "[!] Missing API key. Please set OPENAI_API_KEY in your environment."
  exit 1
fi

MODEL=$(jq -r '.model' "$CONFIG_FILE")
TEMP=$(jq -r '.temperature' "$CONFIG_FILE")
MAXTOK=$(jq -r '.max_tokens' "$CONFIG_FILE")

read -rp $'\e[1;32m>\e[0m Enter prompt: ' USER_PROMPT

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d @- <<JSON
{
  "model": "$MODEL",
  "messages": [
    {"role": "system", "content": "You are a helpful terminal assistant."},
    {"role": "user", "content": "$USER_PROMPT"}
  ],
  "temperature": $TEMP,
  "max_tokens": $MAXTOK
}
JSON
)

echo "$RESPONSE" | jq -r '.choices[0].message.content' | tee -a "$HOME/.gpt_terminal/ai_history.log"
EOF

chmod +x ~/.gpt_terminal/scripts/ai.sh
echo "alias ai='$HOME/.gpt_terminal/scripts/ai.sh'" >> ~/.bashrc
source ~/.bashrc
