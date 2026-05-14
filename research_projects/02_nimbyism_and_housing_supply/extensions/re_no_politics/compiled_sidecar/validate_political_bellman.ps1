param(
    [string]$TruthSummaryPath,
    [string]$SidecarSummaryPath,
    [double]$Tolerance = 1e-10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $TruthSummaryPath)) {
    throw "Truth summary not found: $TruthSummaryPath"
}
if (-not (Test-Path -LiteralPath $SidecarSummaryPath)) {
    throw "Sidecar summary not found: $SidecarSummaryPath"
}

function Compare-ScalarValues {
    param(
        [string]$Name,
        [string]$TruthValue,
        [string]$SidecarValue,
        [double]$Tolerance
    )

    $truthDouble = 0.0
    $sideDouble = 0.0
    $truthIsDouble = [double]::TryParse($TruthValue, [ref]$truthDouble)
    $sideIsDouble = [double]::TryParse($SidecarValue, [ref]$sideDouble)

    if ($truthIsDouble -and $sideIsDouble) {
        $diff = [math]::Abs($truthDouble - $sideDouble)
        if ($diff -gt $Tolerance) {
            throw ("Column {0} differs by {1}: truth={2} sidecar={3}" -f $Name, $diff, $TruthValue, $SidecarValue)
        }
        return $diff
    }

    if ($TruthValue -ne $SidecarValue) {
        throw ("Column {0} differs: truth={1} sidecar={2}" -f $Name, $TruthValue, $SidecarValue)
    }
    return 0.0
}

$truthRows = @(Import-Csv -LiteralPath $TruthSummaryPath)
$sidecarRows = @(Import-Csv -LiteralPath $SidecarSummaryPath)

if ($truthRows.Count -ne $sidecarRows.Count) {
    throw "Row count mismatch: truth=$($truthRows.Count) sidecar=$($sidecarRows.Count)"
}
if ($truthRows.Count -eq 0) {
    throw "Truth summary is empty: $TruthSummaryPath"
}

$truthHeaders = @($truthRows[0].PSObject.Properties.Name)
$sideHeaders = @($sidecarRows[0].PSObject.Properties.Name)

foreach ($header in $truthHeaders) {
    if ($sideHeaders -notcontains $header) {
        throw "Missing expected column in sidecar summary: $header"
    }
}

$maxDiff = 0.0
for ($i = 0; $i -lt $truthRows.Count; $i++) {
    $truthRow = $truthRows[$i]
    $sideRow = $sidecarRows[$i]
    foreach ($header in $truthHeaders) {
        $diff = Compare-ScalarValues -Name $header -TruthValue ([string]$truthRow.$header) -SidecarValue ([string]$sideRow.$header) -Tolerance $Tolerance
        if ($diff -gt $maxDiff) {
            $maxDiff = $diff
        }
    }
}

Write-Output ("rows={0}" -f $truthRows.Count)
Write-Output ("max_abs_diff={0}" -f $maxDiff)
