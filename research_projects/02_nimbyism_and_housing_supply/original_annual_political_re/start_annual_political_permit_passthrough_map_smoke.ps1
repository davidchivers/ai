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
$truthRoot = Join-Path $scriptRoot "truth\annual_political_permit_passthrough_map"
$logsRoot = Join-Path $truthRoot "logs"
New-Item -ItemType Directory -Force -Path $logsRoot | Out-Null

if ([string]::IsNullOrWhiteSpace($RunTag)) {
    $RunTag = "annual_map_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}

$runner = Join-Path $scriptRoot "run_annual_political_permit_passthrough_map_smoke.ps1"
$stdout = Join-Path $logsRoot "$RunTag.stdout.log"
$stderr = Join-Path $logsRoot "$RunTag.stderr.log"
$active = Join-Path $truthRoot "active_run.txt"

$args = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $runner,
    "-RunTag", $RunTag,
    "-T", $T,
    "-PhiGrid", $PhiGrid,
    "-GammaGrid", $GammaGrid,
    "-RhoGrid", $RhoGrid,
    "-VoteScale", $VoteScale,
    "-RestrictionCap", $RestrictionCap
)

$proc = Start-Process -FilePath "powershell.exe" `
    -ArgumentList $args `
    -PassThru `
    -WindowStyle Hidden `
    -RedirectStandardOutput $stdout `
    -RedirectStandardError $stderr

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "pid=$($proc.Id)"
    "run_tag=$RunTag"
    "stdout=$stdout"
    "stderr=$stderr"
    "latest_status=$(Join-Path $truthRoot 'latest_status.json')"
) | Set-Content -Path $active

Write-Output "Started annual political permit pass-through map smoke."
Write-Output "PID: $($proc.Id)"
Write-Output "Run tag: $RunTag"
Write-Output "Active run file: $active"
