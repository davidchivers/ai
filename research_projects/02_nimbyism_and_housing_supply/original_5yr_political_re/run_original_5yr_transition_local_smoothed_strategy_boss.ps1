param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "matlab",
    [double]$MaxHours = 24
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_local_smoothed_strategy_boss_live"
}
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$runId = "smoothlocalboss_" + (Get-Date -Format "yyyyMMdd_HHmmss")
$runDir = Join-Path $LiveRoot ("r\" + $runId)
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
Set-Content -Path (Join-Path $LiveRoot "active_run.txt") -Value $runDir

$statusPath = Join-Path $LiveRoot "latest_status.json"
$reportPath = Join-Path $LiveRoot "latest_report.md"
$logPath = Join-Path $runDir "boss_log.txt"
$finalResultPath = Join-Path $runDir "final_result.json"
$startedAt = Get-Date

$baselineVote = 0.0343491536712217
$baselineGap = 0.00959574825273568
$defaultSeedCsv = "C:\Users\Dave_\AI\research_projects\02_nimbyism_and_housing_supply\original_5yr_political_re\original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_price_path.csv"
$runner = Join-Path $scriptDir "run_original_5yr_transition_joint_supply_wedge_smoothed_politics.ps1"

$stageResults = New-Object System.Collections.Generic.List[object]
$bestGlobal = [ordered]@{
    source = "seed_incumbent"
    max_abs_vote = $baselineVote
    max_abs_gap = $baselineGap
    seed_price_csv = $defaultSeedCsv
    improved = $false
    updated_at = (Get-Date).ToString("s")
}

$stageQueue = @(
    [ordered]@{
        name = "local_smoothdiag_full_s020_k02"
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
        stall_hours = 0.5
    },
    [ordered]@{
        name = "local_smoothdiag_full_s010_k04"
        max_k = 4
        k_schedule = @("2,4")
        basis_count = 2
        max_outer_iter = 1
        demographic_source_mode = "historical_1950"
        finite_diff_step = 0.01
        ridge_lambda = 0.001
        candidate_scales = @("1,0.5")
        trust_region_log_step = 0.08
        housing_clear_max_iter = 2
        political_response_sigma = 0.10
        timeout_hours = 2.0
        stall_hours = 0.75
    },
    [ordered]@{
        name = "local_smoothdiag_full_s005_k06"
        max_k = 6
        k_schedule = @("2,4,6")
        basis_count = 3
        max_outer_iter = 2
        demographic_source_mode = "historical_1950"
        finite_diff_step = 0.01
        ridge_lambda = 0.001
        candidate_scales = @("1,0.75,0.5,0.25")
        trust_region_log_step = 0.08
        housing_clear_max_iter = 2
        political_response_sigma = 0.05
        timeout_hours = 3.0
        stall_hours = 1.0
    },
    [ordered]@{
        name = "local_smoothdiag_proxy_s010_k06"
        max_k = 6
        k_schedule = @("2,4,6")
        basis_count = 3
        max_outer_iter = 2
        demographic_source_mode = "historical_1950_two_group"
        finite_diff_step = 0.01
        ridge_lambda = 0.001
        candidate_scales = @("1,0.75,0.5,0.25")
        trust_region_log_step = 0.08
        housing_clear_max_iter = 2
        political_response_sigma = 0.10
        timeout_hours = 3.0
        stall_hours = 1.0
    }
)

$currentStage = $null

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

function Get-DateSafe {
    param($Value)
    try {
        if ($null -eq $Value) { return $null }
        return [datetime]::Parse([string]$Value, [System.Globalization.CultureInfo]::InvariantCulture)
    }
    catch {
        return $null
    }
}

function Find-ProcessByToken {
    param([string]$Token)
    try {
        return @(
            Get-CimInstance Win32_Process -ErrorAction Stop |
                Where-Object {
                    ($_.Name -match '^(powershell|matlab|MATLAB)(\.exe)?$') -and
                    ($_.CommandLine -like ("*" + $Token + "*"))
                }
        )
    }
    catch {
        Write-Log "Find-ProcessByToken fallback: unable to inspect Win32_Process for token '$Token'."
        return @()
    }
}

function Stop-ProcessesByToken {
    param([string]$Token)
    foreach ($target in @(Find-ProcessByToken -Token $Token)) {
        try {
            Stop-Process -Id $target.ProcessId -Force -ErrorAction Stop
        }
        catch {
        }
    }
}

function Test-StageKey {
    param($Stage, [string]$Key)
    if ($Stage -is [System.Collections.IDictionary]) {
        return $Stage.Contains($Key)
    }
    return ($null -ne $Stage.PSObject.Properties[$Key])
}

function Get-StageValue {
    param($Stage, [string]$Key, $DefaultValue = $null)
    if (Test-StageKey -Stage $Stage -Key $Key) {
        return $Stage[$Key]
    }
    return $DefaultValue
}

function Test-ProcessAlive {
    param([int]$Pid)
    if ($Pid -le 0) {
        return $false
    }
    try {
        Get-Process -Id $Pid -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
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
    }
}

function Get-StageLastWriteTime {
    param([string]$StageDir)
    if (-not (Test-Path $StageDir)) {
        return $null
    }
    try {
        $items = @(Get-ChildItem -Path $StageDir -Recurse -Force -ErrorAction Stop)
        if ($items.Count -eq 0) {
            return (Get-Item -LiteralPath $StageDir).LastWriteTime
        }
        return ($items | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
    }
    catch {
        return $null
    }
}

function Read-StageResult {
    param($Stage)
    $paths = Get-StagePaths -StageName $Stage.name
    if (-not (Test-Path $paths.summary_csv)) {
        return $null
    }

    $rows = @(Import-Csv -Path $paths.summary_csv)
    if ($rows.Count -eq 0) {
        return $null
    }

    $row = $rows[-1]
    $vote = Parse-Double $row.final_max_abs_vote
    $gap = Parse-Double $row.final_max_abs_gap
    $merit = Parse-Double $row.final_merit

    [ordered]@{
        name = $Stage.name
        status = "completed"
        completed_at = (Get-Date).ToString("s")
        max_abs_vote = $vote
        max_abs_gap = $gap
        merit = $merit
        best_price_csv = if (Test-Path $paths.price_csv) { $paths.price_csv } else { "" }
        best_vote_csv = if (Test-Path $paths.vote_csv) { $paths.vote_csv } else { "" }
        best_wedge_csv = if (Test-Path $paths.wedge_csv) { $paths.wedge_csv } else { "" }
        summary_csv = $paths.summary_csv
        improved = ($vote -lt ($bestGlobal.max_abs_vote - 1e-4))
    }
}

function Update-BestGlobal {
    param($Result)
    if ($null -eq $Result) { return }
    if (-not $Result.max_abs_vote) { return }
    if ($Result.max_abs_vote -lt ($bestGlobal.max_abs_vote - 1e-4)) {
        $bestGlobal.source = [string]$Result.name
        $bestGlobal.max_abs_vote = $Result.max_abs_vote
        $bestGlobal.max_abs_gap = $Result.max_abs_gap
        if ($Result.best_price_csv) {
            $bestGlobal.seed_price_csv = [string]$Result.best_price_csv
        }
        $bestGlobal.improved = $true
        $bestGlobal.updated_at = (Get-Date).ToString("s")
    }
}

function Start-Stage {
    param($Stage, [string]$SeedCsv)

    $stageMaxK = Get-StageValue -Stage $Stage -Key "max_k" -DefaultValue 14
    $stageKSchedule = Get-StageValue -Stage $Stage -Key "k_schedule" -DefaultValue @()
    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $runner,
        "-MatlabExe", $MatlabExe,
        "-MaxK", ([string]$stageMaxK),
        "-MaxOuterIter", ([string]$Stage.max_outer_iter),
        "-BasisCount", ([string]$Stage.basis_count),
        "-SeedPriceCsvPath", $SeedCsv,
        "-RunTag", $Stage.name,
        "-DemographicSourceMode", $Stage.demographic_source_mode,
        "-FiniteDiffStep", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $Stage.finite_diff_step)),
        "-RidgeLambda", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $Stage.ridge_lambda)),
        "-CandidateScales", ($Stage.candidate_scales -join ","),
        "-TrustRegionLogStep", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $Stage.trust_region_log_step)),
        "-HousingClearMaxIter", ([string]$Stage.housing_clear_max_iter),
        "-PoliticalResponseSigma", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", [double]$Stage.political_response_sigma))
    )
    if (@($stageKSchedule).Count -gt 0) {
        $arguments += @("-KSchedule", (@($stageKSchedule) -join ","))
    }

    $proc = Start-Process powershell -ArgumentList $arguments -PassThru -WindowStyle Hidden
    $paths = Get-StagePaths -StageName $Stage.name
    [ordered]@{
        name = $Stage.name
        started_at = (Get-Date).ToString("s")
        pid = $proc.Id
        timeout_hours = $Stage.timeout_hours
        summary_csv = $paths.summary_csv
        price_csv = $paths.price_csv
        vote_csv = $paths.vote_csv
        wedge_csv = $paths.wedge_csv
        stage_dir = $paths.stage_dir
        seed_csv = $SeedCsv
        attached = $false
    }
}

