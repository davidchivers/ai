param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe",
    [double]$MaxHours = 24
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_smoothed_tail_fail_safe_live"
}
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$statusPath = Join-Path $LiveRoot "latest_status.json"
$reportPath = Join-Path $LiveRoot "latest_report.md"
$logPath = Join-Path $LiveRoot "workflow_log.txt"
$stopPath = Join-Path $LiveRoot "stop.txt"
$finalResultPath = Join-Path $LiveRoot "final_result.json"
$reviewPath = Join-Path $LiveRoot "queue_review_needed.md"
$nextCandidatePath = Join-Path $LiveRoot "next_best_candidate.json"
$startedAt = Get-Date

$seedPriceCsv = Join-Path $scriptDir "truth\joint_supply_wedge\local_smoothk14_full_s020_relaxed\k10\local_smoothk14_full_s020_relaxed_k10_final_price_path.csv"
$seedWedgeCsv = Join-Path $scriptDir "truth\joint_supply_wedge\local_smoothk14_full_s020_relaxed\k10\local_smoothk14_full_s020_relaxed_k10_final_wedge_path.csv"
$oldAcceptedK10Vote = 0.0213563403337867
$oldAcceptedK10Gap = 0.00985590301536815

$stageQueue = @(
    [ordered]@{
        name = "local_smoothtail_full_s020_k10_12_b3_i1_light"
        description = "Finish the current fair light tail rerun on sigma=0.20."
        max_k = 12
        max_outer_iter = 1
        basis_count = 3
        demographic_source_mode = "historical_1950"
        finite_diff_step = 0.01
        ridge_lambda = 0.001
        candidate_scales = @(0.5, 0.1)
        trust_region_log_step = 0.08
        active_threshold_frac = 0.65
        wedge_floor = -0.5
        wedge_cap = 0.5
        k_schedule = @(10, 11, 12)
        housing_clear_max_iter = 2
        political_response_sigma = 0.20
        prefix_lock_length = 0
        timeout_hours = 8.0
        stall_hours = 2.0
        launch_if_missing = $false
        skip_if_reached_k = 0
    },
    [ordered]@{
        name = "local_smoothtail_tailactive_s020_k11_12_b2_i1"
        description = "Freeze the accepted k10 wedge prefix and force the unlocked tail into the residual at sigma=0.20."
        max_k = 12
        max_outer_iter = 1
        basis_count = 2
        demographic_source_mode = "historical_1950"
        finite_diff_step = 0.01
        ridge_lambda = 0.001
        candidate_scales = @(0.5, 0.1)
        trust_region_log_step = 0.08
        active_threshold_frac = 0.65
        wedge_floor = -0.5
        wedge_cap = 0.5
        k_schedule = @(11, 12)
        housing_clear_max_iter = 2
        political_response_sigma = 0.20
        prefix_lock_length = 10
        use_freezeprefix_launcher = $true
        launcher_label = "tailactive"
        process_token = "local_smoothtail_tailactive_s020_k11_12_b2_i1"
        initial_wait_seconds = 30
        timeout_hours = 6.0
        stall_hours = 2.0
        launch_if_missing = $true
        skip_if_reached_k = 11
    },
    [ordered]@{
        name = "local_smoothtail_tailactive_s020_k13_14_b2_i1_fromk12"
        description = "If sigma=0.20 produces a k12 seed, append k13 and k14 with the k12 prefix frozen."
        max_k = 14
        max_outer_iter = 1
        basis_count = 2
        demographic_source_mode = "historical_1950"
        finite_diff_step = 0.01
        ridge_lambda = 0.001
        candidate_scales = @(0.5, 0.1)
        trust_region_log_step = 0.08
        active_threshold_frac = 0.65
        wedge_floor = -0.5
        wedge_cap = 0.5
        k_schedule = @(13, 14)
        housing_clear_max_iter = 2
        political_response_sigma = 0.20
        prefix_lock_length = 12
        seed_stage_name = "local_smoothtail_tailactive_s020_k11_12_b2_i1"
        seed_stage_k = 12
        required_min_reached_k = 12
        use_freezeprefix_launcher = $true
        launcher_label = "tailactive"
        process_token = "local_smoothtail_tailactive_s020_k13_14_b2_i1_fromk12"
        initial_wait_seconds = 30
        timeout_hours = 8.0
        stall_hours = 2.0
        launch_if_missing = $true
        skip_if_reached_k = 14
    },
    [ordered]@{
        name = "local_smoothtail_tailactive_s040_k11_12_b2_i1"
        description = "Higher-smoothing control with the accepted k10 prefix frozen and unlocked tail forced active."
        max_k = 12
        max_outer_iter = 1
        basis_count = 2
        demographic_source_mode = "historical_1950"
        finite_diff_step = 0.01
        ridge_lambda = 0.001
        candidate_scales = @(0.5, 0.1)
        trust_region_log_step = 0.08
        active_threshold_frac = 0.65
        wedge_floor = -0.5
        wedge_cap = 0.5
        k_schedule = @(11, 12)
        housing_clear_max_iter = 2
        political_response_sigma = 0.40
        prefix_lock_length = 10
        use_freezeprefix_launcher = $true
        launcher_label = "tailactive"
        process_token = "local_smoothtail_tailactive_s040_k11_12_b2_i1"
        initial_wait_seconds = 30
        timeout_hours = 6.0
        stall_hours = 2.0
        launch_if_missing = $true
        skip_if_reached_k = 14
    },
    [ordered]@{
        name = "local_smoothtail_tailactive_s040_k13_14_b2_i1_fromk12"
        description = "If the sigma=0.40 control produces a k12 seed, append k13 and k14 with that prefix frozen."
        max_k = 14
        max_outer_iter = 1
        basis_count = 2
        demographic_source_mode = "historical_1950"
        finite_diff_step = 0.01
        ridge_lambda = 0.001
        candidate_scales = @(0.5, 0.1)
        trust_region_log_step = 0.08
        active_threshold_frac = 0.65
        wedge_floor = -0.5
        wedge_cap = 0.5
        k_schedule = @(13, 14)
        housing_clear_max_iter = 2
        political_response_sigma = 0.40
        prefix_lock_length = 12
        seed_stage_name = "local_smoothtail_tailactive_s040_k11_12_b2_i1"
        seed_stage_k = 12
        required_min_reached_k = 12
        use_freezeprefix_launcher = $true
        launcher_label = "tailactive"
        process_token = "local_smoothtail_tailactive_s040_k13_14_b2_i1_fromk12"
        initial_wait_seconds = 30
        timeout_hours = 8.0
        stall_hours = 2.0
        launch_if_missing = $true
        skip_if_reached_k = 14
    },
    [ordered]@{
        name = "local_smoothtail_tailactive_s020_k11_b1_h4_i1"
        description = "If neither lane reaches k12, retry only k11 with a one-tail-block wedge and deeper housing clearing."
        max_k = 11
        max_outer_iter = 1
        basis_count = 1
        demographic_source_mode = "historical_1950"
        finite_diff_step = 0.01
        ridge_lambda = 0.001
        candidate_scales = @(0.5, 0.1)
        trust_region_log_step = 0.08
        active_threshold_frac = 0.65
        wedge_floor = -0.5
        wedge_cap = 0.5
        k_schedule = @(11)
        housing_clear_max_iter = 4
        political_response_sigma = 0.20
        prefix_lock_length = 10
        use_freezeprefix_launcher = $true
        launcher_label = "tailactive"
        process_token = "local_smoothtail_tailactive_s020_k11_b1_h4_i1"
        initial_wait_seconds = 30
        timeout_hours = 8.0
        stall_hours = 3.0
        launch_if_missing = $true
        skip_if_reached_k = 12
    }
)

