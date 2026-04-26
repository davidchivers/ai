param(
    [string]$RunTag = "",
    [string]$TSchedule = "12",
    [string]$PhiGrid = "0.03,0.06,0.10,0.15",
    [string]$GammaGrid = "0.50,1.00,1.50",
    [string]$RhoGrid = "0,0.50,0.85",
    [string]$VoteScaleGrid = "0.015,0.020,0.030",
    [int]$MaxCandidatesPerVoteScale = 3,
    [int]$PeriodIter = 2
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthRoot = Join-Path $scriptRoot "truth\annual_political_broad_grid_fail_safe"
New-Item -ItemType Directory -Force -Path $truthRoot | Out-Null

if ([string]::IsNullOrWhiteSpace($RunTag)) {
    $RunTag = "annual_broad_grid_" + (Get-Date -Format "yyyyMMdd_HHmmss")
}

$outDir = Join-Path $truthRoot $RunTag
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$statusPath = Join-Path $truthRoot "latest_status.json"

function Write-Status {
    param([string]$State, [string]$Message)
    $payload = [ordered]@{
        state = $State
        message = $Message
        run_tag = $RunTag
        output_dir = $outDir
        updated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    ($payload | ConvertTo-Json -Compress) | Set-Content -Path $statusPath
}

function Safe-ScaleTag {
    param([double]$Value)
    return ("{0:0.000}" -f $Value).Replace(".", "p")
}

Write-Status "running" "Starting saved-grid broad map stage."

$mapRunner = Join-Path $scriptRoot "run_annual_political_permit_passthrough_map_smoke.ps1"
$dynamicRunner = Join-Path $scriptRoot "run_annual_political_transition_fail_safe.ps1"
$mapRoot = Join-Path $scriptRoot "truth\annual_political_permit_passthrough_map"

$voteScales = $VoteScaleGrid -split "," | ForEach-Object { [double]$_.Trim() }
$allMapRows = @()

foreach ($voteScale in $voteScales) {
    $scaleTag = Safe-ScaleTag $voteScale
    $mapTag = "${RunTag}_map_vs${scaleTag}"
    Write-Status "running" "Running saved-grid map for vote_scale=$voteScale."
    & powershell -NoProfile -ExecutionPolicy Bypass -File $mapRunner `
        -RunTag $mapTag `
        -T 12 `
        -PhiGrid $PhiGrid `
        -GammaGrid $GammaGrid `
        -RhoGrid $RhoGrid `
        -VoteScale $voteScale

    $summaryPath = Join-Path $mapRoot "$mapTag\summary.csv"
    $rows = Import-Csv $summaryPath | ForEach-Object {
        [pscustomobject]@{
            vote_scale = $voteScale
            row_id = [int]$_.row_id
            verdict = $_.verdict
            rho = [double]$_.rho
            phi = [double]$_.phi
            gamma = [double]$_.gamma
            max_abs_vote_resid = [double]$_.max_abs_vote_resid
            mean_abs_vote_resid = [double]$_.mean_abs_vote_resid
            improvement_vs_constant = [double]$_.improvement_vs_constant
            max_abs_log_price_move = [double]$_.max_abs_log_price_move
            grid_hit_share = [double]$_.grid_hit_share
            source_map_tag = $mapTag
        }
    }
    $allMapRows += $rows
}

$allMapCsv = Join-Path $outDir "map_summary_all.csv"
$allMapRows | Export-Csv -Path $allMapCsv -NoTypeInformation

$candidatePool = $allMapRows | Where-Object {
    @("usable", "survivor", "weak_survivor") -contains $_.verdict -and
    $_.grid_hit_share -eq 0 -and
    $_.max_abs_log_price_move -le 0.12
}

if (-not $candidatePool -or $candidatePool.Count -eq 0) {
    Write-Status "stopped" "Map stage found no dynamic candidates."
    "No candidates passed map filters." | Set-Content -Path (Join-Path $outDir "note.md")
    exit 0
}

$selected = @()
foreach ($voteScale in $voteScales) {
    $selected += $candidatePool |
        Where-Object { [math]::Abs($_.vote_scale - $voteScale) -lt 1e-12 } |
        Sort-Object max_abs_vote_resid, max_abs_log_price_move |
        Select-Object -First $MaxCandidatesPerVoteScale
}

$selectedCsv = Join-Path $outDir "selected_dynamic_candidates.csv"
$selected | Export-Csv -Path $selectedCsv -NoTypeInformation

Write-Status "running" "Selected $($selected.Count) dynamic candidates from map stage."

$dynamicSummaries = @()
foreach ($voteScale in $voteScales) {
    $group = @($selected | Where-Object { [math]::Abs($_.vote_scale - $voteScale) -lt 1e-12 })
    if ($group.Count -eq 0) {
        continue
    }
    $scaleTag = Safe-ScaleTag $voteScale
    $dynTag = "${RunTag}_dyn_vs${scaleTag}"
    $candidateMat = ($group | ForEach-Object {
        ("{0} {1} {2}" -f $_.rho, $_.phi, $_.gamma)
    }) -join "; "

    Write-Status "running" "Running dynamic annual stage for vote_scale=$voteScale with $($group.Count) candidates."
    & powershell -NoProfile -ExecutionPolicy Bypass -File $dynamicRunner `
        -RunTag $dynTag `
        -TSchedule $TSchedule `
        -PeriodIter $PeriodIter `
        -VoteScale $voteScale `
        -CandidatesMat $candidateMat

    $dynSummaryPath = Join-Path $scriptRoot "truth\annual_political_transition_fail_safe\$dynTag\summary_all.csv"
    if (Test-Path $dynSummaryPath) {
        $dynamicSummaries += Import-Csv $dynSummaryPath | ForEach-Object {
            $_ | Add-Member -NotePropertyName vote_scale -NotePropertyValue $voteScale -PassThru |
                 Add-Member -NotePropertyName dynamic_run_tag -NotePropertyValue $dynTag -PassThru
        }
    }
}

if ($dynamicSummaries.Count -gt 0) {
    $dynamicSummaries | Export-Csv -Path (Join-Path $outDir "dynamic_summary_all.csv") -NoTypeInformation
}

@(
    "# Annual Political Broad Grid Fail-Safe"
    ""
    "- run tag: $RunTag"
    "- T schedule: $TSchedule"
    "- map rows: $($allMapRows.Count)"
    "- selected dynamic candidates: $($selected.Count)"
    "- dynamic summary rows: $($dynamicSummaries.Count)"
    ""
    "The controller ran broad saved-grid maps first, then annual dynamic transition solves only for selected survivors."
) | Set-Content -Path (Join-Path $outDir "note.md")

Write-Status "complete" "Annual broad-grid fail-safe complete."
