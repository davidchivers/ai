param(
    [string]$PackDir = "",
    [string]$SweepCli = "",
    [string]$LiveRoot = "",
    [double]$PriceStart = 0.3401,
    [double]$PriceEnd = 0.34015,
    [int]$PriceCount = 21,
    [double]$PriceMultiplier = 1.01,
    [int]$MaxStages = 8,
    [double]$MaxHours = 10.0,
    [double]$BracketWidthTolerance = 1e-7,
    [double]$VoteTolerance = 1e-4
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$compiledSidecarDir = Join-Path $projectRoot "extensions\re_no_politics\compiled_sidecar"

if ([string]::IsNullOrWhiteSpace($PackDir)) {
    $PackDir = Join-Path $compiledSidecarDir "truth\steady_state_original_p2_rb0_03"
}
if ([string]::IsNullOrWhiteSpace($SweepCli)) {
    $SweepCli = Join-Path $compiledSidecarDir "build_noomp\nimby_steady_state_political_sweep_cli.exe"
}
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\compiled_original_steady_state_overnight_live"
}

New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null
$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path (Join-Path $LiveRoot "r") ("co_" + $runStamp)
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

$statusPath = Join-Path $runDir "status.json"
$summaryPath = Join-Path $runDir "summary.md"
$logPath = Join-Path $runDir "workflow_log.txt"
$activePath = Join-Path $LiveRoot "active_run.txt"
$globalStatusPath = Join-Path $LiveRoot "latest_status.json"
$resultJsonPath = Join-Path $runDir "final_result.json"

Set-Content -Path $activePath -Value $runDir
$startedAt = Get-Date

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

function Write-Status {
    param(
        [string]$CurrentStep,
        [string]$State,
        [hashtable]$Payload
    )
    $obj = [ordered]@{
        run_dir = $runDir
        current_step = $CurrentStep
        state = $State
        updated_at = (Get-Date).ToString("s")
        payload = $Payload
    }
    $json = $obj | ConvertTo-Json -Depth 8
    Set-Content -Path $statusPath -Value $json
    Set-Content -Path $globalStatusPath -Value $json
}

function Import-SweepSummary {
    param([string]$SummaryCsv)
    return Import-Csv -Path $SummaryCsv | Select-Object -First 1
}

function Import-SweepRows {
    param([string]$DetailCsv)
    return @(Import-Csv -Path $DetailCsv)
}

function Get-SweepAnalysis {
    param(
        [string]$SummaryCsv,
        [string]$DetailCsv,
        [string]$StageName,
        [double]$StagePriceStart,
        [double]$StagePriceEnd,
        [int]$StagePriceCount
    )

    $summary = Import-SweepSummary -SummaryCsv $SummaryCsv
    $rows = Import-SweepRows -DetailCsv $DetailCsv
    $votes = @($rows | ForEach-Object { [double]$_.totalvote })
    $prices = @($rows | ForEach-Object { [double]$_.price })
    $bestRow = $rows | Sort-Object { [Math]::Abs([double]$_.totalvote) } | Select-Object -First 1

    $minVote = ($votes | Measure-Object -Minimum).Minimum
    $maxVote = ($votes | Measure-Object -Maximum).Maximum
    $signPattern = if ($maxVote -lt 0.0) {
        "all_negative"
    } elseif ($minVote -gt 0.0) {
        "all_positive"
    } elseif ([int]$summary.has_vote_bracket -eq 1) {
        "bracket"
    } else {
        "mixed_no_adjacent_bracket"
    }

    return [pscustomobject]@{
        stage_name = $StageName
        price_start = $StagePriceStart
        price_end = $StagePriceEnd
        price_count = $StagePriceCount
        price_multiplier = [double]$summary.price_multiplier
        best_distance = [double]$summary.best_distance
        best_distance_price = [double]$summary.best_distance_price
        best_vote_abs = [double]$summary.best_vote_abs
        best_vote_abs_price = [double]$summary.best_vote_abs_price
        has_vote_bracket = ([int]$summary.has_vote_bracket -eq 1)
        bracket_low_price = [double]$summary.bracket_low_price
        bracket_high_price = [double]$summary.bracket_high_price
        bracket_low_vote = [double]$summary.bracket_low_vote
        bracket_high_vote = [double]$summary.bracket_high_vote
        min_vote = $minVote
        max_vote = $maxVote
        sign_pattern = $signPattern
        best_vote = [double]$bestRow.totalvote
        summary_csv = $SummaryCsv
        detail_csv = $DetailCsv
    }
}