$stageResults = New-Object System.Collections.Generic.List[object]
$maxReachedGlobal = 0

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
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

function Get-StageDir {
    param([string]$StageName)
    return Join-Path $scriptDir ("truth\joint_supply_wedge\" + $StageName)
}

function Get-StageSummaryCsv {
    param([string]$StageName)
    return Join-Path (Get-StageDir $StageName) ($StageName + "_summary.csv")
}

function Get-StagePriceCsv {
    param([string]$StageName)
    return Join-Path (Get-StageDir $StageName) ($StageName + "_final_price_path.csv")
}

function Get-StageWedgeCsv {
    param([string]$StageName)
    return Join-Path (Get-StageDir $StageName) ($StageName + "_final_wedge_path.csv")
}

function Get-StageKPriceCsv {
    param([string]$StageName, [int]$K)
    $stageKDir = Join-Path (Get-StageDir $StageName) ("k" + $K.ToString())
    return Join-Path $stageKDir ("{0}_k{1:D2}_final_price_path.csv" -f $StageName, $K)
}

function Get-StageKWedgeCsv {
    param([string]$StageName, [int]$K)
    $stageKDir = Join-Path (Get-StageDir $StageName) ("k" + $K.ToString())
    return Join-Path $stageKDir ("{0}_k{1:D2}_final_wedge_path.csv" -f $StageName, $K)
}

function Get-SeedPriceCsvForStage {
    param($Stage)
    if ($null -ne $Stage.seed_stage_name -and -not [string]::IsNullOrWhiteSpace([string]$Stage.seed_stage_name)) {
        if ($null -ne $Stage.seed_stage_k -and [int]$Stage.seed_stage_k -gt 0) {
            return Get-StageKPriceCsv -StageName ([string]$Stage.seed_stage_name) -K ([int]$Stage.seed_stage_k)
        }
        return Get-StagePriceCsv ([string]$Stage.seed_stage_name)
    }
    return $seedPriceCsv
}

function Get-SeedWedgeCsvForStage {
    param($Stage)
    if ($null -ne $Stage.seed_stage_name -and -not [string]::IsNullOrWhiteSpace([string]$Stage.seed_stage_name)) {
        if ($null -ne $Stage.seed_stage_k -and [int]$Stage.seed_stage_k -gt 0) {
            return Get-StageKWedgeCsv -StageName ([string]$Stage.seed_stage_name) -K ([int]$Stage.seed_stage_k)
        }
        return Get-StageWedgeCsv ([string]$Stage.seed_stage_name)
    }
    return $seedWedgeCsv
}

function Get-StageLastWriteTime {
    param([string]$StageDir)
    if (-not (Test-Path $StageDir)) { return $null }
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

function Get-MaxReachedStage {
    param([string]$StageDir)
    if (-not (Test-Path $StageDir)) { return 0 }
    $dirs = @(Get-ChildItem -LiteralPath $StageDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^k(\d+)$' })
    if ($dirs.Count -eq 0) { return 0 }
    $values = @()
    foreach ($dir in $dirs) {
        $values += [int]$Matches[1]
    }
    return ($values | Measure-Object -Maximum).Maximum
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

function Get-StageProcessToken {
    param($Stage)
    if ($null -ne $Stage.process_token -and -not [string]::IsNullOrWhiteSpace([string]$Stage.process_token)) {
        return [string]$Stage.process_token
    }
    return [string]$Stage.name
}

function Format-MatlabColumnVector {
    param([double[]]$Values)
    return "[" + (($Values | ForEach-Object { [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:G17}", $_) }) -join "; ") + "]"
}

function Format-MatlabIntVector {
    param([int[]]$Values)
    return "[" + (($Values | ForEach-Object { $_.ToString() }) -join "; ") + "]"
}

function Start-Stage {
    param($Stage)

    $runTag = $Stage.name
    $startupLog = Join-Path $scriptDir ("truth\joint_supply_wedge\" + $runTag + "_startup.log")
    if (Test-Path $startupLog) {
        Remove-Item -LiteralPath $startupLog -Force -ErrorAction SilentlyContinue
    }

    if ($Stage.use_freezeprefix_launcher) {
        $launcherPath = Join-Path $scriptDir "launch_original_5yr_smoothed_tail_freezeprefix.ps1"
        $sigmaText = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:G17}', $Stage.political_response_sigma)
        $kScheduleArg = (@($Stage.k_schedule) | ForEach-Object { [int]$_ }) -join ","
        $seedPriceArg = Get-SeedPriceCsvForStage -Stage $Stage
        $seedWedgeArg = Get-SeedWedgeCsvForStage -Stage $Stage
        $launcherLabel = ""
        if ($null -ne $Stage.launcher_label) {
            $launcherLabel = [string]$Stage.launcher_label
        }
        $proc = Start-Process -FilePath "powershell.exe" -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-File", $launcherPath,
            "-Sigma", $sigmaText,
            "-Label", $launcherLabel,
            "-RunTag", $runTag,
            "-MaxK", ([string]$Stage.max_k),
            "-KSchedule", $kScheduleArg,
            "-PrefixLockLength", ([string]$Stage.prefix_lock_length),
            "-BasisCount", ([string]$Stage.basis_count),
            "-HousingClearMaxIter", ([string]$Stage.housing_clear_max_iter),
            "-MaxOuterIter", ([string]$Stage.max_outer_iter),
            "-SeedPriceCsv", $seedPriceArg,
            "-SeedWedgeCsv", $seedWedgeArg
        ) -WindowStyle Hidden -PassThru
        Write-Log "Launched stage $runTag with launcher pid=$($proc.Id)"
        return $proc.Id
    }

    $candidateScaleExpr = Format-MatlabColumnVector @($Stage.candidate_scales)
    $kScheduleExpr = Format-MatlabIntVector @($Stage.k_schedule)
    $stageSeedPriceCsv = Get-SeedPriceCsvForStage -Stage $Stage
    $stageSeedWedgeCsv = Get-SeedWedgeCsvForStage -Stage $Stage
    $prefixLockLength = 0
    if ($null -ne $Stage.prefix_lock_length) {
        $prefixLockLength = $Stage.prefix_lock_length
    }
    $matlabCmd = "addpath('$scriptDir'); diary('$startupLog'); diary on; [summary, results] = run_original_5yr_joint_wedge_smoothed(" +
        ([string]$Stage.max_k) + ", " +
        ([string]$Stage.max_outer_iter) + ", " +
        ([string]$Stage.basis_count) + ", " +
        "'$stageSeedPriceCsv', '$runTag', '$($Stage.demographic_source_mode)', " +
        ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:G17}', $Stage.finite_diff_step)) + ", " +
        ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:G17}', $Stage.ridge_lambda)) + ", " +
        $candidateScaleExpr + ", " +
        ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:G17}', $Stage.trust_region_log_step)) + ", " +
        ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:G17}', $Stage.active_threshold_frac)) + ", " +
        ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:G17}', $Stage.wedge_floor)) + ", " +
        ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:G17}', $Stage.wedge_cap)) + ", " +
        $kScheduleExpr + ", " +
        ([string]$Stage.housing_clear_max_iter) + ", " +
        ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:G17}', $Stage.political_response_sigma)) + ", " +
        "'$stageSeedWedgeCsv', " +
        ([string]$prefixLockLength) + "); disp(summary); diary off; exit;"

    $proc = Start-Process -FilePath $MatlabExe -ArgumentList @("-batch", $matlabCmd) -WindowStyle Hidden -PassThru
    Write-Log "Launched stage $runTag with pid=$($proc.Id)"
    return $proc.Id
}

