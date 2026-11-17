"""Smoke test đa nền tảng cho ccmon (macOS / Linux / Windows), chỉ dùng stdlib.

Chạy trong HOME tạm nên không đụng tới ~/.claude thật:
  python3 tests/smoke.py
"""
import json
import os
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CCMON = os.path.join(ROOT, "ccmon", "ccmon")
HOME = tempfile.mkdtemp(prefix="ccmon-smoke-")
ENV = dict(os.environ, HOME=HOME, USERPROFILE=HOME, APPDATA=os.path.join(HOME, "AppData"),
           XDG_CONFIG_HOME=os.path.join(HOME, ".config"), CCMON_NOTIFY="0", CCMON_LANG="en",
           PYTHONDONTWRITEBYTECODE="1")
SID = "0f1e2d3c-4b5a-6978-8a9b-acbdcedf0011"
if hasattr(sys.stdout, "reconfigure"):  # console Windows (cp1252) không in được emoji/tiếng Việt
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def run(*args, stdin=None):
    r = subprocess.run([sys.executable, CCMON] + list(args), input=(stdin or "").encode("utf-8"),
                       capture_output=True, env=ENV, timeout=30)
    out = r.stdout.decode("utf-8", "replace")
    assert r.returncode == 0, "ccmon %s failed (%d): %s %s" % (args, r.returncode, out, r.stderr)
    return out


def hook(ev, **kw):
    run("hook", stdin=json.dumps(dict(session_id=SID, hook_event_name=ev, cwd=HOME, **kw), ensure_ascii=False))


def check(cond, msg):
    if not cond:
        raise SystemExit("FAIL: " + msg)
    print("ok  -", msg)


check(run("version").startswith("ccmon "), "version")

# lớp tiến trình theo OS (ps / /proc / Toolhelp32)
import importlib.machinery  # noqa: E402
import importlib.util  # noqa: E402
_l = importlib.machinery.SourceFileLoader("ccmon_mod", CCMON)
m = importlib.util.module_from_spec(importlib.util.spec_from_loader("ccmon_mod", _l))
_l.exec_module(m)
procs = m.ps_table()
check(os.getpid() in procs and "python" in procs[os.getpid()].lower(), "ps_table sees this python process")
check(m.proc_parent(os.getpid())[0] == os.getppid(), "proc_parent returns the parent pid")
check(m.pid_alive(os.getpid()), "pid_alive")
check(m.is_claude_proc("claude.exe") and m.is_claude_proc("/usr/bin/node") and not m.is_claude_proc("bash"),
      "is_claude_proc")

# vòng đời phiên qua hook, kèm tiếng Việt + emoji (bắt lỗi code page trên Windows)
hook("SessionStart")
hook("UserPromptSubmit", prompt="Sửa lỗi đăng nhập 🐑")
hook("PreToolUse", tool_name="Bash", tool_input={"command": "ls -la"})
st = json.load(open(os.path.join(HOME, ".claude", "ccmon", "sessions", SID + ".json"), encoding="utf-8"))
check(st["status"] == "running" and st["activity"].startswith("Bash: ls"), "hook PreToolUse -> running")
check(st["last_prompt"] == "Sửa lỗi đăng nhập 🐑", "hook keeps UTF-8 prompt")
hook("Stop")
check(not os.path.exists(os.path.join(HOME, ".claude", "ccmon", "hook-errors.log")), "no hook errors")

out = run("ls", "-a")
check(SID[:8] in out and "DONE" in out, "ls shows the session as DONE")
check(SID[:8] in run("ls", "-a", "dang nhap"), "accent-insensitive search")
check("No sessions match" in run("ls", "-a", "khongcogi"), "search with no match")

sl = run("statusline", stdin=json.dumps({
    "session_id": SID, "session_name": "demo", "model": {"display_name": "Opus"},
    "context_window": {"used_percentage": 12},
    "rate_limits": {"five_hour": {"used_percentage": 46, "resets_at": time.time() + 3600}}}))
check("5h 46%" in sl and "ctx 12%" in sl, "statusline output: %r" % sl)
check("46%" in run("usage"), "usage")

run("name", SID[:8], "Tên phiên")
check("Tên phiên" in run("ls", "-a"), "custom session name")

# setup/teardown chỉ phần hook (không cài dịch vụ) — macOS dùng make install
if sys.platform != "darwin":
    settings = os.path.join(HOME, ".claude", "settings.json")
    os.makedirs(os.path.dirname(settings), exist_ok=True)
    json.dump({"hooks": {"Stop": [{"hooks": [{"type": "command", "command": "echo mine"}]}]}},
              open(settings, "w", encoding="utf-8"))
    run("setup", "--no-service")
    s = json.load(open(settings, encoding="utf-8"))
    check(len(s["hooks"]["Stop"]) == 2 and "ccmon" in s["statusLine"]["command"], "setup adds hooks + statusLine")
    run("setup", "--no-service")
    s = json.load(open(settings, encoding="utf-8"))
    check(len(s["hooks"]["Stop"]) == 2, "setup is idempotent")
    run("teardown", "--no-service")
    s = json.load(open(settings, encoding="utf-8"))
    check(s["hooks"] == {"Stop": [{"hooks": [{"type": "command", "command": "echo mine"}]}]}
          and "statusLine" not in s, "teardown keeps the user's own hooks")

# web dashboard
sock = socket.socket()
sock.bind(("127.0.0.1", 0))
port = sock.getsockname()[1]
sock.close()
srv = subprocess.Popen([sys.executable, CCMON, "serve", str(port)], env=ENV,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    for _ in range(50):
        try:
            data = json.load(urllib.request.urlopen("http://127.0.0.1:%d/api/sessions?all=1" % port, timeout=2))
            break
        except OSError:
            time.sleep(0.2)
    else:
        raise SystemExit("FAIL: dashboard did not start")
    check(any(r["session_id"] == SID for r in data["rows"]), "GET /api/sessions")
    req = urllib.request.Request("http://127.0.0.1:%d/api/ack?id=all" % port, method="POST")
    try:
        urllib.request.urlopen(req, timeout=2)
        check(False, "POST without X-CCMon must be rejected")
    except urllib.error.HTTPError as e:
        check(e.code == 403, "POST without X-CCMon -> 403")
    html = urllib.request.urlopen("http://127.0.0.1:%d/" % port, timeout=2).read().decode("utf-8")
    check("Claude Shepherd" in html, "GET / serves the dashboard")
finally:
    srv.terminate()
    srv.wait(10)

print("all smoke tests passed on", sys.platform)
