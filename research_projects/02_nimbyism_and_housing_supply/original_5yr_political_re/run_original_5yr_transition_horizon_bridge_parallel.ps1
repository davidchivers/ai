param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "matlab",
    [double]$MaxHours = 12,
    [int]$StartK = 7,
    [int]$EndK = 13,
    [double]$PriceGuessLevel = 0.34013605902777766
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_horizon_bridge_live"
}

New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null
$runId = "bridge_" + (Get-Date -Format "yyyyMMdd_HHmmss")
$runDir = Join-Path $LiveRoot ("r\" + $runId)
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
Set-Content -Path (Join-Path $LiveRoot "active_run.txt") -Value $runDir

$statusPath = Join-Path $LiveRoot "latest_status.json"
$summaryPath = Join-Path $runDir "summary.md"
$logPath = Join-Path $runDir "workflow_log.txt"
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

function Ensure-TimeBudget {
    param([string]$NextStep)
    if ((Get-ElapsedHours) -gt $MaxHours) {
        throw "Time budget reached before step $NextStep."
    }
}

function Parse-Bool {
    param($Value)
    if ($null -eq $Value) {
        return $false
    }
    $text = ([string]$Value).Trim().ToLowerInvariant()
    return ($text -eq "true" -or $text -eq "1")
}

function Read-VectorFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        return @()
    }
    return @(Get-Content -Path $Path | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { [double]$_ })
}

function Get-RowString {
    param($Row, [string]$FieldName)
    if ($null -eq $Row) { return "" }
    $property = $Row.PSObject.Properties[$FieldName]
    if ($null -eq $property) { return "" }
    return [string]$property.Value
}

function Get-RowDouble {
    param($Row, [string]$FieldName, [double]$DefaultValue = [double]::NaN)
    if ($null -eq $Row) { return $DefaultValue }
    $property = $Row.PSObject.Properties[$FieldName]
    if ($null -eq $property) { return $DefaultValue }
    $text = ([string]$property.Value).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) { return $DefaultValue }
    $parsed = 0.0
    if ([double]::TryParse($text, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
        return $parsed
    }
    return $DefaultValue
}

function Get-RowBool {
    param($Row, [string]$FieldName)
    if ($null -eq $Row) { return $false }
    $property = $Row.PSObject.Properties[$FieldName]
    if ($null -eq $property) { return $false }
    return Parse-Bool $property.Value
}

function Select-BestSummaryRow {
    param([object[]]$Rows)

    if ($null -eq $Rows -or $Rows.Count -eq 0) {
        return $null
    }

    $bestRow = $Rows[0]
    foreach ($row in $Rows) {
        $rowVote = Get-RowDouble -Row $row -FieldName "max_abs_vote"
        $bestVote = Get-RowDouble -Row $bestRow -FieldName "max_abs_vote"
        if ($rowVote -lt ($bestVote - 1e-12)) {
            $bestRow = $row
            continue
        }
        if ($rowVote -gt ($bestVote + 1e-12)) {
            continue
        }

        $rowMerit = Get-RowDouble -Row $row -FieldName "merit"
        $bestMerit = Get-RowDouble -Row $bestRow -FieldName "merit"
        $rowMeritFinite = (-not [double]::IsNaN($rowMerit)) -and (-not [double]::IsInfinity($rowMerit))
        $bestMeritFinite = (-not [double]::IsNaN($bestMerit)) -and (-not [double]::IsInfinity($bestMerit))
        if ($rowMeritFinite -and $bestMeritFinite) {
            if ($rowMerit -lt ($bestMerit - 1e-12)) {
                $bestRow = $row
                continue
            }
            if ($rowMerit -gt ($bestMerit + 1e-12)) {
                continue
            }
        }

        $rowGap = Get-RowDouble -Row $row -FieldName "max_abs_gap"
        $bestGap = Get-RowDouble -Row $bestRow -FieldName "max_abs_gap"
        if ($rowGap -lt ($bestGap - 1e-12)) {
            $bestRow = $row
        }
    }

    return $bestRow
}

function Find-MatlabRunProcesses {
    param([string]$RunTag)
    return @(
        Get-CimInstance Win32_Process |
            Where-Object {
                $_.Name -match '^(matlab|MATLAB)(\.exe)?$' -and
                $_.CommandLine -like ("*" + $RunTag + "*")
            }
    )
}

