[CmdletBinding()]
param(
    [string]$KListCsv = '1,2,3,4,5,6,7,8,9',
    [int]$MaxIter = 2,
    [int]$MaxParallel = 3,
    [string]$PriceUpdateMode = 'political_only',
    [string]$PoliticalTarget = 'equal_weight_vote',
    [double]$PoliticalUpdateWeight = 0.005,
    [string]$PoliticalUpdateRule = 'fixed_step',
    [string]$WorkflowName = 'political_bellman_parallel_k_live'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$runner = Join-Path $scriptDir 'run_transition_political_bellman_parallel_k_sweep.ps1'
$workflowDir = Join-Path (Join-Path $scriptDir 'truth') $WorkflowName
$launcherStatePath = Join-Path $workflowDir 'launcher_state.json'

if (-not (Test-Path -LiteralPath $workflowDir)) {
    New-Item -ItemType Directory -Path $workflowDir | Out-Null
}

$args = @(
    '-ExecutionPolicy', 'Bypass',
    '-File', $runner,
    '-KListCsv', $KListCsv,
    '-MaxIter', $MaxIter,
    '-MaxParallel', $MaxParallel,
    '-PriceUpdateMode', $PriceUpdateMode,
    '-PoliticalTarget', $PoliticalTarget,
    '-PoliticalUpdateWeight', ('{0:R}' -f $PoliticalUpdateWeight),
    '-PoliticalUpdateRule', $PoliticalUpdateRule,
    '-WorkflowName', $WorkflowName
)

$proc = Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WorkingDirectory $scriptDir -WindowStyle Hidden -PassThru

[ordered]@{
    workflow_name = $WorkflowName
    launcher_pid = $proc.Id
    started_at = (Get-Date).ToString('o')
    workflow_dir = $workflowDir
} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $launcherStatePath

Write-Host "Started parallel MATLAB political Bellman sweep. pid=$($proc.Id) workflow=$WorkflowName"
