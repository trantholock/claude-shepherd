#!/bin/bash
# Cài đặt: symlink ccmon, gắn hook Claude Code, LaunchAgent, build app
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$HOME/bin/ccmon"
LA="$HOME/Library/LaunchAgents"

echo "==> ccmon -> $BIN"
mkdir -p "$HOME/bin"
chmod +x "$ROOT/ccmon/ccmon"
[ -f "$BIN" ] && [ ! -L "$BIN" ] && mv "$BIN" "$BIN.bak-$(date +%Y%m%d%H%M%S)"
ln -sfn "$ROOT/ccmon/ccmon" "$BIN"

echo "==> hook trong ~/.claude/settings.json"
/usr/bin/python3 "$ROOT/scripts/hooks.py" install "/usr/bin/python3 $BIN hook"

echo "==> LaunchAgent"
mkdir -p "$LA" "$HOME/.claude/ccmon"
for t in "$ROOT"/launchd/*.plist.tmpl; do
  name="$(basename "$t" .tmpl)"
  sed "s#__HOME__#$HOME#g" "$t" > "$LA/$name"
done
# dọn LaunchAgent nhãn cũ (trước v1.0) nếu còn
for old in com.trantho.ccmon com.trantho.claude-agents; do
  launchctl bootout "gui/$(id -u)/$old" 2>/dev/null || true
  rm -f "$LA/$old.plist"
done
launchctl bootout "gui/$(id -u)/io.github.trantholock.ccmon" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$LA/io.github.trantholock.ccmon.plist"

echo "==> build app"
"$ROOT/scripts/build-app.sh"
echo "Xong. Dashboard: http://127.0.0.1:7788"
