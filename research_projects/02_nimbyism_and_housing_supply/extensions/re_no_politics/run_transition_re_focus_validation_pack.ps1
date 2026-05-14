$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
$logDir = Join-Path $thisDir 'workflow_logs'

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$stdout = Join-Path $logDir 'focus_validation_pack_stdout.log'
$stderr = Join-Path $logDir 'focus_validation_pack_stderr.log'
$batch = "cd('C:/Users/Dave_/AI/research_projects/02_nimbyism_and_housing_supply/extensions/re_no_politics'); run_transition_re_focus_validation_pack"
$args = "-batch `"$batch`""

Write-Host '=== focus_validation_pack ==='
Write-Host "stdout: $stdout"
Write-Host "stderr: $stderr"

$proc = Start-Process -FilePath $matlab -ArgumentList $args -WorkingDirectory $thisDir `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru -Wait

if ($proc.ExitCode -ne 0) {
    throw "MATLAB stage 'focus_validation_pack' failed with exit code $($proc.ExitCode)."
}

Write-Host 'Focus validation pack finished successfully.'
