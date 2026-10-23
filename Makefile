.PHONY: install app uninstall status check

install:    ## cài toàn bộ: ccmon + hook + LaunchAgent + app
	./scripts/install.sh

app:        ## build lại app desktop (sau khi sửa app/*.swift)
	./scripts/build-app.sh

uninstall:  ## gỡ hook, LaunchAgent, app
	./scripts/uninstall.sh

status:     ## xem các phiên Claude hiện tại
	./ccmon/ccmon ls

check:      ## lint + build thử, giống CI (không cài gì)
	PYTHONDONTWRITEBYTECODE=1 python3 -c "import ast,sys; [ast.parse(open(f).read(), f) for f in sys.argv[1:]]" ccmon/ccmon scripts/hooks.py
	bash -n scripts/*.sh
	@if command -v shellcheck >/dev/null; then shellcheck scripts/*.sh; else echo "shellcheck not installed, skipping"; fi
	plutil -lint app/Info.plist
	mkdir -p build/check
	swiftc -swift-version 5 -parse-as-library -target "$$(uname -m)-apple-macosx14.0" app/ClaudeAgents.swift -o build/check/ClaudeAgents
	swiftc -swift-version 5 -typecheck app/icon.swift
