#!/bin/bash
# ========== AI Terminal Shell Bootstrap ==========
# Shell-side interface to summon GPT co-pilot from within your terminal.
# Designed for Ubuntu-based systems (works with Cinnamon, GNOME, XFCE, etc.)
# Future-state: deeper integration with persistent memory and async job handling.

set -euo pipefail

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
API_KEY="${OPENAI_API_KEY:-YOUR_API_KEY_HERE}"

if [[ -z "$API_KEY" || "$API_KEY" == "YOUR_API_KEY_HERE" ]]; then
  echo "[!] Missing API key. Please edit \$CONFIG_FILE or export OPENAI_API_KEY."
  exit 1
fi

MODEL=$(jq -r '.model' "$CONFIG_FILE")
TEMP=$(jq -r '.temperature' "$CONFIG_FILE")
MAXTOK=$(jq -r '.max_tokens' "$CONFIG_FILE")

read -rp $'\e[1;32m>\e[0m Enter prompt: ' USER_PROMPT

RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Authorization: Bearer \$API_KEY" \
  -H "Content-Type: application/json" \
  -d @- <<JSON
{
  "model": "\$MODEL",
  "messages": [
    {"role": "system", "content": "You are a helpful terminal assistant."},
    {"role": "user", "content": "\$USER_PROMPT"}
  ],
  "temperature": \$TEMP,
  "max_tokens": \$MAXTOK
}
JSON
)

echo "\$RESPONSE" | jq -r '.choices[0].message.content' | tee -a "$HOME/.gpt_terminal/ai_history.log"
EOF
chmod +x "$AI_SH"

# === 6. Shell alias integration ===
PROFILE_FILE="$HOME/.bashrc"
echo "[+] Adding alias to \$PROFILE_FILE..."
grep -qxF "alias ai='\$AI_SH'" "\$PROFILE_FILE" || echo "alias ai='\$AI_SH'" >> "\$PROFILE_FILE"

# === 7. Completion ===
echo "[✓] AI Terminal Shell ready! Run 'ai' in a new terminal window."
echo "[!] Be sure to export your OpenAI API key with: export OPENAI_API_KEY='your-key'"

exit 0
