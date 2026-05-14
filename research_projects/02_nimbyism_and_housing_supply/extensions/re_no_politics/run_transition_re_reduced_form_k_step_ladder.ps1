$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
$logDir = Join-Path $thisDir 'workflow_logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$stdout = Join-Path $logDir 'transition_re_reduced_form_k_step_stdout.log'
$stderr = Join-Path $logDir 'transition_re_reduced_form_k_step_stderr.log'
if (Test-Path $stdout) { Remove-Item $stdout -Force }
if (Test-Path $stderr) { Remove-Item $stderr -Force }

$batchCommand = "cd('C:/Users/Dave_/AI/research_projects/02_nimbyism_and_housing_supply/extensions/re_no_politics'); [summary, frontier] = run_transition_re_reduced_form_k_step_ladder(); disp(summary); disp(frontier);"
$args = "-batch `"$batchCommand`""

$proc = Start-Process -FilePath $matlab `
    -ArgumentList $args `
    -WorkingDirectory $thisDir `
    -RedirectStandardOutput $stdout `
    -RedirectStandardError $stderr `
    -NoNewWindow `
    -PassThru `
    -Wait

if ($proc.ExitCode -ne 0) {
    throw "MATLAB stage 'transition_re_reduced_form_k_step_ladder' failed with exit code $($proc.ExitCode)."
}