function Attach-CurrentStage {
    foreach ($stage in $stageQueue) {
        if ($stage.completed) { continue }
        $paths = Get-StagePaths -StageName $stage.name
        if (Test-Path $paths.summary_csv) {
            continue
        }

        $attachedProcesses = @(Find-ProcessByToken -Token $stage.name)
        if ($attachedProcesses.Count -eq 0) {
            continue
        }

        $attachedPid = 0
        $attachedStartedAt = (Get-Date).ToString("s")
        $procStarts = @()
        foreach ($proc in $attachedProcesses) {
            try {
                $liveProc = Get-Process -Id $proc.ProcessId -ErrorAction Stop
                $procStarts += [pscustomobject]@{
                    pid = $proc.ProcessId
                    started_at = $liveProc.StartTime
                }
            }
            catch {
            }
        }
        if ($procStarts.Count -gt 0) {
            $oldest = $procStarts | Sort-Object started_at | Select-Object -First 1
            $attachedPid = [int]$oldest.pid
            $attachedStartedAt = ([datetime]$oldest.started_at).ToString("s")
        }

        return [ordered]@{
            name = $stage.name
            started_at = $attachedStartedAt
            pid = $attachedPid
            timeout_hours = $stage.timeout_hours
            summary_csv = $paths.summary_csv
            price_csv = $paths.price_csv
            vote_csv = $paths.vote_csv
            wedge_csv = $paths.wedge_csv
            stage_dir = $paths.stage_dir
            seed_csv = $bestGlobal.seed_price_csv
            attached = $true
        }
    }

    return $null
}

