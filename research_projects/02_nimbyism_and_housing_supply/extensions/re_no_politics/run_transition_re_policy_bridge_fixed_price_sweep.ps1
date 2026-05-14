$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
$logDir = Join-Path $thisDir 'workflow_logs'
$stdout = Join-Path $logDir 'transition_re_policy_bridge_fixed_price_sweep_stdout.log'
$stderr = Join-Path $logDir 'transition_re_policy_bridge_fixed_price_sweep_stderr.log'

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$batchCommand = "cd('C:/Users/Dave_/AI/research_projects/02_nimbyism_and_housing_supply/extensions/re_no_politics'); summary = run_transition_re_policy_bridge_fixed_price_sweep(); disp(summary);"
$args = "-batch `"$batchCommand`""

Write-Host '=== fixed-price policy bridge sweep ==='
Write-Host "stdout: $stdout"
Write-Host "stderr: $stderr"

$proc = Start-Process -FilePath $matlab -ArgumentList $args -WorkingDirectory $thisDir `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru -Wait

if ($proc.ExitCode -ne 0) {
    throw "MATLAB stage 'transition_re_policy_bridge_fixed_price_sweep' failed with exit code $($proc.ExitCode)."
}

Write-Host 'fixed-price policy bridge sweep finished successfully.'
