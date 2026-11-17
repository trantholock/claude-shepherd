#!/bin/bash
# Đóng gói bản phát hành Linux + Windows vào dist/ (chạy trên Linux, cần nfpm + zip):
#   scripts/dist.sh 1.1.0
# Ra: tar.gz (mọi distro), .deb, .rpm, .pkg.tar.zst (Arch), zip Windows, SHA256SUMS
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:?usage: dist.sh <version>}"
VERSION="${VERSION#v}"
cd "$ROOT"

# tag phải khớp VERSION trong ccmon, tránh phát hành nhầm số
CODE_VERSION="$(python3 ccmon/ccmon version | awk '{print $2}')"
[ "$CODE_VERSION" = "$VERSION" ] || { echo "ccmon VERSION=$CODE_VERSION but release is $VERSION" >&2; exit 1; }

OUT="$ROOT/dist"
rm -rf "$OUT" && mkdir -p "$OUT"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

# Linux tarball: giải nén ở đâu cũng được, ./install.sh symlink ~/.local/bin/ccmon + ccmon setup
L="$STAGE/claude-shepherd-$VERSION-linux"
mkdir -p "$L/ccmon" "$L/scripts"
cp ccmon/ccmon "$L/ccmon/"
cp scripts/install.sh scripts/uninstall.sh "$L/scripts/"
cp README.md README.vi.md CHANGELOG.md LICENSE "$L/"
for x in install uninstall; do  # wrapper (không symlink: script tính ROOT từ vị trí của chính nó)
  # shellcheck disable=SC2016  # $0/$@ phải giữ nguyên để wrapper tự mở rộng lúc chạy
  printf '#!/bin/sh\nexec "$(dirname "$0")/scripts/%s.sh" "$@"\n' "$x" > "$L/$x.sh"
done
chmod 755 "$L/ccmon/ccmon" "$L/scripts/"*.sh "$L/"*.sh
tar -C "$STAGE" --owner=0 --group=0 -czf "$OUT/claude-shepherd-$VERSION-linux.tar.gz" "$(basename "$L")"

# Windows zip
W="$STAGE/claude-shepherd-$VERSION-windows"
mkdir -p "$W/ccmon"
cp ccmon/ccmon "$W/ccmon/"
cp scripts/install.ps1 scripts/uninstall.ps1 "$W/"
cp README.md README.vi.md CHANGELOG.md LICENSE "$W/"
(cd "$STAGE" && zip -qr "$OUT/claude-shepherd-$VERSION-windows.zip" "$(basename "$W")")

# deb / rpm / Arch
for p in deb rpm archlinux; do
  VERSION="$VERSION" nfpm package --config packaging/nfpm.yaml --packager "$p" --target "$OUT/"
done

(cd "$OUT" && sha256sum -- * > SHA256SUMS)
ls -l "$OUT"
