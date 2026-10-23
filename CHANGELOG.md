# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/trantholock/claude-agents/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/trantholock/claude-agents/releases/tag/v1.0.0
