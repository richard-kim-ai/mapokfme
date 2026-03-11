#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PID_FILE="$PROJECT_DIR/logs/auto-save-watch.pid"

mkdir -p "$PROJECT_DIR/logs"

if [ -f "$PID_FILE" ]; then
  PID="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -n "${PID:-}" ] && kill -0 "$PID" 2>/dev/null; then
    echo "Already running (PID: $PID)"
    exit 0
  fi
  rm -f "$PID_FILE"
fi

nohup /bin/zsh "$PROJECT_DIR/scripts/auto-save-watch-loop.sh" >/dev/null 2>&1 &
sleep 0.3

NEW_PID="$(cat "$PID_FILE" 2>/dev/null || true)"
if [ -n "${NEW_PID:-}" ] && kill -0 "$NEW_PID" 2>/dev/null; then
  echo "Started auto-save watcher (PID: $NEW_PID)"
else
  echo "Failed to start auto-save watcher."
  exit 1
fi

