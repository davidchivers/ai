param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "matlab",
    [int]$MaxParallel = 2,
    [double]$MaxHours = 8
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_local_smooth_k2_packet_boss_live"
}
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$runId = "smoothk2boss_" + (Get-Date -Format "yyyyMMdd_HHmmss")
$runDir = Join-Path $LiveRoot ("r\" + $runId)
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

$statusPath = Join-Path $LiveRoot "latest_status.json"
$reportPath = Join-Path $LiveRoot "latest_report.md"
$logPath = Join-Path $runDir "boss_log.txt"
$startedAt = Get-Date

$baselineVote = 0.0343491536712217
$baselineGap = 0.00959574825273568
$seedCsv = "C:\Users\Dave_\AI\research_projects\02_nimbyism_and_housing_supply\original_5yr_political_re\original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_price_path.csv"
$runner = Join-Path $scriptDir "run_original_5yr_transition_joint_supply_wedge_smoothed_politics.ps1"

$stageQueue = @(
    [ordered]@{
        name = "local_smoothk2_full_s020_base"
        max_k = 2
        k_schedule = @("2")
        basis_count = 2
        max_outer_iter = 1
        demographic_source_mode = "historical_1950"
        finite_diff_step = 0.01
        ridge_lambda = 0.001
        candidate_scales = @("1,0.5")
        trust_region_log_step = 0.08
        housing_clear_max_iter = 1
        political_response_sigma = 0.20
        timeout_hours = 1.5
        launched = $false
        completed = $false
    },
    [ordered]@{
        name = "local_smoothk2_full_s010_base"
        max_k = 2
        k_schedule = @("2")
        basis_count = 2
        max_outer_iter = 1
        demographic_source_mode = "historical_1950"
        finite_diff_step = 0.01
        ridge_lambda = 0.001
        candidate_scales = @("1,0.5")
        trust_region_log_step = 0.08
        housing_clear_max_iter = 1
        political_response_sigma = 0.10
        timeout_hours = 1.5
        launched = $false
        completed = $false
    },
    [ordered]@{
        name = "local_smoothk2_full_s005_base"
        max_k = 2
        k_schedule = @("2")
        basis_count = 2
        max_outer_iter = 1
        demographic_source_mode = "historical_1950"
        finite_diff_step = 0.01
        ridge_lambda = 0.001
        candidate_scales = @("1,0.5")
        trust_region_log_step = 0.08
        housing_clear_max_iter = 1
        political_response_sigma = 0.05
        timeout_hours = 1.5
        launched = $false
        completed = $false
    },
    [ordered]@{
        name = "local_smoothk2_full_s020_wide"
        max_k = 2
        k_schedule = @("2")
        basis_count = 2
        max_outer_iter = 1
        demographic_source_mode = "historical_1950"
        finite_diff_step = 0.05
        ridge_lambda = 0.001
        candidate_scales = @("1,0.5")
        trust_region_log_step = 0.15
        housing_clear_max_iter = 1
        political_response_sigma = 0.20
        timeout_hours = 1.5
        launched = $false
        completed = $false
    }
)

$stageResults = New-Object System.Collections.Generic.List[object]
$runningStages = @()
$bestGlobal = [ordered]@{
    source = "seed_incumbent"
    max_abs_vote = $baselineVote
    max_abs_gap = $baselineGap
    seed_price_csv = $seedCsv
    improved = $false
    updated_at = (Get-Date).ToString("s")
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

function Get-ElapsedHours {
    return ((Get-Date) - $startedAt).TotalHours
}

function Parse-Double {
    param($Value, [double]$DefaultValue = [double]::NaN)
    if ($null -eq $Value) { return $DefaultValue }
    $text = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) { return $DefaultValue }
    $parsed = 0.0
    if ([double]::TryParse($text, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
        return $parsed
    }
    return $DefaultValue
}

function Get-StagePaths {
    param([string]$StageName)
    $stageDir = Join-Path $scriptDir ("truth\joint_supply_wedge\" + $StageName)
    [ordered]@{
        stage_dir = $stageDir
        summary_csv = Join-Path $stageDir ($StageName + "_summary.csv")
        price_csv = Join-Path $stageDir ($StageName + "_final_price_path.csv")
        vote_csv = Join-Path $stageDir ($StageName + "_final_vote_path.csv")
        wedge_csv = Join-Path $stageDir ($StageName + "_final_wedge_path.csv")
        trace_log = Join-Path $stageDir "k02\evaluation_trace.log"
    }
}

function Test-ProcessAlive {
    param([int]$Pid)
    try {
        Get-Process -Id $Pid -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Read-StageResult {
    param($StageState)
    if (-not (Test-Path $StageState.summary_csv)) {
        return $null
    }

    $rows = @(Import-Csv -Path $StageState.summary_csv)
    if ($rows.Count -eq 0) {
        return $null
    }
    $row = $rows[-1]
    [ordered]@{
        name = $StageState.name
        status = "completed"
        completed_at = (Get-Date).ToString("s")
        max_abs_vote = Parse-Double $row.final_max_abs_vote
        max_abs_gap = Parse-Double $row.final_max_abs_gap
        merit = Parse-Double $row.final_merit
        best_price_csv = if (Test-Path $StageState.price_csv) { $StageState.price_csv } else { "" }
        best_vote_csv = if (Test-Path $StageState.vote_csv) { $StageState.vote_csv } else { "" }
        best_wedge_csv = if (Test-Path $StageState.wedge_csv) { $StageState.wedge_csv } else { "" }
        trace_log = if (Test-Path $StageState.trace_log) { $StageState.trace_log } else { "" }
        improved = $false
    }
}

function Update-BestGlobal {
    param($Result)
    if ($null -eq $Result) { return }
    if ([double]::IsNaN([double]$Result.max_abs_vote)) { return }
    if ($Result.max_abs_vote -lt ($bestGlobal.max_abs_vote - 1e-4)) {
        $bestGlobal.source = [string]$Result.name
        $bestGlobal.max_abs_vote = [double]$Result.max_abs_vote
        $bestGlobal.max_abs_gap = [double]$Result.max_abs_gap
        if ($Result.best_price_csv) {
            $bestGlobal.seed_price_csv = [string]$Result.best_price_csv
        }
        $bestGlobal.improved = $true
        $bestGlobal.updated_at = (Get-Date).ToString("s")
        $Result.improved = $true
    }
}

function Start-Stage {
    param($Stage)

    $paths = Get-StagePaths -StageName $Stage.name
    if (Test-Path $paths.stage_dir) {
        Remove-Item -LiteralPath $paths.stage_dir -Recurse -Force -ErrorAction SilentlyContinue
    }

    $proc = Start-Process powershell -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $runner,
        "-MatlabExe", $MatlabExe,
        "-MaxK", ([string]$Stage.max_k),
        "-MaxOuterIter", ([string]$Stage.max_outer_iter),
        "-BasisCount", ([string]$Stage.basis_count),
        "-SeedPriceCsvPath", $bestGlobal.seed_price_csv,
        "-RunTag", $Stage.name,
        "-DemographicSourceMode", $Stage.demographic_source_mode,
        "-FiniteDiffStep", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $Stage.finite_diff_step)),
        "-RidgeLambda", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $Stage.ridge_lambda)),
        "-CandidateScales", ($Stage.candidate_scales -join ","),
        "-TrustRegionLogStep", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $Stage.trust_region_log_step)),
        "-HousingClearMaxIter", ([string]$Stage.housing_clear_max_iter),
        "-PoliticalResponseSigma", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", [double]$Stage.political_response_sigma)),
        "-KSchedule", ($Stage.k_schedule -join ",")
    ) -PassThru -WindowStyle Hidden

    $Stage.launched = $true
    [ordered]@{
        name = $Stage.name
        pid = $proc.Id
        started_at = (Get-Date).ToString("s")
        timeout_hours = $Stage.timeout_hours
        summary_csv = $paths.summary_csv
        price_csv = $paths.price_csv
        vote_csv = $paths.vote_csv
        wedge_csv = $paths.wedge_csv
        trace_log = $paths.trace_log
        stage_dir = $paths.stage_dir
    }
}

