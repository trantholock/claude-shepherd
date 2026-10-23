# Claude Agents

**English** · [Tiếng Việt](README.vi.md)

[![CI](https://github.com/trantholock/claude-agents/actions/workflows/ci.yml/badge.svg)](https://github.com/trantholock/claude-agents/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Platform: macOS 14+](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey)

Keep track of every **Claude Code** session you run in parallel (iTerm, the VS Code extension, the VS Code terminal) so you never miss an agent that has finished or is waiting on you.

- **Claude Code hooks** write each session's state to `~/.claude/ccmon/sessions/<session_id>.json`
- **macOS notifications** when an agent finishes a turn or needs permission
- **Web dashboard** at http://127.0.0.1:7788
- **Desktop app** "Claude Agents": its own window, a Dock badge and a menu bar icon; click a session to jump to its iTerm tab or VS Code window
- **Plan quota** (5-hour / 7-day, same as `/usage`) in the app header, window title, menu bar, web dashboard and the Claude Code status line
- **Session names** you choose (✎ on the dashboard, right-click → Rename… in the app, or `ccmon name`)
- **`ccmon` CLI**

> [!NOTE]
> The UI labels and CLI output are currently in Vietnamese. Translations are a great first contribution — see [CONTRIBUTING.md](CONTRIBUTING.md).

## Requirements

- macOS 14 or later
- Xcode Command Line Tools (`xcode-select --install`)
- Claude Code
- No third-party Python packages: everything runs on the system `/usr/bin/python3` (3.9+)

## Install

```bash
git clone https://github.com/trantholock/claude-agents.git
cd claude-agents
make install     # ccmon + hooks + LaunchAgent + build the app
```

Other targets:

```bash
make app         # rebuild the app after editing app/*.swift or the icon
make check       # run the same lint/build checks as CI
make uninstall   # remove hooks, LaunchAgents and the app (keeps ~/.claude/ccmon data)
```

`~/bin/ccmon` is a symlink to `ccmon/ccmon` in this repo, so changes to the CLI and hook take effect immediately. The background web dashboard needs a restart:

```bash
launchctl kickstart -k gui/$(id -u)/io.github.trantholock.ccmon
```

`make install` edits `~/.claude/settings.json` idempotently and keeps a timestamped backup next to it.

## Session states

| State | Hook event | Meaning |
|---|---|---|
| Running | `UserPromptSubmit`, `PreToolUse`, `PostToolUse` | the agent is working; shows the current tool |
| Waiting for you | `Notification` (permission) | needs permission or an answer |
| Done | `Stop` | finished the turn; shows the last reply |
| Interrupted | transcript contains `Request interrupted by user` | you pressed Esc mid-turn |
| Open, idle | `SessionStart` | a newly opened session |
| Closed | `SessionEnd`, or the claude PID is gone | removed after 24h |

`●` means unseen. A session is marked seen when you click **Open** / **Seen**, or when you send a new prompt.

## CLI

```
ccmon [ls] [-a]        status table (-a includes closed sessions)
ccmon watch            table that refreshes every 2s
ccmon serve [port]     web dashboard (default 7788)
ccmon focus <id>       jump to the session's iTerm tab / VS Code window
ccmon ack [id|all]     mark as seen
ccmon clean            delete closed sessions
ccmon name <id> [name] set a session name (empty name = clear it)
ccmon usage            5h / 7d quota
ccmon statusline       (used as Claude Code's statusLine command)
```

## Quota and session names

After each turn Claude Code sends JSON to the `statusLine` command, including `rate_limits.five_hour|seven_day` (`used_percentage`, `resets_at`) and `session_name`. `ccmon statusline` stores the quota in `~/.claude/ccmon/usage.json`, per-session data in `~/.claude/ccmon/statusline/<id>.json`, and prints a line like `📌 name · 🟢 5h 46% (reset 14:10) · 🟠 7d 81% · ctx 12%`.

- The quota only updates while at least one Claude session is active; after the reset time it shows 0%.
- `make install` only sets `statusLine` if you don't already have your own.
- Display name priority: your custom name (`~/.claude/ccmon/names.json`) > Claude's `session_name` > folder name.

To disable macOS notifications, set `CCMON_NOTIFY=0` in Claude Code's environment.

## Project layout

```
ccmon/ccmon                 CLI + hook + web server (Python stdlib, 3.9 compatible)
app/ClaudeAgents.swift      SwiftUI app (Window + MenuBarExtra), reads the ccmon serve API
app/icon.swift              draws the icon with AppKit -> build/AppIcon.icns
app/Info.plist
launchd/*.plist.tmpl        LaunchAgents: ccmon serve + open the app at login
scripts/install.sh          full install
scripts/build-app.sh        builds the app into build/ and copies it to ~/Applications
scripts/hooks.py            add/remove hooks + statusLine in ~/.claude/settings.json
scripts/uninstall.sh
```

## API (`ccmon serve`)

The server only listens on `127.0.0.1`.

- `GET  /api/sessions?all=0|1` → `{now, rows: [...], usage}`
- `POST /api/ack?id=<id|all>`, `/api/forget?id=`, `/api/focus?id=`, `/api/rename?id=&name=` (requires the `X-CCMon: 1` header)

## Troubleshooting

- Sessions opened before the hooks were installed only appear after their next prompt. In VS Code, run **Reload Window**.
- The first time you focus an iTerm tab, macOS asks for Automation permission → Allow.
- Notifications may be listed under "Script Editor" in System Settings → Notifications.
- Hook errors are logged to `~/.claude/ccmon/hook-errors.log`; the hook never breaks a Claude session.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) and our [Code of Conduct](CODE_OF_CONDUCT.md). To report a security issue, see [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE). This is a community project and is not affiliated with or endorsed by Anthropic. "Claude" is a trademark of Anthropic.
