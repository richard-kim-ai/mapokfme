#!/usr/bin/env bash
set -euo pipefail

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.npm-global/bin"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
POLL_SECONDS="${AUTO_SAVE_POLL_SECONDS:-8}"
LOG_FILE="$PROJECT_DIR/logs/auto-save-watch.log"
PID_FILE="$PROJECT_DIR/logs/auto-save-watch.pid"

mkdir -p "$PROJECT_DIR/logs"
echo "$$" > "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S %z')] $*"
}

snapshot() {
  (
    for file in admin.html index.html mapo_site.html shinchong.html vercel.json package.json package-lock.json vite.config.js; do
      if [ -f "$PROJECT_DIR/$file" ]; then
        stat -f '%m %N' "$PROJECT_DIR/$file"
      fi
    done

    for dir in src public; do
      if [ -d "$PROJECT_DIR/$dir" ]; then
        find "$PROJECT_DIR/$dir" -type f -exec stat -f '%m %N' {} \; 2>/dev/null
      fi
    done
  ) | sort | shasum | awk '{print $1}'
}

exec >> "$LOG_FILE" 2>&1

cd "$PROJECT_DIR"
log "Auto-save watch started. poll=${POLL_SECONDS}s"

LAST_SNAPSHOT="$(snapshot)"

while true; do
  sleep "$POLL_SECONDS"
  CURRENT_SNAPSHOT="$(snapshot)"
  if [ "$CURRENT_SNAPSHOT" != "$LAST_SNAPSHOT" ]; then
    log "Change detected. Running auto-push-deploy."
    /bin/zsh "$PROJECT_DIR/scripts/auto-push-deploy.sh" || log "auto-push-deploy failed."
    LAST_SNAPSHOT="$CURRENT_SNAPSHOT"
  fi
done
