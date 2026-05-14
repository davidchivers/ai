$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $thisDir 'workflow_logs'
$workflowLog = Join-Path $logDir 'extension_away_workflow.log'
$lambdaWorkflow = Join-Path $thisDir 'run_transition_re_lambda_workflow.ps1'
$lambdaSummary = Join-Path $thisDir 'transition_re_lambda_continuation_summary.csv'
$lambdaLive = Join-Path $thisDir 'transition_re_lambda_continuation_summary_live.csv'
$followupReport = Join-Path $thisDir 'write_transition_re_followup_report.ps1'
$coalitionRunner = Join-Path $thisDir 'run_coalition_benchmark_sensitivity.ps1'
$coalitionSummary = Join-Path $thisDir 'coalition_benchmark_summary.csv'
$coalitionLive = Join-Path $thisDir 'coalition_benchmark_summary_live.csv'
$coalitionReport = Join-Path $thisDir 'write_coalition_benchmark_report.ps1'

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

function Write-WorkflowLog {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $workflowLog -Value "[$timestamp] $Message"
}

function Get-MatlabBatchProcesses {
    param([string]$Pattern = '')

    $procs = Get-CimInstance Win32_Process |
        Where-Object {
            ($_.Name -ieq 'MATLAB.exe' -or $_.Name -ieq 'matlab.exe') -and
            $_.CommandLine -and
            $_.CommandLine -match '-batch'
        }

    if ($Pattern) {
        return $procs | Where-Object { $_.CommandLine -match $Pattern }
    }

    return $procs
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

Write-WorkflowLog 'Extension away workflow started.'

try {
    while ($true) {
        $lambdaProcs = Get-MatlabBatchProcesses 'run_transition_re_lambda_continuation'
        if ($lambdaProcs) {
            $summary = ($lambdaProcs | Select-Object -ExpandProperty ProcessId) -join ', '
            Write-WorkflowLog "Lambda continuation batch still running: $summary"
            Start-Sleep -Seconds 300
            continue
        }

        if (Test-Path $lambdaSummary) {
            Write-WorkflowLog 'Lambda continuation summary detected.'
            break
        }

        if (Test-Path $lambdaLive) {
            Write-WorkflowLog 'Lambda live checkpoint detected with no active process. Resuming lambda workflow.'
            Invoke-StageScript -StageName 'lambda_workflow_resume' -ScriptPath $lambdaWorkflow
            continue
        }

        Write-WorkflowLog 'No lambda process or summary detected. Starting lambda workflow directly.'
        Invoke-StageScript -StageName 'lambda_workflow' -ScriptPath $lambdaWorkflow
    }

    Invoke-StageScript -StageName 'refresh_followup_report' -ScriptPath $followupReport

    if (-not (Test-Path $coalitionSummary)) {
        if (Test-Path $coalitionLive) {
            Write-WorkflowLog 'Coalition benchmark live checkpoint detected; resuming coalition runner.'
        }
        Invoke-StageScript -StageName 'coalition_benchmark_sensitivity' -ScriptPath $coalitionRunner
    } else {
        Write-WorkflowLog 'Coalition benchmark summary already exists; skipping coalition run.'
    }

    Invoke-StageScript -StageName 'write_coalition_report' -ScriptPath $coalitionReport
    Write-WorkflowLog 'Extension away workflow finished successfully.'
}
catch {
    Write-WorkflowLog "Extension away workflow failed: $($_.Exception.Message)"
    throw
}
