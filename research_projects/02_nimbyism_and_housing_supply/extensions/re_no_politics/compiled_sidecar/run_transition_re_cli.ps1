param(
    [string]$PackName = 'transition_re_t4_fixed_terminal',
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
    & (Join-Path $scriptDir 'export_transition_re_input.ps1') -PackName $PackName
}

if (-not $SkipBuild) {
    & (Join-Path $scriptDir 'build.ps1')
}

$exe = Join-Path $scriptDir 'build\nimby_transition_re_cli.exe'
if (-not (Test-Path $exe)) {
    throw "Transition-RE CLI executable not found: $exe"
}

$argsList = @($inputDir)
if ($OutputDir) {
    $argsList += @('--output-dir', $OutputDir)
}

& $exe @argsList
