param(
    [string]$PackName = '',
    [string]$InputDir = '',
    [string]$OutputDir = '',
    [int]$MaxK = 0,
    [string]$AlphaGrid = '',
    [string]$AnchorPathCsv = '',
    [string]$AnchorSource = '',
    [double]$GapCutoff = 0.05,
    [double]$PriceBoundTol = 1.0e-6,
    [switch]$Resume,
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $PackName -and -not $InputDir) {
    throw "Provide either -PackName or -InputDir."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'tools\portable_toolchain.ps1')

$null = Set-NimbySidecarPortableToolchain

if (-not $InputDir) {
    $InputDir = Join-Path $scriptDir ("truth\{0}" -f $PackName)
}
if (-not (Test-Path -LiteralPath $InputDir)) {
    throw "Input pack not found: $InputDir"
}

if (-not $PackName) {
    $PackName = Split-Path -Leaf $InputDir
}
if (-not $OutputDir) {
    $OutputDir = Join-Path $scriptDir ("truth\{0}_frontier" -f $PackName)
}

if (-not $SkipBuild) {
    & (Join-Path $scriptDir 'build.ps1')
}

$exe = Join-Path $scriptDir 'build\nimby_transition_re_frontier_cli.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    throw "Frontier CLI executable not found: $exe"
}

$arguments = New-Object System.Collections.Generic.List[string]
$arguments.Add($InputDir)
$arguments.Add('--output-dir')
$arguments.Add($OutputDir)
if ($MaxK -gt 0) {
    $arguments.Add('--max-k')
    $arguments.Add([string]$MaxK)
}
if ($AlphaGrid) {
    $arguments.Add('--alpha-grid')
    $arguments.Add($AlphaGrid)
}
if ($AnchorPathCsv) {
    $arguments.Add('--anchor-path-csv')
    $arguments.Add($AnchorPathCsv)
}
if ($AnchorSource) {
    $arguments.Add('--anchor-source')
    $arguments.Add($AnchorSource)
}
$arguments.Add('--gap-cutoff')
$arguments.Add(([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:R}', $GapCutoff)))
$arguments.Add('--price-bound-tol')
$arguments.Add(([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:R}', $PriceBoundTol)))
if ($Resume) {
    $arguments.Add('--resume')
}

& $exe @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Frontier CLI failed for input $InputDir"
}
