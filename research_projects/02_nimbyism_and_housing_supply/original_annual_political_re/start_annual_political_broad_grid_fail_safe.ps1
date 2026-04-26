param(
    [string]$RunTag = "",
    [string]$TSchedule = "12",
    [int]$MaxCandidatesPerVoteScale = 3,
    [int]$PeriodIter = 2
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthRoot = Join-Path $scriptRoot "truth\annual_political_broad_grid_fail_safe"
$logsRoot = Join-Path $truthRoot "logs"
New-Item -ItemType Directory -Force -Path $logsRoot | Out-Null

if ([string]::IsNullOrWhiteSpace($RunTag)) {
    $RunTag = "annual_broad_grid_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}

$runner = Join-Path $scriptRoot "run_annual_political_broad_grid_fail_safe.ps1"
$stdout = Join-Path $logsRoot "$RunTag.stdout.log"
$stderr = Join-Path $logsRoot "$RunTag.stderr.log"
$active = Join-Path $truthRoot "active_run.txt"

$proc = Start-Process -FilePath "powershell.exe" `
    -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $runner,
        "-RunTag", $RunTag,
        "-TSchedule", $TSchedule,
        "-MaxCandidatesPerVoteScale", "$MaxCandidatesPerVoteScale",
        "-PeriodIter", "$PeriodIter"
    ) `
    -PassThru `
    -WindowStyle Hidden `
    -RedirectStandardOutput $stdout `
    -RedirectStandardError $stderr

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "pid=$($proc.Id)"
    "run_tag=$RunTag"
    "t_schedule=$TSchedule"
    "max_candidates_per_vote_scale=$MaxCandidatesPerVoteScale"
    "stdout=$stdout"
    "stderr=$stderr"
    "latest_status=$(Join-Path $truthRoot 'latest_status.json')"
) | Set-Content -Path $active

Write-Output "Started annual political broad-grid fail-safe."
Write-Output "PID: $($proc.Id)"
Write-Output "Run tag: $RunTag"
Write-Output "Active run file: $active"
