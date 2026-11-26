# 🐑 Claude Shepherd

> **Herd your Claude Code agents.** Running 5 sessions at once? Know instantly which one is done, which is waiting for permission, and jump straight to it.

**English** · [Tiếng Việt](README.vi.md)

[![CI](https://github.com/trantholock/claude-shepherd/actions/workflows/ci.yml/badge.svg)](https://github.com/trantholock/claude-shepherd/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Platform: macOS · Linux · Windows](https://img.shields.io/badge/platform-macOS%20%C2%B7%20Linux%20%C2%B7%20Windows-lightgrey)

![Claude Shepherd dashboard: sessions move from running to done or waiting for permission](docs/demo.gif)

Keep track of every **Claude Code** session you run in parallel (iTerm, the VS Code extension, the VS Code terminal) so you never miss an agent that has finished or is waiting on you.

- **Claude Code hooks** write each session's state to `~/.claude/ccmon/sessions/<session_id>.json`
- **Desktop notifications** (macOS, Linux `notify-send`, Windows toasts) when an agent finishes a turn or needs permission
- **Web dashboard** at http://127.0.0.1:7788
- **Desktop app** "Claude Shepherd" (macOS): its own window, a Dock badge and a menu bar icon; click a session to jump to its iTerm tab or VS Code window
- **Plan quota** (5-hour / 7-day, same as `/usage`) in the app header, window title, menu bar, web dashboard and the Claude Code status line
- **Session names** you choose (✎ on the dashboard, right-click → Rename… in the app, or `ccmon name`)
- **Remote Control sessions** started from your phone or claude.ai can be resumed in an iTerm tab with one click (see [below](#remote-control-sessions))
- **Search** sessions by name, folder, prompt, reply or ID — accent-insensitive, every word must match (dashboard: `/` to focus, Esc to clear; app: ⌘F; CLI: `ccmon ls [-a] <text>`)
- **Tags**: start a prompt with `[task service-a]` to tag the session; common topics (bug, feature, docs, k8s, python…) are tagged automatically. Filter with `#tag` or `tag:tag`
- **Restore after a crash**: sessions that closed unexpectedly (crash, reboot, terminal killed) are offered for restore, like Chrome (see [below](#restoring-sessions-after-a-crash))
- **`ccmon` CLI**

- **English and Vietnamese** UI — more translations welcome

## Requirements

- Claude Code
- Python 3.9+, no third-party packages (macOS uses the system `/usr/bin/python3`)
- macOS 14+ with Xcode Command Line Tools (`xcode-select --install`) for the desktop app

| | macOS | Linux | Windows |
|---|---|---|---|
| CLI, hooks, web dashboard, quota | ✅ | ✅ | ✅ |
| Notifications | ✅ | ✅ `notify-send` | ✅ toast |
| Dashboard starts at login | LaunchAgent | `systemd --user` | `HKCU\…\Run` |
| Jump to a session | iTerm tab, VS Code | VS Code | VS Code |
| Resume in a new terminal (`ccmon term`) | iTerm | GNOME Terminal, Konsole, kitty… | Windows Terminal |
| Desktop app (Dock, menu bar) | ✅ | — | — |

## Install

### Linux

Download from the [latest release](https://github.com/trantholock/claude-shepherd/releases/latest), then run `ccmon setup` **as your normal user** (not `sudo`):

```bash
sudo apt install ./claude-shepherd_*_all.deb             # Debian, Ubuntu
sudo dnf install ./claude-shepherd-*.noarch.rpm          # Fedora, RHEL, Rocky (openSUSE: zypper in)
sudo pacman -U claude-shepherd-*-any.pkg.tar.zst         # Arch, Manjaro
ccmon setup        # hooks + systemd --user service for the dashboard
```

Without root, use the tarball: extract `claude-shepherd-*-linux.tar.gz` and run `./install.sh` (installs `~/.local/bin/ccmon`).
Run `ccmon teardown` before removing the package. Without systemd (WSL, containers), start the dashboard yourself with `ccmon serve &`.

### Windows

Install Python 3.9+ (`winget install Python.Python.3.12`), unzip `claude-shepherd-*-windows.zip` from the [latest release](https://github.com/trantholock/claude-shepherd/releases/latest), then:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1     # uninstall: uninstall.ps1
```

This copies `ccmon` to `%LOCALAPPDATA%\Programs\claude-shepherd`, adds it to your user `PATH`, adds the hooks and starts the dashboard at login. No admin rights needed.

### macOS

```bash
git clone https://github.com/trantholock/claude-shepherd.git
cd claude-shepherd
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
| Closed unexpectedly | the claude PID is gone without `SessionEnd` (crash, reboot, kill) | offered for restore for 3 days |
| Closed | `SessionEnd` | removed after 24h |

`●` means unseen. A session is marked seen when you click **Open** / **Seen**, or when you send a new prompt.

## Remote Control sessions

When `claude remote-control` is running on your Mac, you can start a new session from the Claude mobile app or claude.ai/code. That session runs on the Mac in the background. ccmon recognises it from the `--sdk-url …/code/sessions/cse_…` argument and labels it **Remote**.

Clicking a Remote session in the app, or **Terminal** on the dashboard, opens a new iTerm tab that runs `claude --resume <id>` in the session's folder:

- **Idle or done:** the background worker is stopped first, then the same session is resumed. The conversation moves to the terminal, so you can no longer continue it from your phone.
- **Running or waiting for permission:** the worker is left alone and the tab opens with `--fork-session`. You get a copy that has the full history, and the original keeps going.

To open the session in the browser instead, use **Web** on the dashboard or right-click → Open on web in the app.

To keep `claude remote-control` running all the time, start it from a LaunchAgent with `caffeinate -is` and send its stdout to `/dev/null`. Its screen output redraws constantly and would otherwise grow the log by tens of MB a day.

## Restoring sessions after a crash

A session that disappears without Claude Code's `SessionEnd` hook (the app crashed, the terminal or the Mac was shut down, the process was killed, the machine rebooted) is marked **Closed unexpectedly**. The dashboard and the app show a banner with **Restore all** and **Dismiss**, and `ccmon serve` sends one notification. Restoring opens a new terminal tab (iTerm, Windows Terminal, or your Linux terminal) in the session's folder and runs `claude --resume <id>`, so the conversation continues where it stopped.

```bash
ccmon restore                 # list sessions that closed unexpectedly
ccmon restore all             # reopen all of them (or: ccmon restore <id>)
ccmon restore dismiss [id]    # don't offer them again
ccmon restore mode auto       # reopen on its own, e.g. after a reboot (ask = default, off = disabled)
```

Only sessions with at least one prompt are offered, for up to 3 days. VS Code sessions are resumed in a terminal. The mode is stored in `~/.claude/ccmon/config.json`; `CCMON_RESTORE=ask|auto|off` takes precedence.

## Tags

Every prompt is scanned for tags:

- **Your tags**: a `[...]` group at the start of a line or at the end of the prompt, words separated by spaces or commas. `[task service-a] fix the login bug` tags the session `#task` and `#service-a`. Use `-` for a multi-word tag. The group, as you typed it, also prefixes the session name: `[vi du] my-repo` (the latest prompt with a group wins; removing all of its tags hides the prefix). Brackets inside text or code (`arr[i]`, `- [x]`, `[text](url)`) and Claude Code's `[Image #1]` / `[Pasted text …]` placeholders are ignored.
- **Automatic tags** (shown dashed): keyword rules in English and Vietnamese for the kind of work (`bug`, `feature`, `refactor`, `test`, `docs`, `release`, `review`, `perf`, `security`, `ci`, `question`) and the stack (`k8s`, `docker`, `terraform`, `ansible`, `argocd`, `postgres`, `python`, `go`, `js`, `shell`, `linux`, `windows`…). They run locally with regexes; no prompt leaves the machine.

Tags add up over the session (newest first, at most 20 of your own + 8 automatic). Search with `#tag` or `tag:tag` (prefix match, combine with other words), or click a tag in the dashboard or the app.

```bash
ccmon ls -a tag:service-a     # (in bash, quote '#tag' or use tag:)
ccmon tag <id> +ddi -k8s      # add / remove tags (also: 🏷 in the dashboard, "Edit tags…" in the app)
ccmon tags                    # every tag with its session count
```

Tags you add or remove by hand are kept in `~/.claude/ccmon/tags.json`; a removed automatic tag does not come back.

## CLI

```
ccmon [ls] [-a] [text] status table (-a includes closed sessions; text filters it)
ccmon watch            table that refreshes every 2s
ccmon serve [port]     web dashboard (default 7788)
ccmon focus <id>       jump to the session's iTerm tab / VS Code window (Remote: resume in a terminal)
ccmon term <id>        open the session in a new terminal tab (claude --resume)
ccmon ack [id|all]     mark as seen
ccmon clean            delete closed sessions
ccmon name <id> [name] set a session name (empty name = clear it)
ccmon tag <id> [+t|-t] show / add / remove tags
ccmon tags             every tag with its session count
ccmon usage            5h / 7d quota
ccmon restore [all|<id>|dismiss|mode ask|auto|off]  reopen sessions that closed unexpectedly
ccmon lang [en|vi|auto] UI language
ccmon statusline       (used as Claude Code's statusLine command)
ccmon setup|teardown   Linux/Windows: add/remove hooks + login service (--no-service: hooks only)
ccmon version
```

On Linux, `ccmon term` uses `$CCMON_TERMINAL` if set (for example `CCMON_TERMINAL="kitty -e"`), otherwise the first terminal it finds.

## Quota and session names

After each turn Claude Code sends JSON to the `statusLine` command, including `rate_limits.five_hour|seven_day` (`used_percentage`, `resets_at`) and `session_name`. `ccmon statusline` stores the quota in `~/.claude/ccmon/usage.json`, per-session data in `~/.claude/ccmon/statusline/<id>.json`, and prints a line like `📌 name · 🟢 5h 46% (reset 14:10) · 🟠 7d 81% · ctx 12%`.

- The quota only updates while at least one Claude session is active; after the reset time it shows 0%.
- `make install` only sets `statusLine` if you don't already have your own.
- Display name priority: your custom name (`~/.claude/ccmon/names.json`) > Claude's `session_name` > folder name.

To disable notifications, set `CCMON_NOTIFY=0` in Claude Code's environment.

## Language

The CLI, notifications, web dashboard and app follow your OS language (English by default, Vietnamese if the OS is set to Vietnamese; on Linux `LANGUAGE`/`LANG`). To override it:

```bash
ccmon lang vi     # or: en, auto
```

This is saved in `~/.claude/ccmon/config.json`; restart the app and `ccmon serve` to apply. `CCMON_LANG=en|vi` in the environment takes precedence.

## Project layout

```
ccmon/ccmon                 CLI + hook + web server (Python stdlib, 3.9 compatible)
app/ClaudeShepherd.swift      SwiftUI app (Window + MenuBarExtra), reads the ccmon serve API
app/icon.swift              draws the icon with AppKit -> build/AppIcon.icns
app/Info.plist
launchd/*.plist.tmpl        LaunchAgents: ccmon serve + open the app at login
scripts/install.sh          full install
scripts/build-app.sh        builds the app into build/ and copies it to ~/Applications
scripts/hooks.py            add/remove hooks + statusLine (wrapper around ccmon settings_hooks)
scripts/uninstall.sh
scripts/install.ps1         Windows install / uninstall.ps1
scripts/dist.sh             build Linux/Windows release packages into dist/ (nfpm)
packaging/nfpm.yaml         .deb / .rpm / Arch package definition
tests/smoke.py              cross-platform smoke test (make check, CI)
```

## API (`ccmon serve`)

The server only listens on `127.0.0.1`.

- `GET  /api/sessions?all=0|1` → `{now, rows: [...], usage}`
- `POST /api/ack?id=<id|all>`, `/api/forget?id=`, `/api/focus?id=`, `/api/term?id=`, `/api/rename?id=&name=`, `/api/tags?id=&tags=a%20b` (replaces the list), `/api/restore?id=<id|all>`, `/api/dismiss?id=<id|all>` (requires the `X-CCMon: 1` header)

## Troubleshooting

- Sessions opened before the hooks were installed only appear after their next prompt. In VS Code, run **Reload Window**.
- The first time you focus or open an iTerm tab, macOS asks for Automation permission → Allow.
- Notifications may be listed under "Script Editor" in System Settings → Notifications.
- Linux: no notifications → install `libnotify-bin` (Debian/Ubuntu) or `libnotify`. Dashboard logs: `journalctl --user -u claude-shepherd`.
- Windows: if `ccmon` is not found, open a new terminal so it picks up the new `PATH`.
- Hook errors are logged to `~/.claude/ccmon/hook-errors.log`; the hook never breaks a Claude session.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) and our [Code of Conduct](CODE_OF_CONDUCT.md). To report a security issue, see [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE). This is a community project and is not affiliated with or endorsed by Anthropic. "Claude" is a trademark of Anthropic.