function Invoke-PoliticalSweep {
    param(
        [string]$StageName,
        [double]$StagePriceStart,
        [double]$StagePriceEnd,
        [int]$StagePriceCount
    )

    $outputDir = Join-Path $runDir $StageName
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

    Write-Status -CurrentStep $StageName -State "running" -Payload @{
        pack_dir = $PackDir
        output_dir = $outputDir
        price_start = $StagePriceStart
        price_end = $StagePriceEnd
        price_count = $StagePriceCount
        price_multiplier = $PriceMultiplier
    }
    Write-Log "Running compiled political sweep $StageName on [$StagePriceStart, $StagePriceEnd] with $StagePriceCount points."

    & $SweepCli $PackDir `
        --price-min $StagePriceStart `
        --price-max $StagePriceEnd `
        --price-count $StagePriceCount `
        --price-multiplier $PriceMultiplier `
        --output-dir $outputDir | Out-Null

    return Get-SweepAnalysis `
        -SummaryCsv (Join-Path $outputDir "sidecar_steady_state_political_summary.csv") `
        -DetailCsv (Join-Path $outputDir "sidecar_steady_state_political_sweep.csv") `
        -StageName $StageName `
        -StagePriceStart $StagePriceStart `
        -StagePriceEnd $StagePriceEnd `
        -StagePriceCount $StagePriceCount
}

function Get-NextRange {
    param(
        [pscustomobject]$Analysis,
        [double]$CurrentStart,
        [double]$CurrentEnd
    )

    $currentWidth = [Math]::Max($CurrentEnd - $CurrentStart, 1e-12)
    if ($Analysis.has_vote_bracket) {
        return [pscustomobject]@{
            next_start = $Analysis.bracket_low_price
            next_end = $Analysis.bracket_high_price
            reason = "adjacent_sign_change"
        }
    }

    $center = $Analysis.best_vote_abs_price
    if ($Analysis.sign_pattern -eq "all_negative") {
        return [pscustomobject]@{
            next_start = $center
            next_end = $center + $currentWidth
            reason = "shift_up_after_all_negative"
        }
    }
    if ($Analysis.sign_pattern -eq "all_positive") {
        return [pscustomobject]@{
            next_start = [Math]::Max(0.0, $center - $currentWidth)
            next_end = $center
            reason = "shift_down_after_all_positive"
        }
    }

    $halfWidth = $currentWidth / 2.0
    return [pscustomobject]@{
        next_start = [Math]::Max(0.0, $center - $halfWidth)
        next_end = $center + $halfWidth
        reason = "recenter_on_best_point"
    }
}

$stageResults = New-Object System.Collections.Generic.List[object]
$currentStart = $PriceStart
$currentEnd = $PriceEnd
$finalClassification = "time_budget_hit"
$finalReason = ""

try {
    if (-not (Test-Path $PackDir)) {
        throw "Pack directory not found: $PackDir"
    }
    if (-not (Test-Path $SweepCli)) {
        throw "Sweep CLI not found: $SweepCli"
    }

    for ($stage = 1; $stage -le $MaxStages; $stage++) {
        $elapsedHours = ((Get-Date) - $startedAt).TotalHours
        if ($elapsedHours -ge $MaxHours) {
            $finalClassification = "time_budget_hit"
            $finalReason = "Reached max-hours budget before starting next stage."
            break
        }

        $stageName = "stage_{0:D2}" -f $stage
        $analysis = Invoke-PoliticalSweep `
            -StageName $stageName `
            -StagePriceStart $currentStart `
            -StagePriceEnd $currentEnd `
            -StagePriceCount $PriceCount
        $stageResults.Add($analysis)

        $width = if ($analysis.has_vote_bracket) {
            [double]$analysis.bracket_high_price - [double]$analysis.bracket_low_price
        } else {
            [double]$analysis.price_end - [double]$analysis.price_start
        }

        Write-Log ("Stage {0} complete. best|vote|={1}; bracket={2}; width={3}" -f `
            $stageName, $analysis.best_vote_abs, $analysis.has_vote_bracket, $width)

        if ($analysis.has_vote_bracket -and $width -le $BracketWidthTolerance) {
            $finalClassification = "bracket_converged"
            $finalReason = "Bracket width hit tolerance."
            break
        }
        if ($analysis.best_vote_abs -le $VoteTolerance) {
            $finalClassification = "vote_tolerance_hit"
            $finalReason = "Best absolute vote hit tolerance."
            break
        }
        if ($stage -eq $MaxStages) {
            $finalClassification = "max_stages_hit"
            $finalReason = "Reached max stage count."
            break
        }

        $nextRange = Get-NextRange -Analysis $analysis -CurrentStart $currentStart -CurrentEnd $currentEnd
        $currentStart = [double]$nextRange.next_start
        $currentEnd = [double]$nextRange.next_end
        Write-Log ("Next range: [{0}, {1}] because {2}" -f $currentStart, $currentEnd, $nextRange.reason)
    }

    if ($stageResults.Count -eq 0) {
        throw "No overnight stages completed."
    }

    $bestOverall = $stageResults | Sort-Object { [double]$_.best_vote_abs } | Select-Object -First 1
    $lastStage = $stageResults[$stageResults.Count - 1]
    $elapsed = (Get-Date) - $startedAt

    $stageArray = @($stageResults.ToArray())
    $result = [pscustomobject][ordered]@{
        classification = $finalClassification
        reason = $finalReason
        pack_dir = $PackDir
        sweep_cli = $SweepCli
        price_multiplier = $PriceMultiplier
        best_vote_abs = $bestOverall.best_vote_abs
        best_vote_abs_price = $bestOverall.best_vote_abs_price
        best_distance = $bestOverall.best_distance
        best_distance_price = $bestOverall.best_distance_price
        last_stage = $lastStage
        stage_count = $stageResults.Count
        elapsed_minutes = [Math]::Round($elapsed.TotalMinutes, 1)
        workflow_run_dir = $runDir
        stage_results = $stageArray
    }
    ($result | ConvertTo-Json -Depth 8) | Set-Content -Path $resultJsonPath

    $lines = @(
        "# Compiled original steady-state overnight workflow",
        "",
        "- Run: $runStamp",
        "- Classification: $finalClassification",
        "- Reason: $finalReason",
        "- Elapsed minutes: $([Math]::Round($elapsed.TotalMinutes, 1))",
        "- Best |vote|: $($bestOverall.best_vote_abs) at p = $($bestOverall.best_vote_abs_price)",
        "- Best distance: $($bestOverall.best_distance) at p = $($bestOverall.best_distance_price)",
        "- Last stage: $($lastStage.stage_name)"
    )
    if ($lastStage.has_vote_bracket) {
        $lines += "- Last bracket: [$($lastStage.bracket_low_price), $($lastStage.bracket_high_price)]"
    } else {
        $lines += "- Last stage had no adjacent sign-change bracket."
    }
    foreach ($stageResult in $stageResults) {
        $lines += "- $($stageResult.stage_name): best |vote| = $($stageResult.best_vote_abs) at p = $($stageResult.best_vote_abs_price); bracket = $($stageResult.has_vote_bracket)"
    }
    Set-Content -Path $summaryPath -Value ($lines -join [Environment]::NewLine)

    Write-Status -CurrentStep "complete" -State "completed" -Payload @{
        summary_path = $summaryPath
        result_json = $resultJsonPath
        classification = $finalClassification
        reason = $finalReason
        best_vote_abs = $bestOverall.best_vote_abs
        best_vote_abs_price = $bestOverall.best_vote_abs_price
        best_distance = $bestOverall.best_distance
        best_distance_price = $bestOverall.best_distance_price
        last_stage = $lastStage
        stage_count = $stageResults.Count
        elapsed_minutes = [Math]::Round($elapsed.TotalMinutes, 1)
    }
    Write-Log "Workflow completed successfully."
}
catch {
    Write-Log ("Workflow failed: " + $_.Exception.Message)
    Write-Status -CurrentStep "failed" -State "failed" -Payload @{
        error = $_.Exception.Message
        summary_path = $summaryPath
        result_json = $resultJsonPath
    }
    throw
}
