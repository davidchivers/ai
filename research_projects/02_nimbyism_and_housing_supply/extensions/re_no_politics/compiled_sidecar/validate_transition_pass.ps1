param(
    [string]$PackName = 'transition_pass_t4_diag'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dir = Join-Path $scriptDir ("truth\{0}" -f $PackName)

if (-not (Test-Path $dir)) {
    throw "Transition-pass pack not found: $dir"
}

function Get-MaxAbsDiff([string]$PathA, [string]$PathB, [switch]$Integer) {
    $a = @(Get-Content $PathA)
    $b = @(Get-Content $PathB)
    if ($a.Count -ne $b.Count) {
        throw "Length mismatch between $PathA and $PathB"
    }

    $max = 0.0
    $count = 0
    for ($i = 0; $i -lt $a.Count; $i++) {
        if ($Integer) {
            $d = [math]::Abs([int]$a[$i] - [int]$b[$i])
            if ($d -ne 0) { $count++ }
        } else {
            $d = [math]::Abs([double]$a[$i] - [double]$b[$i])
        }
        if ($d -gt $max) { $max = $d }
    }

    return [pscustomobject]@{
        Max = $max
        Count = $count
    }
}

$policyB = Get-MaxAbsDiff (Join-Path $dir 'matlab_policy_idx_b.csv') (Join-Path $dir 'sidecar_policy_idx_b.csv') -Integer
$policyA = Get-MaxAbsDiff (Join-Path $dir 'matlab_policy_idx_a.csv') (Join-Path $dir 'sidecar_policy_idx_a.csv') -Integer
$values = Get-MaxAbsDiff (Join-Path $dir 'matlab_valuefunctions.csv') (Join-Path $dir 'sidecar_valuefunctions.csv')

Write-Output ("policy_idx_b_diff_count={0}" -f $policyB.Count)
Write-Output ("policy_idx_a_diff_count={0}" -f $policyA.Count)
Write-Output ("valuefunctions_max_abs_diff={0}" -f $values.Max)

foreach ($name in @('Hdemand_path', 'Hsupply_guess_path', 'excess_demand_guess_path', 'implied_price_path', 'log_price_residual_raw', 'debt_path', 'rent_share_path')) {
    $diff = Get-MaxAbsDiff (Join-Path $dir ("matlab_{0}.csv" -f $name)) (Join-Path $dir ("sidecar_{0}.csv" -f $name))
    Write-Output ("{0}_max_abs_diff={1}" -f $name, $diff.Max)
}

$matlabPolicyReferencePath = Join-Path $dir 'matlab_policy_reference_price_path_used.csv'
$sidecarPolicyReferencePath = Join-Path $dir 'sidecar_policy_reference_price_path_used.csv'
if ((Test-Path $matlabPolicyReferencePath) -and (Test-Path $sidecarPolicyReferencePath)) {
    $diff = Get-MaxAbsDiff $matlabPolicyReferencePath $sidecarPolicyReferencePath
    Write-Output ("policy_reference_price_path_used_max_abs_diff={0}" -f $diff.Max)
} elseif ((Test-Path $matlabPolicyReferencePath) -or (Test-Path $sidecarPolicyReferencePath)) {
    throw "policy_reference_price_path_used file presence mismatch in $dir"
}

$matlabTerminalReferencePath = Join-Path $dir 'matlab_terminal_reference_price_used.csv'
$sidecarTerminalReferencePath = Join-Path $dir 'sidecar_terminal_reference_price_used.csv'
if ((Test-Path $matlabTerminalReferencePath) -and (Test-Path $sidecarTerminalReferencePath)) {
    $diff = Get-MaxAbsDiff $matlabTerminalReferencePath $sidecarTerminalReferencePath
    Write-Output ("terminal_reference_price_used_max_abs_diff={0}" -f $diff.Max)
} elseif ((Test-Path $matlabTerminalReferencePath) -or (Test-Path $sidecarTerminalReferencePath)) {
    throw "terminal_reference_price_used file presence mismatch in $dir"
}

$matlabDensityPath = Join-Path $dir 'matlab_density_by_period_age.csv'
$sidecarDensityPath = Join-Path $dir 'sidecar_density_by_period_age.csv'
if ((Test-Path $matlabDensityPath) -and (Test-Path $sidecarDensityPath)) {
    $density = Get-MaxAbsDiff $matlabDensityPath $sidecarDensityPath
    Write-Output ("density_by_period_age_max_abs_diff={0}" -f $density.Max)
} elseif ((Test-Path $matlabDensityPath) -or (Test-Path $sidecarDensityPath)) {
    throw "density_by_period_age file presence mismatch in $dir"
}

foreach ($name in @(
    'equal_weight_vote_path',
    'weighted_vote_path',
    'weighted_vote_share_path',
    'equal_weight_distance_path',
    'weighted_distance_path',
    'owner_share_path',
    'old_owner_share_path',
    'leveraged_owner_share_path'
)) {
    $matlabPath = Join-Path $dir ("matlab_{0}.csv" -f $name)
    $sidecarPath = Join-Path $dir ("sidecar_{0}.csv" -f $name)
    if ((Test-Path $matlabPath) -and (Test-Path $sidecarPath)) {
        $diff = Get-MaxAbsDiff $matlabPath $sidecarPath
        Write-Output ("{0}_max_abs_diff={1}" -f $name, $diff.Max)
    } elseif ((Test-Path $matlabPath) -or (Test-Path $sidecarPath)) {
        throw "$name file presence mismatch in $dir"
    }
}
