$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $thisDir 'workflow_logs'
$workflowLog = Join-Path $logDir 'transition_re_joint_price_vote_weight_sweep_workflow.log'
$runner = Join-Path $thisDir 'run_transition_re_joint_price_vote_weight_sweep.ps1'
$reportWriter = Join-Path $thisDir 'write_transition_re_joint_price_vote_weight_sweep_report.ps1'

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

Write-WorkflowLog 'Joint price-vote weight sweep workflow started.'

try {
    Invoke-StageScript -StageName 'transition_re_joint_price_vote_weight_sweep' -ScriptPath $runner
    Invoke-StageScript -StageName 'write_transition_re_joint_price_vote_weight_sweep_report' -ScriptPath $reportWriter
    Write-WorkflowLog 'Joint price-vote weight sweep workflow finished successfully.'
}
catch {
    Write-WorkflowLog "Joint price-vote weight sweep workflow failed: $($_.Exception.Message)"
    throw
}
