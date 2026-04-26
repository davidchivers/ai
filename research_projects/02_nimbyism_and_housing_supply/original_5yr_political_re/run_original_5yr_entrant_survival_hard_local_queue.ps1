param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe",
    [double]$MaxHours = 18
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\entrant_survival_hard_local_queue_live"
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
        name = "local_entsurv_hard_flat_k2_6_i1"
        scenario = "entrant_survival_flat"
        description = "Sanity check with fixed survival and flat entrant path."
        max_k = 6
        max_outer_iter = 1
        basis_count = 2
        k_schedule = "2,4,6"
        housing_clear_max_iter = 2
        timeout_hours = 4.0
    },
    [ordered]@{
        name = "local_entsurv_hard_boom_k2_6_i1"
        scenario = "entrant_survival_boom"
        description = "Temporary baby-boom entrant path with hard voting."
        max_k = 6
        max_outer_iter = 1
        basis_count = 2
        k_schedule = "2,4,6"
        housing_clear_max_iter = 2
        timeout_hours = 4.0
    },
    [ordered]@{
        name = "local_entsurv_hard_decline_k2_6_i1"
        scenario = "entrant_survival_decline"
        description = "Secular entrant decline with hard voting."
        max_k = 6
        max_outer_iter = 1
        basis_count = 2
        k_schedule = "2,4,6"
        housing_clear_max_iter = 2
        timeout_hours = 4.0
    }
)

$stageResults = New-Object System.Collections.Generic.List[object]

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
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
        message = $Message
        stages = $stageRows
    }
    $payload | ConvertTo-Json -Depth 8 | Set-Content -Path $statusPath

    $lines = @(
        "# Entrant-survival hard-sign local queue",
        "",
        "- state: $State",
        "- current_step: $CurrentStep",
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
    $runner = Join-Path $scriptDir "run_original_5yr_joint_wedge_entrant_survival_hard.ps1"
    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList @(
        "-ExecutionPolicy", "Bypass",
        "-File", $runner,
        "-Scenario", $Stage.scenario,
        "-MaxK", ([string]$Stage.max_k),
        "-MaxOuterIter", ([string]$Stage.max_outer_iter),
        "-BasisCount", ([string]$Stage.basis_count),
        "-RunTag", $Stage.name,
        "-KSchedule", $Stage.k_schedule,
        "-HousingClearMaxIter", ([string]$Stage.housing_clear_max_iter)
    ) -WindowStyle Hidden -PassThru
    Write-Log "Launched $($Stage.name) pid=$($proc.Id)"
    return $proc
}

Write-Log "Entrant-survival hard-sign local queue started."
Write-Status -State "running" -CurrentStep "initializing" -Message "Starting local hard-sign entrant-survival queue."

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
    stages = @($stageResults.ToArray())
}
$final | ConvertTo-Json -Depth 8 | Set-Content -Path $finalPath
Write-Status -State "completed" -CurrentStep "queue_complete" -Message "Entrant-survival hard-sign local queue completed or stopped."
Write-Log "Entrant-survival hard-sign local queue finished."
