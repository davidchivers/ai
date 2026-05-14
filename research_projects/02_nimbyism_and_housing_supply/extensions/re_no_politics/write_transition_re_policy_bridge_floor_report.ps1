$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$summaryPath = Join-Path $thisDir 'transition_re_policy_bridge_floor_sweep_summary.csv'
$pathsPath = Join-Path $thisDir 'transition_re_policy_bridge_floor_sweep_paths.csv'
$reportPath = Join-Path $thisDir 'transition_re_policy_bridge_floor_report.md'

if (-not (Test-Path $summaryPath)) {
    throw "Missing floor sweep summary: $summaryPath"
}

if (-not (Test-Path $pathsPath)) {
    throw "Missing floor sweep paths: $pathsPath"
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
$pathRows = Import-Csv $pathsPath
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$benchmark = $rows | Where-Object { $_.case_name -eq 'steady_state_fixed_price_2_0_benchmark' } | Select-Object -First 1
$unclipped = $rows | Where-Object { $_.case_name -eq 'steady_state_by_period_price_unclipped' } | Select-Object -First 1
$floorRows = $rows |
    Where-Object { $_.case_name -like 'steady_state_by_period_price_floor_*' } |
    Sort-Object { [double]$_.policy_reference_price_floor }

$stableFloorRows = $floorRows | Where-Object { Parse-Bool $_.looks_stable }
$lowestStableFloor = $stableFloorRows | Sort-Object { [double]$_.policy_reference_price_floor } | Select-Object -First 1

$lines = New-Object System.Collections.Generic.List[string]

Add-Line '# Policy bridge floor sweep report'
Add-Line ''
Add-Line "Generated: $timestamp"
Add-Line ''
Add-Line '## Goal'
Add-Line ''
Add-Line '- Keep the within-path policy bridge tied to current prices, but clip that policy reference path from below.'
Add-Line '- Locate the lowest floor that restores full-horizon numerical stability.'
Add-Line '- Interpret the fixed-price bridge as an anchored-expectations object rather than as a one-off numerical trick.'
Add-Line ''
Add-Line '## Benchmark rows'
Add-Line ''

if ($null -ne $benchmark) {
    Add-Line "- fixed-price-2.0 benchmark: max gap = $(Format-Number $benchmark.max_abs_gap 6); residual = $(Format-Number $benchmark.residual_norm 6); price range = [$(Format-Number $benchmark.price_min 6), $(Format-Number $benchmark.price_max 6)]"
}
if ($null -ne $unclipped) {
    Add-Line "- by-period unclipped bridge: max gap = $(Format-Number $unclipped.max_abs_gap 6); residual = $(Format-Number $unclipped.residual_norm 6); price range = [$(Format-Number $unclipped.price_min 6), $(Format-Number $unclipped.price_max 6)]"
}

Add-Line ''
Add-Line '## Floor sweep'
Add-Line ''

foreach ($row in $floorRows) {
    $stableFlag = if (Parse-Bool $row.looks_stable) { 'yes' } else { 'no' }
    $bindings = if ([string]::IsNullOrWhiteSpace($row.policy_reference_floor_binding_periods)) { 'NA' } else { $row.policy_reference_floor_binding_periods }
    Add-Line "- floor $(Format-Number $row.policy_reference_price_floor 2): max gap = $(Format-Number $row.max_abs_gap 6); residual = $(Format-Number $row.residual_norm 6); price range = [$(Format-Number $row.price_min 6), $(Format-Number $row.price_max 6)]; policy-ref range = [$(Format-Number $row.policy_reference_min_used 6), $(Format-Number $row.policy_reference_max_used 6)]; floor bindings = $bindings; stable = $stableFlag"
}

Add-Line ''
Add-Line '## Threshold read'
Add-Line ''

if ($null -ne $lowestStableFloor) {
    $bindingYears = $pathRows |
        Where-Object {
            $_.case_name -eq $lowestStableFloor.case_name -and (Parse-Bool $_.policy_floor_binding)
        } |
        Sort-Object { [int]$_.period_index } |
        ForEach-Object { $_.calendar_year }

    $bindingYearText = if ($bindingYears.Count -gt 0) {
        ($bindingYears -join ', ')
    } else {
        'none'
    }

    Add-Line "- The lowest floor that restores full-horizon stability on this sweep is $(Format-Number $lowestStableFloor.policy_reference_price_floor 2)."
    Add-Line "- At that floor, max gap is $(Format-Number $lowestStableFloor.max_abs_gap 6) and the final price range is [$(Format-Number $lowestStableFloor.price_min 6), $(Format-Number $lowestStableFloor.price_max 6)]."
    Add-Line "- The floor binds in calendar years: $bindingYearText."
} else {
    Add-Line '- No tested by-period floor restored full-horizon stability on this sweep.'
}

Add-Line ''
Add-Line '## Interpretation'
Add-Line ''
Add-Line '- The key margin is not within-path updating itself. The key margin is whether that updating is allowed to follow the low-price tail too far down.'
Add-Line '- If a modest floor restores stability, the fixed-price-2.0 bridge is best read as an anchored-expectations approximation: households update with current prices only inside a benchmark band.'
Add-Line '- If the lowest stable floor lies close to the minimum price on the fixed-price benchmark path, that sharpens the earlier diagnosis that low current-price policy feedback is the object that reintroduces the blow-up.'
Add-Line ''

Set-Content -Path $reportPath -Value $lines
Write-Host "Wrote $reportPath"
