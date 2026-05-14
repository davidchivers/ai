$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $thisDir 'workflow_logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$workflowLog = Join-Path $logDir 'transition_re_reduced_form_workflow.log'
if (Test-Path $workflowLog) { Remove-Item $workflowLog -Force }

function Add-Log([string]$message) {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$timestamp  $message" | Tee-Object -FilePath $workflowLog -Append
}

Add-Log 'Starting reduced-form RE workflow.'
& (Join-Path $thisDir 'run_transition_re_reduced_form_one_step.ps1')
Add-Log 'Completed reduced-form one-step RE run.'
& (Join-Path $thisDir 'run_transition_re_reduced_form_k_step_ladder.ps1')
Add-Log 'Completed reduced-form k-step RE ladder.'
Add-Log 'Reduced-form RE workflow finished.'
