$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $thisDir 'workflow_logs'
$workflowLog = Join-Path $logDir 'transition_re_lambda_workflow.log'
$lambdaRunner = Join-Path $thisDir 'run_transition_re_lambda_continuation.ps1'
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

Write-WorkflowLog 'Lambda continuation workflow started.'

try {
    Invoke-StageScript -StageName 'lambda_continuation' -ScriptPath $lambdaRunner
    Invoke-StageScript -StageName 'refresh_followup_report' -ScriptPath $followupReport
    Write-WorkflowLog 'Lambda continuation workflow finished successfully.'
}
catch {
    Write-WorkflowLog "Lambda continuation workflow failed: $($_.Exception.Message)"
    throw
}
