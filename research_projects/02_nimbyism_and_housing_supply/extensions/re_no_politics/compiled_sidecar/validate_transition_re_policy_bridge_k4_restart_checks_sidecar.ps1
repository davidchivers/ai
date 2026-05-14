param(
    [ValidateSet('0.15','0.20')]
    [string]$Alpha = '0.15',
    [string]$SidecarDir,
    [switch]$RunCli,
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$extensionDir = Split-Path $scriptDir -Parent
$alphaTag = $Alpha.Replace('.', '_')

switch ($Alpha) {
    '0.15' {
        $matlabSummaryPath = Join-Path $extensionDir 'transition_re_policy_bridge_alpha_0_15_k4_restart_checks.csv'
    }
    '0.20' {
        $matlabSummaryPath = Join-Path $extensionDir 'transition_re_policy_bridge_alpha_0_20_k4_restart_checks.csv'
    }
    default {
        throw "Unsupported alpha: $Alpha"
    }
}

if (-not $SidecarDir) {
    $SidecarDir = Join-Path $scriptDir ("truth\transition_re_policy_bridge_k4_restart_checks_sidecar_alpha_{0}" -f $alphaTag)
}

if ($RunCli -or -not (Test-Path (Join-Path $SidecarDir 'sidecar_case_sweep_summary.csv'))) {
    if (Test-Path $SidecarDir) {
        Remove-Item -Recurse -Force $SidecarDir
    }
    & (Join-Path $scriptDir 'run_transition_re_policy_bridge_k4_restart_checks_sidecar.ps1') `
        -Alpha $Alpha `
        -OutputDir $SidecarDir `
        -SkipBuild:$SkipBuild
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

function Compare-CaseTables([string]$MatlabPath, [string]$SidecarPath, [string[]]$KeyColumns, [hashtable]$ColumnMap, [string[]]$NumericColumns, [string[]]$StringColumns) {
    $matlabRows = @{}
    foreach ($row in (Import-Csv $MatlabPath)) {
        $key = (($KeyColumns | ForEach-Object { [string]$row.$_ }) -join '|')
        $matlabRows[$key] = $row
    }
    $sidecarRows = @{}
    foreach ($row in (Import-Csv $SidecarPath)) {
        $key = (($KeyColumns | ForEach-Object { [string]$row.$_ }) -join '|')
        $sidecarRows[$key] = $row
    }

    if ($matlabRows.Count -ne $sidecarRows.Count) {
        throw "Case-count mismatch between $MatlabPath and $SidecarPath"
    }

    $missing = Compare-Object ($matlabRows.Keys | Sort-Object) ($sidecarRows.Keys | Sort-Object)
    if ($missing) {
        throw "Case-name mismatch between $MatlabPath and $SidecarPath"
    }

    $maxNumericDiff = 0.0
    $stringMismatch = 0
    foreach ($rowKey in ($matlabRows.Keys | Sort-Object)) {
        $matlabRow = $matlabRows[$rowKey]
        $sidecarRow = $sidecarRows[$rowKey]
        foreach ($column in $NumericColumns) {
            $sidecarColumn = if ($ColumnMap.ContainsKey($column)) { $ColumnMap[$column] } else { $column }
            $diff = Get-NumericDiff $matlabRow.$column $sidecarRow.$sidecarColumn
            if ($diff -gt $maxNumericDiff) {
                $maxNumericDiff = $diff
            }
        }
        foreach ($column in $StringColumns) {
            $sidecarColumn = if ($ColumnMap.ContainsKey($column)) { $ColumnMap[$column] } else { $column }
            if ([string]$matlabRow.$column -ne [string]$sidecarRow.$sidecarColumn) {
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

$numericColumns = @(
    'max_iter',
    'looks_stable',
    'converged',
    'iterations_completed',
    'residual_norm',
    'max_abs_gap',
    'final_price_4',
    'implied_price_4'
)
$stringColumns = @('guess_source')
$columnMap = @{
    final_price_4 = 'final_price_4'
    implied_price_4 = 'implied_price_4'
}

$metrics = Compare-CaseTables `
    $matlabSummaryPath `
    (Join-Path $SidecarDir 'sidecar_case_sweep_summary.csv') `
    @('case_name') `
    $columnMap `
    $numericColumns `
    $stringColumns

$tol = 1e-6

Write-Output ("NIMBY k=4 restart-check sidecar validation alpha={0}" -f $Alpha)
Write-Output ("  cases={0}" -f $metrics.RowCount)
Write-Output ("  summary_max_numeric_diff={0}" -f $metrics.MaxNumericDiff)
Write-Output ("  summary_string_mismatch={0}" -f $metrics.StringMismatch)

if ($metrics.MaxNumericDiff -gt $tol -or $metrics.StringMismatch -ne 0) {
    throw "Restart-check sidecar validation failed."
}
