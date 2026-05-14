$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$summaryPath = Join-Path $thisDir 'transition_re_political_path_summary.csv'
$periodsPath = Join-Path $thisDir 'transition_re_political_path_periods.csv'
$reportPath = Join-Path $thisDir 'transition_re_political_path_report.md'

if (-not (Test-Path $summaryPath)) {
    throw "Missing political path summary: $summaryPath"
}
if (-not (Test-Path $periodsPath)) {
    throw "Missing political path periods: $periodsPath"
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

$summary = Import-Csv $summaryPath | Select-Object -First 1
$periods = Import-Csv $periodsPath
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$worstEqual = $periods | Sort-Object { [math]::Abs([double]$_.equal_weight_vote) } -Descending | Select-Object -First 1
$worstWeighted = $periods | Sort-Object { [math]::Abs([double]$_.weighted_vote) } -Descending | Select-Object -First 1

$lines = New-Object System.Collections.Generic.List[string]

Add-Line '# Political path diagnostic report'
Add-Line ''
Add-Line "Generated: $timestamp"
Add-Line ''
Add-Line '## Goal'
Add-Line ''
Add-Line '- Build the first bounded transition packet that combines the shared Bellman preference-sign object with period-by-period political aggregation.'
Add-Line '- Keep the run bounded: first 4 periods, one outer iteration, full backward household solve.'
Add-Line ''
Add-Line '## Summary'
Add-Line ''
Add-Line "- Case: $($summary.case_name)"
Add-Line "- Horizon: $($summary.horizon_k) periods"
Add-Line "- Guess source: $($summary.guess_source)"
Add-Line "- Iterations completed: $($summary.iterations_completed)"
Add-Line "- Residual norm: $(Format-Number $summary.residual_norm 6)"
Add-Line "- Max price gap: $(Format-Number $summary.max_abs_gap 6)"
Add-Line "- Accepted update: $($summary.accepted_update)"
Add-Line "- Max abs equal-weight vote: $(Format-Number $summary.max_abs_equal_weight_vote 6)"
Add-Line "- Max abs coalition-weighted vote: $(Format-Number $summary.max_abs_weighted_vote 6)"
Add-Line "- Price range after update: [$(Format-Number $summary.price_min 6), $(Format-Number $summary.price_max 6)]"
Add-Line "- Runtime: $(Format-Number $summary.elapsed_seconds 2) seconds"
Add-Line ''
Add-Line '## Period path'
Add-Line ''

foreach ($row in $periods) {
    Add-Line "- $($row.year): guess = $(Format-Number $row.price_guess 6); final = $(Format-Number $row.final_price 6); implied = $(Format-Number $row.implied_price 6); excess demand = $(Format-Number $row.excess_demand 6); equal-weight vote = $(Format-Number $row.equal_weight_vote 6); weighted vote = $(Format-Number $row.weighted_vote 6)"
}

Add-Line ''
Add-Line '## Diagnostic read'
Add-Line ''
Add-Line "- Worst equal-weight political pressure appears in $($worstEqual.year), with vote = $(Format-Number $worstEqual.equal_weight_vote 6)."
Add-Line "- Worst coalition-weighted political pressure appears in $($worstWeighted.year), with weighted vote = $(Format-Number $worstWeighted.weighted_vote 6)."
Add-Line '- This packet does not solve the full political RE fixed point. It gives the missing time-varying political residual path conditional on the current bounded transition solve.'
Add-Line '- That is the right next object because it tells us whether the political imbalance is concentrated in the same periods as the house-price residuals.'
Add-Line ''
Add-Line '## Next step'
Add-Line ''
Add-Line '- Promote this bounded political-path packet into either a longer-horizon diagnostic or a joint price-plus-vote update rule.'
Add-Line '- If we keep the solver bounded, the clean next escalation is a T=4 political update experiment rather than jumping straight to the full 2010-2018 fixed point.'
Add-Line ''

Set-Content -Path $reportPath -Value $lines
Write-Host "Wrote $reportPath"
