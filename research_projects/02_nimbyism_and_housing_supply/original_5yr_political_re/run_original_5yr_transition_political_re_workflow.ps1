param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "matlab",
    [double]$MaxHours = 10,
    [double]$PriceGuessLevel = 0.34013605902777766
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_political_live"
}

New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null
$runId = "ot_" + (Get-Date -Format "yyyyMMdd_HHmmss")
$runDir = Join-Path $LiveRoot ("r\" + $runId)
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
Set-Content -Path (Join-Path $LiveRoot "active_run.txt") -Value $runDir

$statusPath = Join-Path $LiveRoot "latest_status.json"
$logPath = Join-Path $runDir "workflow_log.txt"
$summaryPath = Join-Path $runDir "summary.md"
$finalResultPath = Join-Path $runDir "final_result.json"
$startedAt = Get-Date
$stageResults = New-Object System.Collections.Generic.List[object]

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

function Write-Status {
    param(
        [string]$State,
        [string]$CurrentStep,
        $Payload
    )

    [ordered]@{
        state = $State
        current_step = $CurrentStep
        updated_at = (Get-Date).ToString("s")
        run_dir = $runDir
        payload = $Payload
    } | ConvertTo-Json -Depth 8 | Set-Content -Path $statusPath
}

function Get-ElapsedHours {
    return ((Get-Date) - $startedAt).TotalHours
}

function Get-StageResultsSnapshot {
    if ($stageResults.Count -eq 0) {
        return ,([object[]]@())
    }
    return ,([object[]]$stageResults.ToArray())
}

function Ensure-TimeBudget {
    param([string]$NextStep)
    if ((Get-ElapsedHours) -gt $MaxHours) {
        throw "Time budget reached before step $NextStep."
    }
}

function Read-VectorFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        return @()
    }
    return @(Get-Content -Path $Path | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { [double]$_ })
}

function Invoke-TransitionStage {
    param(
        [string]$StageName,
        [int]$MaxK,
        [int]$MaxIter,
        [double]$PoliticalUpdateWeight,
        [string]$PoliticalUpdateRule
    )

    Ensure-TimeBudget -NextStep $StageName
    Write-Log "Starting stage $StageName"
    Write-Status -State "running" -CurrentStep $StageName -Payload ([ordered]@{
        workflow = "historical_original_5yr_transition"
        run_id = $runId
        stage_results = (Get-StageResultsSnapshot)
        current_stage = [ordered]@{
            name = $StageName
            max_k = $MaxK
            max_iter = $MaxIter
            political_update_weight = $PoliticalUpdateWeight
            political_update_rule = $PoliticalUpdateRule
            demographic_source_mode = "historical_1950"
        }
    })

    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scriptDir "run_original_5yr_transition_political_bellman_bounded.ps1") `
        -MatlabExe $MatlabExe `
        -MaxK $MaxK `
        -MaxIter $MaxIter `
        -PriceUpdateMode "political_only" `
        -PoliticalTarget "equal_weight_vote" `
        -PoliticalUpdateWeight $PoliticalUpdateWeight `
        -RunTag $StageName `
        -PoliticalUpdateRule $PoliticalUpdateRule `
        -PriceGuessLevel $PriceGuessLevel `
        -DemographicSourceMode "historical_1950" | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "Stage $StageName failed with exit code $LASTEXITCODE."
    }

    $baseName = "original_5yr_transition_political_bellman_$StageName"
    $stageSummaryPath = Join-Path $scriptDir ($baseName + "_summary.csv")
    $stageResultsPath = Join-Path $scriptDir ($baseName + "_results.mat")
    $pricePathCsv = Join-Path $scriptDir ($baseName + "_final_price_path.csv")
    $votePathCsv = Join-Path $scriptDir ($baseName + "_final_vote_path.csv")
    $anchorPathCsv = Join-Path $scriptDir ($baseName + "_final_anchor_path.csv")

    $summaryRows = Import-Csv -Path $stageSummaryPath
    $finalRow = $summaryRows | Select-Object -Last 1
    $pricePath = Read-VectorFile -Path $pricePathCsv
    $votePath = Read-VectorFile -Path $votePathCsv
    $anchorPath = Read-VectorFile -Path $anchorPathCsv

    $stageResult = [ordered]@{
        name = $StageName
        max_k = $MaxK
        max_iter = $MaxIter
        political_update_weight = $PoliticalUpdateWeight
        political_update_rule = $PoliticalUpdateRule
        summary_path = $stageSummaryPath
        results_path = $stageResultsPath
        final_iteration = [int]$finalRow.iteration
        max_abs_vote = [double]$finalRow.max_abs_vote
        mean_vote = [double]$finalRow.mean_vote
        max_abs_gap = [double]$finalRow.max_abs_gap
        residual_norm = [double]$finalRow.residual_norm
        price_min = [double]$finalRow.price_min
        price_max = [double]$finalRow.price_max
        final_price_path = $pricePath
        final_vote_path = $votePath
        final_anchor_path = $anchorPath
        elapsed_hours = (Get-ElapsedHours)
    }

    $stageResults.Add($stageResult)
    Write-Log ("Completed stage {0}: max_abs_vote={1}, max_abs_gap={2}" -f $StageName, $stageResult.max_abs_vote, $stageResult.max_abs_gap)
    return $stageResult
}

