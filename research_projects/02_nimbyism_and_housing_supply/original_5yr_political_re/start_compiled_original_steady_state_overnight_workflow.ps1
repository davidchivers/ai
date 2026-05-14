param(
    [double]$PriceStart = 0.3401,
    [double]$PriceEnd = 0.34015,
    [int]$PriceCount = 21,
    [double]$PriceMultiplier = 1.01,
    [int]$MaxStages = 8,
    [double]$MaxHours = 10.0,
    [double]$BracketWidthTolerance = 1e-7,
    [double]$VoteTolerance = 1e-4
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workflow = Join-Path $scriptDir "run_compiled_original_steady_state_overnight_workflow.ps1"

$args = @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', $workflow,
    '-PriceStart', $PriceStart,
    '-PriceEnd', $PriceEnd,
    '-PriceCount', $PriceCount,
    '-PriceMultiplier', $PriceMultiplier,
    '-MaxStages', $MaxStages,
    '-MaxHours', $MaxHours,
    '-BracketWidthTolerance', $BracketWidthTolerance,
    '-VoteTolerance', $VoteTolerance
)

$proc = Start-Process -FilePath "powershell.exe" -ArgumentList $args -PassThru
$proc | Select-Object Id, ProcessName, StartTime
