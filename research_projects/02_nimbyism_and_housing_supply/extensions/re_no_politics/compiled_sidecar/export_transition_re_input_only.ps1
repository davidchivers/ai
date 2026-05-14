param(
    [string]$PackName = 'transition_re_t4_input_only',
    [int]$Horizon = 4,
    [double]$PriceLevel = 2.0,
    [string]$CandidateSelectionMode = 'global',
    [double]$FocusGapImprovementTol = 1.0e-4,
    [double]$FocusExcessImprovementTol = 1.0e-5,
    [double]$FocusResidualSlack = 2.0e-4,
    [string]$TransitionPolicyMode = 'full_backward',
    [double]$PolicyReferencePrice = 2.0,
    [string]$TerminalReferenceMode = 'fixed_price',
    [double]$TerminalReferencePrice = 2.0,
    [string]$PolicyReferenceMode = '',
    [double]$PolicyReferenceBlendWeight = [double]::NaN,
    [double]$PolicyReferencePriceFloor = [double]::NaN,
    [double]$PolicyReferencePriceCap = [double]::NaN,
    [string]$SolverProfile = 'bounded_candidate_search',
    [string]$InitialPricePathCsv = '',
    [string]$OuterIterationMode = '',
    [double]$FixedPointRelaxationWeight = [double]::NaN,
    [string]$FixedPointRelaxationSpace = '',
    [double]$FixedPointPriceMin = [double]::NaN,
    [double]$FixedPointPriceMax = [double]::NaN,
    [switch]$SaveCandidateHistory,
    [switch]$SavePeriodDetails
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$packDir = Join-Path $scriptDir ("truth\{0}" -f $PackName)
$invariant = [System.Globalization.CultureInfo]::InvariantCulture

function Format-Double([double]$Value) {
    return $Value.ToString("R", $script:invariant)
}

function Read-NumericCsvVector([string]$Path) {
    $values = New-Object System.Collections.Generic.List[double]
    foreach ($line in Get-Content -LiteralPath $Path) {
        foreach ($field in ($line -split ',')) {
            $trimmed = $field.Trim()
            if ($trimmed.Length -gt 0) {
                $values.Add([double]::Parse($trimmed, $script:invariant))
            }
        }
    }
    return ,$values.ToArray()
}

function Write-NamedScalarCsv([string]$Path, [object[]]$Rows) {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('name,value')
    foreach ($row in $Rows) {
        $lines.Add(('{0},{1}' -f $row[0], (Format-Double ([double]$row[1]))))
    }
    [System.IO.File]::WriteAllLines($Path, $lines)
}

function Write-NamedStringCsv([string]$Path, [object[]]$Rows) {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('name,value')
    foreach ($row in $Rows) {
        $lines.Add(('{0},{1}' -f $row[0], [string]$row[1]))
    }
    [System.IO.File]::WriteAllLines($Path, $lines)
}

function Write-VectorCsv([string]$Path, [double[]]$Values) {
    $lines = foreach ($value in $Values) { Format-Double $value }
    [System.IO.File]::WriteAllLines($Path, $lines)
}

function Get-ProfileDefaults(
    [string]$Profile,
    [string]$CandidateSelectionMode,
    [double]$FocusGapImprovementTol,
    [double]$FocusExcessImprovementTol,
    [double]$FocusResidualSlack
) {
    $defaults = [ordered]@{
        candidate_selection_mode = $CandidateSelectionMode
        focus_gap_improvement_tol = $FocusGapImprovementTol
        focus_excess_improvement_tol = $FocusExcessImprovementTol
        focus_residual_slack = $FocusResidualSlack
        sequential_return_endpoint = 0.0
        save_candidate_history = 0.0
        save_period_details = 0.0
    }

    switch ($Profile.ToLowerInvariant()) {
        'frontier_fertility_style' {
            $defaults.max_iter = 25.0
            $defaults.tol = 1.0e-4
            $defaults.damping = 0.25
            $defaults.max_update_frac = 0.10
            $defaults.smoothing_weight = 5.0
            $defaults.terminal_anchor_weight = 0.50
            $defaults.fixed_point_relaxation_weight = 0.10
            $defaults.fixed_point_relaxation_space = 'log'
            $defaults.fixed_point_price_min = 0.40
            $defaults.fixed_point_price_max = 5.00
            $defaults.targeted_correction_weight = 0.35
            $defaults.max_targeted_periods = 3.0
            $defaults.target_block_half_width = 1.0
            $defaults.sequential_block_size = 3.0
            $defaults.block_sweep_passes = 2.0
            $defaults.max_blocks_per_pass = 4.0
            $defaults.greedy_block_accept = 1.0
            $defaults.candidate_improvement_tol = 1.0e-6
            $defaults.candidate_gap_improvement_tol = 1.0e-6
            $defaults.candidate_residual_slack = 5.0e-5
            $defaults.update_scheme = 'sequential_blocks'
            $defaults.outer_iteration_mode = 'fertility_style'
            $defaults.line_search_scales = @(0.01, 0.02, 0.05)
        }
        'bounded_candidate_search' {
            $defaults.max_iter = 3.0
            $defaults.tol = 1.0e-3
            $defaults.damping = 0.25
            $defaults.max_update_frac = 0.10
            $defaults.smoothing_weight = 5.0
            $defaults.terminal_anchor_weight = 0.50
            $defaults.fixed_point_relaxation_weight = 0.40
            $defaults.fixed_point_relaxation_space = 'level'
            $defaults.fixed_point_price_min = 0.40
            $defaults.fixed_point_price_max = 5.00
            $defaults.targeted_correction_weight = 0.35
            $defaults.max_targeted_periods = 3.0
            $defaults.target_block_half_width = 1.0
            $defaults.sequential_block_size = 3.0
            $defaults.block_sweep_passes = 2.0
            $defaults.max_blocks_per_pass = 4.0
            $defaults.greedy_block_accept = 1.0
            $defaults.candidate_improvement_tol = 1.0e-6
            $defaults.candidate_gap_improvement_tol = 1.0e-6
            $defaults.candidate_residual_slack = 5.0e-5
            $defaults.update_scheme = 'sequential_blocks'
            $defaults.outer_iteration_mode = 'candidate_search'
            $defaults.line_search_scales = @(0.01, 0.02, 0.05, 0.10)
        }
        default {
            throw "Unsupported SolverProfile: $Profile"
        }
    }

    return $defaults
}

$profile = Get-ProfileDefaults `
    -Profile $SolverProfile `
    -CandidateSelectionMode $CandidateSelectionMode `
    -FocusGapImprovementTol $FocusGapImprovementTol `
    -FocusExcessImprovementTol $FocusExcessImprovementTol `
    -FocusResidualSlack $FocusResidualSlack

if ($OuterIterationMode) {
    $profile.outer_iteration_mode = $OuterIterationMode
}
if (-not [double]::IsNaN($FixedPointRelaxationWeight)) {
    $profile.fixed_point_relaxation_weight = $FixedPointRelaxationWeight
}
if ($FixedPointRelaxationSpace) {
    $profile.fixed_point_relaxation_space = $FixedPointRelaxationSpace
}
if (-not [double]::IsNaN($FixedPointPriceMin)) {
    $profile.fixed_point_price_min = $FixedPointPriceMin
}
if (-not [double]::IsNaN($FixedPointPriceMax)) {
    $profile.fixed_point_price_max = $FixedPointPriceMax
}
$profile.save_candidate_history = if ($SaveCandidateHistory) { 1.0 } else { 0.0 }
$profile.save_period_details = if ($SavePeriodDetails) { 1.0 } else { 0.0 }

$initialPricePath = if ($InitialPricePathCsv) {
    Read-NumericCsvVector $InitialPricePathCsv
} else {
    @(for ($i = 0; $i -lt $Horizon; $i++) { $PriceLevel })
}
if ($initialPricePath.Count -ne $Horizon) {
    throw "Initial price path length $($initialPricePath.Count) does not match Horizon $Horizon."
}

& (Join-Path $scriptDir 'export_transition_pass_input.ps1') `
    -PackName $PackName `
    -Horizon $Horizon `
    -PriceLevel $PriceLevel `
    -TransitionPolicyMode $TransitionPolicyMode `
    -PolicyReferencePrice $PolicyReferencePrice `
    -TerminalReferenceMode $TerminalReferenceMode `
    -TerminalReferencePrice $TerminalReferencePrice `
    -PolicyReferenceMode $PolicyReferenceMode `
    -PolicyReferenceBlendWeight $PolicyReferenceBlendWeight `
    -PolicyReferencePriceFloor $PolicyReferencePriceFloor `
    -PolicyReferencePriceCap $PolicyReferencePriceCap `
    -SavePeriodDetails:$SavePeriodDetails `
    -PricePathCsv $InitialPricePathCsv

if (-not (Test-Path -LiteralPath $packDir)) {
    throw "Transition-pass pack was not created: $packDir"
}

$scalarRows = @(
    @('max_iter', $profile.max_iter),
    @('tol', $profile.tol),
    @('damping', $profile.damping),
    @('max_update_frac', $profile.max_update_frac),
    @('smoothing_weight', $profile.smoothing_weight),
    @('terminal_anchor_weight', $profile.terminal_anchor_weight),
    @('fixed_point_relaxation_weight', $profile.fixed_point_relaxation_weight),
    @('fixed_point_price_min', $profile.fixed_point_price_min),
    @('fixed_point_price_max', $profile.fixed_point_price_max),
    @('targeted_correction_weight', $profile.targeted_correction_weight),
    @('max_targeted_periods', $profile.max_targeted_periods),
    @('target_block_half_width', $profile.target_block_half_width),
    @('sequential_block_size', $profile.sequential_block_size),
    @('block_sweep_passes', $profile.block_sweep_passes),
    @('max_blocks_per_pass', $profile.max_blocks_per_pass),
    @('greedy_block_accept', $profile.greedy_block_accept),
    @('candidate_improvement_tol', $profile.candidate_improvement_tol),
    @('candidate_gap_improvement_tol', $profile.candidate_gap_improvement_tol),
    @('candidate_residual_slack', $profile.candidate_residual_slack),
    @('focus_gap_improvement_tol', $profile.focus_gap_improvement_tol),
    @('focus_excess_improvement_tol', $profile.focus_excess_improvement_tol),
    @('focus_residual_slack', $profile.focus_residual_slack),
    @('sequential_return_endpoint', $profile.sequential_return_endpoint),
    @('save_candidate_history', $profile.save_candidate_history),
    @('save_period_details', $profile.save_period_details)
)

$stringRows = @(
    @('candidate_selection_mode', [string]$profile.candidate_selection_mode),
    @('update_scheme', [string]$profile.update_scheme),
    @('outer_iteration_mode', [string]$profile.outer_iteration_mode),
    @('fixed_point_relaxation_space', [string]$profile.fixed_point_relaxation_space)
)

Write-NamedScalarCsv (Join-Path $packDir 're_params_scalars.csv') $scalarRows
Write-NamedStringCsv (Join-Path $packDir 're_params_strings.csv') $stringRows
Write-VectorCsv (Join-Path $packDir 'line_search_scales.csv') ([double[]]$profile.line_search_scales)
Write-VectorCsv (Join-Path $packDir 're_initial_price_path.csv') ([double[]]$initialPricePath)

Write-Output "Exported transition-RE input-only pack: $packDir"
Write-Output ("  solver_profile={0}" -f $SolverProfile)
Write-Output ("  horizon={0}" -f $Horizon)
Write-Output ("  transition_policy_mode={0}" -f $TransitionPolicyMode)
Write-Output ("  policy_reference_mode={0}" -f $PolicyReferenceMode)
