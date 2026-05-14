param(
    [string]$PackName = '',
    [string]$InputDir = '',
    [string]$OutputDir = '',
    [double]$GapCutoff = 0.05,
    [double]$PriceBoundTol = 1.0e-6,
    [int]$PerAttemptMaxIter = 0,
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
    $OutputDir = Join-Path $scriptDir ("truth\{0}_retryaware" -f $PackName)
}

if (-not $SkipBuild) {
    & (Join-Path $scriptDir 'build.ps1')
}

$exe = Join-Path $scriptDir 'build\nimby_transition_re_retryaware_cli.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    throw "Retry-aware transition-RE CLI executable not found: $exe"
}

$arguments = New-Object System.Collections.Generic.List[string]
$arguments.Add($InputDir)
$arguments.Add('--output-dir')
$arguments.Add($OutputDir)
$arguments.Add('--gap-cutoff')
$arguments.Add(([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:R}', $GapCutoff)))
$arguments.Add('--price-bound-tol')
$arguments.Add(([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:R}', $PriceBoundTol)))
if ($PerAttemptMaxIter -gt 0) {
    $arguments.Add('--per-attempt-max-iter')
    $arguments.Add([string]$PerAttemptMaxIter)
}

& $exe @arguments
if ($LASTEXITCODE -ne 0) {
    throw "Retry-aware transition-RE CLI failed for input $InputDir"
}