function Write-LiveState {
    param([string]$State, [string]$Classification)

    $payload = [ordered]@{
        workflow = "original_5yr_transition_local_smoothed_strategy_boss"
        run_id = $runId
        classification = $Classification
        elapsed_hours = [math]::Round((Get-ElapsedHours), 3)
        best_global = $bestGlobal
        current_stage = $currentStage
        stage_results = @($stageResults.ToArray())
        stage_queue = $stageQueue
    }

    [ordered]@{
        state = $State
        current_step = if ($currentStage) { $currentStage.name } else { "idle" }
        updated_at = (Get-Date).ToString("s")
        run_dir = $runDir
        payload = $payload
    } | ConvertTo-Json -Depth 12 | Set-Content -Path $statusPath

    $reportLines = @(
        "# Original 5-year local smoothed-politics strategy boss",
        "",
        "- State: $State",
        "- Classification: $Classification",
        "- Updated: $((Get-Date).ToString('s'))",
        "- Elapsed hours: $([math]::Round((Get-ElapsedHours), 2))",
        "- Best max |vote|: $($bestGlobal.max_abs_vote)",
        "- Best max gap: $($bestGlobal.max_abs_gap)",
        "- Best source: $($bestGlobal.source)",
        "- Current stage: $(if ($currentStage) { $currentStage.name } else { 'none' })",
        "- Completed stages: $($stageResults.Count)"
    )
    Set-Content -Path $reportPath -Value ($reportLines -join [Environment]::NewLine)
}

