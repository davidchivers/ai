param(
    [string]$RunTag = "",
    [int]$T = 80,
    [string]$PhiGrid = "0,0.01,0.03,0.06,0.10,0.20",
    [string]$GammaGrid = "0.25,0.50,1.00,1.50",
    [string]$RhoGrid = "0,0.50,0.85",
    [double]$VoteScale = 0.02,
    [double]$RestrictionCap = 0.35
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe"
if (-not (Test-Path $matlab)) {
    throw "MATLAB not found at $matlab"
}

function Convert-Grid([string]$value) {
    return "[" + (($value -split "," | ForEach-Object { $_.Trim() }) -join " ") + "]"
}

if ([string]::IsNullOrWhiteSpace($RunTag)) {
    $RunTag = "annual_map_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}

$phiMat = Convert-Grid $PhiGrid
$gammaMat = Convert-Grid $GammaGrid
$rhoMat = Convert-Grid $RhoGrid
$cmd = "cd('$($scriptRoot.Replace('\','/'))'); run_annual_political_permit_passthrough_map_smoke('RunTag','$RunTag','T',$T,'PhiGrid',$phiMat,'GammaGrid',$gammaMat,'RhoGrid',$rhoMat,'VoteScale',$VoteScale,'RestrictionCap',$RestrictionCap)"

& $matlab -singleCompThread -batch $cmd
