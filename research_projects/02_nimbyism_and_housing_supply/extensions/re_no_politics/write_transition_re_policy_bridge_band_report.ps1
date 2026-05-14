$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$summaryPath = Join-Path $thisDir 'transition_re_policy_bridge_band_sweep_summary.csv'
$reportPath = Join-Path $thisDir 'transition_re_policy_bridge_band_report.md'

if (-not (Test-Path $summaryPath)) {
    throw "Missing band sweep summary: $summaryPath"
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

$rows = Import-Csv $summaryPath
$benchmark = $rows | Where-Object { $_.case_name -eq 'steady_state_fixed_price_2_0_benchmark' } | Select-Object -First 1
$bandRows = $rows | Where-Object { $_.case_name -like 'steady_state_by_period_price_band_*' }
$stableBands = $bandRows | Where-Object { Parse-Bool $_.looks_stable }
$bestBand = $stableBands | Sort-Object { [double]$_.policy_reference_price_cap - [double]$_.policy_reference_price_floor } | Select-Object -First 1
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$lines = New-Object System.Collections.Generic.List[string]

Add-Line '# Policy bridge band sweep report'
Add-Line ''
Add-Line "Generated: $timestamp"
Add-Line ''
Add-Line '## Goal'
Add-Line ''
Add-Line '- Test whether the fixed-price bridge can be relaxed into a narrow benchmark band around `2.0`.'
Add-Line '- Separate the role of low-price and high-price policy feedback.'
Add-Line ''
Add-Line '## Benchmark row'
Add-Line ''
Add-Line "- fixed-price-2.0 benchmark: max gap = $(Format-Number $benchmark.max_abs_gap 6); residual = $(Format-Number $benchmark.residual_norm 6); price range = [$(Format-Number $benchmark.price_min 6), $(Format-Number $benchmark.price_max 6)]"
Add-Line ''
Add-Line '## Band cases'
Add-Line ''

foreach ($row in $bandRows) {
    $stableFlag = if (Parse-Bool $row.looks_stable) { 'yes' } else { 'no' }
    Add-Line "- band [$(Format-Number $row.policy_reference_price_floor 2), $(Format-Number $row.policy_reference_price_cap 2)]: max gap = $(Format-Number $row.max_abs_gap 6); residual = $(Format-Number $row.residual_norm 6); price range = [$(Format-Number $row.price_min 6), $(Format-Number $row.price_max 6)]; stable = $stableFlag"
}

Add-Line ''
Add-Line '## Read'
Add-Line ''

if ($null -ne $bestBand) {
    Add-Line "- The narrowest stable band on this grid is [$(Format-Number $bestBand.policy_reference_price_floor 2), $(Format-Number $bestBand.policy_reference_price_cap 2)]."
    Add-Line "- That means the fixed-price bridge can be relaxed into a bounded benchmark band without reopening the instability."
} else {
    Add-Line '- No tested benchmark band restored the same level of stability as the fixed-price bridge.'
    Add-Line '- That points back to a stronger interpretation: the current best reduced-form expectations object is a nearly frozen benchmark-price policy map, not merely a clipped current-price rule.'
}

Set-Content -Path $reportPath -Value $lines
Write-Host "Wrote $reportPath"
