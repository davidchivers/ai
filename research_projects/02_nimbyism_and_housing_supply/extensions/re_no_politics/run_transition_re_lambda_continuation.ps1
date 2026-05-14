$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
$logDir = Join-Path $thisDir 'workflow_logs'

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$stdout = Join-Path $logDir 'lambda_continuation_stdout.log'
$stderr = Join-Path $logDir 'lambda_continuation_stderr.log'
$batch = "cd('C:/Users/Dave_/AI/research_projects/02_nimbyism_and_housing_supply/extensions/re_no_politics'); run_transition_re_lambda_continuation"
$args = "-batch `"$batch`""

Write-Host '=== lambda_continuation ==='
Write-Host "stdout: $stdout"
Write-Host "stderr: $stderr"

$proc = Start-Process -FilePath $matlab -ArgumentList $args -WorkingDirectory $thisDir `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru -Wait

if ($proc.ExitCode -ne 0) {
    throw "MATLAB stage 'lambda_continuation' failed with exit code $($proc.ExitCode)."
}

Write-Host 'Lambda continuation finished successfully.'
