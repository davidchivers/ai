param(
    [string]$PackName = 'transition_re_t4_fixed_terminal',
    [int]$Horizon = 4,
    [double]$PriceLevel = 2.0,
    [string]$CandidateSelectionMode = 'global',
    [double]$FocusGapImprovementTol = 1.0e-4,
    [double]$FocusExcessImprovementTol = 1.0e-5,
    [double]$FocusResidualSlack = 2.0e-4,
    [string]$TransitionPolicyMode = 'full_backward',
    [double]$PolicyReferencePrice = 2.0,
    [string]$TerminalReferenceMode = 'fixed_price',
    [double]$TerminalReferencePrice = 2.0,
    [string]$PolicyReferenceMode = '',
    [double]$PolicyReferenceBlendWeight = [double]::NaN,
    [double]$PolicyReferencePriceFloor = [double]::NaN,
    [double]$PolicyReferencePriceCap = [double]::NaN,
    [string]$OuterIterationMode = '',
    [double]$FixedPointRelaxationWeight = [double]::NaN,
    [string]$FixedPointRelaxationSpace = '',
    [double]$FixedPointPriceMin = [double]::NaN,
    [double]$FixedPointPriceMax = [double]::NaN,
    [string]$SolverProfile = 'bounded_candidate_search',
    [string]$InitialPricePathCsv = '',
    [switch]$SaveCandidateHistory,
    [switch]$SavePeriodDetails,
    [switch]$SaveOuterIterationPaths
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
$matlabCandidateSelectionMode = ConvertTo-MatlabString $CandidateSelectionMode
$matlabTransitionPolicyMode = ConvertTo-MatlabString $TransitionPolicyMode
$matlabTerminalReferenceMode = ConvertTo-MatlabString $TerminalReferenceMode
$matlabPolicyReferenceMode = ConvertTo-MatlabString $PolicyReferenceMode
$matlabOuterIterationMode = ConvertTo-MatlabString $OuterIterationMode
$matlabFixedPointRelaxationSpace = ConvertTo-MatlabString $FixedPointRelaxationSpace
$matlabSolverProfile = ConvertTo-MatlabString $SolverProfile
$matlabInitialPricePathCsv = ConvertTo-MatlabString $InitialPricePathCsv
$matlabSaveCandidateHistory = if ($SaveCandidateHistory) { 1 } else { 0 }
$matlabSavePeriodDetails = if ($SavePeriodDetails) { 1 } else { 0 }
$matlabSaveOuterIterationPaths = if ($SaveOuterIterationPaths) { 1 } else { 0 }

$batch = "addpath('$matlabScriptDir'); " +
    "initial_price_path_csv = '$matlabInitialPricePathCsv'; " +
    "if isempty(initial_price_path_csv), initial_price_path = []; else, initial_price_path = readmatrix(initial_price_path_csv); end; " +
    "export_transition_re_input_pack('$matlabOutputDir', $Horizon, $PriceLevel, [], '$matlabCandidateSelectionMode', " +
    "$FocusGapImprovementTol, $FocusExcessImprovementTol, $FocusResidualSlack, '$matlabTransitionPolicyMode', $PolicyReferencePrice, " +
    "'$matlabTerminalReferenceMode', $TerminalReferencePrice, '$matlabPolicyReferenceMode', $PolicyReferenceBlendWeight, " +
    "$PolicyReferencePriceFloor, $PolicyReferencePriceCap, '$matlabOuterIterationMode', $FixedPointRelaxationWeight, " +
    "'$matlabFixedPointRelaxationSpace', $FixedPointPriceMin, $FixedPointPriceMax, '$matlabSolverProfile', initial_price_path, " +
    "$matlabSaveCandidateHistory, $matlabSavePeriodDetails, $matlabSaveOuterIterationPaths);"

& $matlab -batch $batch
if ($LASTEXITCODE -ne 0) {
    throw "MATLAB export failed with exit code $LASTEXITCODE."
}
