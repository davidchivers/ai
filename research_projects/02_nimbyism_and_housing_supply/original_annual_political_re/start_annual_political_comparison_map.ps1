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
if ([string]::IsNullOrWhiteSpace($RunTag)) {
    $RunTag = "annual_comparison_map_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}

$outRoot = Join-Path $scriptRoot "truth\annual_political_comparison_map"
New-Item -ItemType Directory -Force -Path $outRoot | Out-Null
$logPath = Join-Path $outRoot "$RunTag.log"
$errPath = Join-Path $outRoot "$RunTag.err.log"

$args = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $scriptRoot "run_annual_political_comparison_map.ps1"),
    "-RunTag", $RunTag,
    "-T", $T,
    "-EtaGrid", $EtaGrid,
    "-TauGrid", $TauGrid,
    "-TinyTauGrid", $TinyTauGrid,
    "-RandomDraws", $RandomDraws,
    "-RandomAmplitudeGrid", $RandomAmplitudeGrid
)

Start-Process -FilePath "powershell.exe" -ArgumentList $args -WorkingDirectory $scriptRoot -RedirectStandardOutput $logPath -RedirectStandardError $errPath -WindowStyle Hidden
Write-Host "Started annual political comparison map: $RunTag"
Write-Host "Log: $logPath"