function Write-Status {
    param(
        [string]$State,
        [string]$CurrentStep,
        [string]$Message
    )

    $stageRows = @()
    foreach ($row in $stageResults) {
        $stageRows += $row
    }

    $payload = New-Object PSObject
    Add-Member -InputObject $payload -MemberType NoteProperty -Name "started_at" -Value $startedAt.ToString("s")
    Add-Member -InputObject $payload -MemberType NoteProperty -Name "updated_at" -Value (Get-Date).ToString("s")
    Add-Member -InputObject $payload -MemberType NoteProperty -Name "current_step" -Value $CurrentStep
    Add-Member -InputObject $payload -MemberType NoteProperty -Name "max_reached_global" -Value $maxReachedGlobal
    Add-Member -InputObject $payload -MemberType NoteProperty -Name "old_accepted_k10_vote" -Value $oldAcceptedK10Vote
    Add-Member -InputObject $payload -MemberType NoteProperty -Name "old_accepted_k10_gap" -Value $oldAcceptedK10Gap
    Add-Member -InputObject $payload -MemberType NoteProperty -Name "stages" -Value $stageRows
    Add-Member -InputObject $payload -MemberType NoteProperty -Name "message" -Value $Message

    $outerStatus = New-Object PSObject
    Add-Member -InputObject $outerStatus -MemberType NoteProperty -Name "state" -Value $State
    Add-Member -InputObject $outerStatus -MemberType NoteProperty -Name "payload" -Value $payload

    $outerStatus | ConvertTo-Json -Depth 8 | Set-Content -Path $statusPath

    $report = @(
        "# Smoothed tail fail-safe workflow",
        "",
        "- state: $State",
        "- current_step: $CurrentStep",
        "- max_reached_global: $maxReachedGlobal",
        "- old accepted k10: vote=$oldAcceptedK10Vote gap=$oldAcceptedK10Gap",
        "- updated_at: $((Get-Date).ToString('s'))",
        "",
        "## Message",
        "",
        $Message,
        "",
        "## Stage results",
        ""
    )

    foreach ($row in $stageResults) {
        $report += "- $($row.name): $($row.status), reached_k=$($row.max_stage_reached), vote=$($row.final_max_abs_vote), gap=$($row.final_max_abs_gap)"
    }

    Set-Content -Path $reportPath -Value ($report -join [Environment]::NewLine)
}

