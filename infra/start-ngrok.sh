#!/usr/bin/env sh
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."
if ! command -v ngrok >/dev/null 2>&1; then
  echo "ngrok is not installed. Download it from https://ngrok.com/download and install it first."
  exit 1
fi

echo "Starting ngrok tunnel to localhost:8080..."
ngrok http 8080
