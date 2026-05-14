param(
    [string]$MatlabExe = "matlab",
    [int]$MaxK = 14,
    [int]$MaxOuterIter = 4,
    [int]$BasisCount = 3,
    [string]$SeedPriceCsvPath = "",
    [string]$RunTag = "",
    [string]$DemographicSourceMode = "historical_1950",
    [double]$FiniteDiffStep = 0.01,
    [double]$RidgeLambda = 0.001,
    [object[]]$CandidateScales = @(),
    [double]$TrustRegionLogStep = 0.08,
    [double]$ActiveThresholdFrac = 0.65,
    [double]$WedgeFloor = -0.50,
    [double]$WedgeCap = 0.50,
    [object[]]$KSchedule = @(),
    [int]$HousingClearMaxIter = 4
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$seedPriceCsvExpr = if ([string]::IsNullOrWhiteSpace($SeedPriceCsvPath)) { "''" } else { "'" + ($SeedPriceCsvPath -replace "'", "''") + "'" }
$runTagExpr = if ([string]::IsNullOrWhiteSpace($RunTag)) { "''" } else { "'" + ($RunTag -replace "'", "''") + "'" }

function Convert-ToMatlabVectorExpr {
    param([object[]]$Items)

    $parsed = @()
    foreach ($item in $Items) {
        if ($item -is [string]) {
            $parts = $item -split '[,; ]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            foreach ($part in $parts) {
                $parsed += [double]$part
            }
        } elseif ($null -ne $item) {
            $parsed += [double]$item
        }
    }

    if ($parsed.Count -eq 0) {
        return "[]"
    }

    $formatted = $parsed | ForEach-Object {
        [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $_)
    }
    return "[" + ($formatted -join "; ") + "]"
}

$candidateScalesExpr = Convert-ToMatlabVectorExpr -Items $CandidateScales
$kScheduleExpr = Convert-ToMatlabVectorExpr -Items $KSchedule

$matlabCommand = @"
addpath('$scriptDir');
[summary, results] = run_original_5yr_transition_joint_supply_wedge_continuation($MaxK, $MaxOuterIter, $BasisCount, $seedPriceCsvExpr, $runTagExpr, '$DemographicSourceMode', $FiniteDiffStep, $RidgeLambda, $candidateScalesExpr, $TrustRegionLogStep, $ActiveThresholdFrac, $WedgeFloor, $WedgeCap, $kScheduleExpr, $HousingClearMaxIter);
disp(summary);
exit;
"@

& $MatlabExe -batch $matlabCommand
