$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$reportPath = Join-Path $thisDir 'transition_re_followup_report.md'
$tuningPath = Join-Path $thisDir 'transition_re_tuning_summary.csv'
$blockPath = Join-Path $thisDir 'transition_re_block_search_summary.csv'
$candidatePath = Join-Path $thisDir 'transition_re_candidate_selection_summary.csv'
$candidateLivePath = Join-Path $thisDir 'transition_re_candidate_selection_summary_live.csv'
$validationPath = Join-Path $thisDir 'transition_re_validation_summary.csv'
$validationLivePath = Join-Path $thisDir 'transition_re_validation_summary_live.csv'
$focusPath = Join-Path $thisDir 'transition_re_focus_objective_summary.csv'
$focusLivePath = Join-Path $thisDir 'transition_re_focus_objective_summary_live.csv'
$focusValidationPath = Join-Path $thisDir 'transition_re_focus_validation_summary.csv'
$focusValidationLivePath = Join-Path $thisDir 'transition_re_focus_validation_summary_live.csv'
$lambdaPath = Join-Path $thisDir 'transition_re_lambda_continuation_summary.csv'
$lambdaLivePath = Join-Path $thisDir 'transition_re_lambda_continuation_summary_live.csv'
$queueLogPath = Join-Path $thisDir 'workflow_logs\candidate_selection_followup_queue.log'

function Format-Number {
    param(
        [Parameter(Mandatory = $false)]$Value,
        [Parameter(Mandatory = $false)][int]$Digits = 6
    )

    if ($null -eq $Value -or $Value -eq '') {
        return 'NA'
    }

    $number = 0.0
    if ([double]::TryParse($Value.ToString(), [ref]$number)) {
        return ('{0:N' + $Digits + '}') -f $number
    }

    return $Value.ToString()
}

function Add-Line {
    param([string]$Text)
    $script:lines.Add($Text) | Out-Null
}

$lines = New-Object System.Collections.Generic.List[string]
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

Add-Line '# Transition RE follow-up report'
Add-Line ''
Add-Line "Generated: $timestamp"
Add-Line ''

if (-not (Test-Path $tuningPath)) {
    throw "Missing tuning summary: $tuningPath"
}

$tuning = Import-Csv $tuningPath
$bestTuning = $tuning | Select-Object -First 1

Add-Line '## Best tuning config'
Add-Line ''
Add-Line "- Config ID: $($bestTuning.config_id)"
Add-Line "- Residual norm: $(Format-Number $bestTuning.residual_norm 12)"
Add-Line "- Max gap: $(Format-Number $bestTuning.max_abs_gap 12)"
Add-Line "- Accepted update: $($bestTuning.accepted_update)"
Add-Line "- Worst periods: gap $($bestTuning.worst_gap_period), excess demand $($bestTuning.worst_excess_demand_period)"
Add-Line "- Parameters: damping=$($bestTuning.damping), smoothing=$($bestTuning.smoothing_weight), targeted=$($bestTuning.targeted_correction_weight), scales=$($bestTuning.line_search_scales)"
Add-Line ''

if (Test-Path $blockPath) {
    $block = Import-Csv $blockPath
    $bestBlock = $block | Select-Object -First 1
    $maxPersistence = ($block | Measure-Object -Property last_nontrivial_iter -Maximum).Maximum
    $maxUpdates = ($block | Measure-Object -Property nontrivial_update_count -Maximum).Maximum

    Add-Line '## Block-search follow-up'
    Add-Line ''
    Add-Line "- Best block-search row: $($bestBlock.case_name)"
    Add-Line "- Residual norm: $(Format-Number $bestBlock.residual_norm 12)"
    Add-Line "- Max gap: $(Format-Number $bestBlock.max_abs_gap 12)"
    Add-Line "- Persistence: last nontrivial iteration = $maxPersistence; max nontrivial update count = $maxUpdates"
    Add-Line "- Repeated bottleneck: worst gap period $($bestBlock.worst_gap_period), worst excess-demand period $($bestBlock.worst_excess_demand_period)"
    Add-Line ''
}

