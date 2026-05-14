param(
    [string]$PackName = 'original_5yr_transition_pass_hist_k2',
    [int]$Horizon = 2,
    [double]$PriceLevel = 0.34013605902777766,
    [string]$PricePathCsv = '',
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptDir))
$matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
if (-not (Test-Path $matlab)) {
    throw "MATLAB executable not found: $matlab"
}

function ConvertTo-MatlabString([string]$Value) {
    return ($Value.Replace('\', '/').Replace("'", "''"))
}

$bridgeDir = Join-Path $projectRoot 'original_5yr_political_re\compiled_sidecar_bridge'
$matlabScriptDir = ConvertTo-MatlabString (Join-Path $scriptDir 'matlab')
$matlabBridgeDir = ConvertTo-MatlabString $bridgeDir
$matlabOutputDir = ConvertTo-MatlabString (Join-Path $scriptDir ("truth\{0}" -f $PackName))
$matlabProjectRoot = ConvertTo-MatlabString $projectRoot
$matlabPricePathCsv = ConvertTo-MatlabString $PricePathCsv

if (-not [string]::IsNullOrWhiteSpace($PricePathCsv) -and -not (Test-Path -LiteralPath $PricePathCsv)) {
    throw "Price path CSV not found: $PricePathCsv"
}

$batch = "addpath('$matlabBridgeDir','-begin'); " +
    "addpath('$matlabScriptDir'); " +
    "price_path_csv = '$matlabPricePathCsv'; " +
    "if isempty(price_path_csv), explicit_price_path = []; else, explicit_price_path = readmatrix(price_path_csv); end; " +
    "export_transition_pass_input_pack('$matlabOutputDir', $Horizon, $PriceLevel, '$matlabProjectRoot', 'full_backward', " +
    "$PriceLevel, 'fixed_price', $PriceLevel, 'path_current_prices', NaN, NaN, NaN, true, explicit_price_path, true, true, 1.01, struct());"

& $matlab -batch $batch
if ($LASTEXITCODE -ne 0) {
    throw "MATLAB export failed with exit code $LASTEXITCODE."
}

if (-not $SkipBuild) {
    & (Join-Path $scriptDir 'build.ps1')
}

$exe = Join-Path $scriptDir 'build\nimby_transition_pass_cli.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    throw "Transition-pass CLI executable not found: $exe"
}

$inputDir = Join-Path $scriptDir ("truth\{0}" -f $PackName)
& $exe $inputDir
if ($LASTEXITCODE -ne 0) {
    throw "Compiled transition-pass CLI failed for input $inputDir"
}

& (Join-Path $scriptDir 'validate_transition_pass.ps1') -PackName $PackName
