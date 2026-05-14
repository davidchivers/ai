param(
    [Parameter(Mandatory = $true)]
    [string]$JobId,
    [Parameter(Mandatory = $true)]
    [string]$RemoteRunDir,
    [string]$OutputStem = "nimby_vs_fertility_smoothed_political_path_trial",
    [int]$PollMinutes = 10,
    [double]$MaxHours = 12
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$scriptPath = Join-Path $PSScriptRoot "hamilton_annual_smoothed_political_path_trial_handoff.ps1"
$launcherStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$launcherStdout = Join-Path $logsRoot "hamilton_annual_smoothed_political_path_trial_handoff_launcher_$launcherStamp.stdout.log"
$launcherStderr = Join-Path $logsRoot "hamilton_annual_smoothed_political_path_trial_handoff_launcher_$launcherStamp.stderr.log"
$activeRunPath = Join-Path $logsRoot "active_hamilton_annual_smoothed_political_path_trial_handoff.txt"

$proc = Start-Process -FilePath "powershell.exe" `
    -ArgumentList @(
        "-ExecutionPolicy", "Bypass",
        "-File", $scriptPath,
        "-JobId", $JobId,
        "-RemoteRunDir", $RemoteRunDir,
        "-OutputStem", $OutputStem,
        "-PollMinutes", $PollMinutes,
        "-MaxHours", $MaxHours
    ) `
    -PassThru `
    -WindowStyle Hidden `
    -RedirectStandardOutput $launcherStdout `
    -RedirectStandardError $launcherStderr

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "pid=$($proc.Id)"
    "script=$scriptPath"
    "job_id=$JobId"
    "remote_run_dir=$RemoteRunDir"
    "output_stem=$OutputStem"
    "poll_minutes=$PollMinutes"
    "max_hours=$MaxHours"
    "launcher_stdout=$launcherStdout"
    "launcher_stderr=$launcherStderr"
    "latest_pointer=$(Join-Path $logsRoot 'latest_hamilton_annual_smoothed_political_path_trial_handoff.txt')"
) | Set-Content -Path $activeRunPath

Write-Output "Started Hamilton annual smoothed political-path trial handoff."
Write-Output "PID: $($proc.Id)"
Write-Output "Active run file: $activeRunPath"
