param(
    [string]$JobId = "",
    [string]$RemoteRunDir = "",
    [string]$RemoteHost = "hfnt93@hamilton8.dur.ac.uk",
    [int]$PollMinutes = 10,
    [double]$MaxHours = 12
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$scriptPath = Join-Path $PSScriptRoot "hamilton_bellman_re_t13_deep_suffix_handoff.ps1"
$launcherStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$launcherStdout = Join-Path $logsRoot "hamilton_bellman_re_t13_deep_suffix_handoff_launcher_$launcherStamp.stdout.log"
$launcherStderr = Join-Path $logsRoot "hamilton_bellman_re_t13_deep_suffix_handoff_launcher_$launcherStamp.stderr.log"
$activeRunPath = Join-Path $logsRoot "active_hamilton_bellman_re_t13_deep_suffix_handoff.txt"
$latestPointerPath = Join-Path $logsRoot "latest_hamilton_bellman_re_t13_deep_suffix_handoff.txt"

$argumentList = @(
    "-ExecutionPolicy", "Bypass",
    "-File", $scriptPath,
    "-RemoteHost", $RemoteHost,
    "-PollMinutes", $PollMinutes,
    "-MaxHours", $MaxHours
)
if (-not [string]::IsNullOrWhiteSpace($JobId)) {
    $argumentList += @("-JobId", $JobId)
}
if (-not [string]::IsNullOrWhiteSpace($RemoteRunDir)) {
    $argumentList += @("-RemoteRunDir", $RemoteRunDir)
}

$proc = Start-Process -FilePath "powershell.exe" `
    -ArgumentList $argumentList `
    -PassThru `
    -WindowStyle Hidden `
    -RedirectStandardOutput $launcherStdout `
    -RedirectStandardError $launcherStderr

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "pid=$($proc.Id)"
    "script=$scriptPath"
    "job_id=$JobId"
    "remote_host=$RemoteHost"
    "remote_run_dir=$RemoteRunDir"
    "poll_minutes=$PollMinutes"
    "max_hours=$MaxHours"
    "launcher_stdout=$launcherStdout"
    "launcher_stderr=$launcherStderr"
    "latest_pointer=$latestPointerPath"
) | Set-Content -LiteralPath $activeRunPath

Write-Output "Started Hamilton T13 deep suffix handoff monitor."
Write-Output "PID: $($proc.Id)"
Write-Output "Active run file: $activeRunPath"