function Write-LiveState {
    param([string]$State, [string]$Classification)

    $payload = [ordered]@{
        workflow = "original_5yr_transition_local_smooth_k2_packet_boss"
        run_id = $runId
        classification = $Classification
        elapsed_hours = [math]::Round((Get-ElapsedHours), 3)
        max_parallel = $MaxParallel
        best_global = $bestGlobal
        running_stages = @($runningStages)
        stage_results = @($stageResults.ToArray())
        stage_queue = $stageQueue
    }

    [ordered]@{
        state = $State
        current_step = if ($runningStages.Count -gt 0) { ($runningStages | ForEach-Object { $_.name }) -join "," } else { "idle" }
        updated_at = (Get-Date).ToString("s")
        run_dir = $runDir
        payload = $payload
    } | ConvertTo-Json -Depth 10 | Set-Content -Path $statusPath

    $lines = @(
        "# Smooth k=2 packet boss",
        "",
        "- State: $State",
        "- Classification: $Classification",
        "- Updated: $((Get-Date).ToString('s'))",
        "- Elapsed hours: $([math]::Round((Get-ElapsedHours), 2))",
        "- Max parallel: $MaxParallel",
        "- Best max |vote|: $($bestGlobal.max_abs_vote)",
        "- Best max gap: $($bestGlobal.max_abs_gap)",
        "- Running: $(if ($runningStages.Count -gt 0) { ($runningStages | ForEach-Object { $_.name }) -join ', ' } else { 'none' })",
        "- Completed: $($stageResults.Count)"
    )
    Set-Content -Path $reportPath -Value ($lines -join [Environment]::NewLine)
}

