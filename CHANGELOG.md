# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- English UI (default) alongside Vietnamese, chosen from the macOS language or `ccmon lang en|vi|auto` / `CCMON_LANG`.
- Demo GIF and screenshot in the README.
- Sessions started from the Claude mobile app or claude.ai through `claude remote-control` are recognised and shown as **Remote**. Clicking one opens a new iTerm tab running `claude --resume <id>`. If the remote session is idle, its background worker is stopped first so the conversation moves to the terminal. If it is still running or waiting for permission, it is opened with `--fork-session` instead. The web page stays available from the **Web** button and the app's context menu.
- `ccmon term <id>` and `POST /api/term?id=` open a session in a new iTerm tab with `claude --resume`. The dashboard shows a **Terminal** button on closed sessions, and the app adds **Resume in Terminal** to their context menu.

### Changed

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

[Unreleased]: https://github.com/trantholock/claude-shepherd/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/trantholock/claude-shepherd/releases/tag/v1.0.0
