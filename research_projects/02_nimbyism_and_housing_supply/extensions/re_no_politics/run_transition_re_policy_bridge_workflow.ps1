$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $thisDir 'workflow_logs'
$workflowLog = Join-Path $logDir 'transition_re_policy_bridge_workflow.log'
$k2Runner = Join-Path $thisDir 'run_transition_re_k2_policy_bridge_followup.ps1'
$byPeriodRunner = Join-Path $thisDir 'run_transition_re_k_step_policy_bridge_ladder.ps1'
$reportWriter = Join-Path $thisDir 'write_transition_re_policy_bridge_report.ps1'
$matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'

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

function Invoke-MatlabBatchStage {
    param(
        [Parameter(Mandatory = $true)][string]$StageName,
        [Parameter(Mandatory = $true)][string]$BatchCommand
    )

    $stdout = Join-Path $logDir ($StageName + '_stdout.log')
    $stderr = Join-Path $logDir ($StageName + '_stderr.log')
    $args = "-batch `"$BatchCommand`""

    Write-WorkflowLog "Starting stage: $StageName"
    $proc = Start-Process -FilePath $matlab -ArgumentList $args -WorkingDirectory $thisDir `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow -PassThru -Wait

    if ($proc.ExitCode -ne 0) {
        throw "Stage '$StageName' failed with exit code $($proc.ExitCode)."
    }

    Write-WorkflowLog "Finished stage: $StageName"
}

Write-WorkflowLog 'Policy bridge workflow started.'

try {
    Invoke-StageScript -StageName 'k2_policy_bridge_followup' -ScriptPath $k2Runner
    Invoke-StageScript -StageName 'k_step_policy_bridge_by_period' -ScriptPath $byPeriodRunner
    Invoke-MatlabBatchStage -StageName 'k_step_policy_bridge_fixed_price_full_horizon' -BatchCommand "cd('C:/Users/Dave_/AI/research_projects/02_nimbyism_and_housing_supply/extensions/re_no_politics'); summary = run_transition_re_k_step_policy_bridge_ladder(9, 'steady_state_fixed_price_2_0'); disp(summary);"
    Invoke-StageScript -StageName 'write_policy_bridge_report' -ScriptPath $reportWriter
    Write-WorkflowLog 'Policy bridge workflow finished successfully.'
}
catch {
    Write-WorkflowLog "Policy bridge workflow failed: $($_.Exception.Message)"
    throw
}
