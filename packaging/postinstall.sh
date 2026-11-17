#!/bin/sh
# Hook nằm trong ~/.claude của từng người dùng nên gói không tự cài được — chỉ nhắc.
cat <<'EOF'

Claude Shepherd installed. As your normal user (not root), run:

    ccmon setup        # add Claude Code hooks + start the dashboard at login

Dashboard: http://127.0.0.1:7788
Before removing the package, run `ccmon teardown` to remove the hooks.

EOF
exit 0
