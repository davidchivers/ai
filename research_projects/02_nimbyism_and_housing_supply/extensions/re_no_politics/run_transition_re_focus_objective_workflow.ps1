$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $thisDir 'workflow_logs'
$workflowLog = Join-Path $logDir 'transition_re_focus_objective_workflow.log'
$tradeoffReport = Join-Path $thisDir 'write_transition_re_objective_tradeoff_report.ps1'
$focusRunner = Join-Path $thisDir 'run_transition_re_focus_objective_followup.ps1'
$followupReport = Join-Path $thisDir 'write_transition_re_followup_report.ps1'

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

Write-WorkflowLog 'Focus-objective workflow started.'

try {
    Invoke-StageScript -StageName 'objective_tradeoff_report' -ScriptPath $tradeoffReport
    Invoke-StageScript -StageName 'focus_objective_followup' -ScriptPath $focusRunner
    Invoke-StageScript -StageName 'refresh_followup_report' -ScriptPath $followupReport
    Write-WorkflowLog 'Focus-objective workflow finished successfully.'
}
catch {
    Write-WorkflowLog "Focus-objective workflow failed: $($_.Exception.Message)"
    throw
}
