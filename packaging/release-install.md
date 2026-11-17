
## Install

All platforms need Python 3.9+ (stdlib only) and Claude Code. Sessions started after install are tracked; the dashboard runs at http://127.0.0.1:7788.

| Platform | Download | Install |
|---|---|---|
| **Windows 10/11** | `claude-shepherd-*-windows.zip` | Unzip, then `powershell -ExecutionPolicy Bypass -File install.ps1` |
| **Debian / Ubuntu** | `claude-shepherd_*_all.deb` | `sudo apt install ./claude-shepherd_*_all.deb` then `ccmon setup` |
| **Fedora / RHEL / Rocky / openSUSE** | `claude-shepherd-*.noarch.rpm` | `sudo dnf install ./claude-shepherd-*.noarch.rpm` (or `zypper in`) then `ccmon setup` |
| **Arch / Manjaro** | `claude-shepherd-*-any.pkg.tar.zst` | `sudo pacman -U claude-shepherd-*-any.pkg.tar.zst` then `ccmon setup` |
| **Any Linux** | `claude-shepherd-*-linux.tar.gz` | Extract, then `./install.sh` (no root; installs to `~/.local/bin`) |
| **macOS 14+** | Source code | `git clone` then `make install` (builds the desktop app) |

Run `ccmon setup` as your normal user, not with `sudo`. Before removing a package, run `ccmon teardown`.
On Linux and Windows you get the CLI, the hooks, desktop notifications and the web dashboard. The desktop app (Dock badge, menu bar) is macOS-only.

Verify downloads with `sha256sum -c SHA256SUMS`.
