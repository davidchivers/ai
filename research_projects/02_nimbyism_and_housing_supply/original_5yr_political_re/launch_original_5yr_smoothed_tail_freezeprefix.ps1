param(
    [double]$Sigma = 0.20,
    [string]$Label = "",
    [string]$RunTag = "",
    [int]$MaxK = 12,
    [string]$KSchedule = "11,12",
    [int]$PrefixLockLength = 10,
    [int]$BasisCount = 2,
    [int]$HousingClearMaxIter = 2,
    [int]$MaxOuterIter = 1,
    [string]$SeedPriceCsv = "",
    [string]$SeedWedgeCsv = "",
    [string]$MatlabExe = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sigmaText = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:G17}", $Sigma)
$labelText = $Label.Replace("'", "''")
$runTagText = $RunTag.Replace("'", "''")
$seedPriceText = $SeedPriceCsv.Replace("'", "''")
$seedWedgeText = $SeedWedgeCsv.Replace("'", "''")
$kValues = @(
    $KSchedule.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries) |
        ForEach-Object { [int]($_.Trim()) }
)
if ($kValues.Count -eq 0) {
    $kScheduleExpr = "[]"
}
else {
    $kScheduleExpr = "[" + (($kValues | ForEach-Object { $_.ToString() }) -join "; ") + "]"
}

$matlabCmd = "cd('$scriptDir'); run_original_5yr_smoothed_tail_freezeprefix($sigmaText, '$labelText', '$runTagText', $MaxK, $kScheduleExpr, $PrefixLockLength, $BasisCount, $HousingClearMaxIter, '$seedPriceText', '$seedWedgeText', $MaxOuterIter); exit;"

& $MatlabExe -batch $matlabCmd
