param(
    [int]$MaxK = 4,
    [string]$PhiGrid = "0,0.025,0.05,0.10,0.20",
    [string]$RhoGrid = "0,0.70",
    [int]$PriceClearMaxIter = 2,
    [int]$OuterIter = 2,
    [double]$VoteScale = 0.02,
    [double]$PolicyRelaxation = 0.75,
    [double]$WedgeFloor = -0.35,
    [double]$WedgeCap = 0.20,
    [double]$PoliticalResponseSigma = 0.20,
    [string]$RunTag = "",
    [string]$MatlabExe = "matlab"
)

$ErrorActionPreference = "Stop"

function Convert-ToMatlabVector {
    param([string]$Text)
    $values = $Text -split '[,; ]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if ($values.Count -eq 0) {
        throw "Expected at least one numeric value."
    }
    return "[" + ($values -join " ") + "]"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthDir = Join-Path $scriptDir "truth\political_permit_passthrough"
if (-not (Test-Path -LiteralPath $truthDir)) {
    New-Item -ItemType Directory -Path $truthDir | Out-Null
}

if ([string]::IsNullOrWhiteSpace($RunTag)) {
    $RunTag = "local_phi_pass_k${MaxK}_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}

$phiVector = Convert-ToMatlabVector $PhiGrid
$rhoVector = Convert-ToMatlabVector $RhoGrid
$logPath = Join-Path $truthDir "${RunTag}_matlab.log"

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$matlabCommand = @(
    "cd('$($scriptDir.Replace('\','/'))')"
    ("run_original_5yr_political_permit_passthrough_smoke({0}, {1}, {2}, '{3}', {4}, {5}, {6}, {7}, {8}, {9}, '', 'historical_1950', {10})" -f `
        $MaxK, `
        $phiVector, `
        $rhoVector, `
        $RunTag, `
        $PriceClearMaxIter, `
        $OuterIter, `
        $VoteScale.ToString("R", $culture), `
        $PolicyRelaxation.ToString("R", $culture), `
        $WedgeFloor.ToString("R", $culture), `
        $WedgeCap.ToString("R", $culture), `
        $PoliticalResponseSigma.ToString("R", $culture))
) -join "; "

& $MatlabExe -singleCompThread -batch $matlabCommand *> $logPath
if ($LASTEXITCODE -ne 0) {
    throw "MATLAB political permit pass-through smoke failed. See $logPath"
}

Write-Host "Finished political permit pass-through smoke: $RunTag"
Write-Host "Log: $logPath"
