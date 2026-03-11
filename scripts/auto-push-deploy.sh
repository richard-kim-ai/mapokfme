#!/bin/zsh
set -euo pipefail

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.npm-global/bin"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REMOTE="${AUTO_SYNC_REMOTE:-origin}"
BRANCH="${AUTO_SYNC_BRANCH:-main}"
VERCEL_BIN="${VERCEL_BIN:-/Users/richard/.npm-global/bin/vercel}"
LOCK_DIR="/tmp/${USER:-unknown}-mapokfme-auto-push-deploy.lock"
LOG_FILE="$PROJECT_DIR/logs/auto-push-deploy.log"

mkdir -p "$PROJECT_DIR/logs"
exec >> "$LOG_FILE" 2>&1

log() {
  print -r -- "[$(date '+%Y-%m-%d %H:%M:%S %z')] $*"
}

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  log "Skip: another sync process is running."
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

cd "$PROJECT_DIR"

if [ -f .git/MERGE_HEAD ] || [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
  log "Skip: git merge/rebase already in progress."
  exit 0
fi

if [ -z "$(git status --porcelain)" ]; then
  log "No local changes."
  exit 0
fi

log "Changes detected. Commit/push/deploy started."

git add -A
if git diff --cached --quiet; then
  log "No staged changes after add."
  exit 0
fi

COMMIT_MSG="auto: sync $(TZ=Asia/Seoul date '+%Y-%m-%d %H:%M:%S KST')"
git commit -m "$COMMIT_MSG"

if ! git fetch "$REMOTE" --prune; then
  log "Fetch failed."
  exit 1
fi

if ! git rebase "$REMOTE/$BRANCH"; then
  log "Rebase failed. Abort rebase."
  git rebase --abort || true
  exit 1
fi

if ! git push "$REMOTE" "$BRANCH"; then
  log "Push failed."
  exit 1
fi

if [ ! -x "$VERCEL_BIN" ]; then
  log "Vercel CLI not found at $VERCEL_BIN"
  exit 1
fi

if "$VERCEL_BIN" --prod --yes --cwd "$PROJECT_DIR"; then
  log "Deploy succeeded."
else
  log "Deploy failed."
  exit 1
fi