function Read-StageResult {
    param($Stage, [string]$Status, [string]$Reason)

    $stageDir = Get-StageDir $Stage.name
    $summaryCsv = Get-StageSummaryCsv $Stage.name
    $maxReached = Get-MaxReachedStage $stageDir
    $finalVote = [double]::NaN
    $finalGap = [double]::NaN
    $finalMerit = [double]::NaN

    if (Test-Path $summaryCsv) {
        $rows = @(Import-Csv -Path $summaryCsv)
        if ($rows.Count -gt 0) {
            $row = $rows[-1]
            $finalVote = Parse-Double $row.final_max_abs_vote
            $finalGap = Parse-Double $row.final_max_abs_gap
            $finalMerit = Parse-Double $row.final_merit
        }
    }

    return [ordered]@{
        name = $Stage.name
        status = $Status
        reason = $Reason
        completed_at = (Get-Date).ToString("s")
        max_stage_reached = $maxReached
        final_max_abs_vote = $finalVote
        final_max_abs_gap = $finalGap
        final_merit = $finalMerit
        summary_csv = $summaryCsv
        price_csv = Get-StagePriceCsv $Stage.name
        wedge_csv = Get-StageWedgeCsv $Stage.name
    }
}

Write-Log "Smoothed tail fail-safe workflow started."
Write-Status -State "running" -CurrentStep "initializing" -Message "Attaching to or launching the active smoothed tail queue."

