#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PID_FILE="$PROJECT_DIR/logs/auto-save-watch.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "Auto-save watcher is not running."
  exit 0
fi

PID="$(cat "$PID_FILE" 2>/dev/null || true)"
if [ -z "${PID:-}" ]; then
  rm -f "$PID_FILE"
  echo "Auto-save watcher is not running."
  exit 0
fi

if kill -0 "$PID" 2>/dev/null; then
  kill "$PID"
  sleep 0.2
fi

rm -f "$PID_FILE"
echo "Stopped auto-save watcher (PID: $PID)"
