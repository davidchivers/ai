$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
$logDir = Join-Path $thisDir 'workflow_logs'
$stdout = Join-Path $logDir 'transition_re_joint_price_vote_stdout.log'
$stderr = Join-Path $logDir 'transition_re_joint_price_vote_stderr.log'

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$batchCommand = "cd('C:/Users/Dave_/AI/research_projects/02_nimbyism_and_housing_supply/extensions/re_no_politics'); [summary, period_rows, all_results] = run_transition_re_joint_price_vote_experiment(4, 2, 0.001); disp(summary); disp(period_rows);"
$args = "-batch `"$batchCommand`""

Write-Host '=== Joint price-and-vote experiment ==='
Write-Host "stdout: $stdout"
Write-Host "stderr: $stderr"

$proc = Start-Process -FilePath $matlab -ArgumentList $args -WorkingDirectory $thisDir `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru -Wait

if ($proc.ExitCode -ne 0) {
    throw "MATLAB stage 'transition_re_joint_price_vote_experiment' failed with exit code $($proc.ExitCode)."
}

Write-Host 'Joint price-and-vote experiment finished successfully.'
