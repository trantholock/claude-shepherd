"""Thêm/gỡ hook + statusLine của ccmon trong ~/.claude/settings.json (idempotent, có backup)."""
import json
import os
import shutil
import sys
import time

P = os.path.expanduser("~/.claude/settings.json")
EVENTS = ["SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUse", "Notification", "Stop", "SessionEnd"]
MARK = "ccmon hook"


def is_ours(entry):
    return any(MARK in h.get("command", "") for h in entry.get("hooks", []))


def main():
    action = sys.argv[1]
    s = json.load(open(P)) if os.path.exists(P) else {}
    if os.path.exists(P):
        shutil.copy(P, P + ".bak-ccmon-" + time.strftime("%Y%m%d%H%M%S"))
    hooks = s.setdefault("hooks", {})
    for ev in EVENTS:
        lst = [e for e in hooks.get(ev, []) if not is_ours(e)]
        if action == "install":
            e = {"hooks": [{"type": "command", "command": sys.argv[2], "timeout": 5}]}
            if ev in ("PreToolUse", "PostToolUse"):
                e["matcher"] = "*"
            lst.append(e)
        if lst:
            hooks[ev] = lst
        else:
            hooks.pop(ev, None)
    if not hooks:
        s.pop("hooks")
    # statusLine: chỉ chiếm chỗ khi chưa có statusLine riêng của người dùng
    sl = s.get("statusLine") or {}
    ours = "ccmon" in sl.get("command", "")
    if action == "install" and (not sl or ours):
        s["statusLine"] = {"type": "command", "command": sys.argv[2].replace(" hook", " statusline")}
    elif action == "install":
        print("giữ statusLine hiện có (%s) — quota sẽ không được cập nhật" % sl.get("command"))
    elif ours:
        s.pop("statusLine")
    with open(P, "w") as f:
        json.dump(s, f, indent=2, ensure_ascii=False)
    print("hooks %s: %s" % (action, ", ".join(EVENTS)))


main()
