param(
    [string]$PackName = 'transition_re_t4_fixed_terminal',
    [string]$PackDir = ''
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
if (-not $PackDir) {
    $PackDir = Join-Path $scriptDir ("truth\{0}" -f $PackName)
}
if (-not (Test-Path $PackDir)) {
    throw "Pack directory not found: $PackDir"
}

$matlabScriptDir = ConvertTo-MatlabString (Join-Path $scriptDir 'matlab')
$matlabPackDir = ConvertTo-MatlabString $PackDir
$batch = "addpath('$matlabScriptDir'); refresh_transition_re_outputs_from_pack('$matlabPackDir');"

& $matlab -batch $batch
if ($LASTEXITCODE -ne 0) {
    throw "MATLAB refresh failed with exit code $LASTEXITCODE."
}
