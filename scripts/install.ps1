# Claude Shepherd — cài trên Windows (không cần quyền admin, chỉ cho user hiện tại)
#   powershell -ExecutionPolicy Bypass -File install.ps1
# - copy ccmon vào %LOCALAPPDATA%\Programs\claude-shepherd + tạo ccmon.cmd, thêm thư mục vào PATH của user
# - ccmon setup: gắn hook Claude Code vào ~\.claude\settings.json (có backup) + chạy dashboard khi đăng nhập
# Chạy lại nhiều lần được (idempotent).
$ErrorActionPreference = 'Stop'

function Find-Python {
    # py launcher trước; "python" có thể là stub WindowsApps mở Microsoft Store -> kiểm tra bằng cách chạy thử
    foreach ($spec in 'py -3', 'python', 'python3') {
        $c = $spec -split ' '
        $rest = @($c | Select-Object -Skip 1)
        if (-not (Get-Command $c[0] -ErrorAction SilentlyContinue)) { continue }
        # không dùng dấu " trong code Python: PS 5.1 và 7.3+ truyền " cho lệnh native khác nhau
        $exe = & $c[0] @rest -c 'import sys; assert sys.version_info >= (3, 9); print(sys.executable)' 2>$null
        if ($LASTEXITCODE -eq 0 -and $exe -and (Test-Path $exe)) { return $exe.Trim() }
    }
    return $null
}

$py = Find-Python
if (-not $py) {
    Write-Error 'Python 3.9+ is required. Install it with:  winget install Python.Python.3.12'
}

$src = @("$PSScriptRoot\ccmon\ccmon", "$PSScriptRoot\..\ccmon\ccmon") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $src) { Write-Error "ccmon not found next to $PSCommandPath" }

$dir = Join-Path $env:LOCALAPPDATA 'Programs\claude-shepherd'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Write-Host "==> ccmon -> $dir"
Copy-Item -Force $src (Join-Path $dir 'ccmon')
# shim để gõ "ccmon ..." trong cmd/PowerShell
Set-Content -Encoding ASCII -Path (Join-Path $dir 'ccmon.cmd') -Value "@`"$py`" `"%~dp0ccmon`" %*"

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not (($userPath -split ';') -contains $dir)) {
    [Environment]::SetEnvironmentVariable('Path', (($userPath, $dir) | Where-Object { $_ }) -join ';', 'User')
    Write-Host "==> added $dir to your PATH (open a new terminal to use ccmon)"
}

Write-Host '==> ccmon setup'
& $py (Join-Path $dir 'ccmon') setup
if ($LASTEXITCODE -ne 0) { Write-Error 'ccmon setup failed' }
