#!/bin/zsh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUN_PROJECT_DIR="$HOME/mapokfme-homepage"
LABEL="com.mapokfme.auto-push-deploy"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$PLIST_DIR/$LABEL.plist"
LOG_DIR="$RUN_PROJECT_DIR/logs"

if [ -e "$RUN_PROJECT_DIR" ] && [ ! -L "$RUN_PROJECT_DIR" ]; then
  echo "Error: $RUN_PROJECT_DIR already exists and is not a symlink."
  exit 1
fi

ln -sfn "$PROJECT_DIR" "$RUN_PROJECT_DIR"
mkdir -p "$PLIST_DIR" "$LOG_DIR"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>$RUN_PROJECT_DIR/scripts/auto-push-deploy.sh</string>
  </array>

  <key>WorkingDirectory</key>
  <string>$RUN_PROJECT_DIR</string>

  <key>RunAtLoad</key>
  <true/>

  <key>StartInterval</key>
  <integer>90</integer>

  <key>StandardOutPath</key>
  <string>$LOG_DIR/launchd.out.log</string>

  <key>StandardErrorPath</key>
  <string>$LOG_DIR/launchd.err.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$LABEL" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"
launchctl enable "gui/$(id -u)/$LABEL"
launchctl kickstart -k "gui/$(id -u)/$LABEL"

echo "Installed: $LABEL"
echo "Plist: $PLIST_PATH"
echo "Main log: $LOG_DIR/auto-push-deploy.log"
echo "Runner symlink: $RUN_PROJECT_DIR -> $PROJECT_DIR"
