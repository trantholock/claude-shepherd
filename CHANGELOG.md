# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **Restore sessions that closed unexpectedly**, like Chrome's "Restore pages". A session whose `claude` process is gone without a `SessionEnd` hook (crash, `kill`, terminal or machine shut down, reboot) is shown as **Closed unexpectedly** at the top of the dashboard and the app, with **Restore all** / **Dismiss**. Restoring runs `claude --resume <id>` in a new terminal tab in the session's folder.
  - Only sessions with at least one prompt are offered, for 3 days. SDK/headless sessions are skipped. Boot time is checked so a PID reused after a reboot is not mistaken for the old session.
  - `ccmon serve` sends one notification per crash. `ccmon restore mode auto` reopens sessions on its own instead (for example after a reboot); `ccmon restore mode off` turns the feature off.
  - CLI: `ccmon restore` (list), `ccmon restore all|<id>`, `ccmon restore dismiss [id]`. API: `POST /api/restore?id=<id|all>`, `POST /api/dismiss?id=<id|all>`.
  - On the first run, sessions that were already dead are marked closed, so you are not offered old sessions.

## [1.1.0] - 2026-11-17

### Added

- **Linux and Windows support** for the `ccmon` CLI, hooks, desktop notifications and web dashboard (the desktop app stays macOS-only).
  - Linux: `.deb` (Debian/Ubuntu), `.rpm` (Fedora/RHEL/Rocky/openSUSE), `.pkg.tar.zst` (Arch) and a generic `tar.gz` with `install.sh`. The dashboard runs as a `systemd --user` service; notifications use `notify-send`; `ccmon term` opens `x-terminal-emulator`, GNOME Terminal, Konsole, kitty, Alacritty, WezTerm… or `$CCMON_TERMINAL`.
  - Windows 10/11: zip with `install.ps1` / `uninstall.ps1` (no admin). The dashboard starts at login from `HKCU\…\Run`; notifications are Windows toasts; `ccmon term` opens a Windows Terminal tab (or a new console).
  - `ccmon setup` / `ccmon teardown [--no-service]` add or remove the hooks and the login service on Linux/Windows. `ccmon version`.
- Release workflow: pushing a `vX.Y.Z` tag runs CI on macOS, Linux and Windows, builds the packages, installs them on Ubuntu 22.04/24.04, Debian 12, Fedora 41, Rocky 9, openSUSE Tumbleweed and Arch, then publishes a GitHub Release with `SHA256SUMS`.
- Cross-platform smoke test (`tests/smoke.py`), run by `make check` and CI.
- English UI (default) alongside Vietnamese, chosen from the macOS language or `ccmon lang en|vi|auto` / `CCMON_LANG`.
- Demo GIF and screenshot in the README.
- Sessions started from the Claude mobile app or claude.ai through `claude remote-control` are recognised and shown as **Remote**. Clicking one opens a new iTerm tab running `claude --resume <id>`. If the remote session is idle, its background worker is stopped first so the conversation moves to the terminal. If it is still running or waiting for permission, it is opened with `--fork-session` instead. The web page stays available from the **Web** button and the app's context menu.
- `ccmon term <id>` and `POST /api/term?id=` open a session in a new iTerm tab with `claude --resume`. The dashboard shows a **Terminal** button on closed sessions, and the app adds **Resume in Terminal** to their context menu.
- Search sessions by name, folder, prompt, reply, current tool or session ID. Matching ignores case and Vietnamese accents, and every word must match. The dashboard has a search box (`/` to focus, Esc to clear, kept in the URL as `#q=`), the app has one above the list (⌘F), and `ccmon ls [-a] <text>` filters the table.

### Changed

- `ccmon` reads hook input and writes its files as UTF-8 on every OS (Windows defaults to the console code page).
- The hook/statusLine editing logic moved from `scripts/hooks.py` into `ccmon` so all platforms share it; `scripts/hooks.py` is now a thin wrapper.
- Shebang is now `#!/usr/bin/env python3`. The macOS hooks and LaunchAgent still call `/usr/bin/python3` explicitly.
- Project renamed to **Claude Shepherd** (repo `claude-shepherd`, app "Claude Shepherd.app", bundle ID `io.github.trantholock.claude-shepherd`). `make install` removes the old "Claude Agents" app and LaunchAgent. The CLI is still `ccmon`.

## [1.0.0] - 2026-10-23

### Added

- `ccmon` CLI, Claude Code hook and local web dashboard
- "Claude Agents" SwiftUI desktop app with Dock badge and menu bar icon
- macOS notifications when a session finishes or waits for permission
- 5h / 7d plan quota via the Claude Code `statusLine`
- Custom session names
- Jump to the session's iTerm tab / VS Code window

### Changed

- LaunchAgent labels and bundle ID renamed from `com.trantho.*` to `io.github.trantholock.*`; `make install` removes the old ones.

[Unreleased]: https://github.com/trantholock/claude-shepherd/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/trantholock/claude-shepherd/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/trantholock/claude-shepherd/releases/tag/v1.0.0
