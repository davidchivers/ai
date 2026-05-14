param(
    [int]$StartingHorizon = 13,
    [string]$CurrentJobId = "",
    [string]$CurrentRemoteRunDir = "",
    [string]$CurrentProfileName = "standard_tail",
    [int]$CurrentAttemptIndex = 0,
    [double]$PromoteThreshold = 0.05,
    [int]$MaxHorizon = 15,
    [int]$PollMinutes = 10,
    [double]$MaxHours = 48
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$scriptPath = Join-Path $PSScriptRoot "bellman_re_horizon_autopilot.ps1"
$launcherStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$launcherStdout = Join-Path $logsRoot "bellman_re_horizon_autopilot_launcher_$launcherStamp.stdout.log"
$launcherStderr = Join-Path $logsRoot "bellman_re_horizon_autopilot_launcher_$launcherStamp.stderr.log"
$activeRunPath = Join-Path $logsRoot "active_bellman_re_horizon_autopilot.txt"

$argumentList = @(
    "-ExecutionPolicy", "Bypass",
    "-File", $scriptPath,
    "-StartingHorizon", $StartingHorizon,
    "-CurrentProfileName", $CurrentProfileName,
    "-CurrentAttemptIndex", $CurrentAttemptIndex,
    "-PromoteThreshold", $PromoteThreshold,
    "-MaxHorizon", $MaxHorizon,
    "-PollMinutes", $PollMinutes,
    "-MaxHours", $MaxHours
)
if (-not [string]::IsNullOrWhiteSpace($CurrentJobId)) {
    $argumentList += @("-CurrentJobId", $CurrentJobId)
}
if (-not [string]::IsNullOrWhiteSpace($CurrentRemoteRunDir)) {
    $argumentList += @("-CurrentRemoteRunDir", $CurrentRemoteRunDir)
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
    "starting_horizon=$StartingHorizon"
    "current_job_id=$CurrentJobId"
    "current_remote_run_dir=$CurrentRemoteRunDir"
    "current_profile_name=$CurrentProfileName"
    "current_attempt_index=$CurrentAttemptIndex"
    "promote_threshold=$PromoteThreshold"
    "max_horizon=$MaxHorizon"
    "poll_minutes=$PollMinutes"
    "max_hours=$MaxHours"
    "launcher_stdout=$launcherStdout"
    "launcher_stderr=$launcherStderr"
) | Set-Content -LiteralPath $activeRunPath

Write-Output "Started Bellman RE horizon autopilot."
Write-Output "PID: $($proc.Id)"
Write-Output "Active run file: $activeRunPath"
