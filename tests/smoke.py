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


def hook(ev, sid=SID, env=None, **kw):
    data = json.dumps(dict(session_id=sid, hook_event_name=ev, cwd=HOME, **kw), ensure_ascii=False).encode("utf-8")
    r = subprocess.run([sys.executable, CCMON, "hook"], input=data, capture_output=True,
                       env=dict(ENV, **(env or {})), timeout=30)
    assert r.returncode == 0, r.stderr


def dead_pid():
    p = subprocess.Popen([sys.executable, "-c", "pass"])
    p.wait()
    return str(p.pid)


def state_of(sid):
    return json.load(open(os.path.join(HOME, ".claude", "ccmon", "sessions", sid + ".json"), encoding="utf-8"))


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

# phiên đã chết TRƯỚC lần chạy đầu của tính năng khôi phục -> không được đề nghị mở lại
OLD = "0ld00000-dead-4000-8000-000000000001"
hook("SessionStart", sid=OLD, env={"CLAUDE_PID": dead_pid()})
hook("UserPromptSubmit", sid=OLD, prompt="phiên cũ")

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
check(state_of(OLD)["status"] == "closed", "first run: sessions dead before the restore feature are just closed")

# khôi phục phiên bị tắt đột ngột (crash/kill: không có SessionEnd, tiến trình claude đã chết)
LOST = "1057aaaa-bbbb-4ccc-8ddd-eeeeffff0001"
hook("SessionStart", sid=LOST, env={"CLAUDE_PID": dead_pid()})
hook("UserPromptSubmit", sid=LOST, prompt="viết báo cáo DORA")
out = run("ls")
check(LOST[:8] in out and "CLOSED UNEXPECTEDLY" in out, "crashed session shows as CLOSED UNEXPECTEDLY without -a")
check(state_of(LOST)["status"] == "lost", "lost state is persisted")
check(LOST[:8] in run("restore"), "ccmon restore lists it")
ENV["CCMON_RESTORE"] = "off"
check("CLOSED UNEXPECTEDLY" not in run("ls", "-a"), "restore mode off: nothing offered")
del ENV["CCMON_RESTORE"]
run("restore", "dismiss", LOST[:8])
check(state_of(LOST)["status"] == "closed" and LOST[:8] not in run("ls"), "dismiss closes it")
NOPROMPT = "1057aaaa-bbbb-4ccc-8ddd-eeeeffff0002"
hook("SessionStart", sid=NOPROMPT, env={"CLAUDE_PID": dead_pid()})
run("ls")
check(state_of(NOPROMPT)["status"] != "lost", "session without any prompt is not offered")

if sys.platform.startswith("linux"):  # mở terminal thật: chỉ kiểm được trên Linux qua CCMON_TERMINAL
    LOST2 = "1057aaaa-bbbb-4ccc-8ddd-eeeeffff0003"
    hook("SessionStart", sid=LOST2, env={"CLAUDE_PID": dead_pid()})
    hook("UserPromptSubmit", sid=LOST2, prompt="deploy portal")
    rec = os.path.join(HOME, "term-args.json")
    recorder = os.path.join(HOME, "rec.py")
    open(recorder, "w").write("import json,sys;json.dump(sys.argv[1:],open(%r,'w'))" % rec)
    ENV["CCMON_TERMINAL"] = '"%s" "%s"' % (sys.executable, recorder)
    out = run("restore", "all")
    for _ in range(50):
        if os.path.exists(rec) and os.path.getsize(rec):
            break
        time.sleep(0.1)
    args = json.load(open(rec))
    check(LOST2[:8] + "  ok" in out and "claude --resume " + LOST2 in args[-1] and "--fork-session" not in args[-1],
          "restore all opens claude --resume in a terminal: %r" % args)
    check(state_of(LOST2)["reason"] == "restored", "restored session is marked")
    hook("SessionStart", sid=LOST2, source="resume")
    check(state_of(LOST2)["status"] == "idle", "resumed session comes back as open")

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
    LOST3 = "1057aaaa-bbbb-4ccc-8ddd-eeeeffff0004"
    hook("SessionStart", sid=LOST3, env={"CLAUDE_PID": dead_pid()})
    hook("UserPromptSubmit", sid=LOST3, prompt="api")
    data = json.load(urllib.request.urlopen("http://127.0.0.1:%d/api/sessions" % port, timeout=2))
    check(any(r["session_id"] == LOST3 and r["state"] == "lost" for r in data["rows"]), "API lists lost sessions")
    req = urllib.request.Request("http://127.0.0.1:%d/api/dismiss?id=%s" % (port, LOST3), method="POST",
                                 headers={"X-CCMon": "1"})
    urllib.request.urlopen(req, timeout=2)
    check(state_of(LOST3)["status"] == "closed", "POST /api/dismiss")
    html = urllib.request.urlopen("http://127.0.0.1:%d/" % port, timeout=2).read().decode("utf-8")
    check("Claude Shepherd" in html, "GET / serves the dashboard")
finally:
    srv.terminate()
    srv.wait(10)

print("all smoke tests passed on", sys.platform)
