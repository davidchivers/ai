$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$reportPath = Join-Path $thisDir 'coalition_benchmark_report.md'
$summaryPath = Join-Path $thisDir 'coalition_benchmark_summary.csv'
$liveSummaryPath = Join-Path $thisDir 'coalition_benchmark_summary_live.csv'

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

$lines = New-Object System.Collections.Generic.List[string]
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

Add-Line '# Coalition benchmark report'
Add-Line ''
Add-Line "Generated: $timestamp"
Add-Line ''

if (Test-Path $summaryPath) {
    $tbl = Import-Csv $summaryPath
    $benchmark = $tbl | Where-Object { $_.case_name -eq 'benchmark_equal_weight' } | Select-Object -First 1
    $combined = $tbl | Where-Object { $_.case_name -eq 'combined_default' } | Select-Object -First 1

    Add-Line '## Benchmark'
    Add-Line ''
    Add-Line "- Benchmark case: $($benchmark.case_name)"
    Add-Line "- Best price: $(Format-Number $benchmark.best_price 6)"
    Add-Line "- Weighted vote: $(Format-Number $benchmark.weighted_vote 6)"
    Add-Line "- Equal-weight vote: $(Format-Number $benchmark.equal_weight_vote 6)"
    Add-Line "- Debt stock: $(Format-Number $benchmark.debtstock 6)"
    Add-Line ''

    Add-Line '## Combined coalition case'
    Add-Line ''
    Add-Line "- Case: $($combined.case_name)"
    Add-Line "- Best price: $(Format-Number $combined.best_price 6)"
    Add-Line "- Price shift vs benchmark: $(Format-Number $combined.benchmark_price_diff 6)"
    Add-Line "- Weighted vote shift vs benchmark: $(Format-Number $combined.benchmark_weighted_vote_diff 6)"
    Add-Line "- Debt stock shift vs benchmark: $(Format-Number $combined.benchmark_debtstock_diff 6)"
    Add-Line ''

    Add-Line '## One-margin cases'
    Add-Line ''
    $oneMargin = $tbl | Where-Object { $_.case_name -ne 'benchmark_equal_weight' -and $_.case_name -ne 'combined_default' }
    foreach ($row in $oneMargin) {
        Add-Line "- $($row.case_name): price shift = $(Format-Number $row.benchmark_price_diff 6), weighted-vote shift = $(Format-Number $row.benchmark_weighted_vote_diff 6), debt-stock shift = $(Format-Number $row.benchmark_debtstock_diff 6)"
    }
} elseif (Test-Path $liveSummaryPath) {
    $tbl = Import-Csv $liveSummaryPath
    Add-Line '## Status'
    Add-Line ''
    Add-Line "- Coalition benchmark run is in progress."
    Add-Line "- Completed rows: $($tbl.Count)"
} else {
    Add-Line '## Status'
    Add-Line ''
    Add-Line '- Coalition benchmark run has not started yet.'
}

Set-Content -Path $reportPath -Value $lines
Write-Host "Wrote $reportPath"
