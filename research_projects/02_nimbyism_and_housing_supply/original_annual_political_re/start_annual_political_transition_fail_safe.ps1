param(
    [string]$RunTag = "",
    [string]$TSchedule = "4",
    [int]$PeriodIter = 2,
    [double]$VoteScale = 0.02,
    [ValidateSet("smooth", "hard_sign")]
    [string]$PressureMode = "smooth",
    [ValidateSet("source_path", "flat_entrant", "baby_boom", "secular_decline")]
    [string]$DemographicScenario = "source_path",
    [double]$DemographicShockAmplitude = 0.25,
    [string]$CandidatesMat = ""
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthRoot = Join-Path $scriptRoot "truth\annual_political_transition_fail_safe"
$logsRoot = Join-Path $truthRoot "logs"
New-Item -ItemType Directory -Force -Path $logsRoot | Out-Null

if ([string]::IsNullOrWhiteSpace($RunTag)) {
    $RunTag = "annual_transition_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}

$runner = Join-Path $scriptRoot "run_annual_political_transition_fail_safe.ps1"
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
        "-PeriodIter", "$PeriodIter",
        "-VoteScale", "$VoteScale",
        "-PressureMode", "$PressureMode",
        "-DemographicScenario", "$DemographicScenario",
        "-DemographicShockAmplitude", "$DemographicShockAmplitude",
        "-CandidatesMat", "$CandidatesMat"
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
    "vote_scale=$VoteScale"
    "pressure_mode=$PressureMode"
    "demographic_scenario=$DemographicScenario"
    "demographic_shock_amplitude=$DemographicShockAmplitude"
    "candidates_mat=$CandidatesMat"
    "stdout=$stdout"
    "stderr=$stderr"
    "latest_status=$(Join-Path $truthRoot 'latest_status.json')"
) | Set-Content -Path $active

Write-Output "Started annual political transition fail-safe."
Write-Output "PID: $($proc.Id)"
Write-Output "Run tag: $RunTag"
Write-Output "Active run file: $active"
