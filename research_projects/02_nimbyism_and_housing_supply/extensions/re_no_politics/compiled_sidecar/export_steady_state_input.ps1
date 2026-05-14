param(
    [string]$PackName = 'steady_state_p2_rb0_03',
    [double]$PriceLevel = 2.0,
    [double]$RbPos = 0.03,
    [string]$SteadyStateMode = 're_no_politics'
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
$matlabSteadyStateMode = ConvertTo-MatlabString $SteadyStateMode

$batch = "addpath('$matlabScriptDir'); " +
    "export_steady_state_input_pack('$matlabOutputDir', $PriceLevel, $RbPos, [], '$matlabSteadyStateMode');"

& $matlab -batch $batch
if ($LASTEXITCODE -ne 0) {
    throw "MATLAB export failed with exit code $LASTEXITCODE."
}