function Start-TransitionStageProcess {
    param(
        [string]$StageName,
        [int]$MaxK
    )

    $runnerPath = Join-Path $scriptDir "run_original_5yr_transition_political_bellman_bounded.ps1"
    $argumentList = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $runnerPath,
        "-MatlabExe", $MatlabExe,
        "-MaxK", [string]$MaxK,
        "-MaxIter", "2",
        "-PriceUpdateMode", "political_only",
        "-PoliticalTarget", "equal_weight_vote",
        "-PoliticalUpdateWeight", "0.005",
        "-RunTag", $StageName,
        "-PoliticalUpdateRule", "fixed_step_targeted_linesearch",
        "-PriceGuessLevel", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $PriceGuessLevel)),
        "-DemographicSourceMode", "historical_1950",
        "-OuterLineSearchScales", "1",
        "-OuterLineSearchTol", "1E-06",
        "-MaxTargetedPeriods", "3",
        "-TargetBlockHalfWidth", "0",
        "-TargetMaskMode", "union_only"
    )

    return Start-Process powershell -ArgumentList $argumentList -PassThru -WindowStyle Hidden
}

function Read-StageResult {
    param(
        [string]$StageName,
        [int]$MaxK
    )

    $baseName = "original_5yr_transition_political_bellman_$StageName"
    $summaryCsv = Join-Path $scriptDir ($baseName + "_summary.csv")
    $resultsPath = Join-Path $scriptDir ($baseName + "_results.mat")
    $pricePathCsv = Join-Path $scriptDir ($baseName + "_final_price_path.csv")
    $votePathCsv = Join-Path $scriptDir ($baseName + "_final_vote_path.csv")

    $summaryRows = @(Import-Csv -Path $summaryCsv)
    $finalRow = $summaryRows | Select-Object -Last 1
    $bestRow = Select-BestSummaryRow -Rows $summaryRows

    return [ordered]@{
        name = $StageName
        status = "completed"
        max_k = $MaxK
        summary_path = $summaryCsv
        results_path = $resultsPath
        summary_rows = $summaryRows.Count
        final_iteration = [int](Get-RowDouble -Row $finalRow -FieldName "iteration" -DefaultValue 0)
        best_iteration = [int](Get-RowDouble -Row $bestRow -FieldName "iteration" -DefaultValue 0)
        max_abs_vote = Get-RowDouble -Row $bestRow -FieldName "max_abs_vote"
        max_abs_gap = Get-RowDouble -Row $bestRow -FieldName "max_abs_gap"
        residual_norm = Get-RowDouble -Row $bestRow -FieldName "residual_norm"
        merit = Get-RowDouble -Row $bestRow -FieldName "merit"
        vote_l2 = Get-RowDouble -Row $bestRow -FieldName "vote_l2"
        accepted_step_scale = Get-RowDouble -Row $bestRow -FieldName "accepted_step_scale"
        accepted_update_mask = Get-RowString -Row $bestRow -FieldName "accepted_update_mask"
        line_search_improved = Get-RowBool -Row $bestRow -FieldName "line_search_improved"
        probe_accepted = Get-RowBool -Row $bestRow -FieldName "probe_accepted"
        final_price_path = Read-VectorFile -Path $pricePathCsv
        final_vote_path = Read-VectorFile -Path $votePathCsv
        elapsed_hours = (Get-ElapsedHours)
    }
}

