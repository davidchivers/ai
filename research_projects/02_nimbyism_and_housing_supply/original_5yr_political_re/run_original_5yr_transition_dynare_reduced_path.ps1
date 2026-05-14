param(
    [string]$MatlabExe = "matlab",
    [int]$MaxK = 14,
    [int]$MaxOuterIter = 2,
    [int]$BasisCount = 4,
    [string]$SeedPriceCsvPath = "",
    [string]$RunTag = "",
    [string]$DemographicSourceMode = "historical_1950",
    [double]$FiniteDiffStep = 2.5e-4,
    [double]$RidgeLambda = 1e-3,
    [object[]]$CandidateScales = @(),
    [double]$TrustRegionLogStep = 2e-3,
    [double]$ActiveThresholdFrac = 0.65,
    [double]$PriceFloor = 0.05,
    [double]$PriceCap = 5.0
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$runTagExpr = if ([string]::IsNullOrWhiteSpace($RunTag)) { "''" } else { "'" + ($RunTag -replace "'", "''") + "'" }
$seedPriceCsvExpr = if ([string]::IsNullOrWhiteSpace($SeedPriceCsvPath)) { "''" } else { "'" + ($SeedPriceCsvPath -replace "'", "''") + "'" }

$parsedCandidateScales = @()
foreach ($item in $CandidateScales) {
    if ($item -is [string]) {
        $parts = $item -split '[,; ]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        foreach ($part in $parts) {
            $parsedCandidateScales += [double]$part
        }
    } elseif ($null -ne $item) {
        $parsedCandidateScales += [double]$item
    }
}
$candidateScalesExpr = if ($parsedCandidateScales.Count -gt 0) {
    "[" + (($parsedCandidateScales | ForEach-Object { [System.Globalization.CultureInfo]::InvariantCulture.TextInfo.ToLower(("{0:R}" -f $_)) }) -join "; ") + "]"
} else {
    "[]"
}

$matlabCommand = @"
addpath('$scriptDir');
[summary, results] = run_original_5yr_transition_dynare_reduced_path($MaxK, $MaxOuterIter, $BasisCount, $seedPriceCsvExpr, $runTagExpr, '$DemographicSourceMode', $FiniteDiffStep, $RidgeLambda, $candidateScalesExpr, $TrustRegionLogStep, $ActiveThresholdFrac, $PriceFloor, $PriceCap);
disp(summary);
exit;
"@

& $MatlabExe -batch $matlabCommand
