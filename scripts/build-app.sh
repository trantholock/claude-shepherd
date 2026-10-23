#!/bin/bash
# Build "Claude Shepherd.app" vào build/, cài sang ~/Applications rồi chạy lại app
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
B="$ROOT/build"
APP="$B/Claude Shepherd.app"
DEST="$HOME/Applications/Claude Shepherd.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# icon: vẽ bằng app/icon.swift -> iconset -> icns (chỉ vẽ lại khi icon.swift đổi)
if [ ! -f "$B/AppIcon.icns" ] || [ "$ROOT/app/icon.swift" -nt "$B/AppIcon.icns" ]; then
  swift "$ROOT/app/icon.swift" "$B/icon-1024.png"
  rm -rf "$B/AppIcon.iconset" && mkdir "$B/AppIcon.iconset"
  for s in 16 32 128 256 512; do
    sips -z $s $s "$B/icon-1024.png" --out "$B/AppIcon.iconset/icon_${s}x${s}.png" >/dev/null
    sips -z $((s*2)) $((s*2)) "$B/icon-1024.png" --out "$B/AppIcon.iconset/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$B/AppIcon.iconset" -o "$B/AppIcon.icns"
fi
cp "$B/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$ROOT/app/Info.plist" "$APP/Contents/Info.plist"
swiftc -O -swift-version 5 -parse-as-library -target "$(uname -m)-apple-macosx14.0" \
  "$ROOT/app/ClaudeShepherd.swift" -o "$APP/Contents/MacOS/ClaudeShepherd"
codesign --force -s - "$APP"

pkill -x ClaudeShepherd || true
for _ in $(seq 25); do pgrep -x ClaudeShepherd >/dev/null || break; sleep 0.2; done
mkdir -p "$HOME/Applications"
rm -rf "$DEST" && cp -R "$APP" "$DEST"
open "$DEST"
echo "OK: $DEST"
