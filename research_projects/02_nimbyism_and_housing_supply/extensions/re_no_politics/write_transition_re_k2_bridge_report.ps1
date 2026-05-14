$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$summaryPath = Join-Path $thisDir 'transition_re_k2_bridge_summary.csv'
$reportPath = Join-Path $thisDir 'transition_re_k2_bridge_report.md'

if (-not (Test-Path $summaryPath)) {
    throw "Missing bridge summary: $summaryPath"
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

$rows = Import-Csv $summaryPath
$okRows = $rows | Where-Object { $_.status -eq 'ok' }
$rankedRows = $okRows | Sort-Object {[double]$_.max_abs_gap}
$bestRow = $rankedRows | Select-Object -First 1
$worstRow = $rankedRows | Select-Object -Last 1
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$lines = New-Object System.Collections.Generic.List[string]

Add-Line '# k=2 bridge report'
Add-Line ''
Add-Line "Generated: $timestamp"
Add-Line ''
Add-Line '## Goal'
Add-Line ''
Add-Line '- Test whether the immediate `k = 2` instability is mainly being driven by the terminal steady-state continuation object.'
Add-Line '- Hold the rest of the fertility-style bounded solve fixed and vary only how the terminal reference price is chosen.'
Add-Line ''
Add-Line '## Cases'
Add-Line ''

foreach ($row in $rows) {
    Add-Line "- $($row.case_name): mode = $($row.terminal_reference_mode); terminal reference price used = $(Format-Number $row.terminal_reference_price_used 6); final p2 = $(Format-Number $row.final_price_2 6); implied p2 = $(Format-Number $row.implied_price_2 6); max gap = $(Format-Number $row.max_abs_gap 6)"
}

Add-Line ''
Add-Line '## Best current bridge case'
Add-Line ''

if ($null -ne $bestRow) {
    Add-Line "- Case: $($bestRow.case_name)"
    Add-Line "- Max gap: $(Format-Number $bestRow.max_abs_gap 6)"
    Add-Line "- Residual norm: $(Format-Number $bestRow.residual_norm 6)"
    Add-Line "- Final price path: [$(Format-Number $bestRow.final_price_1 6), $(Format-Number $bestRow.final_price_2 6)]"
    Add-Line "- Implied price path: [$(Format-Number $bestRow.implied_price_1 6), $(Format-Number $bestRow.implied_price_2 6)]"
    Add-Line "- Excess demand path: [$(Format-Number $bestRow.excess_demand_1 6), $(Format-Number $bestRow.excess_demand_2 6)]"
}
else {
    Add-Line '- No completed rows were available.'
}

Add-Line ''
Add-Line '## Interpretation'
Add-Line ''

if ($null -ne $bestRow -and $null -ne $worstRow) {
    $bestGap = [double]$bestRow.max_abs_gap
    $worstGap = [double]$worstRow.max_abs_gap
    $bestImpliedP2 = [double]$bestRow.implied_price_2

    if ($bestGap -lt 5 -and $bestImpliedP2 -lt 10) {
        Add-Line '- At least one terminal-tail simplification materially calms the `k = 2` map. The next step should be to formalize that bridge rather than returning to the full transplant.'
    }
    elseif ($bestGap -lt $worstGap * 0.5) {
        Add-Line '- Tail simplification helps a lot, but it does not fully solve the problem. The terminal continuation block is part of the instability, but not the whole story.'
    }
    else {
        Add-Line '- Tail simplification alone does not materially fix the `k = 2` instability. That points away from the terminal steady-state tail as the sole bottleneck.'
    }
}
else {
    Add-Line '- Interpretation unavailable because no completed rows were found.'
}

Add-Line ''
Add-Line '## Next step'
Add-Line ''
Add-Line '- If one case clearly dominates, build the next reduced-form bridge around that case.'
Add-Line '- If all cases remain explosive, simplify the within-period or age-profile object next rather than only the terminal tail.'
Add-Line ''

Set-Content -Path $reportPath -Value $lines
Write-Host "Wrote $reportPath"
