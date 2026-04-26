param(
    [string]$MatlabExe = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe",
    [string]$Scenario = "entrant_survival_boom",
    [int]$MaxK = 14,
    [int]$MaxOuterIter = 1,
    [int]$BasisCount = 2,
    [string]$SeedPriceCsvPath = "",
    [string]$SeedWedgeCsvPath = "",
    [string]$RunTag = "",
    [double]$FiniteDiffStep = 0.01,
    [double]$RidgeLambda = 0.001,
    [object[]]$CandidateScales = @(1, 0.5),
    [double]$TrustRegionLogStep = 0.08,
    [double]$ActiveThresholdFrac = 0.65,
    [double]$WedgeFloor = -0.50,
    [double]$WedgeCap = 0.50,
    [object[]]$KSchedule = @(2, 4, 6, 8, 10, 12, 14),
    [int]$HousingClearMaxIter = 2
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Convert-ToMatlabVectorExpr {
    param([object[]]$Items)

    $parsed = @()
    foreach ($item in $Items) {
        if ($item -is [string]) {
            $parts = $item -split '[,; ]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            foreach ($part in $parts) {
                $parsed += [double]$part
            }
        }
        elseif ($null -ne $item) {
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

function Convert-ToMatlabStringLiteral {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "''"
    }
    return "'" + ($Value -replace "'", "''") + "'"
}

if ([string]::IsNullOrWhiteSpace($RunTag)) {
    $RunTag = "local_entrant_survival_hard_" + ($Scenario -replace '[^A-Za-z0-9_]+', '_')
}

$seedPriceExpr = Convert-ToMatlabStringLiteral -Value $SeedPriceCsvPath
$seedWedgeExpr = Convert-ToMatlabStringLiteral -Value $SeedWedgeCsvPath
$runTagExpr = Convert-ToMatlabStringLiteral -Value $RunTag
$candidateScalesExpr = Convert-ToMatlabVectorExpr -Items $CandidateScales
$kScheduleExpr = Convert-ToMatlabVectorExpr -Items $KSchedule

$matlabCommand = @"
addpath('$scriptDir');
[summary, results] = run_original_5yr_joint_wedge_hard($MaxK, $MaxOuterIter, $BasisCount, $seedPriceExpr, $runTagExpr, '$Scenario', $FiniteDiffStep, $RidgeLambda, $candidateScalesExpr, $TrustRegionLogStep, $ActiveThresholdFrac, $WedgeFloor, $WedgeCap, $kScheduleExpr, $HousingClearMaxIter, $seedWedgeExpr, 0);
disp(summary);
exit;
"@

& $MatlabExe -batch $matlabCommand
