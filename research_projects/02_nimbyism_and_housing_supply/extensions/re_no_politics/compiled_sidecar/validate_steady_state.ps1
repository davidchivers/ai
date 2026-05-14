param(
    [string]$PackName = 'steady_state_p2_rb0_03'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dir = Join-Path $scriptDir ("truth\{0}" -f $PackName)

if (-not (Test-Path $dir)) {
    throw "Steady-state pack not found: $dir"
}

function Get-MaxAbsDiff([string]$PathA, [string]$PathB, [switch]$Integer) {
    $a = Get-Content $PathA
    $b = Get-Content $PathB
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

function Get-NamedScalarMap([string]$Path) {
    $rows = Import-Csv -Path $Path
    $map = @{}
    foreach ($row in $rows) {
        $map[$row.name] = [double]$row.value
    }
    return $map
}

$policyB = Get-MaxAbsDiff (Join-Path $dir 'matlab_age_policy_idx_b.csv') (Join-Path $dir 'sidecar_age_policy_idx_b.csv') -Integer
$policyA = Get-MaxAbsDiff (Join-Path $dir 'matlab_age_policy_idx_a.csv') (Join-Path $dir 'sidecar_age_policy_idx_a.csv') -Integer
$values = Get-MaxAbsDiff (Join-Path $dir 'matlab_age_valuefunctions.csv') (Join-Path $dir 'sidecar_age_valuefunctions.csv')
$dens4 = Get-MaxAbsDiff (Join-Path $dir 'matlab_dens4.csv') (Join-Path $dir 'sidecar_dens4.csv')

Write-Output ("age_policy_idx_b_diff_count={0}" -f $policyB.Count)
Write-Output ("age_policy_idx_a_diff_count={0}" -f $policyA.Count)
Write-Output ("age_valuefunctions_max_abs_diff={0}" -f $values.Max)
Write-Output ("dens4_max_abs_diff={0}" -f $dens4.Max)

$matlabSummary = Get-NamedScalarMap (Join-Path $dir 'matlab_summary.csv')
$sidecarSummary = Get-NamedScalarMap (Join-Path $dir 'sidecar_summary.csv')

foreach ($name in @('Hdemand', 'Hsupply', 'debtstock')) {
    $diff = [math]::Abs($matlabSummary[$name] - $sidecarSummary[$name])
    Write-Output ("{0}_max_abs_diff={1}" -f $name, $diff)
}
