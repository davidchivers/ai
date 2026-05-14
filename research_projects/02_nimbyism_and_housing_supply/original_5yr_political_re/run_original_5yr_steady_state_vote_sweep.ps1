param(
    [string]$MatlabExe = "matlab",
    [double]$RbPos = 0.03,
    [double]$PriceStart = 1.8,
    [double]$PriceEnd = 2.2,
    [int]$NumPoints = 30,
    [string]$OutputDir = ""
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pricesExpr = "linspace($PriceStart, $PriceEnd, $NumPoints)"
$outputExpr = if ([string]::IsNullOrWhiteSpace($OutputDir)) { "''" } else { "'" + ($OutputDir -replace "'", "''") + "'" }
$matlabCommand = @"
addpath('$scriptDir');
prices = $pricesExpr;
results = run_original_5yr_steady_state_vote_sweep(prices, $RbPos, $outputExpr);
disp(results.best_vote_abs_price);
exit;
"@

& $MatlabExe -batch $matlabCommand
