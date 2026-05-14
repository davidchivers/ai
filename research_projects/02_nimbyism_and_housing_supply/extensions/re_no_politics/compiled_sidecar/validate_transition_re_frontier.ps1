param(
    [string]$SidecarSummaryPath = '',
    [string]$MatlabSummaryPath = '',
    [int]$MaxK = 0,
    [double]$Tolerance = 1.0e-8
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $SidecarSummaryPath -or -not $MatlabSummaryPath) {
    throw "Provide -SidecarSummaryPath and -MatlabSummaryPath."
}
if (-not (Test-Path -LiteralPath $SidecarSummaryPath)) {
    throw "Sidecar summary not found: $SidecarSummaryPath"
}
if (-not (Test-Path -LiteralPath $MatlabSummaryPath)) {
    throw "MATLAB summary not found: $MatlabSummaryPath"
}

$invariant = [System.Globalization.CultureInfo]::InvariantCulture

function Parse-Double([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -eq 'NaN') {
        return [double]::NaN
    }
    return [double]::Parse($Value, $invariant)
}

$sidecarRows = Import-Csv -LiteralPath $SidecarSummaryPath
$matlabRows = Import-Csv -LiteralPath $MatlabSummaryPath
if ($MaxK -gt 0) {
    $sidecarRows = @($sidecarRows | Where-Object { [int]$_.k -le $MaxK })
    $matlabRows = @($matlabRows | Where-Object { [int]$_.k -le $MaxK })
}

function Key-Row($row) {
    $alpha = (Parse-Double ([string]$row.policy_reference_blend_weight)).ToString('R', $invariant)
    return ('{0}|{1}' -f [int]$row.k, $alpha)
}

$sidecarMap = @{}
foreach ($row in $sidecarRows) {
    $sidecarMap[(Key-Row $row)] = $row
}

$matlabMap = @{}
foreach ($row in $matlabRows) {
    $matlabMap[(Key-Row $row)] = $row
}

$commonKeys = @($sidecarMap.Keys | Where-Object { $matlabMap.ContainsKey($_) } | Sort-Object)
if ($commonKeys.Count -eq 0) {
    throw "No overlapping frontier rows found between the two summaries."
}

$numericCols = @(
    'residual_norm',
    'max_abs_gap',
    'max_abs_update',
    'price_min',
    'price_max',
    'path_span',
    'policy_reference_price_first_used',
    'policy_reference_price_last_used'
)

$stringCols = @(
    'status',
    'warm_start_source'
)

$boolCols = @(
    'converged',
    'looks_stable'
)

$maxDiff = @{}
foreach ($col in $numericCols) {
    $maxDiff[$col] = 0.0
}

$stringMismatch = @{}
foreach ($col in $stringCols + $boolCols) {
    $stringMismatch[$col] = 0
}

foreach ($key in $commonKeys) {
    $side = $sidecarMap[$key]
    $mat = $matlabMap[$key]
    foreach ($col in $numericCols) {
        $d = [Math]::Abs((Parse-Double $side.$col) - (Parse-Double $mat.$col))
        if ($d -gt $maxDiff[$col]) {
            $maxDiff[$col] = $d
        }
    }
    foreach ($col in $stringCols + $boolCols) {
        if ([string]$side.$col -ne [string]$mat.$col) {
            $stringMismatch[$col]++
        }
    }
}

$missingSidecar = @($matlabMap.Keys | Where-Object { -not $sidecarMap.ContainsKey($_) } | Sort-Object)
$missingMatlab = @($sidecarMap.Keys | Where-Object { -not $matlabMap.ContainsKey($_) } | Sort-Object)

$pass = $true
foreach ($col in $numericCols) {
    if ($maxDiff[$col] -gt $Tolerance) {
        $pass = $false
    }
}
foreach ($col in $stringCols + $boolCols) {
    if ($stringMismatch[$col] -ne 0) {
        $pass = $false
    }
}

Write-Output ('frontier_common_rows=' + $commonKeys.Count)
foreach ($col in $numericCols) {
    Write-Output ('frontier_max_abs_diff_' + $col + '=' + $maxDiff[$col].ToString('R', $invariant))
}
foreach ($col in $stringCols + $boolCols) {
    Write-Output ('frontier_mismatch_count_' + $col + '=' + $stringMismatch[$col])
}
Write-Output ('frontier_missing_sidecar_rows=' + $missingSidecar.Count)
Write-Output ('frontier_missing_matlab_rows=' + $missingMatlab.Count)
Write-Output ('transition_re_frontier_validation=' + ($(if ($pass) { 'PASS' } else { 'FAIL' })))

if (-not $pass) {
    exit 1
}
