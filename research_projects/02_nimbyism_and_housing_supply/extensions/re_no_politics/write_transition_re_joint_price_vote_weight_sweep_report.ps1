$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$summaryPath = Join-Path $thisDir 'transition_re_joint_price_vote_weight_sweep_summary.csv'
$periodsPath = Join-Path $thisDir 'transition_re_joint_price_vote_weight_sweep_periods.csv'
$reportPath = Join-Path $thisDir 'transition_re_joint_price_vote_weight_sweep_report.md'

if (-not (Test-Path $summaryPath)) {
    throw "Missing vote-weight sweep summary: $summaryPath"
}
if (-not (Test-Path $periodsPath)) {
    throw "Missing vote-weight sweep periods: $periodsPath"
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

$summary = Import-Csv $summaryPath | Sort-Object {[double]$_.vote_weight}
$periods = Import-Csv $periodsPath
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$lines = New-Object System.Collections.Generic.List[string]

Add-Line '# Joint price and vote weight sweep report'
Add-Line ''
Add-Line "Generated: $timestamp"
Add-Line ''
Add-Line '## Goal'
Add-Line ''
Add-Line '- Check whether the bounded conflict between housing pressure and political pressure is robust to the political update weight.'
Add-Line '- Hold the underlying `T = 4` housing solve fixed and vary only the vote-update weight.'
Add-Line ''
Add-Line '## Summary'
Add-Line ''

foreach ($row in $summary) {
    Add-Line "- weight = $(Format-Number $row.vote_weight 4): adjusted range = [$(Format-Number $row.price_min 6), $(Format-Number $row.price_max 6)]; mean adjustment = $(Format-Number $row.mean_adjustment 6); max abs adjustment = $(Format-Number $row.max_abs_adjustment 6); conflict share = $(Format-Number $row.conflict_period_share 3)"
}

$heaviest = $summary | Select-Object -Last 1
$heaviestRows = $periods | Where-Object { $_.vote_weight -eq $heaviest.vote_weight }

Add-Line ''
Add-Line "## Highest tested weight (`$\omega_{vote} = $($heaviest.vote_weight)`)"
Add-Line ''

foreach ($row in $heaviestRows) {
    Add-Line "- $($row.year): housing candidate = $(Format-Number $row.housing_candidate_price 6); vote share = $(Format-Number $row.weighted_vote_share 6); adjusted price = $(Format-Number $row.adjusted_price 6); conflict = $($row.conflict)"
}

Add-Line ''
Add-Line '## Read'
Add-Line ''
Add-Line '- The base bounded housing solve is unchanged across the sweep; only the political feedback weight moves.'
Add-Line '- If conflict share stays high across the whole weight grid, then the sign opposition is structural under the current bounded packet, not a quirk of the original `0.001` choice.'
Add-Line '- If larger weights only scale the downward adjustment while preserving the same sign pattern, then the main conclusion is robust: the political update pushes against the housing-clearing update.'
Add-Line ''

Set-Content -Path $reportPath -Value $lines
Write-Host "Wrote $reportPath"
