#!/bin/zsh
set -euo pipefail

LABEL="com.mapokfme.auto-push-deploy"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"
RUN_PROJECT_DIR="$HOME/mapokfme-homepage"

launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
rm -f "$PLIST_PATH"
if [ -L "$RUN_PROJECT_DIR" ]; then
  rm -f "$RUN_PROJECT_DIR"
fi

echo "Removed: $LABEL"
echo "Deleted: $PLIST_PATH"