for ($stageIndex = 0; $stageIndex -lt $stageQueue.Count; $stageIndex++) {
    if ((Get-Date) - $startedAt -gt [TimeSpan]::FromHours($MaxHours)) {
        Write-Log "MaxHours reached. Stopping workflow."
        break
    }
    if (Test-Path $stopPath) {
        Write-Log "Stop file detected. Stopping workflow."
        break
    }

    $stage = $stageQueue[$stageIndex]
    if ($stage.skip_if_reached_k -gt 0 -and $maxReachedGlobal -ge $stage.skip_if_reached_k) {
        $skipped = [ordered]@{
            name = $stage.name
            status = "skipped"
            reason = "already_reached_k_$($stage.skip_if_reached_k)"
            completed_at = (Get-Date).ToString("s")
            max_stage_reached = $maxReachedGlobal
            final_max_abs_vote = [double]::NaN
            final_max_abs_gap = [double]::NaN
            final_merit = [double]::NaN
            summary_csv = Get-StageSummaryCsv $stage.name
            price_csv = Get-StagePriceCsv $stage.name
            wedge_csv = Get-StageWedgeCsv $stage.name
        }
        $stageResults.Add($skipped) | Out-Null
        Write-Status -State "running" -CurrentStep $stage.name -Message "Skipping $($stage.name) because an earlier stage already reached k=$maxReachedGlobal."
        continue
    }

    if ($null -ne $stage.required_min_reached_k -and [int]$stage.required_min_reached_k -gt 0 -and $maxReachedGlobal -lt [int]$stage.required_min_reached_k) {
        $skipped = [ordered]@{
            name = $stage.name
            status = "skipped"
            reason = "not_reached_k_$($stage.required_min_reached_k)"
            completed_at = (Get-Date).ToString("s")
            max_stage_reached = $maxReachedGlobal
            final_max_abs_vote = [double]::NaN
            final_max_abs_gap = [double]::NaN
            final_merit = [double]::NaN
            summary_csv = Get-StageSummaryCsv $stage.name
            price_csv = Get-StagePriceCsv $stage.name
            wedge_csv = Get-StageWedgeCsv $stage.name
        }
        $stageResults.Add($skipped) | Out-Null
        Write-Status -State "running" -CurrentStep $stage.name -Message "Skipping $($stage.name) because no accepted seed has reached k=$($stage.required_min_reached_k)."
        continue
    }

    if ($null -ne $stage.seed_stage_name -and -not [string]::IsNullOrWhiteSpace([string]$stage.seed_stage_name)) {
        $stageSeedPriceCsv = Get-SeedPriceCsvForStage -Stage $stage
        $stageSeedWedgeCsv = Get-SeedWedgeCsvForStage -Stage $stage
        if (-not (Test-Path $stageSeedPriceCsv) -or -not (Test-Path $stageSeedWedgeCsv)) {
            $seedLabel = [string]$stage.seed_stage_name
            if ($null -ne $stage.seed_stage_k -and [int]$stage.seed_stage_k -gt 0) {
                $seedLabel = $seedLabel + "_k" + ([int]$stage.seed_stage_k).ToString()
            }
            $skipped = [ordered]@{
                name = $stage.name
                status = "skipped"
                reason = "missing_seed_$seedLabel"
                completed_at = (Get-Date).ToString("s")
                max_stage_reached = $maxReachedGlobal
                final_max_abs_vote = [double]::NaN
                final_max_abs_gap = [double]::NaN
                final_merit = [double]::NaN
                summary_csv = Get-StageSummaryCsv $stage.name
                price_csv = Get-StagePriceCsv $stage.name
                wedge_csv = Get-StageWedgeCsv $stage.name
            }
            $stageResults.Add($skipped) | Out-Null
            Write-Status -State "running" -CurrentStep $stage.name -Message "Skipping $($stage.name) because the required seed files from $seedLabel are missing."
            continue
        }
    }

    $stageDir = Get-StageDir $stage.name
    $stageStartedAt = Get-Date
    $attached = $false
    $launched = $false
    $stageProcessToken = Get-StageProcessToken -Stage $stage

    while ($true) {
        if (Test-Path $stopPath) {
            Write-Log "Stop file detected while monitoring $($stage.name)."
            break
        }

        $matching = @(Find-ProcessByToken -Token $stageProcessToken)
        $alive = ($matching.Count -gt 0)
        $lastWrite = Get-StageLastWriteTime $stageDir
        $maxReached = Get-MaxReachedStage $stageDir
        if ($maxReached -gt $maxReachedGlobal) {
            $maxReachedGlobal = $maxReached
        }

        if ($alive) {
            if (-not $attached -and -not $launched) {
                Write-Log "Attached to existing process for $($stage.name)."
                $attached = $true
            }
            $sinceWriteHours = if ($null -ne $lastWrite) { ((Get-Date) - $lastWrite).TotalHours } else { 0.0 }
            $sinceStartHours = ((Get-Date) - $stageStartedAt).TotalHours
            Write-Status -State "running" -CurrentStep $stage.name -Message "Monitoring $($stage.name); reached_k=$maxReached, hours=$([math]::Round($sinceStartHours,2)), idle_hours=$([math]::Round($sinceWriteHours,2))."

            if ($sinceStartHours -gt $stage.timeout_hours) {
                Write-Log "Timing out $($stage.name) after $sinceStartHours hours."
                Stop-ProcessesByToken -Token $stageProcessToken
                Start-Sleep -Seconds 5
                $result = Read-StageResult -Stage $stage -Status "failed" -Reason "timeout"
                $stageResults.Add($result) | Out-Null
                break
            }
            if ($null -ne $lastWrite -and $sinceWriteHours -gt $stage.stall_hours) {
                Write-Log "Stall detected for $($stage.name) after $sinceWriteHours idle hours."
                Stop-ProcessesByToken -Token $stageProcessToken
                Start-Sleep -Seconds 5
                $result = Read-StageResult -Stage $stage -Status "failed" -Reason "stall"
                $stageResults.Add($result) | Out-Null
                break
            }
            Start-Sleep -Seconds 60
            continue
        }

        if (-not $launched -and -not $attached -and (Test-Path (Get-StageSummaryCsv $stage.name))) {
            $result = Read-StageResult -Stage $stage -Status "completed" -Reason "summary_written"
            $stageResults.Add($result) | Out-Null
            Write-Status -State "running" -CurrentStep $stage.name -Message "Stage $($stage.name) already has a summary; recording result without relaunching."
            break
        }

        if (-not $launched -and -not $attached -and $stage.launch_if_missing) {
            Start-Stage -Stage $stage | Out-Null
            $launched = $true
            $stageStartedAt = Get-Date
            $initialWaitSeconds = 10
            if ($null -ne $stage.initial_wait_seconds) {
                $initialWaitSeconds = [int]$stage.initial_wait_seconds
            }
            Start-Sleep -Seconds $initialWaitSeconds
            continue
        }

        $resultStatus = if (Test-Path (Get-StageSummaryCsv $stage.name)) { "completed" } else { "failed" }
        $resultReason = if ($resultStatus -eq "completed") { "summary_written" } else { "no_summary" }
        $result = Read-StageResult -Stage $stage -Status $resultStatus -Reason $resultReason
        $stageResults.Add($result) | Out-Null
        Write-Status -State "running" -CurrentStep $stage.name -Message "Stage $($stage.name) finished with status $resultStatus; reached_k=$($result.max_stage_reached), vote=$($result.final_max_abs_vote), gap=$($result.final_max_abs_gap)."
        break
    }
}

