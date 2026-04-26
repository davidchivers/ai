param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe",
    [double]$Sigma = 0.20,
    [double]$MaxHours = 18
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\ghost_tail_k10_live"
}
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$statusPath = Join-Path $LiveRoot "latest_status.json"
$reportPath = Join-Path $LiveRoot "latest_report.md"
$logPath = Join-Path $LiveRoot "workflow_log.txt"
$stopPath = Join-Path $LiveRoot "stop.txt"
$finalPath = Join-Path $LiveRoot "final_result.json"
$startedAt = Get-Date

$seedDir = Join-Path $scriptDir "truth\seeds"
New-Item -ItemType Directory -Force -Path $seedDir | Out-Null
$probeRun = "local_entsurv_smooth_probe_s020_flat_k4_14"
$probeK8Dir = Join-Path $scriptDir ("truth\joint_supply_wedge\" + $probeRun + "\k08")
$seedPrice = Join-Path $seedDir "flat_probe_s020_k08_price.csv"
$seedWedge = Join-Path $seedDir "flat_probe_s020_k08_wedge.csv"
$srcPrice = Join-Path $probeK8Dir ($probeRun + "_k08_final_price_path.csv")
$srcWedge = Join-Path $probeK8Dir ($probeRun + "_k08_final_wedge_path.csv")
Copy-Item -LiteralPath ("\\?\" + $srcPrice) -Destination $seedPrice -Force
Copy-Item -LiteralPath ("\\?\" + $srcWedge) -Destination $seedWedge -Force

$stageQueue = @(
    [ordered]@{ name = "gt_k10_g00_s020_i1"; ghost = 0; max_k = 10; timeout_hours = 3.0 },
    [ordered]@{ name = "gt_k10_g02_s020_i1"; ghost = 2; max_k = 12; timeout_hours = 4.0 },
    [ordered]@{ name = "gt_k10_g04_s020_i1"; ghost = 4; max_k = 14; timeout_hours = 5.0 },
    [ordered]@{ name = "gt_k10_g06_s020_i1"; ghost = 6; max_k = 16; timeout_hours = 6.0 }
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

function Parse-Double {
    param($Value)
    if ($null -eq $Value) { return [double]::NaN }
    $parsed = 0.0
    if ([double]::TryParse(([string]$Value).Trim(), [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
        return $parsed
    }
    return [double]::NaN
}

function Get-StageDir {
    param([string]$StageName)
    return Join-Path $scriptDir ("truth\joint_supply_wedge\" + $StageName)
}

function Get-StageSummaryCsv {
    param([string]$StageName)
    return Join-Path (Get-StageDir $StageName) ($StageName + "_summary.csv")
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
    $row = $null
    if (Test-Path $summaryCsv) {
        $rows = @(Import-Csv -Path $summaryCsv)
        if ($rows.Count -gt 0) { $row = $rows[-1] }
    }
    return [ordered]@{
        name = $Stage.name
        status = $Status
        reason = $Reason
        ghost_tail_periods = $Stage.ghost
        internal_horizon = $Stage.max_k
        objective_horizon = 10
        completed_at = (Get-Date).ToString("s")
        target_max_abs_vote = if ($null -ne $row) { Parse-Double $row.final_max_abs_vote } else { [double]::NaN }
        full_max_abs_vote = if ($null -ne $row) { Parse-Double $row.final_full_max_abs_vote } else { [double]::NaN }
        ghost_max_abs_vote = if ($null -ne $row) { Parse-Double $row.final_ghost_max_abs_vote } else { [double]::NaN }
        target_max_abs_gap = if ($null -ne $row) { Parse-Double $row.final_max_abs_gap } else { [double]::NaN }
        full_max_abs_gap = if ($null -ne $row) { Parse-Double $row.final_full_max_abs_gap } else { [double]::NaN }
        merit = if ($null -ne $row) { Parse-Double $row.final_merit } else { [double]::NaN }
        summary_csv = $summaryCsv
    }
}

function Write-Status {
    param([string]$State, [string]$CurrentStep, [string]$Message)
    $stageRows = @()
    foreach ($row in $stageResults) { $stageRows += $row }
    $payload = [ordered]@{
        state = $State
        started_at = $startedAt.ToString("s")
        updated_at = (Get-Date).ToString("s")
        current_step = $CurrentStep
        sigma = $Sigma
        seed_price_csv_path = $seedPrice
        seed_wedge_csv_path = $seedWedge
        message = $Message
        stages = $stageRows
    }
    $payload | ConvertTo-Json -Depth 8 | Set-Content -Path $statusPath

    $lines = @(
        "# Ghost-tail k=10 diagnostic",
        "",
        "- state: $State",
        "- current_step: $CurrentStep",
        "- sigma: $Sigma",
        "- objective_horizon: 10",
        "- updated_at: $((Get-Date).ToString('s'))",
        "",
        $Message,
        "",
        "## Stage results",
        ""
    )
    foreach ($row in $stageResults) {
        $lines += "- G=$($row.ghost_tail_periods), H=$($row.internal_horizon): $($row.status), target_vote=$($row.target_max_abs_vote), full_vote=$($row.full_max_abs_vote), target_gap=$($row.target_max_abs_gap)"
    }
    Set-Content -Path $reportPath -Value ($lines -join [Environment]::NewLine)
}

function Start-Stage {
    param($Stage)
    $candidateScalesExpr = Format-MatlabDoubleVector @(1.0, 0.5)
    $kScheduleExpr = Format-MatlabVector @($Stage.max_k)
    $sigmaText = Format-MatlabDouble $Sigma
    $batchPath = Join-Path $LiveRoot ($Stage.name + "_batch.m")
    $stdoutPath = Join-Path $LiveRoot ($Stage.name + "_matlab_stdout.log")
    $stderrPath = Join-Path $LiveRoot ($Stage.name + "_matlab_stderr.log")
    $scriptDirEsc = Escape-MatlabSingleQuotedString $scriptDir
    $batchPathEsc = Escape-MatlabSingleQuotedString $batchPath
    $seedPriceEsc = Escape-MatlabSingleQuotedString $seedPrice
    $seedWedgeEsc = Escape-MatlabSingleQuotedString $seedWedge
    $batchLines = @(
        "addpath('$scriptDirEsc');",
        "[summary, results] = run_original_5yr_joint_wedge_smoothed($($Stage.max_k), 1, 4, '$seedPriceEsc', '$($Stage.name)', 'entrant_survival_flat', 0.01, 0.001, $candidateScalesExpr, 0.08, 0.65, -0.5, 0.5, $kScheduleExpr, 2, $sigmaText, '$seedWedgeEsc', 0, 'strict', 10);",
        "disp(summary);"
    )
    Set-Content -Path $batchPath -Value $batchLines
    $batchCommand = "run('$batchPathEsc')"
    $proc = Start-Process -FilePath $MatlabExe -ArgumentList @("-batch", "`"$batchCommand`"") -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru
    Write-Log "Launched $($Stage.name) pid=$($proc.Id) batch=$batchPath stdout=$stdoutPath stderr=$stderrPath"
    return $proc
}

try {
    Write-Log "Ghost-tail diagnostic started."
    Write-Status -State "running" -CurrentStep "initializing" -Message "Testing whether the k=10 political spike is a terminal-horizon artifact by adding G = 0, 2, 4, 6 auxiliary periods."

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
            $stageResults.Add((Read-StageResult -Stage $stage -Status "completed" -Reason "summary_written")) | Out-Null
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
            try { $alive = $null -ne (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue) } catch { $alive = $false }
            $elapsed = ((Get-Date) - $stageStartedAt).TotalHours
            Write-Status -State "running" -CurrentStep $stage.name -Message "Monitoring $($stage.name); G=$($stage.ghost), H=$($stage.max_k), hours=$([math]::Round($elapsed,2))."

            if ($elapsed -gt [double]$stage.timeout_hours) {
                Write-Log "Timing out $($stage.name)."
                Stop-StageProcesses -Token $stage.name
                $stageResults.Add((Read-StageResult -Stage $stage -Status "failed" -Reason "timeout")) | Out-Null
                break
            }
            if (-not $alive) {
                $status = if (Test-Path (Get-StageSummaryCsv $stage.name)) { "completed" } else { "failed" }
                $reason = if ($status -eq "completed") { "summary_written" } else { "no_summary" }
                $stageResults.Add((Read-StageResult -Stage $stage -Status $status -Reason $reason)) | Out-Null
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
    Write-Status -State "completed" -CurrentStep "queue_complete" -Message "Ghost-tail diagnostic completed or stopped."
    Write-Log "Ghost-tail diagnostic finished."
}
catch {
    $errorText = ($_ | Out-String).Trim()
    try { Write-Log ("ERROR: " + $errorText) } catch {}
    try { Write-Status -State "failed" -CurrentStep "runner_error" -Message $errorText } catch {}
    throw
}
