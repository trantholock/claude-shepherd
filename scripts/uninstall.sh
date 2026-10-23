#!/bin/bash
# Gỡ: hook, LaunchAgent, app, symlink (giữ lại dữ liệu ~/.claude/ccmon)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
/usr/bin/python3 "$ROOT/scripts/hooks.py" uninstall
for l in io.github.trantholock.ccmon io.github.trantholock.claude-shepherd io.github.trantholock.claude-agents com.trantho.ccmon com.trantho.claude-agents; do
  launchctl bootout "gui/$(id -u)/$l" 2>/dev/null
  rm -f "$HOME/Library/LaunchAgents/$l.plist"
done
pkill -x ClaudeShepherd
pkill -x ClaudeAgents
rm -rf "$HOME/Applications/Claude Shepherd.app" "$HOME/Applications/Claude Agents.app"
[ -L "$HOME/bin/ccmon" ] && rm "$HOME/bin/ccmon"
echo "Đã gỡ. Dữ liệu phiên vẫn ở ~/.claude/ccmon (xóa tay nếu muốn)."