function Wait-For-Stage {
    param(
        [string]$StageName,
        [int]$MaxK
    )

    Ensure-TimeBudget -NextStep $StageName
    $summaryCsv = Join-Path $scriptDir ("original_5yr_transition_political_bellman_" + $StageName + "_summary.csv")
    if (Test-Path $summaryCsv) {
        Write-Log "Stage $StageName already completed; reading existing summary."
        return Read-StageResult -StageName $StageName -MaxK $MaxK
    }

    $runState = "started_new"
    $matchingProcs = Find-MatlabRunProcesses -RunTag $StageName
    $startedProcId = $null
    $stageLaunchTime = Get-Date
    if ($matchingProcs.Count -gt 0) {
        $runState = "attached_existing"
        Write-Log "Attaching to existing MATLAB run for $StageName."
    } else {
        $startedProc = Start-TransitionStageProcess -StageName $StageName -MaxK $MaxK
        $startedProcId = $startedProc.Id
        Write-Log "Started stage $StageName under powershell pid=$($startedProc.Id)."
    }

    while (-not (Test-Path $summaryCsv)) {
        Ensure-TimeBudget -NextStep $StageName
        $matchingProcs = Find-MatlabRunProcesses -RunTag $StageName
        $runnerAlive = $false
        if ($null -ne $startedProcId) {
            $runnerAlive = $null -ne (Get-Process -Id $startedProcId -ErrorAction SilentlyContinue)
        }
        $payload = [ordered]@{
            workflow = "historical_original_5yr_horizon_bridge_parallel"
            run_id = $runId
            stage_results = @($stageResults.ToArray())
            current_stage = [ordered]@{
                name = $StageName
                run_state = $runState
                max_k = $MaxK
                runner_pid = $startedProcId
                runner_alive = $runnerAlive
                current_pids = @($matchingProcs | Select-Object -ExpandProperty ProcessId)
            }
        }
        Write-Status -State "running" -CurrentStep $StageName -Payload $payload

        if ($matchingProcs.Count -eq 0) {
            $startupGraceSeconds = 180
            $writeGraceSeconds = 30
            $elapsedSinceLaunch = ((Get-Date) - $stageLaunchTime).TotalSeconds
            if ($runnerAlive -or $elapsedSinceLaunch -lt $startupGraceSeconds) {
                Start-Sleep -Seconds 15
                continue
            }

            Start-Sleep -Seconds $writeGraceSeconds
            if (-not (Test-Path $summaryCsv)) {
                throw "Stage $StageName exited without producing a summary."
            }
        }
        Start-Sleep -Seconds 20
    }

    $stageResult = Read-StageResult -StageName $StageName -MaxK $MaxK
    $stageResults.Add($stageResult)
    Write-Log "Stage $StageName completed with max |vote| = $($stageResult.max_abs_vote)."
    return $stageResult
}

try {
    Write-Log "Historical original 5-year horizon bridge workflow started."
    $bridgeAttempts = New-Object System.Collections.Generic.List[object]
    $bestBridge = $null

    foreach ($k in $StartK..$EndK) {
        $stageName = "hist_k${k}_uniononly_scale1_i2"
        $stageResult = Wait-For-Stage -StageName $stageName -MaxK $k
        $bridgeAttempts.Add($stageResult)
        if ($null -eq $bestBridge) {
            $bestBridge = $stageResult
        } elseif ($stageResult.max_abs_vote -lt $bestBridge.max_abs_vote) {
            $bestBridge = $stageResult
        }
    }

    $payload = [ordered]@{
        workflow = "historical_original_5yr_horizon_bridge_parallel"
        run_id = $runId
        start_k = $StartK
        end_k = $EndK
        attempts = $bridgeAttempts.ToArray()
        best_stage = $bestBridge
        elapsed_hours = (Get-ElapsedHours)
    }

    $summaryLines = @(
        "# Original 5-year parallel horizon bridge",
        "",
        "- Start k: $StartK",
        "- End k: $EndK",
        "- Best stage: $($bestBridge.name)",
        "- Best max |vote|: $($bestBridge.max_abs_vote)",
        "- Elapsed hours: $([math]::Round((Get-ElapsedHours), 3))"
    )
    Set-Content -Path $summaryPath -Value ($summaryLines -join [Environment]::NewLine)
    $payload | ConvertTo-Json -Depth 8 | Set-Content -Path $finalResultPath
    Write-Status -State "completed" -CurrentStep "completed" -Payload $payload
    Write-Log "Parallel horizon bridge workflow completed."
}
catch {
    $message = $_.Exception.Message
    Write-Log "Parallel horizon bridge workflow stopped with error: $message"
    $payload = [ordered]@{
        workflow = "historical_original_5yr_horizon_bridge_parallel"
        run_id = $runId
        error = $message
        attempts = @($stageResults.ToArray())
        elapsed_hours = (Get-ElapsedHours)
    }
    $payload | ConvertTo-Json -Depth 8 | Set-Content -Path $finalResultPath
    Write-Status -State "blocked" -CurrentStep "stopped" -Payload $payload
    throw
}
