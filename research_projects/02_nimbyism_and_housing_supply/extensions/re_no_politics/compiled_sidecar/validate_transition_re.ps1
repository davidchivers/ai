param(
    [string]$PackName = 'transition_re_t4_fixed_terminal',
    [string]$SidecarDir,
    [switch]$RunCli,
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$packDir = Join-Path $scriptDir ("truth\{0}" -f $PackName)

if (-not (Test-Path $packDir)) {
    throw "Transition-RE pack not found: $packDir"
}

if (-not $SidecarDir) {
    if ($RunCli) {
        $SidecarDir = Join-Path $env:TEMP ("nimby_transition_re_validate_{0}" -f $PackName)
    } else {
        $SidecarDir = $packDir
    }
}

if ($RunCli -or -not (Test-Path (Join-Path $SidecarDir 'sidecar_re_summary.csv'))) {
    if (Test-Path $SidecarDir) {
        Remove-Item -Recurse -Force $SidecarDir
    }
    & (Join-Path $scriptDir 'run_transition_re_cli.ps1') -PackName $PackName -OutputDir $SidecarDir -SkipBuild:$SkipBuild
}

function Get-MaxAbsDiff([string]$PathA, [string]$PathB) {
    function Get-NumericTokens([string]$Path) {
        $tokens = New-Object System.Collections.Generic.List[string]
        foreach ($line in Get-Content $Path) {
            foreach ($part in ($line -split ',')) {
                $trimmed = $part.Trim()
                if ($trimmed.Length -gt 0) {
                    $tokens.Add($trimmed)
                }
            }
        }
        return $tokens
    }

    $a = Get-NumericTokens $PathA
    $b = Get-NumericTokens $PathB
    if ($a.Count -ne $b.Count) {
        throw "Length mismatch between $PathA and $PathB"
    }

    $max = 0.0
    for ($i = 0; $i -lt $a.Count; $i++) {
        $d = [math]::Abs([double]$a[$i] - [double]$b[$i])
        if ($d -gt $max) { $max = $d }
    }
    return $max
}

function Get-SummaryMap([string]$Path) {
    $rows = Import-Csv $Path
    $map = @{}
    foreach ($row in $rows) {
        $map[$row.name] = $row.value
    }
    return $map
}

function Get-IterationLogMetrics([string]$MatlabPath, [string]$SidecarPath) {
    $matlab = Import-Csv $MatlabPath
    $sidecar = Import-Csv $SidecarPath
    if ($matlab.Count -ne $sidecar.Count) {
        throw "Iteration-log length mismatch between $MatlabPath and $SidecarPath"
    }

    $residualMax = 0.0
    $gapMax = 0.0
    $updateMax = 0.0
    $labelMismatch = 0

    for ($i = 0; $i -lt $matlab.Count; $i++) {
        $residualMax = [math]::Max($residualMax, [math]::Abs([double]$matlab[$i].residual_norm - [double]$sidecar[$i].residual_norm))
        $gapMax = [math]::Max($gapMax, [math]::Abs([double]$matlab[$i].max_abs_gap - [double]$sidecar[$i].max_abs_gap))
        $updateMax = [math]::Max($updateMax, [math]::Abs([double]$matlab[$i].max_abs_update - [double]$sidecar[$i].max_abs_update))
        if ([string]$matlab[$i].accepted_update -ne [string]$sidecar[$i].accepted_update) {
            $labelMismatch++
        }
    }

    return [pscustomobject]@{
        ResidualMax = $residualMax
        GapMax = $gapMax
        UpdateMax = $updateMax
        LabelMismatch = $labelMismatch
    }
}

function Get-NumericDiff($LeftValue, $RightValue) {
    $leftMissing = [string]::IsNullOrWhiteSpace([string]$LeftValue)
    $rightMissing = [string]::IsNullOrWhiteSpace([string]$RightValue)
    if ($leftMissing -and $rightMissing) {
        return 0.0
    }
    if ($leftMissing -or $rightMissing) {
        return [double]::PositiveInfinity
    }

    $left = [double]$LeftValue
    $right = [double]$RightValue
    if ([double]::IsNaN($left) -and [double]::IsNaN($right)) {
        return 0.0
    }
    if ([double]::IsNaN($left) -or [double]::IsNaN($right)) {
        return [double]::PositiveInfinity
    }
    return [math]::Abs($left - $right)
}

function Compare-CsvTables([string]$MatlabPath, [string]$SidecarPath, [string[]]$NumericColumns, [string[]]$StringColumns) {
    $matlabRows = @(Import-Csv $MatlabPath)
    $sidecarRows = @(Import-Csv $SidecarPath)
    if ($matlabRows.Count -ne $sidecarRows.Count) {
        throw "CSV row-count mismatch between $MatlabPath and $SidecarPath"
    }

    $maxNumericDiff = 0.0
    $stringMismatch = 0
    for ($i = 0; $i -lt $matlabRows.Count; $i++) {
        foreach ($column in $NumericColumns) {
            $diff = Get-NumericDiff $matlabRows[$i].$column $sidecarRows[$i].$column
            if ($diff -gt $maxNumericDiff) {
                $maxNumericDiff = $diff
            }
        }
        foreach ($column in $StringColumns) {
            if ([string]$matlabRows[$i].$column -ne [string]$sidecarRows[$i].$column) {
                $stringMismatch++
            }
        }
    }

    return [pscustomobject]@{
        RowCount = $matlabRows.Count
        MaxNumericDiff = $maxNumericDiff
        StringMismatch = $stringMismatch
    }
}

$summaryTol = 1e-9
$pathTol = 1e-9
$iterTol = 1e-9

$summaryMatlab = Get-SummaryMap (Join-Path $packDir 'matlab_re_summary.csv')
$summarySidecar = Get-SummaryMap (Join-Path $SidecarDir 'sidecar_re_summary.csv')

$summaryDiffs = [pscustomobject]@{
    converged_match = ([string]$summaryMatlab['converged'] -eq [string]$summarySidecar['converged'])
    iterations_diff = [math]::Abs([double]$summaryMatlab['iterations'] - [double]$summarySidecar['iterations'])
    final_label_available = $summaryMatlab.ContainsKey('final_label')
    final_label_match = ((-not $summaryMatlab.ContainsKey('final_label')) -or ([string]$summaryMatlab['final_label'] -eq [string]$summarySidecar['final_label']))
    final_max_abs_gap_diff = [math]::Abs([double]$summaryMatlab['final_max_abs_gap'] - [double]$summarySidecar['final_max_abs_gap'])
    final_residual_norm_diff = [math]::Abs([double]$summaryMatlab['final_residual_norm'] - [double]$summarySidecar['final_residual_norm'])
}

$paths = @(
    'final_price_path',
    'implied_price_path',
    'Hdemand_path',
    'Hsupply_path',
    'excess_demand_path',
    'log_price_residual_raw'
)

$pathDiffs = @{}
foreach ($name in $paths) {
    $pathDiffs[$name] = Get-MaxAbsDiff `
        (Join-Path $packDir ("matlab_re_{0}.csv" -f $name)) `
        (Join-Path $SidecarDir ("sidecar_re_{0}.csv" -f $name))
}

$densityDiff = $null
$matlabDensityPath = Join-Path $packDir 'matlab_re_density_by_period_age.csv'
$sidecarDensityPath = Join-Path $SidecarDir 'sidecar_re_density_by_period_age.csv'
if ((Test-Path $matlabDensityPath) -or (Test-Path $sidecarDensityPath)) {
    if (-not ((Test-Path $matlabDensityPath) -and (Test-Path $sidecarDensityPath))) {
        throw "RE density_by_period_age file presence mismatch between $packDir and $SidecarDir"
    }
    $densityDiff = Get-MaxAbsDiff $matlabDensityPath $sidecarDensityPath
}

$iterationCurrentDiff = $null
$iterationImpliedDiff = $null
$iterationSelectedDiff = $null

$matlabIterationCurrentPath = Join-Path $packDir 'matlab_re_iteration_current_price_paths.csv'
$sidecarIterationCurrentPath = Join-Path $SidecarDir 'sidecar_re_iteration_current_price_paths.csv'
if ((Test-Path $matlabIterationCurrentPath) -and (Test-Path $sidecarIterationCurrentPath)) {
    $iterationCurrentDiff = Get-MaxAbsDiff $matlabIterationCurrentPath $sidecarIterationCurrentPath
}

$matlabIterationImpliedPath = Join-Path $packDir 'matlab_re_iteration_implied_price_paths.csv'
$sidecarIterationImpliedPath = Join-Path $SidecarDir 'sidecar_re_iteration_implied_price_paths.csv'
if ((Test-Path $matlabIterationImpliedPath) -and (Test-Path $sidecarIterationImpliedPath)) {
    $iterationImpliedDiff = Get-MaxAbsDiff $matlabIterationImpliedPath $sidecarIterationImpliedPath
}

$matlabIterationSelectedPath = Join-Path $packDir 'matlab_re_iteration_selected_price_paths.csv'
$sidecarIterationSelectedPath = Join-Path $SidecarDir 'sidecar_re_iteration_selected_price_paths.csv'
if ((Test-Path $matlabIterationSelectedPath) -and (Test-Path $sidecarIterationSelectedPath)) {
    $iterationSelectedDiff = Get-MaxAbsDiff $matlabIterationSelectedPath $sidecarIterationSelectedPath
}

$iterDiffs = Get-IterationLogMetrics `
    (Join-Path $packDir 'matlab_re_iteration_log.csv') `
    (Join-Path $SidecarDir 'sidecar_re_iteration_log.csv')

$selectionIterationMetrics = $null
$selectionPassMetrics = $null
$selectionCandidateMetrics = $null

$matlabSelectionIterationPath = Join-Path $packDir 'matlab_re_selection_iterations.csv'
$sidecarSelectionIterationPath = Join-Path $SidecarDir 'sidecar_re_selection_iterations.csv'
$matlabSelectionPassPath = Join-Path $packDir 'matlab_re_selection_passes.csv'
$sidecarSelectionPassPath = Join-Path $SidecarDir 'sidecar_re_selection_passes.csv'
$matlabSelectionCandidatePath = Join-Path $packDir 'matlab_re_selection_candidates.csv'
$sidecarSelectionCandidatePath = Join-Path $SidecarDir 'sidecar_re_selection_candidates.csv'

$hasMatlabSelectionDiagnostics =
    (Test-Path $matlabSelectionIterationPath) -and
    (Test-Path $matlabSelectionPassPath) -and
    (Test-Path $matlabSelectionCandidatePath)
$hasSidecarSelectionDiagnostics =
    (Test-Path $sidecarSelectionIterationPath) -and
    (Test-Path $sidecarSelectionPassPath) -and
    (Test-Path $sidecarSelectionCandidatePath)

if ($hasMatlabSelectionDiagnostics -ne $hasSidecarSelectionDiagnostics) {
    if ($hasMatlabSelectionDiagnostics) {
        throw "Selection-diagnostics file presence mismatch between $packDir and $SidecarDir"
    }
}

if ($hasMatlabSelectionDiagnostics) {
    $selectionIterationMetrics = Compare-CsvTables `
        $matlabSelectionIterationPath `
        $sidecarSelectionIterationPath `
        @('iteration', 'current_residual_norm', 'current_max_abs_gap', 'has_sequential', 'sequential_final_residual_norm', 'sequential_final_max_abs_gap', 'final_residual_norm', 'final_max_abs_gap') `
        @('candidate_selection_mode', 'current_label', 'targeted_periods', 'targeted_blocks', 'sequential_selection_mode', 'sequential_start_label', 'sequential_final_label', 'final_selected_label')
    $selectionPassMetrics = Compare-CsvTables `
        $matlabSelectionPassPath `
        $sidecarSelectionPassPath `
        @('iteration', 'pass', 'selected_residual_norm', 'selected_max_abs_gap', 'accepted_in_pass') `
        @('start_label', 'focus_periods', 'targeted_periods', 'targeted_blocks', 'block_starts', 'selected_label', 'greedy_accept_label')
    $selectionCandidateMetrics = Compare-CsvTables `
        $matlabSelectionCandidatePath `
        $sidecarSelectionCandidatePath `
        @('iteration', 'pass', 'block_start', 'block_stop', 'scale', 'candidate_residual_norm', 'candidate_max_abs_gap', 'candidate_focus_gap', 'candidate_focus_excess', 'incumbent_residual_norm', 'incumbent_max_abs_gap', 'incumbent_focus_gap', 'incumbent_focus_excess', 'wins_focus', 'wins_global', 'wins_sequential', 'greedy_global', 'greedy_sequential', 'became_best', 'accepted_greedily') `
        @('stage', 'candidate_label', 'incumbent_label', 'focus_periods', 'selection_reason', 'greedy_reason')
}

Write-Output ("summary_converged_match={0}" -f [int]$summaryDiffs.converged_match)
Write-Output ("summary_iterations_diff={0}" -f $summaryDiffs.iterations_diff)
Write-Output ("summary_final_label_available={0}" -f [int]$summaryDiffs.final_label_available)
Write-Output ("summary_final_label_match={0}" -f [int]$summaryDiffs.final_label_match)
Write-Output ("summary_final_max_abs_gap_diff={0}" -f $summaryDiffs.final_max_abs_gap_diff)
Write-Output ("summary_final_residual_norm_diff={0}" -f $summaryDiffs.final_residual_norm_diff)

foreach ($name in $paths) {
    Write-Output ("{0}_max_abs_diff={1}" -f $name, $pathDiffs[$name])
}
if ($densityDiff) {
    Write-Output ("density_by_period_age_max_abs_diff={0}" -f $densityDiff)
}
if ($null -ne $iterationCurrentDiff) {
    Write-Output ("iteration_current_price_paths_max_abs_diff={0}" -f $iterationCurrentDiff)
}
if ($null -ne $iterationImpliedDiff) {
    Write-Output ("iteration_implied_price_paths_max_abs_diff={0}" -f $iterationImpliedDiff)
}
if ($null -ne $iterationSelectedDiff) {
    Write-Output ("iteration_selected_price_paths_max_abs_diff={0}" -f $iterationSelectedDiff)
}

Write-Output ("iteration_residual_norm_max_abs_diff={0}" -f $iterDiffs.ResidualMax)
Write-Output ("iteration_max_abs_gap_max_abs_diff={0}" -f $iterDiffs.GapMax)
Write-Output ("iteration_max_abs_update_max_abs_diff={0}" -f $iterDiffs.UpdateMax)
Write-Output ("iteration_label_mismatch_count={0}" -f $iterDiffs.LabelMismatch)

if ($hasMatlabSelectionDiagnostics) {
    Write-Output ("selection_iterations_row_count={0}" -f $selectionIterationMetrics.RowCount)
    Write-Output ("selection_iterations_max_numeric_diff={0}" -f $selectionIterationMetrics.MaxNumericDiff)
    Write-Output ("selection_iterations_string_mismatch_count={0}" -f $selectionIterationMetrics.StringMismatch)
    Write-Output ("selection_passes_row_count={0}" -f $selectionPassMetrics.RowCount)
    Write-Output ("selection_passes_max_numeric_diff={0}" -f $selectionPassMetrics.MaxNumericDiff)
    Write-Output ("selection_passes_string_mismatch_count={0}" -f $selectionPassMetrics.StringMismatch)
    Write-Output ("selection_candidates_row_count={0}" -f $selectionCandidateMetrics.RowCount)
    Write-Output ("selection_candidates_max_numeric_diff={0}" -f $selectionCandidateMetrics.MaxNumericDiff)
    Write-Output ("selection_candidates_string_mismatch_count={0}" -f $selectionCandidateMetrics.StringMismatch)
}

$pathDiffMax = ($pathDiffs.Values | Measure-Object -Maximum).Maximum
$passed =
    $summaryDiffs.converged_match -and
    $summaryDiffs.final_label_match -and
    ($summaryDiffs.iterations_diff -le $summaryTol) -and
    ($summaryDiffs.final_max_abs_gap_diff -le $summaryTol) -and
    ($summaryDiffs.final_residual_norm_diff -le $summaryTol) -and
    ($pathDiffMax -le $pathTol) -and
    (($null -eq $densityDiff) -or ($densityDiff -le $pathTol)) -and
    (($null -eq $iterationCurrentDiff) -or ($iterationCurrentDiff -le $pathTol)) -and
    (($null -eq $iterationImpliedDiff) -or ($iterationImpliedDiff -le $pathTol)) -and
    (($null -eq $iterationSelectedDiff) -or ($iterationSelectedDiff -le $pathTol)) -and
    ($iterDiffs.ResidualMax -le $iterTol) -and
    ($iterDiffs.GapMax -le $iterTol) -and
    ($iterDiffs.UpdateMax -le $iterTol) -and
    ($iterDiffs.LabelMismatch -eq 0)

if ($hasMatlabSelectionDiagnostics) {
    $passed = $passed -and
        ($selectionIterationMetrics.MaxNumericDiff -le $iterTol) -and
        ($selectionIterationMetrics.StringMismatch -eq 0) -and
        ($selectionPassMetrics.MaxNumericDiff -le $iterTol) -and
        ($selectionPassMetrics.StringMismatch -eq 0) -and
        ($selectionCandidateMetrics.MaxNumericDiff -le $iterTol) -and
        ($selectionCandidateMetrics.StringMismatch -eq 0)
}

if (-not $passed) {
    throw "Transition-RE validation failed for $PackName"
}

Write-Output ("transition_re_validation=PASS")
