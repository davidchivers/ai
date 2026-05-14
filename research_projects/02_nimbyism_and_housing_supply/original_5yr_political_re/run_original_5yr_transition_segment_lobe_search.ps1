param(
    [string]$MatlabExe = "matlab",
    [int]$MaxK = 14,
    [string]$SeedPriceCsvPath = "",
    [string]$RunTag = "",
    [string]$DemographicSourceMode = "historical_1950",
    [object[]]$LogStepGrid = @(),
    [double]$ActiveThresholdFrac = 0.65,
    [double]$PriceFloor = 0.05,
    [double]$PriceCap = 5.0
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$runTagExpr = if ([string]::IsNullOrWhiteSpace($RunTag)) { "''" } else { "'" + ($RunTag -replace "'", "''") + "'" }
$seedPriceCsvExpr = if ([string]::IsNullOrWhiteSpace($SeedPriceCsvPath)) { "''" } else { "'" + ($SeedPriceCsvPath -replace "'", "''") + "'" }

$parsedLogStepGrid = @()
foreach ($item in $LogStepGrid) {
    if ($item -is [string]) {
        $parts = $item -split '[,; ]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        foreach ($part in $parts) {
            $parsedLogStepGrid += [double]$part
        }
    } elseif ($null -ne $item) {
        $parsedLogStepGrid += [double]$item
    }
}
$logStepGridExpr = if ($parsedLogStepGrid.Count -gt 0) {
    "[" + (($parsedLogStepGrid | ForEach-Object { [System.Globalization.CultureInfo]::InvariantCulture.TextInfo.ToLower(("{0:R}" -f $_)) }) -join "; ") + "]"
} else {
    "[]"
}

$matlabCommand = @"
addpath('$scriptDir');
[summary, results] = run_original_5yr_transition_segment_lobe_search($MaxK, $seedPriceCsvExpr, $runTagExpr, '$DemographicSourceMode', $logStepGridExpr, $ActiveThresholdFrac, $PriceFloor, $PriceCap);
disp(summary(1:min(10,height(summary)),:));
exit;
"@

& $MatlabExe -batch $matlabCommand
