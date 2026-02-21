#!/data/data/com.termux/files/usr/bin/bash

set -e

APP_DIR="$HOME/vivo_app"
LOG_DIR="$APP_DIR/logs"
PID_FILE="$APP_DIR/server.pid"

echo "🚀 Starting redeploy..."

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

# 2️⃣ Pull latest code
echo "📥 Pulling latest code..."
git pull origin main

# 3️⃣ Install dependencies if needed
echo "📦 Installing dependencies..."
npm install

# 4️⃣ Build React app
echo "🏗 Building app..."
npm run build

# 5️⃣ Start server in background
echo "🚀 Starting server..."
mkdir -p "$LOG_DIR"
nohup node server.js > "$LOG_DIR/server.log" 2>&1 &

NEW_PID=$!
echo "$NEW_PID" > "$PID_FILE"

echo "✅ Redeploy complete. Server PID: $NEW_PID"