$nextCandidate = [ordered]@{
    name = "terminal_closure_then_stacked_joint_residual_solve"
    reason = "Oracle broad strategy ranked terminal/ghost-tail closure diagnostics and then a stacked joint residual solve as the best exact-model lane once the bounded smoothed-tail queue gets one fair decision round."
    source = "nimby-re-broad-strategy"
    written_at = (Get-Date).ToString("s")
}
$nextCandidate | ConvertTo-Json -Depth 5 | Set-Content -Path $nextCandidatePath

$reviewLines = @(
    "# Queue review needed",
    "",
    "The smoothed tail fail-safe queue has exhausted its current automatic stages.",
    "",
    "Next candidate by current strategy ranking:",
    "",
    "- terminal/ghost-tail closure diagnostic",
    "- then stacked joint residual solve if the tail queue still fails",
    "- reason: best exact-model path after one fair local tail decision round",
    "",
    "See:",
    "",
    "- oracle_reviews/nimby_re_extended_strategy_response_20260423.md",
    "- workflow_original_5yr_joint_supply_wedge_smoothed_politics.md"
)
Set-Content -Path $reviewPath -Value ($reviewLines -join [Environment]::NewLine)

$finalPayload = [ordered]@{
    state = "completed"
    completed_at = (Get-Date).ToString("s")
    max_reached_global = $maxReachedGlobal
    stages = @($stageResults)
    next_best_candidate = $nextCandidate
}
$finalPayload | ConvertTo-Json -Depth 8 | Set-Content -Path $finalResultPath
Write-Status -State "completed" -CurrentStep "queue_exhausted" -Message "Smoothed tail fail-safe queue completed. Review file and next-best candidate written."
Write-Log "Smoothed tail fail-safe workflow completed."
