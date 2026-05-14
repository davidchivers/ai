$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$summaryPath = Join-Path $thisDir 'transition_re_joint_price_vote_summary.csv'
$periodsPath = Join-Path $thisDir 'transition_re_joint_price_vote_periods.csv'
$reportPath = Join-Path $thisDir 'transition_re_joint_price_vote_report.md'

if (-not (Test-Path $summaryPath)) {
    throw "Missing joint price-vote summary: $summaryPath"
}
if (-not (Test-Path $periodsPath)) {
    throw "Missing joint price-vote periods: $periodsPath"
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

$summary = Import-Csv $summaryPath
$periods = Import-Csv $periodsPath
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$lines = New-Object System.Collections.Generic.List[string]

Add-Line '# Joint price and vote experiment report'
Add-Line ''
Add-Line "Generated: $timestamp"
Add-Line ''
Add-Line '## Goal'
Add-Line ''
Add-Line '- Take the bounded `T = 4` political-path packet one step further by feeding political pressure back into the price path.'
Add-Line '- Keep the update heuristic and bounded: one housing solve per outer step, then a small log-price adjustment proportional to coalition-weighted vote share.'
Add-Line ''
Add-Line '## Iteration summary'
Add-Line ''

foreach ($row in $summary) {
    Add-Line "- joint iter $($row.joint_iter): residual norm = $(Format-Number $row.residual_norm 6); max price gap = $(Format-Number $row.max_abs_gap 6); max abs weighted vote = $(Format-Number $row.max_abs_weighted_vote 6); adjusted price range = [$(Format-Number $row.price_min 6), $(Format-Number $row.price_max 6)]"
}

$lastIter = ($summary | Sort-Object {[int]$_.joint_iter} | Select-Object -Last 1).joint_iter
$lastRows = $periods | Where-Object { $_.joint_iter -eq $lastIter }

Add-Line ''
Add-Line "## Final joint iteration (`$joint\_iter = $lastIter`)"
Add-Line ''

foreach ($row in $lastRows) {
    Add-Line "- $($row.year): input = $(Format-Number $row.input_price 6); housing candidate = $(Format-Number $row.housing_candidate_price 6); weighted vote share = $(Format-Number $row.weighted_vote_share 6); politically adjusted = $(Format-Number $row.politically_adjusted_price 6); implied = $(Format-Number $row.implied_price 6)"
}

Add-Line ''
Add-Line '## Read'
Add-Line ''
Add-Line '- This is still not a solved political RE fixed point. It is a bounded joint-update experiment.'
Add-Line '- The point is to see whether political pressure pushes in the same direction as the housing-clearing update or against it.'
Add-Line '- If coalition-weighted vote share is negative while implied prices are above the current path, then the two forces are working against each other.'
Add-Line '- That is the crucial bounded diagnostic before attempting a more serious joint solver.'
Add-Line ''

Set-Content -Path $reportPath -Value $lines
Write-Host "Wrote $reportPath"