function Compare-StageResult {
    param($Left, $Right)
    if ($null -eq $Left) { return $Right }
    if ($null -eq $Right) { return $Left }
    if ($Right.max_abs_vote -lt $Left.max_abs_vote) { return $Right }
    if ($Right.max_abs_vote -gt $Left.max_abs_vote) { return $Left }
    if ($Right.max_abs_gap -lt $Left.max_abs_gap) { return $Right }
    return $Left
}

try {
    Write-Log "Historical original 5-year transition workflow started."

    $k1 = Invoke-TransitionStage -StageName "hist_k1_smoke" -MaxK 1 -MaxIter 1 -PoliticalUpdateWeight 0.005 -PoliticalUpdateRule "fixed_step"
    $k2Base = Invoke-TransitionStage -StageName "hist_k2_baseline" -MaxK 2 -MaxIter 2 -PoliticalUpdateWeight 0.005 -PoliticalUpdateRule "fixed_step"
    $k2Fast = Invoke-TransitionStage -StageName "hist_k2_fixed_fast" -MaxK 2 -MaxIter 3 -PoliticalUpdateWeight 0.02 -PoliticalUpdateRule "fixed_step"
    $k2Secant = Invoke-TransitionStage -StageName "hist_k2_secant" -MaxK 2 -MaxIter 3 -PoliticalUpdateWeight 0.005 -PoliticalUpdateRule "diagonal_secant"

    $bestK2 = $null
    $bestK2 = Compare-StageResult -Left $bestK2 -Right $k2Base
    $bestK2 = Compare-StageResult -Left $bestK2 -Right $k2Fast
    $bestK2 = Compare-StageResult -Left $bestK2 -Right $k2Secant

    $classification = "k2_sweep_complete"
    $nextStep = "stop_after_k2"
    $k3Smoke = $null
    $k3Continue = $null
    $k4Smoke = $null

    if ($bestK2.max_abs_gap -le 0.05) {
        $classification = "k3_probe_started"
        $nextStep = "k3_smoke"
        $k3Smoke = Invoke-TransitionStage -StageName "hist_k3_smoke" -MaxK 3 -MaxIter 1 -PoliticalUpdateWeight $bestK2.political_update_weight -PoliticalUpdateRule $bestK2.political_update_rule

        if ($k3Smoke.max_abs_gap -le 0.05) {
            $classification = "k3_continue_started"
            $nextStep = "k3_continue"
            $k3Continue = Invoke-TransitionStage -StageName "hist_k3_continue" -MaxK 3 -MaxIter 2 -PoliticalUpdateWeight $bestK2.political_update_weight -PoliticalUpdateRule $bestK2.political_update_rule

            if ($k3Continue.max_abs_gap -le 0.05) {
                $classification = "k4_probe_started"
                $nextStep = "k4_smoke"
                $k4Smoke = Invoke-TransitionStage -StageName "hist_k4_smoke" -MaxK 4 -MaxIter 1 -PoliticalUpdateWeight $bestK2.political_update_weight -PoliticalUpdateRule $bestK2.political_update_rule
                $classification = "k4_probe_complete"
                $nextStep = "completed"
            } else {
                $classification = "k3_not_stable_enough_for_k4"
                $nextStep = "stop_after_k3_continue"
            }
        } else {
            $classification = "k3_smoke_not_stable_enough"
            $nextStep = "stop_after_k3_smoke"
        }
    }

    $payload = [ordered]@{
        workflow = "historical_original_5yr_transition"
        run_id = $runId
        demographic_source_mode = "historical_1950"
        selected_years = @(1950,1955,1960,1965,1970,1975,1980,1985,1990,1995,2000,2005,2010,2015)
        classification = $classification
        next_step = $nextStep
        best_k2 = $bestK2
        k1 = $k1
        k2_baseline = $k2Base
        k2_fixed_fast = $k2Fast
        k2_secant = $k2Secant
        k3_smoke = $k3Smoke
        k3_continue = $k3Continue
        k4_smoke = $k4Smoke
        stage_results = (Get-StageResultsSnapshot)
        elapsed_hours = (Get-ElapsedHours)
    }

    $summaryLines = @(
        "# Original 5-Year Historical Transition Workflow",
        "",
        "- Classification: $classification",
        "- Demographic source: historical_1950",
        "- Years: 1950, 1955, ..., 2015",
        "- Best k2 branch: $($bestK2.name)",
        "- Best k2 max |vote|: $($bestK2.max_abs_vote)",
        "- Best k2 max gap: $($bestK2.max_abs_gap)",
        "- Elapsed hours: $([math]::Round((Get-ElapsedHours), 3))"
    )
    Set-Content -Path $summaryPath -Value ($summaryLines -join [Environment]::NewLine)
    $payload | ConvertTo-Json -Depth 8 | Set-Content -Path $finalResultPath
    Write-Status -State "completed" -CurrentStep "completed" -Payload $payload
    Write-Log "Workflow completed."
}
catch {
    $message = $_.Exception.Message
    $classification = if ($message -like "Time budget reached*") { "time_budget_reached" } else { "blocked_or_failed" }
    Write-Log "Workflow stopped with error: $message"
    $payload = [ordered]@{
        workflow = "historical_original_5yr_transition"
        run_id = $runId
        classification = $classification
        error = $message
        stage_results = (Get-StageResultsSnapshot)
        elapsed_hours = (Get-ElapsedHours)
    }
    $payload | ConvertTo-Json -Depth 8 | Set-Content -Path $finalResultPath
    $state = if ($classification -eq "time_budget_reached") { "completed" } else { "blocked" }
    Write-Status -State $state -CurrentStep "stopped" -Payload $payload
    throw
}
