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
    [string]$RunTag = ""
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$runner = Join-Path $scriptDir "run_original_5yr_political_permit_passthrough_smoke.ps1"
if (-not (Test-Path -LiteralPath $runner)) {
    throw "Runner not found: $runner"
}

if ([string]::IsNullOrWhiteSpace($RunTag)) {
    $RunTag = "local_phi_pass_k${MaxK}_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}

$args = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$runner`"",
    "-MaxK", $MaxK,
    "-PhiGrid", "`"$PhiGrid`"",
    "-RhoGrid", "`"$RhoGrid`"",
    "-PriceClearMaxIter", $PriceClearMaxIter,
    "-OuterIter", $OuterIter,
    "-VoteScale", $VoteScale,
    "-PolicyRelaxation", $PolicyRelaxation,
    "-WedgeFloor", $WedgeFloor,
    "-WedgeCap", $WedgeCap,
    "-PoliticalResponseSigma", $PoliticalResponseSigma,
    "-RunTag", "`"$RunTag`""
)

$process = Start-Process -FilePath "powershell.exe" -ArgumentList $args -WindowStyle Hidden -PassThru
$truthDir = Join-Path $scriptDir "truth\political_permit_passthrough"
if (-not (Test-Path -LiteralPath $truthDir)) {
    New-Item -ItemType Directory -Path $truthDir | Out-Null
}
$state = [pscustomobject]@{
    state = "launched"
    run_tag = $RunTag
    pid = $process.Id
    max_k = $MaxK
    phi_grid = $PhiGrid
    rho_grid = $RhoGrid
    launched_at = (Get-Date).ToString("s")
}
$state | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $truthDir "latest_launch.json")
$state | Format-List