Write-Log "Smooth k=2 packet boss started."
Write-LiveState -State "running" -Classification "active"

while ((Get-ElapsedHours) -lt $MaxHours) {
    $survivors = @()
    foreach ($stageState in $runningStages) {
        $result = Read-StageResult -StageState $stageState
        if ($result) {
            Update-BestGlobal -Result $result
            $stageResults.Add($result)
            ($stageQueue | Where-Object { $_.name -eq $stageState.name } | Select-Object -First 1).completed = $true
            Write-Log "Completed $($stageState.name): vote=$($result.max_abs_vote) gap=$($result.max_abs_gap)"
            continue
        }

        $startedAtStage = [datetime]::Parse($stageState.started_at, [System.Globalization.CultureInfo]::InvariantCulture)
        $ageHours = ((Get-Date) - $startedAtStage).TotalHours
        if ($ageHours -ge [double]$stageState.timeout_hours) {
            try { Stop-Process -Id $stageState.pid -Force -ErrorAction Stop } catch {}
            $stageResults.Add([ordered]@{
                name = $stageState.name
                status = "timed_out_without_summary"
                completed_at = (Get-Date).ToString("s")
                max_abs_vote = [double]::NaN
                max_abs_gap = [double]::NaN
                merit = [double]::NaN
                best_price_csv = ""
                best_vote_csv = ""
                best_wedge_csv = ""
                trace_log = if (Test-Path $stageState.trace_log) { $stageState.trace_log } else { "" }
                improved = $false
            })
            ($stageQueue | Where-Object { $_.name -eq $stageState.name } | Select-Object -First 1).completed = $true
            Write-Log "Timed out $($stageState.name)"
            continue
        }

        if (-not (Test-ProcessAlive -Pid $stageState.pid)) {
            $stageResults.Add([ordered]@{
                name = $stageState.name
                status = "failed_without_summary"
                completed_at = (Get-Date).ToString("s")
                max_abs_vote = [double]::NaN
                max_abs_gap = [double]::NaN
                merit = [double]::NaN
                best_price_csv = ""
                best_vote_csv = ""
                best_wedge_csv = ""
                trace_log = if (Test-Path $stageState.trace_log) { $stageState.trace_log } else { "" }
                improved = $false
            })
            ($stageQueue | Where-Object { $_.name -eq $stageState.name } | Select-Object -First 1).completed = $true
            Write-Log "Failed $($stageState.name) without summary"
            continue
        }

        $survivors += $stageState
    }
    $runningStages = $survivors

    while ($runningStages.Count -lt $MaxParallel) {
        $nextStage = $stageQueue | Where-Object { -not $_.launched -and -not $_.completed } | Select-Object -First 1
        if (-not $nextStage) {
            break
        }
        $runningStages += (Start-Stage -Stage $nextStage)
        Write-Log "Launched $($nextStage.name)"
    }

    $allDone = (@($stageQueue | Where-Object { -not $_.completed }).Count -eq 0) -and ($runningStages.Count -eq 0)
    if ($allDone) {
        Write-LiveState -State "completed" -Classification "queue_exhausted"
        Write-Log "Queue exhausted."
        break
    }

    Write-LiveState -State "running" -Classification "active"
    Start-Sleep -Seconds 30
}

if ((Get-ElapsedHours) -ge $MaxHours) {
    Write-LiveState -State "completed" -Classification "time_budget_reached"
    Write-Log "Time budget reached."
}
