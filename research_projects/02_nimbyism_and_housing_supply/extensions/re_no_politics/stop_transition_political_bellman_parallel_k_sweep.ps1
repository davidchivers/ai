[CmdletBinding()]
param(
    [string]$WorkflowName = 'political_bellman_parallel_k_live'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workflowDir = Join-Path (Join-Path $scriptDir 'truth') $WorkflowName
$stopPath = Join-Path $workflowDir 'stop.txt'
$launcherStatePath = Join-Path $workflowDir 'launcher_state.json'

if (-not (Test-Path -LiteralPath $workflowDir)) {
    throw "Workflow directory not found: $workflowDir"
}

Set-Content -LiteralPath $stopPath -Value ('stop requested at {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

if (Test-Path -LiteralPath $launcherStatePath) {
    try {
        $state = Get-Content -Raw $launcherStatePath | ConvertFrom-Json
        if ($state.launcher_pid) {
            Stop-Process -Id ([int]$state.launcher_pid) -Force -ErrorAction SilentlyContinue
        }
    } catch {
    }
}

Write-Host "Stop requested for workflow $WorkflowName"
