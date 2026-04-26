param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe",
    [double]$Sigma = 0.20,
    [double]$MaxHours = 24
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\entrant_survival_smooth_probe_local_queue_live"
}
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$statusPath = Join-Path $LiveRoot "latest_status.json"
$reportPath = Join-Path $LiveRoot "latest_report.md"
$logPath = Join-Path $LiveRoot "workflow_log.txt"
$stopPath = Join-Path $LiveRoot "stop.txt"
$finalPath = Join-Path $LiveRoot "final_result.json"
$startedAt = Get-Date

$stageQueue = @(
    [ordered]@{
        name = "local_entsurv_smooth_probe_s020_flat_k4_14"
        scenario = "entrant_survival_flat"
        max_k = 14
        max_outer_iter = 1
        basis_count = 2
        k_schedule = @(4, 6, 8, 10, 12, 14)
        housing_clear_max_iter = 2
        timeout_hours = 8.0
        seed_price_csv_path = Join-Path $scriptDir "truth\seeds\flat_s020_k02_price.csv"
        seed_wedge_csv_path = Join-Path $scriptDir "truth\seeds\flat_s020_k02_wedge.csv"
    }
)

$stageResults = New-Object System.Collections.Generic.List[object]

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

function Format-MatlabVector {
    param([int[]]$Values)
    return "[" + (($Values | ForEach-Object { $_.ToString() }) -join "; ") + "]"
}

function Format-MatlabDoubleVector {
    param([double[]]$Values)
    return "[" + (($Values | ForEach-Object { [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $_) }) -join "; ") + "]"
}

function Format-MatlabDouble {
    param([double]$Value)
    return [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $Value)
}

function Escape-MatlabSingleQuotedString {
    param([string]$Value)
    return $Value.Replace("'", "''")
}

