# Contributing to Claude Shepherd

Thanks for your interest in improving Claude Shepherd! Issues and pull requests are welcome, in English or Vietnamese.

## Ways to contribute

- **Report a bug** or **request a feature** via [GitHub Issues](https://github.com/trantholock/claude-shepherd/issues/new/choose).
- **Translate** the UI/CLI labels (currently Vietnamese) — English is the most wanted.
- **Add support** for more terminals/editors in `ccmon focus` (Terminal.app, Ghostty, WezTerm, Cursor, …).
- **Improve docs** — screenshots and GIFs are especially helpful.

Look for issues labelled [`good first issue`](https://github.com/trantholock/claude-shepherd/labels/good%20first%20issue) if you're new.

## Development setup

```bash
git clone https://github.com/<you>/claude-shepherd.git
cd claude-shepherd
make install   # symlinks ~/bin/ccmon to your checkout, so CLI/hook edits are live
```

- **CLI / hook / web server** — `ccmon/ccmon`, a single file that must only use the Python standard library and stay compatible with the macOS system Python (3.9).
- **Desktop app** — `app/ClaudeShepherd.swift` (SwiftUI, macOS 14+). Rebuild with `make app`.
- **Web dashboard** — served by `ccmon serve`; restart it after changes:
  `launchctl kickstart -k gui/$(id -u)/io.github.trantholock.ccmon`

Before opening a PR, run the same checks as CI:

```bash
make check
```

## Guidelines

- **The hook must never break a Claude session.** It has a 5 s timeout, must exit quickly, and should swallow and log errors to `~/.claude/ccmon/hook-errors.log`.
- **No new dependencies** — stdlib Python, system tools and Swift/AppKit only.
- **Keep the server local** — it binds to `127.0.0.1`; state-changing endpoints require the `X-CCMon: 1` header.
- **Don't clobber user settings** — `scripts/hooks.py` must stay idempotent and keep backups.
- Match the style of the surrounding code; keep changes focused.
- Update `README.md` / `README.vi.md` and `CHANGELOG.md` when behavior changes.

## Pull requests

1. Fork the repo and create a branch from `main` (`feat/…`, `fix/…`, `docs/…`).
2. Make your change and run `make check`.
3. Use clear commit messages; [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`) are preferred.
4. Open a PR and fill in the template. Describe how you tested it (macOS version, terminal/editor).

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE) and that you will follow the [Code of Conduct](CODE_OF_CONDUCT.md).
