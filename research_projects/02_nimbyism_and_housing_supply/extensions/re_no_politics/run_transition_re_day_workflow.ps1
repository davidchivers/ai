$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $thisDir 'workflow_logs'
$workflowLog = Join-Path $logDir 'transition_re_day_workflow.log'
$candidateRunner = Join-Path $thisDir 'run_transition_re_candidate_selection_followup.ps1'
$candidateQueueRunner = Join-Path $thisDir 'queue_transition_re_candidate_selection_followup.ps1'
$reportWriter = Join-Path $thisDir 'write_transition_re_followup_report.ps1'
$validationRunner = Join-Path $thisDir 'run_transition_re_validation_pack.ps1'
$candidateSummary = Join-Path $thisDir 'transition_re_candidate_selection_summary.csv'
$candidateLive = Join-Path $thisDir 'transition_re_candidate_selection_summary_live.csv'
$validationSummary = Join-Path $thisDir 'transition_re_validation_summary.csv'

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

Write-WorkflowLog 'Day workflow started.'

try {
    while ($true) {
        $candidateProcs = Get-MatlabBatchProcesses 'run_transition_re_candidate_selection_followup'
        if ($candidateProcs) {
            $summary = ($candidateProcs | Select-Object -ExpandProperty ProcessId) -join ', '
            Write-WorkflowLog "Candidate-selection batch still running: $summary"
            Start-Sleep -Seconds 300
            continue
        }

        if (Test-Path $candidateSummary) {
            Write-WorkflowLog 'Candidate-selection summary detected.'
            break
        }

        if (Test-Path $candidateLive) {
            Write-WorkflowLog 'Candidate-selection live checkpoint detected with no active process. Resuming candidate-selection runner.'
            Invoke-StageScript -StageName 'candidate_selection_resume' -ScriptPath $candidateRunner
            continue
        }

        $otherBatch = Get-MatlabBatchProcesses
        if ($otherBatch) {
            $summary = ($otherBatch | Select-Object -ExpandProperty ProcessId) -join ', '
            Write-WorkflowLog "No candidate-selection process yet, but other batch MATLAB work is active: $summary. Starting queue watcher."
            Invoke-StageScript -StageName 'candidate_selection_queue' -ScriptPath $candidateQueueRunner
        } else {
            Write-WorkflowLog 'No candidate-selection process or summary detected. Starting candidate-selection runner directly.'
            Invoke-StageScript -StageName 'candidate_selection_followup' -ScriptPath $candidateRunner
        }
    }

    Invoke-StageScript -StageName 'refresh_report_after_candidate_selection' -ScriptPath $reportWriter

    if (-not (Test-Path $validationSummary)) {
        Invoke-StageScript -StageName 'validation_pack' -ScriptPath $validationRunner
    } else {
        Write-WorkflowLog 'Validation summary already exists; skipping validation stage.'
    }

    Invoke-StageScript -StageName 'refresh_report_after_validation' -ScriptPath $reportWriter
    Write-WorkflowLog 'Day workflow finished successfully.'
}
catch {
    Write-WorkflowLog "Day workflow failed: $($_.Exception.Message)"
    throw
}