function Get-StageDir {
    param([string]$StageName)
    return Join-Path $scriptDir ("truth\joint_supply_wedge\" + $StageName)
}

function Get-StageSummaryCsv {
    param([string]$StageName)
    return Join-Path (Get-StageDir $StageName) ($StageName + "_summary.csv")
}

function Get-MaxReachedStage {
    param([string]$StageName)
    $stageDir = Get-StageDir $StageName
    if (-not (Test-Path $stageDir)) { return 0 }
    $dirs = @(Get-ChildItem -LiteralPath $stageDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^k(\d+)$' })
    if ($dirs.Count -eq 0) { return 0 }
    $values = @()
    foreach ($dir in $dirs) {
        $values += [int]($dir.Name.Substring(1))
    }
    return ($values | Measure-Object -Maximum).Maximum
}

function Parse-Double {
    param($Value)
    if ($null -eq $Value) { return [double]::NaN }
    $parsed = 0.0
    if ([double]::TryParse(([string]$Value).Trim(), [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
        return $parsed
    }
    return [double]::NaN
}

function Find-StageProcesses {
    param([string]$Token)
    $rows = @()
    foreach ($proc in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
        $cmd = [string]$proc.CommandLine
        if (($proc.Name -match '^(powershell|pwsh|matlab|MATLAB)(\.exe)?$') -and
            ($cmd -like ("*" + $Token + "*")) -and
            ($cmd -notlike "*Get-CimInstance Win32_Process*")) {
            $rows += $proc
        }
    }
    return $rows
}

function Stop-StageProcesses {
    param([string]$Token)
    foreach ($proc in @(Find-StageProcesses -Token $Token)) {
        try { Stop-Process -Id $proc.ProcessId -Force -ErrorAction Stop } catch {}
    }
}

function Read-StageResult {
    param($Stage, [string]$Status, [string]$Reason)
    $summaryCsv = Get-StageSummaryCsv $Stage.name
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
        scenario = $Stage.scenario
        sigma = $Sigma
        status = $Status
        reason = $Reason
        completed_at = (Get-Date).ToString("s")
        max_stage_reached = Get-MaxReachedStage $Stage.name
        final_max_abs_vote = $finalVote
        final_max_abs_gap = $finalGap
        final_merit = $finalMerit
        summary_csv = $summaryCsv
    }
}

function Write-Status {
    param([string]$State, [string]$CurrentStep, [string]$Message)
    $stageRows = @()
    foreach ($row in $stageResults) {
        $stageRows += $row
    }
    $payload = [ordered]@{
        state = $State
        started_at = $startedAt.ToString("s")
        updated_at = (Get-Date).ToString("s")
        current_step = $CurrentStep
        sigma = $Sigma
        message = $Message
        stages = $stageRows
    }
    $payload | ConvertTo-Json -Depth 8 | Set-Content -Path $statusPath

    $lines = @(
        "# Entrant-survival smoothed-politics probe local queue",
        "",
        "- state: $State",
        "- current_step: $CurrentStep",
        "- sigma: $Sigma",
        "- updated_at: $((Get-Date).ToString('s'))",
        "",
        $Message,
        "",
        "## Stage results",
        ""
    )
    foreach ($row in $stageResults) {
        $lines += "- $($row.name): $($row.status), reached_k=$($row.max_stage_reached), vote=$($row.final_max_abs_vote), gap=$($row.final_max_abs_gap)"
    }
    Set-Content -Path $reportPath -Value ($lines -join [Environment]::NewLine)
}

function Start-Stage {
    param($Stage)
    $candidateScalesExpr = Format-MatlabDoubleVector @(1.0, 0.5)
    $kScheduleExpr = Format-MatlabVector @($Stage.k_schedule)
    $sigmaText = Format-MatlabDouble $Sigma
    $batchPath = Join-Path $LiveRoot ($Stage.name + "_batch.m")
    $stdoutPath = Join-Path $LiveRoot ($Stage.name + "_matlab_stdout.log")
    $stderrPath = Join-Path $LiveRoot ($Stage.name + "_matlab_stderr.log")
    $scriptDirEsc = Escape-MatlabSingleQuotedString $scriptDir
    $batchPathEsc = Escape-MatlabSingleQuotedString $batchPath
    $seedPricePath = ''
    $seedWedgePath = ''
    if ($Stage.Contains('seed_price_csv_path')) {
        $seedPricePath = [string]$Stage.seed_price_csv_path
    }
    if ($Stage.Contains('seed_wedge_csv_path')) {
        $seedWedgePath = [string]$Stage.seed_wedge_csv_path
    }
    if (-not [string]::IsNullOrWhiteSpace($seedPricePath) -and -not (Test-Path $seedPricePath)) {
        throw "Missing seed price path for $($Stage.name): $seedPricePath"
    }
    if (-not [string]::IsNullOrWhiteSpace($seedWedgePath) -and -not (Test-Path $seedWedgePath)) {
        throw "Missing seed wedge path for $($Stage.name): $seedWedgePath"
    }
    $seedPricePathEsc = Escape-MatlabSingleQuotedString $seedPricePath
    $seedWedgePathEsc = Escape-MatlabSingleQuotedString $seedWedgePath
    $batchLines = @(
        "addpath('$scriptDirEsc');",
        "[summary, results] = run_original_5yr_joint_wedge_smoothed($($Stage.max_k), $($Stage.max_outer_iter), $($Stage.basis_count), '$seedPricePathEsc', '$($Stage.name)', '$($Stage.scenario)', 0.01, 0.001, $candidateScalesExpr, 0.08, 0.65, -0.5, 0.5, $kScheduleExpr, $($Stage.housing_clear_max_iter), $sigmaText, '$seedWedgePathEsc', 0, 'stage_init_only');",
        "disp(summary);"
    )
    Set-Content -Path $batchPath -Value $batchLines
    $batchCommand = "run('$batchPathEsc')"
    $proc = Start-Process -FilePath $MatlabExe -ArgumentList @("-batch", "`"$batchCommand`"") -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru
    Write-Log "Launched $($Stage.name) pid=$($proc.Id) batch=$batchPath stdout=$stdoutPath stderr=$stderrPath"
    return $proc
}

try {
Write-Log "Entrant-survival smoothed-politics probe local queue started."
Write-Status -State "running" -CurrentStep "initializing" -Message "Starting local entrant-survival probe ladder to k=14: evaluate stage-init once at each rung, record it, and move on."

    foreach ($stage in $stageQueue) {
        if ((Get-Date) - $startedAt -gt [TimeSpan]::FromHours($MaxHours)) {
            Write-Log "MaxHours reached."
            break
        }
        if (Test-Path $stopPath) {
            Write-Log "Stop file detected."
            break
        }

        if (Test-Path (Get-StageSummaryCsv $stage.name)) {
            $result = Read-StageResult -Stage $stage -Status "completed" -Reason "summary_written"
            $stageResults.Add($result) | Out-Null
            Write-Status -State "running" -CurrentStep $stage.name -Message "Recorded existing summary for $($stage.name)."
            continue
        }

        $proc = Start-Stage -Stage $stage
        $stageStartedAt = Get-Date
        while ($true) {
            if (Test-Path $stopPath) {
                Write-Log "Stop file detected while monitoring $($stage.name)."
                Stop-StageProcesses -Token $stage.name
                break
            }
            $alive = $false
            try {
                $alive = $null -ne (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue)
            }
            catch {
                $alive = $false
            }
            $elapsed = ((Get-Date) - $stageStartedAt).TotalHours
            Write-Status -State "running" -CurrentStep $stage.name -Message "Monitoring $($stage.name); reached_k=$(Get-MaxReachedStage $stage.name), hours=$([math]::Round($elapsed,2))."

            if ($elapsed -gt [double]$stage.timeout_hours) {
                Write-Log "Timing out $($stage.name)."
                Stop-StageProcesses -Token $stage.name
                $result = Read-StageResult -Stage $stage -Status "failed" -Reason "timeout"
                $stageResults.Add($result) | Out-Null
                break
            }
            if (-not $alive) {
                $status = if (Test-Path (Get-StageSummaryCsv $stage.name)) { "completed" } else { "failed" }
                $reason = if ($status -eq "completed") { "summary_written" } else { "no_summary" }
                $result = Read-StageResult -Stage $stage -Status $status -Reason $reason
                $stageResults.Add($result) | Out-Null
                Write-Status -State "running" -CurrentStep $stage.name -Message "Stage $($stage.name) finished with $status."
                break
            }
            Start-Sleep -Seconds 60
        }
    }

    $final = [ordered]@{
        state = "completed"
        completed_at = (Get-Date).ToString("s")
        sigma = $Sigma
        stages = @($stageResults.ToArray())
    }
    $final | ConvertTo-Json -Depth 8 | Set-Content -Path $finalPath
    Write-Status -State "completed" -CurrentStep "queue_complete" -Message "Entrant-survival smoothed-politics probe local queue completed or stopped."
    Write-Log "Entrant-survival smoothed-politics probe local queue finished."
}
catch {
    $errorText = ($_ | Out-String).Trim()
    try { Write-Log ("ERROR: " + $errorText) } catch {}
    try { Write-Status -State "failed" -CurrentStep "runner_error" -Message $errorText } catch {}
    throw
}
