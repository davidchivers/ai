$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $thisDir 'workflow_logs'
$watcherLog = Join-Path $logDir 'transition_re_focus_post_workflow.log'
$focusWorkflowLog = Join-Path $logDir 'transition_re_focus_objective_workflow.log'
$focusSummary = Join-Path $thisDir 'transition_re_focus_objective_summary.csv'
$candidateSummary = Join-Path $thisDir 'transition_re_candidate_selection_summary.csv'
$validationRunner = Join-Path $thisDir 'run_transition_re_focus_validation_pack.ps1'
$followupReport = Join-Path $thisDir 'write_transition_re_followup_report.ps1'
$maxWaitHours = 24
$improvementTol = 1e-6

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

function Write-WorkflowLog {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $watcherLog -Value "[$timestamp] $Message"
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

Write-WorkflowLog 'Focus post-workflow watcher started.'

try {
    $start = Get-Date
    while ($true) {
        if (Test-Path $focusWorkflowLog) {
            $tail = Get-Content -Path $focusWorkflowLog -Tail 20
            if ($tail -match 'Focus-objective workflow finished successfully\.') {
                break
            }
            if ($tail -match 'Focus-objective workflow failed:') {
                throw 'Focus-objective workflow failed before post-workflow decision.'
            }
        }

        if (((Get-Date) - $start).TotalHours -ge $maxWaitHours) {
            throw "Timed out waiting for focus-objective workflow after $maxWaitHours hours."
        }

        Start-Sleep -Seconds 60
    }

    if (-not (Test-Path $focusSummary)) {
        throw "Focus-objective summary not found: $focusSummary"
    }
    if (-not (Test-Path $candidateSummary)) {
        throw "Candidate-selection summary not found: $candidateSummary"
    }

    $focusRows = Import-Csv $focusSummary | Where-Object { $_.status -eq 'ok' }
    $baselineRow = Import-Csv $candidateSummary |
        Where-Object { $_.status -eq 'ok' -and $_.case_name -eq 'config11_global_control' } |
        Select-Object -First 1

    if (-not $focusRows) {
        throw 'No completed focus-objective rows available for the post-workflow decision.'
    }
    if (-not $baselineRow) {
        throw 'Baseline control row config11_global_control not found in candidate-selection summary.'
    }

    $bestFocus = $focusRows | Select-Object -First 1
    $baselineGap = [double]$baselineRow.max_abs_gap
    $bestFocusGap = [double]$bestFocus.max_abs_gap
    $gapImprovement = $baselineGap - $bestFocusGap

    Write-WorkflowLog ("Baseline control gap = {0:N12}; best focus gap = {1:N12}; improvement = {2:N12}" -f `
        $baselineGap, $bestFocusGap, $gapImprovement)

    if ($gapImprovement -gt $improvementTol) {
        Write-WorkflowLog ("Improvement threshold met by {0}; launching focus validation pack." -f $bestFocus.case_name)
        Invoke-StageScript -StageName 'focus_validation_pack' -ScriptPath $validationRunner
    } else {
        Write-WorkflowLog ("No focus-objective case beat config11_global_control on max gap by at least {0}; stopping without validation." -f $improvementTol)
    }

    Invoke-StageScript -StageName 'refresh_followup_report' -ScriptPath $followupReport
    Write-WorkflowLog 'Focus post-workflow watcher finished successfully.'
}
catch {
    Write-WorkflowLog "Focus post-workflow watcher failed: $($_.Exception.Message)"
    throw
}
