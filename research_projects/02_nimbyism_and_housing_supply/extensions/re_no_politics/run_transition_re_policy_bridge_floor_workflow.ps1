$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $thisDir 'workflow_logs'
$workflowLog = Join-Path $logDir 'transition_re_policy_bridge_floor_workflow.log'
$runner = Join-Path $thisDir 'run_transition_re_policy_bridge_floor_sweep.ps1'
$reportWriter = Join-Path $thisDir 'write_transition_re_policy_bridge_floor_report.ps1'

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

Write-WorkflowLog 'Policy bridge floor workflow started.'

try {
    Invoke-StageScript -StageName 'policy_bridge_floor_sweep' -ScriptPath $runner
    Invoke-StageScript -StageName 'write_policy_bridge_floor_report' -ScriptPath $reportWriter
    Write-WorkflowLog 'Policy bridge floor workflow finished successfully.'
}
catch {
    Write-WorkflowLog "Policy bridge floor workflow failed: $($_.Exception.Message)"
    throw
}
