#!/bin/bash
# ========== AI Terminal Shell Bootstrap ==========
# Shell-side interface to summon GPT co-pilot from within your terminal.
# Designed for Ubuntu-based systems (works with Cinnamon, GNOME, XFCE, etc.)
# Future-state: deeper integration with persistent memory and async job handling.

set -e

# === 1. Define directories and local assets ===
AI_ROOT="$HOME/.gpt_terminal"
SCRIPTS_DIR="$AI_ROOT/scripts"
CONFIG_DIR="$AI_ROOT/config"
HISTORY_FILE="$AI_ROOT/ai_history.log"
LOG_FILE="$AI_ROOT/ai_shell.log"

# === 2. Create structure ===
echo "[+] Setting up local directories..."
mkdir -p "$SCRIPTS_DIR" "$CONFIG_DIR"
touch "$HISTORY_FILE" "$LOG_FILE"

# === 3. Install dependencies ===
echo "[+] Installing required packages..."
sudo apt update && sudo apt install -y jq curl dialog xclip

# === 4. Create config template ===
CONFIG_FILE="$CONFIG_DIR/settings.json"
if [ ! -f "$CONFIG_FILE" ]; then
  cat <<EOF > "$CONFIG_FILE"
{
  "model": "gpt-4",
  "temperature": 0.7,
  "max_tokens": 1024,
  "use_clipboard": true
}
EOF
fi

# === 5. Generate AI shell entrypoint ===
AI_SH="$SCRIPTS_DIR/ai.sh"
cat <<'EOF' > "$AI_SH"
#!/bin/bash

CONFIG_FILE="$HOME/.gpt_terminal/config/settings.json"
API_URL="https://api.openai.com/v1/chat/completions"
API_KEY="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"  # Use ENV var if available

if [[ -z "$API_KEY" || "$API_KEY" == "YOUR_API_KEY_HERE" ]]; then
  echo "[!] Missing API key. Please edit your settings.json or export OPENAI_API_KEY."
  exit 1
fi

MODEL=$(jq -r '.model' "$CONFIG_FILE")
TEMP=$(jq -r '.temperature' "$CONFIG_FILE")
MAXTOK=$(jq -r '.max_tokens' "$CONFIG_FILE")

read -rp $'\e[1;32m>\e[0m Enter prompt: ' USER_PROMPT

REQUEST_BODY=$(jq -n \
  --arg model "$MODEL" \
  --arg prompt "$USER_PROMPT" \
  --argjson temp "$TEMP" \
  --argjson max_tokens "$MAXTOK" \
  '{
    model: $model,
    messages: [
      { role: "system", content: "You are a helpful terminal assistant." },
      { role: "user", content: $prompt }
    ],
    temperature: $temp,
    max_tokens: $max_tokens
  }')

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY")

CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

if jq -e '.choices[0].message.content' <<< "$RESPONSE" >/dev/null; then
  echo -e "\n\e[1;34m=== AI Response ===\e[0m"
  echo "$CONTENT" | tee -a "$HOME/.gpt_terminal/ai_history.log"
else
  echo "[!] Invalid response from API. Raw output:" >&2
  echo "$RESPONSE" >&2
  exit 2
fi
EOF
chmod +x "$AI_SH"

# === 6. Shell alias integration ===
echo "[+] Adding alias to ~/.bashrc..."
grep -qxF "alias ai='$AI_SH'" ~/.bashrc || echo "alias ai='$AI_SH'" >> ~/.bashrc

# === 7. Done ===
echo "[✓] AI Terminal Shell ready! Run 'ai' in a new terminal window."
echo "[!] Be sure to manually insert your OpenAI API key or export OPENAI_API_KEY."

exit 0
