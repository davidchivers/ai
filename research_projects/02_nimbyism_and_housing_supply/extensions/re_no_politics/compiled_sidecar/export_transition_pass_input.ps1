param(
    [string]$PackName = 'transition_pass_t4_diag',
    [int]$Horizon = 4,
    [double]$PriceLevel = 2.0,
    [string]$TransitionPolicyMode = 'full_backward',
    [double]$PolicyReferencePrice = 2.0,
    [string]$TerminalReferenceMode = 'fixed_price',
    [double]$TerminalReferencePrice = 2.0,
    [string]$PolicyReferenceMode = '',
    [double]$PolicyReferenceBlendWeight = [double]::NaN,
    [double]$PolicyReferencePriceFloor = [double]::NaN,
    [double]$PolicyReferencePriceCap = [double]::NaN,
    [switch]$SavePeriodDetails,
    [string]$PricePathCsv = '',
    [switch]$ComputePoliticalPath,
    [switch]$SavePoliticalDetails,
    [double]$PricePreferenceMultiplier = 1.01,
    [double]$AlphaOwner = 0.5,
    [double]$AlphaOldOwner = 0.5,
    [double]$AlphaLeverage = 0.25,
    [double]$AlphaBigHouse = 0.10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
if (-not (Test-Path $matlab)) {
    throw "MATLAB executable not found: $matlab"
}

function ConvertTo-MatlabString([string]$Value) {
    return ($Value.Replace('\', '/').Replace("'", "''"))
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputDir = Join-Path $scriptDir ("truth\{0}" -f $PackName)
$matlabOutputDir = ConvertTo-MatlabString $outputDir
$matlabScriptDir = ConvertTo-MatlabString (Join-Path $scriptDir 'matlab')
$matlabTransitionPolicyMode = ConvertTo-MatlabString $TransitionPolicyMode
$matlabTerminalReferenceMode = ConvertTo-MatlabString $TerminalReferenceMode
$matlabPolicyReferenceMode = ConvertTo-MatlabString $PolicyReferenceMode
$matlabSavePeriodDetails = if ($SavePeriodDetails) { 1 } else { 0 }
$matlabComputePoliticalPath = if ($ComputePoliticalPath) { 1 } else { 0 }
$matlabSavePoliticalDetails = if ($SavePoliticalDetails) { 1 } else { 0 }
$matlabPricePathCsv = ConvertTo-MatlabString $PricePathCsv

$batch = "addpath('$matlabScriptDir'); " +
    "coalition_params = struct('alpha_owner', $AlphaOwner, 'alpha_old_owner', $AlphaOldOwner, 'alpha_leverage', $AlphaLeverage, 'alpha_bighouse', $AlphaBigHouse); " +
    "price_path_csv = '$matlabPricePathCsv'; " +
    "if isempty(price_path_csv), explicit_price_path = []; else, explicit_price_path = readmatrix(price_path_csv); end; " +
    "export_transition_pass_input_pack('$matlabOutputDir', $Horizon, $PriceLevel, [], '$matlabTransitionPolicyMode', " +
    "$PolicyReferencePrice, '$matlabTerminalReferenceMode', $TerminalReferencePrice, '$matlabPolicyReferenceMode', " +
    "$PolicyReferenceBlendWeight, $PolicyReferencePriceFloor, $PolicyReferencePriceCap, $matlabSavePeriodDetails, explicit_price_path, " +
    "$matlabComputePoliticalPath, $matlabSavePoliticalDetails, $PricePreferenceMultiplier, coalition_params);"

& $matlab -batch $batch
if ($LASTEXITCODE -ne 0) {
    throw "MATLAB export failed with exit code $LASTEXITCODE."
}