Write-Log "Local smoothed strategy boss started."

if (Test-Path $statusPath) {
    try {
        $priorStatus = Get-Content -Raw -Path $statusPath | ConvertFrom-Json
        if ($priorStatus.payload) {
            foreach ($result in @($priorStatus.payload.stage_results)) {
                if ($result.name) {
                    $stageResults.Add($result)
                }
            }
            foreach ($stage in $stageQueue) {
                $priorStage = @($priorStatus.payload.stage_queue | Where-Object { $_.name -eq $stage.name } | Select-Object -First 1)
                if ($priorStage.Count -gt 0 -and $priorStage[0].PSObject.Properties['completed']) {
                    $stage.completed = [bool]$priorStage[0].completed
                }
            }

            $priorBestVote = Parse-Double $priorStatus.payload.best_global.max_abs_vote
            $priorBestGap = Parse-Double $priorStatus.payload.best_global.max_abs_gap
            if (-not [double]::IsNaN($priorBestVote) -and $priorBestVote -lt $bestGlobal.max_abs_vote) {
                $bestGlobal.source = [string]$priorStatus.payload.best_global.source
                $bestGlobal.max_abs_vote = $priorBestVote
                $bestGlobal.max_abs_gap = $priorBestGap
                $bestGlobal.seed_price_csv = [string]$priorStatus.payload.best_global.seed_price_csv
                $bestGlobal.improved = [bool]$priorStatus.payload.best_global.improved
                $bestGlobal.updated_at = [string]$priorStatus.payload.best_global.updated_at
            }
        }
    }
    catch {
        Write-Log "Failed to resume prior status; starting fresh."
    }
}

$attachedStage = Attach-CurrentStage
if ($attachedStage) {
    $currentStage = $attachedStage
    Write-Log "Attached to running smoothed local stage $($currentStage.name)."
}

Write-LiveState -State "running" -Classification "active"

