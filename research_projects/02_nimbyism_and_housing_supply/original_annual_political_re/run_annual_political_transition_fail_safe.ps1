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
$matlab = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe"
if (-not (Test-Path $matlab)) {
    throw "MATLAB not found at $matlab"
}

if ([string]::IsNullOrWhiteSpace($RunTag)) {
    $RunTag = "annual_transition_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}

$tMat = "[" + (($TSchedule -split "," | ForEach-Object { $_.Trim() }) -join " ") + "]"
if ([string]::IsNullOrWhiteSpace($CandidatesMat)) {
    $candidateArg = ""
} else {
    $trimmedCandidates = $CandidatesMat.Trim()
    if (-not $trimmedCandidates.StartsWith("[")) {
        $trimmedCandidates = "[$trimmedCandidates]"
    }
    $candidateArg = ",'Candidates',$trimmedCandidates"
}
$cmd = "cd('$($scriptRoot.Replace('\','/'))'); run_annual_political_transition_fail_safe('RunTag','$RunTag','TSchedule',$tMat,'PeriodIter',$PeriodIter,'VoteScale',$VoteScale,'PressureMode','$PressureMode','DemographicScenario','$DemographicScenario','DemographicShockAmplitude',$DemographicShockAmplitude$candidateArg)"

& $matlab -singleCompThread -batch $cmd
