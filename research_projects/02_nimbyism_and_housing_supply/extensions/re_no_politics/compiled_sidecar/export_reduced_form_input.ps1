param(
    [string]$PackName = 'reduced_form_one_step',
    [int]$K = 1,
    [int]$StartIndex = 2,
    [double]$ReWeight = 1.0,
    [double]$RelaxationWeight = 0.50,
    [double]$PriceMin = 1.75,
    [double]$PriceMax = 2.25,
    [int]$MaxIter = 100,
    [double]$Tolerance = 1.0e-8
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

$batch = "addpath('$matlabScriptDir'); " +
    "export_reduced_form_input_pack('$matlabOutputDir', $K, struct(" +
    "'start_index', $StartIndex, " +
    "'re_weight', $ReWeight, " +
    "'relaxation_weight', $RelaxationWeight, " +
    "'price_min', $PriceMin, " +
    "'price_max', $PriceMax, " +
    "'max_iter', $MaxIter, " +
    "'tol', $Tolerance), []);"

& $matlab -batch $batch
if ($LASTEXITCODE -ne 0) {
    throw "MATLAB export failed with exit code $LASTEXITCODE."
}
