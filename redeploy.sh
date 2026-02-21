#!/data/data/com.termux/files/usr/bin/bash

set -e

APP_DIR="$HOME/vivo_app"
LOG_DIR="$APP_DIR/logs"
PID_FILE="$APP_DIR/server.pid"
TUNNEL_PID_FILE="$APP_DIR/tunnel.pid"
TUNNEL_URL_FILE="$APP_DIR/tunnel.url"
TUNNEL_LOG_FILE="$LOG_DIR/cloudflared.log"

# App server settings (keep in sync with server.js)
PORT=5173
BASE_PATH="/vivo_app"

TS=$(date +"%Y%m%d-%H%M%S")
REDEPLOY_LOG_FILE="$LOG_DIR/redeploy-$TS.log"

mkdir -p "$LOG_DIR"

# Log everything (stdout+stderr) to a timestamped file, and also print to terminal.
exec > >(tee -a "$REDEPLOY_LOG_FILE") 2>&1

START_TIME=$(date +%s)

echo "🚀 Starting redeploy..."
echo "🧾 Log file: $REDEPLOY_LOG_FILE"

cd "$APP_DIR"

# 1️⃣ Stop running server if exists
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "🛑 Stopping old server (PID $OLD_PID)"
    kill "$OLD_PID"
    sleep 2
  fi
  rm -f "$PID_FILE"
fi

# 1️⃣b Stop running Cloudflare Tunnel if exists
if [ -f "$TUNNEL_PID_FILE" ]; then
  OLD_TUNNEL_PID=$(cat "$TUNNEL_PID_FILE")
  if kill -0 "$OLD_TUNNEL_PID" 2>/dev/null; then
    echo "🛑 Stopping old Cloudflare Tunnel (PID $OLD_TUNNEL_PID)"
    kill "$OLD_TUNNEL_PID" || true
    sleep 2
  fi
  rm -f "$TUNNEL_PID_FILE"
fi

# 2️⃣ Pull latest code
echo "📥 Pulling latest code..."
git pull origin main

# 3️⃣ Install dependencies if needed
echo "📦 Installing dependencies..."
# Faster + reproducible installs on CI/Termux when lockfile exists.
# Set INSTALL=0 to skip install.
if [ "${INSTALL:-1}" = "1" ]; then
  if [ -f package-lock.json ]; then
    npm ci --prefer-offline --no-audit --no-fund
  else
    npm install --prefer-offline --no-audit --no-fund
  fi
else
  echo "⏭ Skipping dependency install (INSTALL=0)"
fi

# 4️⃣ Build React app
echo "🏗 Building app..."
# Set BUILD=0 to skip build.
if [ "${BUILD:-1}" = "1" ]; then
  npm run build
else
  echo "⏭ Skipping build (BUILD=0)"
fi

# 5️⃣ Start server in background
echo "🚀 Starting server..."
nohup node server.js > "$LOG_DIR/server.log" 2>&1 &

NEW_PID=$!
echo "$NEW_PID" > "$PID_FILE"

echo "✅ Redeploy complete. Server PID: $NEW_PID"

# Print LAN URL (useful on phone/local network)
LAN_IP=""
if command -v ip >/dev/null 2>&1; then
  # Common on Android/Termux
  LAN_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++){if($i=="src"){print $(i+1); exit}}}')
fi
if [ -z "$LAN_IP" ] && command -v hostname >/dev/null 2>&1; then
  # Fallback for some environments
  LAN_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
fi

LOCAL_URL="http://localhost:${PORT}${BASE_PATH}/"
echo "🔗 Local URL:  $LOCAL_URL"
if [ -n "$LAN_IP" ]; then
  echo "🔗 LAN URL:    http://${LAN_IP}:${PORT}${BASE_PATH}/"
fi

# 6️⃣ (Optional) Start Cloudflare Tunnel and capture public URL
# Usage:
#   START_TUNNEL=1 ./redeploy.sh
# Prerequisite (Termux):
#   pkg install cloudflared
if [ "${START_TUNNEL:-0}" = "1" ]; then
  if ! command -v cloudflared >/dev/null 2>&1; then
    echo "⚠️  START_TUNNEL=1 was set, but cloudflared is not installed."
    echo "   Install (Termux): pkg install cloudflared"
    exit 1
  fi

  echo "🌐 Starting Cloudflare Tunnel..."
  rm -f "$TUNNEL_URL_FILE"
  mkdir -p "$LOG_DIR"

  # Tunnel the local Express server. We include the base path so the URL opens directly to the app.
  # Note: cloudflared will print a URL like https://random-name.trycloudflare.com
  nohup cloudflared tunnel --url "http://localhost:${PORT}${BASE_PATH}/" --no-autoupdate > "$TUNNEL_LOG_FILE" 2>&1 &
  TUNNEL_PID=$!
  echo "$TUNNEL_PID" > "$TUNNEL_PID_FILE"

  echo "⏳ Waiting for tunnel URL..."
  # Poll the log for the trycloudflare URL for up to ~20 seconds.
  for i in $(seq 1 40); do
    TUNNEL_URL=$(grep -Eo 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' "$TUNNEL_LOG_FILE" | head -n 1 || true)
    if [ -n "$TUNNEL_URL" ]; then
      echo "$TUNNEL_URL" > "$TUNNEL_URL_FILE"
      echo "✅ Tunnel ready: $TUNNEL_URL"
      echo "   Tunnel PID: $TUNNEL_PID (saved to $TUNNEL_PID_FILE)"
      echo "   URL saved to: $TUNNEL_URL_FILE"
      break
    fi
    sleep 0.5
  done

  if [ ! -s "$TUNNEL_URL_FILE" ]; then
    echo "⚠️  Tunnel started (PID $TUNNEL_PID), but URL not detected yet."
    echo "   Check logs: $TUNNEL_LOG_FILE"
  fi
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "⏱ Total time: ${ELAPSED}s"