while ((Get-ElapsedHours) -lt $MaxHours) {
    if ($currentStage) {
        $result = Read-StageResult -Stage $currentStage
        if ($result) {
            $stageResults.Add($result)
            Update-BestGlobal -Result $result
            Write-Log "Smoothed local stage $($currentStage.name) completed. max |vote|=$($result.max_abs_vote)"
            foreach ($stage in $stageQueue) {
                if ($stage.name -eq $currentStage.name) {
                    $stage.completed = $true
                }
            }
            $currentStage = $null
        }
        else {
            $stageStartedAt = Get-DateSafe $currentStage.started_at
            $stageAgeHours = if ($stageStartedAt) { ((Get-Date) - $stageStartedAt).TotalHours } else { 0.0 }
            $stageDirLastWrite = Get-StageLastWriteTime -StageDir $currentStage.stage_dir
            $idleWriteHours = if ($stageDirLastWrite) { ((Get-Date) - $stageDirLastWrite).TotalHours } else { [double]::PositiveInfinity }
            $stageQueueConfig = @($stageQueue | Where-Object { $_.name -eq $currentStage.name } | Select-Object -First 1)
            $stallHours = if ($stageQueueConfig.Count -gt 0) { [double](Get-StageValue -Stage $stageQueueConfig[0] -Key "stall_hours" -DefaultValue 1.0) } else { 1.0 }
            if ($stageAgeHours -ge [double]$currentStage.timeout_hours) {
                Stop-ProcessesByToken -Token $currentStage.name
                $timedOut = [ordered]@{
                    name = $currentStage.name
                    status = "timed_out_without_summary"
                    completed_at = (Get-Date).ToString("s")
                    best_price_csv = ""
                    max_abs_vote = [double]::NaN
                    max_abs_gap = [double]::NaN
                    improved = $false
                }
                $stageResults.Add($timedOut)
                Write-Log "Smoothed local stage $($currentStage.name) timed out after $([math]::Round($stageAgeHours, 2))h; advancing."
                foreach ($stage in $stageQueue) {
                    if ($stage.name -eq $currentStage.name) {
                        $stage.completed = $true
                    }
                }
                $currentStage = $null
            }
            elseif ($idleWriteHours -ge $stallHours -and -not (Test-Path $currentStage.summary_csv)) {
                Stop-ProcessesByToken -Token $currentStage.name
                $stalled = [ordered]@{
                    name = $currentStage.name
                    status = "stalled_without_summary"
                    completed_at = (Get-Date).ToString("s")
                    best_price_csv = ""
                    max_abs_vote = [double]::NaN
                    max_abs_gap = [double]::NaN
                    improved = $false
                }
                $stageResults.Add($stalled)
                Write-Log "Smoothed local stage $($currentStage.name) stalled with no writes for $([math]::Round($idleWriteHours, 2))h; advancing."
                foreach ($stage in $stageQueue) {
                    if ($stage.name -eq $currentStage.name) {
                        $stage.completed = $true
                    }
                }
                $currentStage = $null
            }
        }

        $matchingProcesses = if ($currentStage) { @(Find-ProcessByToken -Token $currentStage.name) } else { @() }
        if ($currentStage -and -not (Test-ProcessAlive -Pid ([int]$currentStage.pid)) -and $matchingProcesses.Count -eq 0 -and -not (Test-Path $currentStage.summary_csv)) {
            $failed = [ordered]@{
                name = $currentStage.name
                status = "failed_without_summary"
                completed_at = (Get-Date).ToString("s")
                best_price_csv = ""
                max_abs_vote = [double]::NaN
                max_abs_gap = [double]::NaN
                improved = $false
            }
            $stageResults.Add($failed)
            Write-Log "Smoothed local stage $($currentStage.name) failed without summary; advancing."
            foreach ($stage in $stageQueue) {
                if ($stage.name -eq $currentStage.name) {
                    $stage.completed = $true
                }
            }
            $currentStage = $null
        }
    }

    if (-not $currentStage) {
        foreach ($stage in $stageQueue) {
            if ($stage.completed) { continue }
            $currentStage = Start-Stage -Stage $stage -SeedCsv $bestGlobal.seed_price_csv
            Write-Log "Started smoothed local stage $($stage.name) with seed $($bestGlobal.seed_price_csv)"
            break
        }
    }

    $allDone = @($stageQueue | Where-Object { -not $_.completed }).Count -eq 0 -and (-not $currentStage)
    if ($bestGlobal.max_abs_vote -le 0.001) {
        Write-LiveState -State "completed" -Classification "re_complete"
        Write-Log "Stop condition reached: RE complete."
        break
    }
    if ($allDone) {
        Write-LiveState -State "completed" -Classification "queue_exhausted"
        Write-Log "Stop condition reached: queue_exhausted."
        break
    }

    Write-LiveState -State "running" -Classification "active"
    Start-Sleep -Seconds 60
}

if ((Get-ElapsedHours) -ge $MaxHours) {
    Write-LiveState -State "completed" -Classification "time_budget_reached"
    Write-Log "Time budget reached."
}

$finalPayload = Get-Content -Raw -Path $statusPath | ConvertFrom-Json
$finalPayload | ConvertTo-Json -Depth 12 | Set-Content -Path $finalResultPath
