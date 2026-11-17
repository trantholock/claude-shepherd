"""Thêm/gỡ hook + statusLine của ccmon trong ~/.claude/settings.json (idempotent, có backup).

Dùng bởi scripts/install.sh / uninstall.sh trên macOS. Logic nằm trong ccmon (settings_hooks)
để `ccmon setup` trên Linux/Windows dùng chung một chỗ.
  python3 scripts/hooks.py install "<lệnh hook>"   |   python3 scripts/hooks.py uninstall
"""
import importlib.machinery
import importlib.util
import os
import sys

_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ccmon", "ccmon")
_loader = importlib.machinery.SourceFileLoader("ccmon", _path)
_spec = importlib.util.spec_from_loader("ccmon", _loader)
ccmon = importlib.util.module_from_spec(_spec)
_loader.exec_module(ccmon)

ccmon.settings_hooks(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "")