Add-Line '## Candidate-selection follow-up'
Add-Line ''

if (Test-Path $candidatePath) {
    $candidate = Import-Csv $candidatePath
    $topCandidate = $candidate | Select-Object -First 1
    Add-Line "- Status: completed"
    Add-Line "- Best row: $($topCandidate.case_name)"
    Add-Line "- Residual norm: $(Format-Number $topCandidate.residual_norm 12)"
    Add-Line "- Max gap: $(Format-Number $topCandidate.max_abs_gap 12)"
    Add-Line "- Persistence: last nontrivial iteration = $($topCandidate.last_nontrivial_iter), nontrivial update count = $($topCandidate.nontrivial_update_count)"
    Add-Line "- Mode: $($topCandidate.candidate_selection_mode); greedy = $($topCandidate.greedy_block_accept); residual slack = $($topCandidate.candidate_residual_slack)"
} elseif (Test-Path $candidateLivePath) {
    $candidateLive = Import-Csv $candidateLivePath
    $topCandidate = $candidateLive | Select-Object -First 1
    Add-Line "- Status: live checkpoint in progress"
    Add-Line "- Current best row: $($topCandidate.case_name)"
    Add-Line "- Residual norm: $(Format-Number $topCandidate.residual_norm 12)"
    Add-Line "- Max gap: $(Format-Number $topCandidate.max_abs_gap 12)"
} else {
    Add-Line "- Status: not finished yet"
    if (Test-Path $queueLogPath) {
        $lastQueueLine = Get-Content $queueLogPath | Select-Object -Last 1
        Add-Line "- Queue note: $lastQueueLine"
    }
}

Add-Line ''
Add-Line '## Validation pack'
Add-Line ''

if (Test-Path $validationPath) {
    $validation = Import-Csv $validationPath
    $topValidation = $validation | Select-Object -First 1
    Add-Line "- Status: completed"
    Add-Line "- Best validation row: $($topValidation.case_name)"
    Add-Line "- Source case: $($topValidation.source_case_name)"
    Add-Line "- Residual norm: $(Format-Number $topValidation.residual_norm 12)"
    Add-Line "- Max gap: $(Format-Number $topValidation.max_abs_gap 12)"
    Add-Line "- Persistence: last nontrivial iteration = $($topValidation.last_nontrivial_iter), nontrivial update count = $($topValidation.nontrivial_update_count)"
} elseif (Test-Path $validationLivePath) {
    $validationLive = Import-Csv $validationLivePath
    $topValidation = $validationLive | Select-Object -First 1
    Add-Line "- Status: live checkpoint in progress"
    Add-Line "- Current best validation row: $($topValidation.case_name)"
    Add-Line "- Source case: $($topValidation.source_case_name)"
} else {
    Add-Line "- Status: not started or not finished yet"
}

Add-Line ''
Add-Line '## Focus-objective follow-up'
Add-Line ''

if (Test-Path $focusPath) {
    $focus = Import-Csv $focusPath
    $topFocus = $focus | Select-Object -First 1
    Add-Line "- Status: completed"
    Add-Line "- Best focus-objective row: $($topFocus.case_name)"
    Add-Line "- Residual norm: $(Format-Number $topFocus.residual_norm 12)"
    Add-Line "- Max gap: $(Format-Number $topFocus.max_abs_gap 12)"
    Add-Line "- Persistence: last nontrivial iteration = $($topFocus.last_nontrivial_iter), nontrivial update count = $($topFocus.nontrivial_update_count)"
    Add-Line "- Mode: $($topFocus.candidate_selection_mode); focus gap tol = $($topFocus.focus_gap_improvement_tol); focus slack = $($topFocus.focus_residual_slack)"
} elseif (Test-Path $focusLivePath) {
    $focusLive = Import-Csv $focusLivePath
    $topFocus = $focusLive | Select-Object -First 1
    Add-Line "- Status: live checkpoint in progress"
    Add-Line "- Current best focus-objective row: $($topFocus.case_name)"
    Add-Line "- Residual norm: $(Format-Number $topFocus.residual_norm 12)"
    Add-Line "- Max gap: $(Format-Number $topFocus.max_abs_gap 12)"
} else {
    Add-Line "- Status: not started or not finished yet"
}

