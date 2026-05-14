$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
$logDir = Join-Path $thisDir 'workflow_logs'
$stdout = Join-Path $logDir 'transition_re_political_path_stdout.log'
$stderr = Join-Path $logDir 'transition_re_political_path_stderr.log'

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$batchCommand = "cd('C:/Users/Dave_/AI/research_projects/02_nimbyism_and_housing_supply/extensions/re_no_politics'); [summary, periods, results] = run_transition_re_political_path_diagnostic(4); disp(summary); disp(periods);"
$args = "-batch `"$batchCommand`""

Write-Host '=== Transition political-path diagnostic ==='
Write-Host "stdout: $stdout"
Write-Host "stderr: $stderr"

$proc = Start-Process -FilePath $matlab -ArgumentList $args -WorkingDirectory $thisDir `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru -Wait

if ($proc.ExitCode -ne 0) {
    throw "MATLAB stage 'transition_re_political_path_diagnostic' failed with exit code $($proc.ExitCode)."
}

Write-Host 'Transition political-path diagnostic finished successfully.'
