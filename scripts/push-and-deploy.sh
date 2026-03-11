#!/bin/zsh
set -euo pipefail

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.npm-global/bin"

PROJECT_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
REMOTE="${AUTO_SYNC_REMOTE:-origin}"
BRANCH="${AUTO_SYNC_BRANCH:-main}"
VERCEL_BIN="${VERCEL_BIN:-/Users/richard/.npm-global/bin/vercel}"
LOG_FILE="$PROJECT_DIR/logs/post-commit-auto-deploy.log"

mkdir -p "$PROJECT_DIR/logs"

log() {
  print -r -- "[$(date '+%Y-%m-%d %H:%M:%S %z')] $*"
}

exec >> "$LOG_FILE" 2>&1

cd "$PROJECT_DIR"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
  log "Skip: current branch is $CURRENT_BRANCH, target is $BRANCH."
  exit 0
fi

if [ -f .git/MERGE_HEAD ] || [ -d .git/rebase-merge ] || [ -d .git/rebase-apply ]; then
  log "Skip: git merge/rebase in progress."
  exit 0
fi

log "Auto push/deploy start for commit $(git rev-parse --short HEAD)"
git push "$REMOTE" "$BRANCH"

if [ ! -x "$VERCEL_BIN" ]; then
  log "Vercel CLI not found at $VERCEL_BIN"
  exit 1
fi

"$VERCEL_BIN" --prod --yes --cwd "$PROJECT_DIR"
log "Auto push/deploy done."

