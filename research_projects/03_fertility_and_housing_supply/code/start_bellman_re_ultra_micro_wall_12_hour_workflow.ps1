$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$scriptPath = Join-Path $PSScriptRoot "bellman_re_ultra_micro_wall_12_hour_workflow.ps1"
$launcherStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$launcherStdout = Join-Path $logsRoot "bellman_re_ultra_micro_wall_12_hour_workflow_launcher_$launcherStamp.stdout.log"
$launcherStderr = Join-Path $logsRoot "bellman_re_ultra_micro_wall_12_hour_workflow_launcher_$launcherStamp.stderr.log"
$activeRunPath = Join-Path $logsRoot "active_bellman_re_ultra_micro_wall_12_hour_workflow.txt"

$proc = Start-Process -FilePath "powershell.exe" `
    -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", $scriptPath) `
    -PassThru `
    -WindowStyle Hidden `
    -RedirectStandardOutput $launcherStdout `
    -RedirectStandardError $launcherStderr

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "pid=$($proc.Id)"
    "script=$scriptPath"
    "launcher_stdout=$launcherStdout"
    "launcher_stderr=$launcherStderr"
    "latest_pointer=$(Join-Path $logsRoot 'latest_bellman_re_ultra_micro_wall_12_hour_workflow.txt')"
) | Set-Content -Path $activeRunPath

Write-Output "Started Bellman RE ultra-micro wall 12-hour workflow."
Write-Output "PID: $($proc.Id)"
Write-Output "Active run file: $activeRunPath"
