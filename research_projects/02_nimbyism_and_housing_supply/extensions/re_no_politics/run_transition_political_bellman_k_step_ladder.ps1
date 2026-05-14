[CmdletBinding()]
param(
    [int]$MaxK = 9,
    [int]$MaxIter = 1,
    [string]$PriceUpdateMode = 'joint_housing_political',
    [string]$PoliticalTarget = 'equal_weight_vote',
    [double]$PoliticalUpdateWeight = 0.005,
    [string]$RunTag = '',
    [string]$PoliticalUpdateRule = 'fixed_step'
)

$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
$logDir = Join-Path $thisDir 'workflow_logs'
$tagPart = if ([string]::IsNullOrWhiteSpace($RunTag)) { 'default' } else { ($RunTag -replace '[^A-Za-z0-9_]+', '_') }
$stdout = Join-Path $logDir ("transition_political_bellman_ladder_{0}_stdout.log" -f $tagPart)
$stderr = Join-Path $logDir ("transition_political_bellman_ladder_{0}_stderr.log" -f $tagPart)

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$batchCommand = "cd('C:/Users/Dave_/AI/research_projects/02_nimbyism_and_housing_supply/extensions/re_no_politics'); summary = run_transition_political_bellman_k_step_ladder($MaxK, $MaxIter, '$PriceUpdateMode', '$PoliticalTarget', $PoliticalUpdateWeight, '$RunTag', '$PoliticalUpdateRule'); disp(summary);"
$args = "-batch `"$batchCommand`""

Write-Host '=== Political Bellman k-step ladder ==='
Write-Host "max_k: $MaxK"
Write-Host "max_iter: $MaxIter"
Write-Host "price_update_mode: $PriceUpdateMode"
Write-Host "political_target: $PoliticalTarget"
Write-Host "political_update_weight: $PoliticalUpdateWeight"
Write-Host "political_update_rule: $PoliticalUpdateRule"
Write-Host "run_tag: $RunTag"
Write-Host "stdout: $stdout"
Write-Host "stderr: $stderr"

$proc = Start-Process -FilePath $matlab -ArgumentList $args -WorkingDirectory $thisDir `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru -Wait

if ($proc.ExitCode -ne 0) {
    throw "MATLAB stage 'transition_political_bellman_k_step_ladder' failed with exit code $($proc.ExitCode)."
}

Write-Host 'Political Bellman k-step ladder finished successfully.'
