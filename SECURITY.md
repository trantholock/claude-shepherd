# Security Policy

## Supported versions

Only the latest release on `main` receives security fixes.

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Report privately via [GitHub Security Advisories](https://github.com/trantholock/claude-agents/security/advisories/new), or email **trantho.lock@gmail.com**. Include steps to reproduce and the impact. You should get a reply within 7 days.

## Scope

Claude Agents runs locally with your user's permissions. Areas of particular interest:

- The `ccmon serve` HTTP API (bound to `127.0.0.1`), e.g. CSRF / DNS-rebinding from a web page
- The hook, which processes JSON sent by Claude Code and session transcripts
- AppleScript / `osascript` calls used for notifications and focusing windows
- Edits to `~/.claude/settings.json`
