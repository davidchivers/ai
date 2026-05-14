$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$summaryPath = Join-Path $thisDir 'transition_re_policy_bridge_fixed_price_sweep_summary.csv'
$reportPath = Join-Path $thisDir 'transition_re_policy_bridge_fixed_price_report.md'

if (-not (Test-Path $summaryPath)) {
    throw "Missing fixed-price sweep summary: $summaryPath"
}

function Format-Number {
    param(
        [Parameter(Mandatory = $false)]$Value,
        [Parameter(Mandatory = $false)][int]$Digits = 6
    )

    if ($null -eq $Value -or $Value -eq '') {
        return 'NA'
    }

    $number = 0.0
    if ([double]::TryParse($Value.ToString(), [ref]$number)) {
        return ('{0:N' + $Digits + '}') -f $number
    }

    return $Value.ToString()
}

function Add-Line {
    param([string]$Text)
    $script:lines.Add($Text) | Out-Null
}

function Parse-Bool {
    param($Value)
    if ($null -eq $Value) {
        return $false
    }

    $text = $Value.ToString().Trim().ToLowerInvariant()
    return $text -in @('true', '1', 'yes')
}

$rows = Import-Csv $summaryPath | Sort-Object { [double]$_.policy_reference_price }
$stableRows = $rows | Where-Object { Parse-Bool $_.looks_stable }
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$lines = New-Object System.Collections.Generic.List[string]

Add-Line '# Fixed-price policy bridge sweep report'
Add-Line ''
Add-Line "Generated: $timestamp"
Add-Line ''
Add-Line '## Goal'
Add-Line ''
Add-Line '- Test whether the stable fixed-price policy bridge is specific to `2.0` or robust to a neighborhood around that benchmark.'
Add-Line ''
Add-Line '## Cases'
Add-Line ''

foreach ($row in $rows) {
    $stableFlag = if (Parse-Bool $row.looks_stable) { 'yes' } else { 'no' }
    Add-Line "- fixed price $(Format-Number $row.policy_reference_price 2): max gap = $(Format-Number $row.max_abs_gap 6); residual = $(Format-Number $row.residual_norm 6); price range = [$(Format-Number $row.price_min 6), $(Format-Number $row.price_max 6)]; stable = $stableFlag"
}

Add-Line ''
Add-Line '## Read'
Add-Line ''

if ($stableRows.Count -gt 0) {
    $minStable = ($stableRows | Sort-Object { [double]$_.policy_reference_price } | Select-Object -First 1)
    $maxStable = ($stableRows | Sort-Object { [double]$_.policy_reference_price } | Select-Object -Last 1)
    Add-Line "- Stable fixed-price bridges on this grid span [$(Format-Number $minStable.policy_reference_price 2), $(Format-Number $maxStable.policy_reference_price 2)]."
    Add-Line '- That means the current reduced-form object is not tied mechanically to the exact price `2.0`; it is a frozen policy map over a benchmark neighborhood.'
} else {
    Add-Line '- No tested fixed policy-reference price on this grid restored full-horizon stability.'
}

Set-Content -Path $reportPath -Value $lines
Write-Host "Wrote $reportPath"
