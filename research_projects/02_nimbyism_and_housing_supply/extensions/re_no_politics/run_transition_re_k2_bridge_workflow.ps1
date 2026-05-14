$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $thisDir 'workflow_logs'
$workflowLog = Join-Path $logDir 'transition_re_k2_bridge_workflow.log'
$bridgeRunner = Join-Path $thisDir 'run_transition_re_k2_bridge_followup.ps1'
$bridgeReport = Join-Path $thisDir 'write_transition_re_k2_bridge_report.ps1'

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

function Write-WorkflowLog {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $workflowLog -Value "[$timestamp] $Message"
}

function Invoke-StageScript {
    param(
        [Parameter(Mandatory = $true)][string]$StageName,
        [Parameter(Mandatory = $true)][string]$ScriptPath
    )

    Write-WorkflowLog "Starting stage: $StageName"
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ScriptPath
    if ($LASTEXITCODE -ne 0) {
        throw "Stage '$StageName' failed with exit code $LASTEXITCODE."
    }
    Write-WorkflowLog "Finished stage: $StageName"
}

Write-WorkflowLog 'k=2 bridge workflow started.'

try {
    Invoke-StageScript -StageName 'k2_bridge_followup' -ScriptPath $bridgeRunner
    Invoke-StageScript -StageName 'write_k2_bridge_report' -ScriptPath $bridgeReport
    Write-WorkflowLog 'k=2 bridge workflow finished successfully.'
}
catch {
    Write-WorkflowLog "k=2 bridge workflow failed: $($_.Exception.Message)"
    throw
}
