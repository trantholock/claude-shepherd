# Claude Shepherd — gỡ trên Windows: hook, mục chạy khi đăng nhập, ccmon, PATH (giữ dữ liệu ~\.claude\ccmon)
#   powershell -ExecutionPolicy Bypass -File uninstall.ps1
$ErrorActionPreference = 'Stop'
$dir = Join-Path $env:LOCALAPPDATA 'Programs\claude-shepherd'
$ccmon = Join-Path $dir 'ccmon'

if (Test-Path $ccmon) {
    $cmd = Get-Content (Join-Path $dir 'ccmon.cmd') -ErrorAction SilentlyContinue | Select-Object -First 1
    $py = if ($cmd -match '^@"([^"]+)"') { $Matches[1] } else { 'py' }
    & $py $ccmon teardown
    Remove-Item -Recurse -Force $dir
}

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath) {
    $new = ($userPath -split ';' | Where-Object { $_ -and $_ -ne $dir }) -join ';'
    if ($new -ne $userPath) { [Environment]::SetEnvironmentVariable('Path', $new, 'User') }
}
Write-Host 'Removed. Session data is kept in ~\.claude\ccmon (delete it by hand if you want).'
