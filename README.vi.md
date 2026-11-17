# 🐑 Claude Shepherd

> **Chăn đàn agent Claude Code của bạn.** Chạy 5 phiên cùng lúc? Biết ngay phiên nào đã xong, phiên nào đang chờ cấp quyền, và nhảy thẳng tới đó.

[English](README.md) · **Tiếng Việt**

[![CI](https://github.com/trantholock/claude-shepherd/actions/workflows/ci.yml/badge.svg)](https://github.com/trantholock/claude-shepherd/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

![Dashboard Claude Shepherd](docs/demo.gif)

Theo dõi trạng thái mọi phiên **Claude Code** đang chạy song song (iTerm, VSCode extension, terminal trong VSCode) để không bỏ sót agent nào đã xong hoặc đang chờ bạn.

- **Hook** của Claude Code ghi trạng thái từng phiên vào `~/.claude/ccmon/sessions/<session_id>.json`
- **Thông báo desktop** (macOS, Linux `notify-send`, toast Windows) khi agent xong lượt hoặc cần cấp quyền
- **Dashboard web** http://127.0.0.1:7788
- **App desktop** "Claude Shepherd" (macOS): cửa sổ riêng + badge trên Dock + biểu tượng trên menu bar, bấm vào phiên để nhảy tới đúng tab iTerm / cửa sổ VSCode
- **Quota gói Claude** (5 giờ / 7 ngày, giống `/usage`) trên header app, tiêu đề cửa sổ, menu bar, dashboard web và statusLine của Claude Code
- **Đặt tên phiên** cho dễ nhớ (✎ trên dashboard, chuột phải → Đổi tên… trong app, hoặc `ccmon name`)
- **Phiên Remote Control** mở từ điện thoại hoặc claude.ai: bấm một lần để resume trong tab iTerm (xem [bên dưới](#phiên-remote-control))
- **Tìm kiếm** phiên theo tên, thư mục, prompt, câu trả lời hoặc ID — không phân biệt dấu, mọi từ phải khớp (dashboard: `/` để focus, Esc để xoá; app: ⌘F; CLI: `ccmon ls [-a] <từ khoá>`)
- **CLI** `ccmon`

## Cài đặt

Linux và Windows có CLI, hook, thông báo và dashboard web; app desktop chỉ có trên macOS. Cần Python 3.9+ (không cần thư viện ngoài).

### Linux

Tải gói ở [bản phát hành mới nhất](https://github.com/trantholock/claude-shepherd/releases/latest), rồi chạy `ccmon setup` **bằng user thường** (không `sudo`):

```bash
sudo apt install ./claude-shepherd_*_all.deb             # Debian, Ubuntu
sudo dnf install ./claude-shepherd-*.noarch.rpm          # Fedora, RHEL, Rocky (openSUSE: zypper in)
sudo pacman -U claude-shepherd-*-any.pkg.tar.zst         # Arch, Manjaro
ccmon setup        # hook + dịch vụ systemd --user cho dashboard
```

Không có quyền root: giải nén `claude-shepherd-*-linux.tar.gz` rồi chạy `./install.sh` (cài vào `~/.local/bin`). Chạy `ccmon teardown` trước khi gỡ gói. Không có systemd (WSL, container) thì tự chạy `ccmon serve &`.

### Windows

Cài Python 3.9+ (`winget install Python.Python.3.12`), giải nén `claude-shepherd-*-windows.zip`, rồi:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1     # gỡ: uninstall.ps1
```

Không cần quyền admin: copy `ccmon` vào `%LOCALAPPDATA%\Programs\claude-shepherd`, thêm vào `PATH` của user, gắn hook và chạy dashboard khi đăng nhập.

### macOS

```bash
git clone https://github.com/trantholock/claude-shepherd.git
cd claude-shepherd
make install
```

Cần macOS 14+, Xcode Command Line Tools (`xcode-select --install`), không cần thư viện Python ngoài (chạy bằng `/usr/bin/python3`).

```bash
make install     # ccmon + hook + LaunchAgent + build app
make app         # build lại app sau khi sửa app/*.swift hoặc icon
make uninstall   # gỡ hook, LaunchAgent, app (giữ dữ liệu ~/.claude/ccmon)
```

`~/bin/ccmon` là symlink vào `ccmon/ccmon` của repo này, nên sửa CLI/hook là có hiệu lực ngay. Riêng dashboard web chạy nền thì cần khởi động lại: `launchctl kickstart -k gui/$(id -u)/io.github.trantholock.ccmon`.

## Trạng thái

| Trạng thái | Sự kiện hook | Ý nghĩa |
|---|---|---|
| ĐANG CHẠY | `UserPromptSubmit`, `PreToolUse`, `PostToolUse` | agent đang làm, hiện tool đang chạy |
| CHỜ BẠN | `Notification` (permission) | cần cấp quyền / trả lời |
| XONG | `Stop` | xong lượt, hiện câu trả lời cuối |
| BỊ NGẮT | transcript có `Request interrupted by user` | bạn bấm Esc giữa chừng |
| MỞ, CHƯA LÀM | `SessionStart` | phiên mới mở |
| ĐÃ ĐÓNG | `SessionEnd` hoặc PID claude không còn | tự xóa sau 24h |

`●` = chưa xem. Phiên chuyển sang "đã xem" khi bấm **Mở**/**Đã xem**, hoặc khi bạn gửi prompt mới.

## Phiên Remote Control

Khi `claude remote-control` đang chạy trên Mac, bạn có thể tạo session mới từ app Claude trên điện thoại hoặc từ claude.ai/code. Session đó chạy ngầm trên Mac. ccmon nhận ra nó qua tham số `--sdk-url …/code/sessions/cse_…` và gắn nhãn **Remote**.

Bấm vào session Remote trong app, hoặc nút **Terminal** trên dashboard, sẽ mở tab iTerm mới chạy `claude --resume <id>` trong thư mục của session:

- **Đang rảnh hoặc đã xong:** dừng tiến trình chạy ngầm trước, rồi resume đúng session đó. Hội thoại chuyển hẳn sang terminal, nên trên điện thoại không gõ tiếp được nữa.
- **Đang chạy hoặc đang chờ duyệt quyền:** không dừng tiến trình mà mở bằng `--fork-session`. Bạn có một bản sao đủ lịch sử, còn bản gốc vẫn tiếp tục chạy.

Muốn mở trên trình duyệt thì dùng nút **Web** trên dashboard, hoặc chuột phải → Mở trên web trong app.

Để `claude remote-control` luôn chạy, hãy khởi động nó bằng LaunchAgent với `caffeinate -is` và cho stdout vào `/dev/null`. Màn hình của nó vẽ lại liên tục, nếu ghi hết vào log thì log tăng hàng chục MB mỗi ngày.

## CLI

```
ccmon [ls] [-a] [từ]  bảng trạng thái (-a gồm cả phiên đã đóng; từ = lọc theo từ khoá)
ccmon watch           bảng tự làm mới 2s
ccmon serve [port]    dashboard web (mặc định 7788)
ccmon focus <id>      nhảy tới tab iTerm / cửa sổ VSCode của phiên (Remote: resume trong iTerm)
ccmon term <id>       mở phiên trong tab iTerm mới (claude --resume)
ccmon ack [id|all]    đánh dấu đã xem
ccmon clean           xóa phiên đã đóng
ccmon name <id> [tên] đặt tên phiên (bỏ trống = xóa tên tự đặt)
ccmon usage           quota 5h / 7 ngày
ccmon lang [en|vi|auto] ngôn ngữ giao diện
ccmon statusline      (dùng cho statusLine của Claude Code)
```

## Quota & tên phiên

Claude Code gửi JSON cho lệnh `statusLine` sau mỗi lượt, có `rate_limits.five_hour|seven_day` (`used_percentage`, `resets_at`) và `session_name`. `ccmon statusline` ghi quota vào `~/.claude/ccmon/usage.json`, dữ liệu theo phiên vào `~/.claude/ccmon/statusline/<id>.json`, và in ra dòng `📌 tên · 🟢 5h 46% (reset 14:10) · 🟠 7d 81% · ctx 12%`.

- Quota chỉ cập nhật khi có ít nhất 1 phiên Claude đang hoạt động; đã qua giờ reset thì hiện 0%.
- `make install` chỉ đặt statusLine khi bạn chưa có statusLine riêng.
- Tên hiển thị: tên tự đặt (`~/.claude/ccmon/names.json`) > `session_name` Claude tự đặt > tên thư mục.

Tắt thông báo: đặt `CCMON_NOTIFY=0` trong môi trường của Claude Code.

## Ngôn ngữ

CLI, thông báo, dashboard và app theo ngôn ngữ của hệ điều hành (mặc định tiếng Anh, tiếng Việt nếu OS đặt tiếng Việt; Linux theo `LANGUAGE`/`LANG`). Để chọn cố định:

```bash
ccmon lang vi     # hoặc: en, auto
```

Lưu ở `~/.claude/ccmon/config.json`; khởi động lại app và `ccmon serve` để áp dụng. Biến môi trường `CCMON_LANG=en|vi` được ưu tiên hơn.

## Cấu trúc

```
ccmon/ccmon                 CLI + hook + web server (Python stdlib, tương thích 3.9)
app/ClaudeShepherd.swift      app SwiftUI (Window + MenuBarExtra), đọc API của ccmon serve
app/icon.swift              vẽ icon bằng AppKit -> build/AppIcon.icns
app/Info.plist
launchd/*.plist.tmpl        LaunchAgent: ccmon serve + tự mở app khi đăng nhập
scripts/install.sh          cài toàn bộ
scripts/build-app.sh        build app vào build/ rồi chép sang ~/Applications
scripts/hooks.py            thêm/gỡ hook + statusLine trong ~/.claude/settings.json (idempotent, có backup)
scripts/uninstall.sh
```

## API (ccmon serve)

- `GET  /api/sessions?all=0|1` → `{now, rows: [...]}`
- `POST /api/ack?id=<id|all>`, `/api/forget?id=`, `/api/focus?id=`, `/api/term?id=`, `/api/rename?id=&name=` (bắt buộc header `X-CCMon: 1`)

## Ghi chú

- Phiên mở trước khi cài hook chỉ xuất hiện sau prompt tiếp theo. VSCode cần Reload Window.
- Lần đầu focus hoặc mở tab iTerm, macOS sẽ hỏi quyền Automation → Allow.
- Thông báo có thể nằm dưới tên "Script Editor" trong System Settings → Notifications.
- Lỗi hook ghi vào `~/.claude/ccmon/hook-errors.log`; hook không bao giờ làm hỏng phiên Claude.

## Đóng góp

Mọi đóng góp đều được chào đón — xem [CONTRIBUTING.md](CONTRIBUTING.md) và [Quy tắc ứng xử](CODE_OF_CONDUCT.md). Báo lỗi bảo mật: [SECURITY.md](SECURITY.md).

## Giấy phép

[MIT](LICENSE). Đây là dự án cộng đồng, không liên kết hay được Anthropic bảo trợ. "Claude" là nhãn hiệu của Anthropic.
