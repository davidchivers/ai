param(
    [string]$MatlabExe = "matlab",
    [int]$MaxK = 2,
    [int]$MaxIter = 2,
    [string]$PriceUpdateMode = "political_only",
    [string]$PoliticalTarget = "equal_weight_vote",
    [double]$PoliticalUpdateWeight = 0.005,
    [string]$RunTag = "",
    [string]$PoliticalUpdateRule = "fixed_step",
    [double]$PriceGuessLevel = 0.34013605902777766,
    [string]$DemographicSourceMode = "annual_subsampled",
    [object[]]$OuterLineSearchScales = @(),
    [double]$OuterLineSearchTol = [double]::NaN,
    [int]$MaxTargetedPeriods = 0,
    [int]$TargetBlockHalfWidth = -1,
    [string]$TargetMaskMode = ""
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$runTagExpr = if ([string]::IsNullOrWhiteSpace($RunTag)) { "''" } else { "'" + ($RunTag -replace "'", "''") + "'" }
$parsedOuterLineSearchScales = @()
foreach ($item in $OuterLineSearchScales) {
    if ($item -is [string]) {
        $parts = $item -split '[,; ]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        foreach ($part in $parts) {
            $parsedOuterLineSearchScales += [double]$part
        }
    } elseif ($null -ne $item) {
        $parsedOuterLineSearchScales += [double]$item
    }
}
$lineSearchScalesExpr = if ($parsedOuterLineSearchScales.Count -gt 0) {
    "[" + (($parsedOuterLineSearchScales | ForEach-Object { [System.Globalization.CultureInfo]::InvariantCulture.TextInfo.ToLower(("{0:R}" -f $_)) }) -join "; ") + "]"
} else {
    "[]"
}
$lineSearchTolExpr = if ([double]::IsNaN($OuterLineSearchTol)) {
    "[]"
} else {
    [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $OuterLineSearchTol)
}
$maxTargetedPeriodsExpr = if ($MaxTargetedPeriods -gt 0) { [string]$MaxTargetedPeriods } else { "[]" }
$targetBlockHalfWidthExpr = if ($TargetBlockHalfWidth -ge 0) { [string]$TargetBlockHalfWidth } else { "[]" }
$targetMaskModeExpr = if ([string]::IsNullOrWhiteSpace($TargetMaskMode)) { "[]" } else { "'" + ($TargetMaskMode -replace "'", "''") + "'" }
$matlabCommand = @"
addpath('$scriptDir');
[summary, results] = run_original_5yr_transition_political_bellman_bounded($MaxK, $MaxIter, '$PriceUpdateMode', '$PoliticalTarget', $PoliticalUpdateWeight, $runTagExpr, '$PoliticalUpdateRule', $PriceGuessLevel, '$DemographicSourceMode', $lineSearchScalesExpr, $lineSearchTolExpr, $maxTargetedPeriodsExpr, $targetBlockHalfWidthExpr, $targetMaskModeExpr);
disp(summary);
exit;
"@

& $MatlabExe -batch $matlabCommand
