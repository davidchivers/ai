param(
    [string]$SidecarDir,
    [switch]$RunCli,
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$extensionDir = Split-Path $scriptDir -Parent
$matlabSummaryPath = Join-Path $extensionDir 'transition_re_policy_bridge_k4_warm_start_diagnostics_summary.csv'
$matlabPathsPath = Join-Path $extensionDir 'transition_re_policy_bridge_k4_warm_start_diagnostics_paths.csv'

if (-not $SidecarDir) {
    $SidecarDir = Join-Path $scriptDir 'truth\transition_re_policy_bridge_k4_warm_start_sidecar_alpha_0_14'
}

if ($RunCli -or -not (Test-Path (Join-Path $SidecarDir 'sidecar_case_sweep_summary.csv'))) {
    if (Test-Path $SidecarDir) {
        Remove-Item -Recurse -Force $SidecarDir
    }
    & (Join-Path $scriptDir 'run_transition_re_policy_bridge_k4_warm_start_sidecar.ps1') -OutputDir $SidecarDir -SkipBuild:$SkipBuild
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

function Compare-CaseTables([string]$MatlabPath, [string]$SidecarPath, [string[]]$KeyColumns, [string[]]$NumericColumns, [string[]]$StringColumns) {
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
            $diff = Get-NumericDiff $matlabRow.$column $sidecarRow.$column
            if ($diff -gt $maxNumericDiff) {
                $maxNumericDiff = $diff
            }
        }
        foreach ($column in $StringColumns) {
            if ([string]$matlabRow.$column -ne [string]$sidecarRow.$column) {
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

$numericSummaryColumns = @(
    'alpha','k','max_iter','iterations_completed','converged','looks_stable',
    'residual_norm','max_abs_gap','max_abs_update',
    'price_min','price_max','path_span',
    'policy_reference_price_first_used','policy_reference_price_last_used',
    'start_price_1','start_price_2','start_price_3','start_price_4',
    'final_price_1','final_price_2','final_price_3','final_price_4',
    'implied_price_1','implied_price_2','implied_price_3','implied_price_4'
)
$stringSummaryColumns = @('guess_source','status','accepted_update')

$summaryMetrics = Compare-CaseTables `
    $matlabSummaryPath `
    (Join-Path $SidecarDir 'sidecar_case_sweep_summary.csv') `
    @('case_name') `
    $numericSummaryColumns `
    $stringSummaryColumns

$numericPathColumns = @('alpha','k','max_iter','period','start_price','final_price','implied_price','policy_reference_price_used','Hdemand','Hsupply','excess_demand')
$stringPathColumns = @('guess_source')

$pathMetrics = Compare-CaseTables `
    $matlabPathsPath `
    (Join-Path $SidecarDir 'sidecar_case_sweep_paths.csv') `
    @('case_name','period') `
    $numericPathColumns `
    $stringPathColumns

$summaryTol = 1e-8
$pathTol = 1e-8

Write-Output "NIMBY k=4 warm-start sidecar validation"
Write-Output ("  cases={0}" -f $summaryMetrics.RowCount)
Write-Output ("  summary_max_numeric_diff={0}" -f $summaryMetrics.MaxNumericDiff)
Write-Output ("  summary_string_mismatch={0}" -f $summaryMetrics.StringMismatch)
Write-Output ("  path_rows={0}" -f $pathMetrics.RowCount)
Write-Output ("  path_max_numeric_diff={0}" -f $pathMetrics.MaxNumericDiff)
Write-Output ("  path_string_mismatch={0}" -f $pathMetrics.StringMismatch)

if ($summaryMetrics.MaxNumericDiff -gt $summaryTol -or $summaryMetrics.StringMismatch -ne 0 -or
    $pathMetrics.MaxNumericDiff -gt $pathTol -or $pathMetrics.StringMismatch -ne 0) {
    throw "Warm-start sidecar validation failed."
}
