$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$scriptPath = Join-Path $PSScriptRoot "refresh_corrected_benchmark_outputs_overnight.ps1"
$launcherStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$launcherStdout = Join-Path $logsRoot "overnight_launcher_$launcherStamp.stdout.log"
$launcherStderr = Join-Path $logsRoot "overnight_launcher_$launcherStamp.stderr.log"
$activeRunPath = Join-Path $logsRoot "active_overnight_benchmark_refresh.txt"

$proc = Start-Process -FilePath "powershell.exe" `
    -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", $scriptPath) `
    -PassThru `
    -WindowStyle Hidden `
    -RedirectStandardOutput $launcherStdout `
    -RedirectStandardError $launcherStderr

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "pid=$($proc.Id)",
    "script=$scriptPath",
    "launcher_stdout=$launcherStdout",
    "launcher_stderr=$launcherStderr",
    "latest_pointer=$(Join-Path $logsRoot 'latest_overnight_benchmark_refresh.txt')"
) | Set-Content -Path $activeRunPath

Write-Output "Started overnight benchmark refresh."
Write-Output "PID: $($proc.Id)"
Write-Output "Active run file: $activeRunPath"
