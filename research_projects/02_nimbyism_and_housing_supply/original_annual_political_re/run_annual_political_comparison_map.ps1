param(
    [string]$RunTag = "",
    [int]$T = 80,
    [string]$EtaGrid = "0.090,0.105,0.120",
    [string]$TauGrid = "0.020",
    [string]$TinyTauGrid = "0.001",
    [int]$RandomDraws = 200,
    [string]$RandomAmplitudeGrid = "0.03,0.05,0.075,0.10"
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe"
if (-not (Test-Path $matlab)) {
    throw "MATLAB not found at $matlab"
}

if ([string]::IsNullOrWhiteSpace($RunTag)) {
    $RunTag = "annual_comparison_map_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}

function Convert-ToMatlabVector {
    param([string]$Csv)
    return "[" + (($Csv -split "," | ForEach-Object { $_.Trim() }) -join " ") + "]"
}

$etaMat = Convert-ToMatlabVector $EtaGrid
$tauMat = Convert-ToMatlabVector $TauGrid
$tinyTauMat = Convert-ToMatlabVector $TinyTauGrid
$ampMat = Convert-ToMatlabVector $RandomAmplitudeGrid

$cmd = "cd('$($scriptRoot.Replace('\','/'))'); run_annual_political_comparison_map('RunTag','$RunTag','T',$T,'EtaGrid',$etaMat,'TauGrid',$tauMat,'TinyTauGrid',$tinyTauMat,'RandomDraws',$RandomDraws,'RandomAmplitudeGrid',$ampMat)"

& $matlab -singleCompThread -batch $cmd
