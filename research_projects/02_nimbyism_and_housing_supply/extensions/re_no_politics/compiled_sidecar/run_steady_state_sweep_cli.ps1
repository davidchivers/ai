param(
    [string]$PackName = 'steady_state_p2_rb0_03',
    [double]$PriceMin,
    [double]$PriceMax,
    [int]$PriceCount = 30,
    [string]$PriceGridCsv,
    [string]$OutputDir,
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'tools\portable_toolchain.ps1')

$null = Set-NimbySidecarPortableToolchain
$inputDir = Join-Path $scriptDir ("truth\{0}" -f $PackName)

if (-not (Test-Path $inputDir)) {
    & (Join-Path $scriptDir 'export_steady_state_input.ps1') -PackName $PackName
}

if (-not $SkipBuild) {
    & (Join-Path $scriptDir 'build.ps1')
}

$exe = Join-Path $scriptDir 'build\nimby_steady_state_sweep_cli.exe'
if (-not (Test-Path $exe)) {
    throw "Steady-state sweep CLI executable not found: $exe"
}

$argsList = @($inputDir, '--price-count', $PriceCount)
if ($PSBoundParameters.ContainsKey('PriceMin')) {
    $argsList += @('--price-min', $PriceMin)
}
if ($PSBoundParameters.ContainsKey('PriceMax')) {
    $argsList += @('--price-max', $PriceMax)
}
if ($PSBoundParameters.ContainsKey('PriceGridCsv')) {
    $argsList += @('--price-grid-csv', $PriceGridCsv)
}
if ($OutputDir) {
    $argsList += @('--output-dir', $OutputDir)
}

& $exe @argsList