Add-Line ''
Add-Line '## Focus-objective validation'
Add-Line ''

if (Test-Path $focusValidationPath) {
    $focusValidation = Import-Csv $focusValidationPath
    $topFocusValidation = $focusValidation | Select-Object -First 1
    Add-Line "- Status: completed"
    Add-Line "- Best focus-validation row: $($topFocusValidation.case_name)"
    Add-Line "- Source case: $($topFocusValidation.source_case_name)"
    Add-Line "- Residual norm: $(Format-Number $topFocusValidation.residual_norm 12)"
    Add-Line "- Max gap: $(Format-Number $topFocusValidation.max_abs_gap 12)"
    Add-Line "- Persistence: last nontrivial iteration = $($topFocusValidation.last_nontrivial_iter), nontrivial update count = $($topFocusValidation.nontrivial_update_count)"
} elseif (Test-Path $focusValidationLivePath) {
    $focusValidationLive = Import-Csv $focusValidationLivePath
    $topFocusValidation = $focusValidationLive | Select-Object -First 1
    Add-Line "- Status: live checkpoint in progress"
    Add-Line "- Current best focus-validation row: $($topFocusValidation.case_name)"
    Add-Line "- Source case: $($topFocusValidation.source_case_name)"
} else {
    Add-Line "- Status: not started or not finished yet"
}

Add-Line ''
Add-Line '## Lambda continuation'
Add-Line ''

if (Test-Path $lambdaPath) {
    $lambda = Import-Csv $lambdaPath
    $lambdaLast = $lambda | Sort-Object {[double]$_.lambda} | Select-Object -Last 1
    Add-Line "- Status: completed"
    Add-Line "- Final lambda row: lambda = $($lambdaLast.lambda)"
    Add-Line "- Residual norm: $(Format-Number $lambdaLast.residual_norm 12)"
    Add-Line "- Max gap: $(Format-Number $lambdaLast.max_abs_gap 12)"
    Add-Line "- Worst periods: gap $($lambdaLast.worst_gap_period), excess demand $($lambdaLast.worst_excess_demand_period)"
    Add-Line "- Warm start source: $($lambdaLast.start_guess_source)"
} elseif (Test-Path $lambdaLivePath) {
    $lambdaLive = Import-Csv $lambdaLivePath
    $lambdaLast = $lambdaLive | Sort-Object {[double]$_.lambda} | Select-Object -Last 1
    Add-Line "- Status: live checkpoint in progress"
    Add-Line "- Latest lambda row: lambda = $($lambdaLast.lambda)"
    Add-Line "- Residual norm: $(Format-Number $lambdaLast.residual_norm 12)"
    Add-Line "- Max gap: $(Format-Number $lambdaLast.max_abs_gap 12)"
    Add-Line "- Warm start source: $($lambdaLast.start_guess_source)"
} else {
    Add-Line "- Status: not started or not finished yet"
}

Add-Line ''
Add-Line '## Interpretation'
Add-Line ''
Add-Line '- The main bottleneck is still localized rather than global: the summaries keep pointing back to period 3 and the 4-6 block region.'
Add-Line '- The candidate-selection run is designed to test whether a different acceptance rule extends nontrivial updates beyond the current iteration-3/4 plateau.'
Add-Line '- The validation pack is the next check after candidate selection: baseline control versus the best non-baseline candidate under a slightly longer horizon.'
Add-Line '- The focus-objective follow-up is the next bounded test if the goal is to improve the worst-period metric rather than average residual fit.'
Add-Line '- The focus-objective validation stage only runs if a completed focus-objective case actually beats the canonical control on max gap.'
Add-Line '- The lambda continuation workflow is the bounded next-step if we want RE intuition without another broad tuning sweep.'
Add-Line '- Rerun this script at any point to refresh the report in place.'
Add-Line ''

Set-Content -Path $reportPath -Value $lines
Write-Host "Wrote $reportPath"
