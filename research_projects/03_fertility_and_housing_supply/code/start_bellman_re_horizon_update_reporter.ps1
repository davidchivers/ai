param(
    [string]$RemoteHost = "hfnt93@hamilton8.dur.ac.uk",
    [int]$PollMinutes = 5,
    [double]$MaxHours = 48
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$scriptPath = Join-Path $PSScriptRoot "bellman_re_horizon_update_reporter.py"
$launcherStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$launcherStdout = Join-Path $logsRoot "bellman_re_horizon_update_reporter_launcher_$launcherStamp.stdout.log"
$launcherStderr = Join-Path $logsRoot "bellman_re_horizon_update_reporter_launcher_$launcherStamp.stderr.log"
$activeRunPath = Join-Path $logsRoot "active_bellman_re_horizon_update_reporter.txt"

$argumentList = @(
    $scriptPath,
    "--remote-host", $RemoteHost,
    "--poll-minutes", $PollMinutes,
    "--max-hours", $MaxHours
)

$proc = Start-Process -FilePath "python.exe" `
    -ArgumentList $argumentList `
    -PassThru `
    -WindowStyle Hidden `
    -RedirectStandardOutput $launcherStdout `
    -RedirectStandardError $launcherStderr

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "pid=$($proc.Id)"
    "script=$scriptPath"
    "remote_host=$RemoteHost"
    "poll_minutes=$PollMinutes"
    "max_hours=$MaxHours"
    "launcher_stdout=$launcherStdout"
    "launcher_stderr=$launcherStderr"
) | Set-Content -LiteralPath $activeRunPath

Write-Output "Started Bellman RE horizon update reporter."
Write-Output "PID: $($proc.Id)"
Write-Output "Active run file: $activeRunPath"
