param(
    [string]$RemoteHost = "hfnt93@hamilton8.dur.ac.uk",
    [string]$RemoteBaseDir = "/nobackup/hfnt93/fert_runs",
    [string]$RunLabel = "bellman_re_t13_deep_suffix_hamilton"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$compiledRoot = Join-Path $projectRoot "compiled_sidecar"
$logsRoot = Join-Path $projectRoot "notes/build/logs"
$scriptTemplate = Join-Path $PSScriptRoot "hamilton_bellman_re_t13_deep_suffix.sh"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$localStageDir = Join-Path $logsRoot ("{0}_{1}" -f $RunLabel, $timestamp)
$archivePath = Join-Path $localStageDir "compiled_sidecar_t13_deep_suffix.tar.gz"
$activePointer = Join-Path $logsRoot ("active_{0}.txt" -f $RunLabel)
$submissionPath = Join-Path $localStageDir "submission.txt"
$keyPath = Join-Path $HOME ".ssh\id_ed25519"
$remoteRunDir = "{0}/{1}_{2}" -f $RemoteBaseDir.TrimEnd("/"), $RunLabel, $timestamp

if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}
New-Item -ItemType Directory -Path $localStageDir | Out-Null

if (-not (Test-Path $scriptTemplate)) {
    throw "Remote script not found: $scriptTemplate"
}
if (-not (Test-Path $keyPath)) {
    throw "SSH key not found: $keyPath"
}

$sshBaseArgs = @(
    "-F", "NUL",
    "-o", "IdentitiesOnly=yes",
    "-i", $keyPath
)

Set-Location $compiledRoot
& tar.exe -czf $archivePath CMakeLists.txt include src truth/transition_input_t13_diag
Set-Location $projectRoot

& ssh @sshBaseArgs $RemoteHost "mkdir -p '$remoteRunDir'"
& scp @sshBaseArgs $archivePath "${RemoteHost}:$remoteRunDir/compiled_sidecar.tar.gz"
& scp @sshBaseArgs $scriptTemplate "${RemoteHost}:$remoteRunDir/run_t13_deep_suffix.sh"

$remoteSubmitCommand = @"
set -euo pipefail
cd '$remoteRunDir'
mkdir -p compiled_sidecar
tar -xzf compiled_sidecar.tar.gz -C compiled_sidecar
chmod +x run_t13_deep_suffix.sh
sbatch run_t13_deep_suffix.sh
"@

$sbatchOutput = & ssh @sshBaseArgs $RemoteHost $remoteSubmitCommand
$jobIdMatch = [regex]::Match($sbatchOutput, "Submitted batch job\s+([0-9]+)")
$jobId = if ($jobIdMatch.Success) { $jobIdMatch.Groups[1].Value } else { "" }

@(
    "submitted_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "remote_host=$RemoteHost"
    "remote_run_dir=$remoteRunDir"
    "job_id=$jobId"
    "local_stage_dir=$localStageDir"
    "archive_path=$archivePath"
    "submission_output=$sbatchOutput"
) | Set-Content -Path $activePointer

@(
    "Hamilton submission complete"
    "remote_host=$RemoteHost"
    "remote_run_dir=$remoteRunDir"
    "job_id=$jobId"
    "submission_output=$sbatchOutput"
) | Set-Content -Path $submissionPath

Write-Output $submissionPath
