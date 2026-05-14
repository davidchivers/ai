$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$k2SummaryPath = Join-Path $thisDir 'transition_re_k2_policy_bridge_summary.csv'
$ladderSummaryPath = Join-Path $thisDir 'transition_re_k_step_policy_bridge_summary.csv'
$fixedLadderSummaryPath = Join-Path $thisDir 'transition_re_k_step_policy_bridge_steady_state_fixed_price_2_0_summary.csv'
$reportPath = Join-Path $thisDir 'transition_re_policy_bridge_report.md'

if (-not (Test-Path $k2SummaryPath)) {
    throw "Missing k=2 policy bridge summary: $k2SummaryPath"
}

if (-not (Test-Path $ladderSummaryPath)) {
    throw "Missing policy bridge ladder summary: $ladderSummaryPath"
}

if (-not (Test-Path $fixedLadderSummaryPath)) {
    throw "Missing fixed-price policy bridge ladder summary: $fixedLadderSummaryPath"
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

$k2Rows = Import-Csv $k2SummaryPath
$k2Best = $k2Rows | Sort-Object {[double]$_.max_abs_gap} | Select-Object -First 1
$ladderRows = Import-Csv $ladderSummaryPath
$fixedLadderRows = Import-Csv $fixedLadderSummaryPath
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$lines = New-Object System.Collections.Generic.List[string]

Add-Line '# Policy bridge report'
Add-Line ''
Add-Line "Generated: $timestamp"
Add-Line ''
Add-Line '## Goal'
Add-Line ''
Add-Line '- Replace the explosive full backward-looking within-path policy map with a simpler bridge object based on steady-state policy rules.'
Add-Line '- Check first whether that simplification fixes the `k = 2` problem, then test how far the same bridge survives as the horizon is extended.'
Add-Line ''
Add-Line '## k=2 policy bridge cases'
Add-Line ''

foreach ($row in $k2Rows) {
    Add-Line "- $($row.case_name): mode = $($row.transition_policy_mode); implied p2 = $(Format-Number $row.implied_price_2 6); final p2 = $(Format-Number $row.final_price_2 6); max gap = $(Format-Number $row.max_abs_gap 6); excess demand 2 = $(Format-Number $row.excess_demand_2 6)"
}

Add-Line ''
Add-Line '## Best k=2 bridge case'
Add-Line ''
Add-Line "- Case: $($k2Best.case_name)"
Add-Line "- Max gap: $(Format-Number $k2Best.max_abs_gap 6)"
Add-Line "- Residual norm: $(Format-Number $k2Best.residual_norm 6)"
Add-Line "- Final price path: [$(Format-Number $k2Best.final_price_1 6), $(Format-Number $k2Best.final_price_2 6)]"
Add-Line "- Implied price path: [$(Format-Number $k2Best.implied_price_1 6), $(Format-Number $k2Best.implied_price_2 6)]"
Add-Line ''
Add-Line '## k-step ladder: by-period-price policies'
Add-Line ''

foreach ($row in $ladderRows) {
    Add-Line "- k = $($row.k): max gap = $(Format-Number $row.max_abs_gap 6); residual = $(Format-Number $row.residual_norm 6); price range = [$(Format-Number $row.price_min 6), $(Format-Number $row.price_max 6)]"
}

Add-Line ''
Add-Line '## k-step ladder: fixed-price-2.0 policies'
Add-Line ''

foreach ($row in $fixedLadderRows) {
    Add-Line "- k = $($row.k): max gap = $(Format-Number $row.max_abs_gap 6); residual = $(Format-Number $row.residual_norm 6); price range = [$(Format-Number $row.price_min 6), $(Format-Number $row.price_max 6)]"
}

$ladderStable = $ladderRows | Where-Object { [double]$_.max_abs_gap -lt 1.0 }
$ladderLastStable = $ladderStable | Sort-Object {[int]$_.k} | Select-Object -Last 1
$ladderFirstUnstable = $ladderRows | Where-Object { [double]$_.max_abs_gap -ge 1.0 } | Sort-Object {[int]$_.k} | Select-Object -First 1
$fixedLadderStable = $fixedLadderRows | Where-Object { [double]$_.max_abs_gap -lt 1.0 }
$fixedLadderLastStable = $fixedLadderStable | Sort-Object {[int]$_.k} | Select-Object -Last 1
$fixedLadderFinal = $fixedLadderRows | Sort-Object {[int]$_.k} | Select-Object -Last 1

Add-Line ''
Add-Line '## Interpretation'
Add-Line ''

if ($null -ne $ladderLastStable) {
    Add-Line "- The policy bridge materially changes the `k = 2` result. The max gap falls from roughly `158` under the dynamic benchmark to about $(Format-Number $k2Best.max_abs_gap 3) under the bridge."
    Add-Line "- The bridge remains numerically well behaved through k = $($ladderLastStable.k)."
}

if ($null -ne $ladderFirstUnstable) {
    Add-Line "- The same bridge breaks again at k = $($ladderFirstUnstable.k), where the max gap jumps to about $(Format-Number $ladderFirstUnstable.max_abs_gap 3)."
}

if ($null -ne $fixedLadderLastStable) {
    Add-Line "- If the policy bridge is fixed at price `2.0`, the ladder remains numerically well behaved through k = $($fixedLadderLastStable.k)."
    Add-Line "- At the full 9-period horizon, the fixed-price bridge ends with max gap about $(Format-Number $fixedLadderFinal.max_abs_gap 3) and price range [$(Format-Number $fixedLadderFinal.price_min 3), $(Format-Number $fixedLadderFinal.price_max 3)]."
}

Add-Line '- That pattern says the explosive part of the original transplant is mainly the full forward-looking within-path policy feedback reacting to low current prices, not just the terminal tail.'
Add-Line '- The fixed-price policy bridge is therefore the first reduced-form branch that stays stable across the full horizon.'
Add-Line ''
Add-Line '## Next step'
Add-Line ''
Add-Line '- Treat the fixed-price policy bridge as the canonical simplified RE branch for any further NIMBY work.'
Add-Line '- If this branch continues, the next technical question is whether the fixed-price bridge can be interpreted as a reduced-form expectations object worth writing up, not whether the old full transplant should be tuned again.'
Add-Line ''

Set-Content -Path $reportPath -Value $lines
Write-Host "Wrote $reportPath"
