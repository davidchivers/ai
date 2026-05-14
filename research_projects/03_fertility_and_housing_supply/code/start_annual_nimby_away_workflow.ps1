param(
    [ValidateRange(1, 4)]
    [int]$StartAtStep = 1,
    [ValidateRange(1, 4)]
    [int]$EndAtStep = 4,
    [double]$Step4TimeoutHours = 18
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$scriptPath = Join-Path $PSScriptRoot "annual_nimby_away_workflow.ps1"
$launcherStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$launcherStdout = Join-Path $logsRoot "annual_nimby_away_launcher_$launcherStamp.stdout.log"
$launcherStderr = Join-Path $logsRoot "annual_nimby_away_launcher_$launcherStamp.stderr.log"
$activeRunPath = Join-Path $logsRoot "active_annual_nimby_away.txt"

$proc = Start-Process -FilePath "powershell.exe" `
    -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", $scriptPath, "-StartAtStep", $StartAtStep, "-EndAtStep", $EndAtStep, "-Step4TimeoutHours", $Step4TimeoutHours) `
    -PassThru `
    -WindowStyle Hidden `
    -RedirectStandardOutput $launcherStdout `
    -RedirectStandardError $launcherStderr

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "pid=$($proc.Id)"
    "script=$scriptPath"
    "selected_steps=$StartAtStep-$EndAtStep"
    "step4_timeout_hours=$Step4TimeoutHours"
    "launcher_stdout=$launcherStdout"
    "launcher_stderr=$launcherStderr"
    "latest_pointer=$(Join-Path $logsRoot 'latest_annual_nimby_away.txt')"
) | Set-Content -Path $activeRunPath

Write-Output "Started annual NIMBY away workflow."
Write-Output "PID: $($proc.Id)"
Write-Output "Active run file: $activeRunPath"
