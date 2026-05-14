param(
    [string]$PackName = 'transition_pass_t4_political_diag',
    [string]$OutputDir = '',
    [string]$InitialPricePathCsv = '',
    [string]$PoliticalTarget = 'equal_weight_vote',
    [string]$PriceUpdateMode = 'political_only',
    [string]$PoliticalUpdateRule = 'fixed_step',
    [int]$MaxIter = 4,
    [double]$TolVote = 1e-3,
    [double]$PoliticalUpdateWeight = 0.005,
    [double]$MaxUpdateFrac = 0.02,
    [double]$PriceFloor = 0.40,
    [double]$PriceCap = 5.0,
    [double]$SecantDamping = 0.75,
    [double]$SecantMinAbsSlope = 1e-3,
    [string]$GuessSource = 'transition_re_no_politics_results.final_price_path_prefix',
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'tools\portable_toolchain.ps1')

$null = Set-NimbySidecarPortableToolchain
$inputDir = Join-Path $scriptDir ("truth\{0}" -f $PackName)
if (-not (Test-Path -LiteralPath $inputDir)) {
    throw "Political Bellman input pack not found: $inputDir"
}

if (-not [string]::IsNullOrWhiteSpace($InitialPricePathCsv)) {
    if (-not (Test-Path -LiteralPath $InitialPricePathCsv)) {
        throw "Initial price path CSV not found: $InitialPricePathCsv"
    }
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $scriptDir ("truth\{0}_political_bellman_{1}" -f $PackName, $PoliticalUpdateRule)
}

if (-not $SkipBuild) {
    & (Join-Path $scriptDir 'build.ps1')
}

$exe = Join-Path $scriptDir 'build\nimby_political_bellman_cli.exe'
if (-not (Test-Path $exe)) {
    throw "Political Bellman CLI executable not found: $exe"
}

$argsList = @(
    $inputDir,
    '--output-dir', $OutputDir,
    '--max-iter', $MaxIter,
    '--tol-vote', $TolVote,
    '--political-target', $PoliticalTarget,
    '--price-update-mode', $PriceUpdateMode,
    '--political-update-rule', $PoliticalUpdateRule,
    '--political-update-weight', $PoliticalUpdateWeight,
    '--max-update-frac', $MaxUpdateFrac,
    '--price-floor', $PriceFloor,
    '--price-cap', $PriceCap,
    '--secant-damping', $SecantDamping,
    '--secant-min-abs-slope', $SecantMinAbsSlope,
    '--guess-source', $GuessSource
)

if (-not [string]::IsNullOrWhiteSpace($InitialPricePathCsv)) {
    $argsList += @('--initial-price-path-csv', $InitialPricePathCsv)
}

& $exe @argsList
