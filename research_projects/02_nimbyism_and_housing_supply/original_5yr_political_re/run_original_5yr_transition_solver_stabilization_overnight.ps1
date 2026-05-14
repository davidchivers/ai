param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "matlab",
    [double]$MaxHours = 48,
    [double]$PriceGuessLevel = 0.34013605902777766
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_solver_stabilization_live"
}

New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null
$runId = "stab_" + (Get-Date -Format "yyyyMMdd_HHmmss")
$runDir = Join-Path $LiveRoot ("r\" + $runId)
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
Set-Content -Path (Join-Path $LiveRoot "active_run.txt") -Value $runDir

$statusPath = Join-Path $LiveRoot "latest_status.json"
$logPath = Join-Path $runDir "workflow_log.txt"
$summaryPath = Join-Path $runDir "summary.md"
$finalResultPath = Join-Path $runDir "final_result.json"
$startedAt = Get-Date
$stageResults = New-Object System.Collections.Generic.List[object]

$referenceK6SmokeVote = 0.0278386148549857
$referenceK14SmokeVote = 0.0343491536712217

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
    if ($MaxHours -le 0) {
        return
    }
    if ((Get-ElapsedHours) -gt $MaxHours) {
        throw "Time budget reached before step $NextStep."
    }
}

function Get-StageResultsSnapshot {
    if ($stageResults.Count -eq 0) {
        return ,([object[]]@())
    }
    return ,([object[]]$stageResults.ToArray())
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
    param(
        $Row,
        [string]$FieldName
    )
    if ($null -eq $Row) { return "" }
    $property = $Row.PSObject.Properties[$FieldName]
    if ($null -eq $property) { return "" }
    return [string]$property.Value
}

function Get-RowDouble {
    param(
        $Row,
        [string]$FieldName,
        [double]$DefaultValue = [double]::NaN
    )
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
    param(
        $Row,
        [string]$FieldName
    )
    if ($null -eq $Row) { return $false }
    $property = $Row.PSObject.Properties[$FieldName]
    if ($null -eq $property) { return $false }
    return Parse-Bool $property.Value
}

function Select-BestSummaryRow {
    param(
        [object[]]$Rows
    )

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

function Get-StageBaseName {
    param([string]$StageName)
    return "original_5yr_transition_political_bellman_$StageName"
}

function Get-StageSummaryPath {
    param([string]$StageName)
    return Join-Path $scriptDir ((Get-StageBaseName -StageName $StageName) + "_summary.csv")
}

function Get-StageFinalPricePathCsv {
    param([string]$StageName)
    return Join-Path $scriptDir ((Get-StageBaseName -StageName $StageName) + "_final_price_path.csv")
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
        [int]$MaxK,
        [int]$MaxIter,
        [double]$PoliticalUpdateWeight,
        [string]$PoliticalUpdateRule,
        [double[]]$OuterLineSearchScales,
        [double]$OuterLineSearchTol,
        [int]$MaxTargetedPeriods,
        [int]$TargetBlockHalfWidth,
        [string]$TargetMaskMode,
        [string]$PriceGuessCsvPath = "",
        [string]$OuterStepNormalization = "",
        [double]$OuterTargetLogStep = [double]::NaN
    )

    $runnerPath = Join-Path $scriptDir "run_original_5yr_transition_political_bellman_bounded.ps1"
    $weightText = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $PoliticalUpdateWeight)
    $priceText = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $PriceGuessLevel)
    $tolText = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $OuterLineSearchTol)
    $scaleText = [string]::Join(",", ($OuterLineSearchScales | ForEach-Object {
        [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $_)
    }))
    $targetLogStepText = if ([double]::IsNaN($OuterTargetLogStep)) {
        ""
    } else {
        [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $OuterTargetLogStep)
    }

    $argumentList = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $runnerPath,
        "-MatlabExe", $MatlabExe,
        "-MaxK", [string]$MaxK,
        "-MaxIter", [string]$MaxIter,
        "-PriceUpdateMode", "political_only",
        "-PoliticalTarget", "equal_weight_vote",
        "-PoliticalUpdateWeight", $weightText,
        "-RunTag", $StageName,
        "-PoliticalUpdateRule", $PoliticalUpdateRule,
        "-PriceGuessLevel", $priceText,
        "-DemographicSourceMode", "historical_1950",
        "-OuterLineSearchScales", $scaleText,
        "-OuterLineSearchTol", $tolText,
        "-MaxTargetedPeriods", [string]$MaxTargetedPeriods,
        "-TargetBlockHalfWidth", [string]$TargetBlockHalfWidth
    )
    if (-not [string]::IsNullOrWhiteSpace($TargetMaskMode)) {
        $argumentList += @("-TargetMaskMode", $TargetMaskMode)
    }
    if (-not [string]::IsNullOrWhiteSpace($PriceGuessCsvPath)) {
        $argumentList += @("-PriceGuessCsvPath", $PriceGuessCsvPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($OuterStepNormalization)) {
        $argumentList += @("-OuterStepNormalization", $OuterStepNormalization)
    }
    if (-not [string]::IsNullOrWhiteSpace($targetLogStepText)) {
        $argumentList += @("-OuterTargetLogStep", $targetLogStepText)
    }

    return Start-Process powershell -ArgumentList $argumentList -PassThru -WindowStyle Hidden
}

function Read-StageResult {
    param(
        [string]$StageName,
        [int]$MaxK,
        [int]$MaxIter,
        [double]$PoliticalUpdateWeight,
        [string]$PoliticalUpdateRule,
        [double[]]$OuterLineSearchScales,
        [double]$OuterLineSearchTol,
        [int]$MaxTargetedPeriods,
        [int]$TargetBlockHalfWidth,
        [string]$TargetMaskMode,
        [string]$PriceGuessCsvPath = "",
        [string]$OuterStepNormalization = "",
        [double]$OuterTargetLogStep = [double]::NaN
    )

    $baseName = Get-StageBaseName -StageName $StageName
    $stageSummaryPath = Join-Path $scriptDir ($baseName + "_summary.csv")
    $stageResultsPath = Join-Path $scriptDir ($baseName + "_results.mat")
    $pricePathCsv = Join-Path $scriptDir ($baseName + "_final_price_path.csv")
    $votePathCsv = Join-Path $scriptDir ($baseName + "_final_vote_path.csv")
    $anchorPathCsv = Join-Path $scriptDir ($baseName + "_final_anchor_path.csv")

    $summaryRows = @(Import-Csv -Path $stageSummaryPath)
    $finalRow = $summaryRows | Select-Object -Last 1
    $bestRow = Select-BestSummaryRow -Rows $summaryRows
    $pricePath = Read-VectorFile -Path $pricePathCsv
    $votePath = Read-VectorFile -Path $votePathCsv
    $anchorPath = Read-VectorFile -Path $anchorPathCsv
    $everLineSearchUsed = @($summaryRows | Where-Object { Get-RowBool -Row $_ -FieldName "line_search_used" }).Count -gt 0
    $everLineSearchImproved = @($summaryRows | Where-Object { Get-RowBool -Row $_ -FieldName "line_search_improved" }).Count -gt 0
    $everProbeAccepted = @($summaryRows | Where-Object { Get-RowBool -Row $_ -FieldName "probe_accepted" }).Count -gt 0

    return [ordered]@{
        name = $StageName
        status = "completed"
        max_k = $MaxK
        max_iter = $MaxIter
        political_update_weight = $PoliticalUpdateWeight
        political_update_rule = $PoliticalUpdateRule
        outer_line_search_scales = $OuterLineSearchScales
        outer_line_search_tol = $OuterLineSearchTol
        max_targeted_periods = $MaxTargetedPeriods
        target_block_half_width = $TargetBlockHalfWidth
        target_mask_mode = $TargetMaskMode
        price_guess_csv_path = $PriceGuessCsvPath
        outer_step_normalization = $OuterStepNormalization
        outer_target_log_step = $OuterTargetLogStep
        summary_path = $stageSummaryPath
        results_path = $stageResultsPath
        summary_rows = $summaryRows.Count
        final_iteration = [int](Get-RowDouble -Row $finalRow -FieldName "iteration" -DefaultValue 0)
        best_iteration = [int](Get-RowDouble -Row $bestRow -FieldName "iteration" -DefaultValue 0)
        max_abs_vote = Get-RowDouble -Row $bestRow -FieldName "max_abs_vote"
        best_max_abs_vote = Get-RowDouble -Row $bestRow -FieldName "max_abs_vote"
        final_max_abs_vote = Get-RowDouble -Row $finalRow -FieldName "max_abs_vote"
        mean_vote = Get-RowDouble -Row $bestRow -FieldName "mean_vote"
        max_abs_gap = Get-RowDouble -Row $bestRow -FieldName "max_abs_gap"
        best_max_abs_gap = Get-RowDouble -Row $bestRow -FieldName "max_abs_gap"
        final_max_abs_gap = Get-RowDouble -Row $finalRow -FieldName "max_abs_gap"
        residual_norm = Get-RowDouble -Row $bestRow -FieldName "residual_norm"
        merit = Get-RowDouble -Row $bestRow -FieldName "merit"
        vote_l2 = Get-RowDouble -Row $bestRow -FieldName "vote_l2"
        price_min = Get-RowDouble -Row $bestRow -FieldName "price_min"
        price_max = Get-RowDouble -Row $bestRow -FieldName "price_max"
        accepted_step_scale = Get-RowDouble -Row $bestRow -FieldName "accepted_step_scale"
        accepted_update_mask = Get-RowString -Row $bestRow -FieldName "accepted_update_mask"
        final_accepted_update_mask = Get-RowString -Row $finalRow -FieldName "accepted_update_mask"
        line_search_used = $everLineSearchUsed
        line_search_improved = $everLineSearchImproved
        probe_accepted = $everProbeAccepted
        final_price_path = $pricePath
        final_vote_path = $votePath
        final_anchor_path = $anchorPath
        elapsed_hours = (Get-ElapsedHours)
    }
}

function New-FailedStageResult {
    param(
        [string]$StageName,
        [int]$MaxK,
        [int]$MaxIter,
        [double]$PoliticalUpdateWeight,
        [string]$PoliticalUpdateRule,
        [double[]]$OuterLineSearchScales,
        [double]$OuterLineSearchTol,
        [int]$MaxTargetedPeriods,
        [int]$TargetBlockHalfWidth,
        [string]$TargetMaskMode,
        [string]$PriceGuessCsvPath,
        [string]$OuterStepNormalization,
        [double]$OuterTargetLogStep,
        [string]$ErrorMessage
    )

    return [ordered]@{
        name = $StageName
        status = "failed"
        max_k = $MaxK
        max_iter = $MaxIter
        political_update_weight = $PoliticalUpdateWeight
        political_update_rule = $PoliticalUpdateRule
        outer_line_search_scales = $OuterLineSearchScales
        outer_line_search_tol = $OuterLineSearchTol
        max_targeted_periods = $MaxTargetedPeriods
        target_block_half_width = $TargetBlockHalfWidth
        target_mask_mode = $TargetMaskMode
        price_guess_csv_path = $PriceGuessCsvPath
        outer_step_normalization = $OuterStepNormalization
        outer_target_log_step = $OuterTargetLogStep
        error = $ErrorMessage
        line_search_improved = $false
        accepted_update_mask = ""
        elapsed_hours = (Get-ElapsedHours)
    }
}

function Invoke-Or-Wait-For-Stage {
    param(
        [string]$StageName,
        [int]$MaxK,
        [int]$MaxIter,
        [double]$PoliticalUpdateWeight,
        [string]$PoliticalUpdateRule,
        [double[]]$OuterLineSearchScales,
        [double]$OuterLineSearchTol,
        [int]$MaxTargetedPeriods,
        [int]$TargetBlockHalfWidth,
        [string]$TargetMaskMode,
        [string]$PriceGuessCsvPath = "",
        [string]$OuterStepNormalization = "",
        [double]$OuterTargetLogStep = [double]::NaN
    )

    Ensure-TimeBudget -NextStep $StageName
    $summaryCsv = Get-StageSummaryPath -StageName $StageName
    if (Test-Path $summaryCsv) {
        Write-Log "Stage $StageName already completed; reading existing summary."
        return Read-StageResult -StageName $StageName -MaxK $MaxK -MaxIter $MaxIter -PoliticalUpdateWeight $PoliticalUpdateWeight -PoliticalUpdateRule $PoliticalUpdateRule -OuterLineSearchScales $OuterLineSearchScales -OuterLineSearchTol $OuterLineSearchTol -MaxTargetedPeriods $MaxTargetedPeriods -TargetBlockHalfWidth $TargetBlockHalfWidth -TargetMaskMode $TargetMaskMode -PriceGuessCsvPath $PriceGuessCsvPath -OuterStepNormalization $OuterStepNormalization -OuterTargetLogStep $OuterTargetLogStep
    }

    $runState = "started_new"
    $matchingProcs = Find-MatlabRunProcesses -RunTag $StageName
    $startedProcId = $null
    $stageLaunchTime = Get-Date
    if ($matchingProcs.Count -gt 0) {
        $runState = "attached_existing"
        Write-Log "Attaching to existing MATLAB run for $StageName."
    } else {
        $startedProc = Start-TransitionStageProcess -StageName $StageName -MaxK $MaxK -MaxIter $MaxIter -PoliticalUpdateWeight $PoliticalUpdateWeight -PoliticalUpdateRule $PoliticalUpdateRule -OuterLineSearchScales $OuterLineSearchScales -OuterLineSearchTol $OuterLineSearchTol -MaxTargetedPeriods $MaxTargetedPeriods -TargetBlockHalfWidth $TargetBlockHalfWidth -TargetMaskMode $TargetMaskMode -PriceGuessCsvPath $PriceGuessCsvPath -OuterStepNormalization $OuterStepNormalization -OuterTargetLogStep $OuterTargetLogStep
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
            workflow = "historical_original_5yr_solver_stabilization"
            run_id = $runId
            stage_results = (Get-StageResultsSnapshot)
            current_stage = [ordered]@{
                name = $StageName
                run_state = $runState
                max_k = $MaxK
                max_iter = $MaxIter
                political_update_weight = $PoliticalUpdateWeight
                political_update_rule = $PoliticalUpdateRule
                outer_line_search_scales = $OuterLineSearchScales
                outer_line_search_tol = $OuterLineSearchTol
                max_targeted_periods = $MaxTargetedPeriods
                target_block_half_width = $TargetBlockHalfWidth
                target_mask_mode = $TargetMaskMode
                price_guess_csv_path = $PriceGuessCsvPath
                outer_step_normalization = $OuterStepNormalization
                outer_target_log_step = $OuterTargetLogStep
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
        Start-Sleep -Seconds 30
    }

    Write-Log "Stage $StageName completed."
    $stageResult = Read-StageResult -StageName $StageName -MaxK $MaxK -MaxIter $MaxIter -PoliticalUpdateWeight $PoliticalUpdateWeight -PoliticalUpdateRule $PoliticalUpdateRule -OuterLineSearchScales $OuterLineSearchScales -OuterLineSearchTol $OuterLineSearchTol -MaxTargetedPeriods $MaxTargetedPeriods -TargetBlockHalfWidth $TargetBlockHalfWidth -TargetMaskMode $TargetMaskMode -PriceGuessCsvPath $PriceGuessCsvPath -OuterStepNormalization $OuterStepNormalization -OuterTargetLogStep $OuterTargetLogStep
    $stageResult.status = "completed"
    $stageResults.Add($stageResult)
    return $stageResult
}

function Invoke-Stage-With-Reflow {
    param(
        [string]$StageName,
        [int]$MaxK,
        [int]$MaxIter,
        [double]$PoliticalUpdateWeight,
        [string]$PoliticalUpdateRule,
        [double[]]$OuterLineSearchScales,
        [double]$OuterLineSearchTol,
        [int]$MaxTargetedPeriods,
        [int]$TargetBlockHalfWidth,
        [string]$TargetMaskMode,
        [string]$PriceGuessCsvPath = "",
        [string]$OuterStepNormalization = "",
        [double]$OuterTargetLogStep = [double]::NaN
    )

    try {
        return Invoke-Or-Wait-For-Stage -StageName $StageName -MaxK $MaxK -MaxIter $MaxIter -PoliticalUpdateWeight $PoliticalUpdateWeight -PoliticalUpdateRule $PoliticalUpdateRule -OuterLineSearchScales $OuterLineSearchScales -OuterLineSearchTol $OuterLineSearchTol -MaxTargetedPeriods $MaxTargetedPeriods -TargetBlockHalfWidth $TargetBlockHalfWidth -TargetMaskMode $TargetMaskMode -PriceGuessCsvPath $PriceGuessCsvPath -OuterStepNormalization $OuterStepNormalization -OuterTargetLogStep $OuterTargetLogStep
    }
    catch {
        $failed = New-FailedStageResult -StageName $StageName -MaxK $MaxK -MaxIter $MaxIter -PoliticalUpdateWeight $PoliticalUpdateWeight -PoliticalUpdateRule $PoliticalUpdateRule -OuterLineSearchScales $OuterLineSearchScales -OuterLineSearchTol $OuterLineSearchTol -MaxTargetedPeriods $MaxTargetedPeriods -TargetBlockHalfWidth $TargetBlockHalfWidth -TargetMaskMode $TargetMaskMode -PriceGuessCsvPath $PriceGuessCsvPath -OuterStepNormalization $OuterStepNormalization -OuterTargetLogStep $OuterTargetLogStep -ErrorMessage $_.Exception.Message
        $stageResults.Add($failed)
        Write-Log "Stage $StageName failed but workflow will continue: $($_.Exception.Message)"
        return $failed
    }
}

function Compare-StageResult {
    param($Left, $Right)
    if ($null -eq $Left) { return $Right }
    if ($null -eq $Right) { return $Left }
    if ($Left.status -ne "completed") { return $Right }
    if ($Right.status -ne "completed") { return $Left }
    if ($Right.max_abs_vote -lt $Left.max_abs_vote) { return $Right }
    if ($Right.max_abs_vote -gt $Left.max_abs_vote) { return $Left }
    if ($Right.merit -lt $Left.merit) { return $Right }
    if ($Right.merit -gt $Left.merit) { return $Left }
    if ($Right.max_abs_gap -lt $Left.max_abs_gap) { return $Right }
    return $Left
}

function Test-StageImproved {
    param(
        $StageResult,
        [double]$ReferenceVote
    )
    if ($null -eq $StageResult) { return $false }
    if ($StageResult.status -ne "completed") { return $false }
    if (-not ($StageResult.line_search_improved -or $StageResult.probe_accepted)) { return $false }
    return ($StageResult.max_abs_vote -lt ($ReferenceVote - 1e-6))
}

function New-K6Candidate {
    param(
        [string]$StageName,
        [int]$MaxIter = 2,
        [double]$PoliticalUpdateWeight,
        [string]$PoliticalUpdateRule,
        [double[]]$OuterLineSearchScales,
        [int]$MaxTargetedPeriods,
        [int]$TargetBlockHalfWidth,
        [string]$TargetMaskMode = "full_library",
        [string]$PriceGuessCsvPath = "",
        [string]$OuterStepNormalization = "",
        [double]$OuterTargetLogStep = [double]::NaN
    )

    return [ordered]@{
        StageName = $StageName
        MaxK = 6
        MaxIter = $MaxIter
        PoliticalUpdateWeight = $PoliticalUpdateWeight
        PoliticalUpdateRule = $PoliticalUpdateRule
        OuterLineSearchScales = $OuterLineSearchScales
        OuterLineSearchTol = 1e-6
        MaxTargetedPeriods = $MaxTargetedPeriods
        TargetBlockHalfWidth = $TargetBlockHalfWidth
        TargetMaskMode = $TargetMaskMode
        PriceGuessCsvPath = $PriceGuessCsvPath
        OuterStepNormalization = $OuterStepNormalization
        OuterTargetLogStep = $OuterTargetLogStep
    }
}

function New-HorizonCandidate {
    param(
        [int]$MaxK,
        [string]$StageName,
        [int]$MaxIter = 2,
        [double]$PoliticalUpdateWeight,
        [string]$PoliticalUpdateRule,
        [double[]]$OuterLineSearchScales,
        [int]$MaxTargetedPeriods,
        [int]$TargetBlockHalfWidth,
        [string]$TargetMaskMode = "full_library",
        [string]$PriceGuessCsvPath = "",
        [string]$OuterStepNormalization = "",
        [double]$OuterTargetLogStep = [double]::NaN
    )

    return [ordered]@{
        StageName = $StageName
        MaxK = $MaxK
        MaxIter = $MaxIter
        PoliticalUpdateWeight = $PoliticalUpdateWeight
        PoliticalUpdateRule = $PoliticalUpdateRule
        OuterLineSearchScales = $OuterLineSearchScales
        OuterLineSearchTol = 1e-6
        MaxTargetedPeriods = $MaxTargetedPeriods
        TargetBlockHalfWidth = $TargetBlockHalfWidth
        TargetMaskMode = $TargetMaskMode
        PriceGuessCsvPath = $PriceGuessCsvPath
        OuterStepNormalization = $OuterStepNormalization
        OuterTargetLogStep = $OuterTargetLogStep
    }
}

try {
    Write-Log "Historical original 5-year solver-stabilization workflow started."

    $k6Attempts = New-Object System.Collections.Generic.List[object]
    $k6Candidates = @(
        (New-K6Candidate -StageName "hist_k6_uniononly_scale1_i2" -PoliticalUpdateWeight 0.005 -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(1.0) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 0 -TargetMaskMode "union_only"),
        (New-K6Candidate -StageName "hist_k6_uniononly_scale05_i2" -PoliticalUpdateWeight 0.005 -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(0.5) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 0 -TargetMaskMode "union_only"),
        (New-K6Candidate -StageName "hist_k6_unionblock_scale1_i2" -PoliticalUpdateWeight 0.005 -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(1.0) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 1 -TargetMaskMode "union_and_block"),
        (New-K6Candidate -StageName "hist_k6_uniononly_scale1_i3" -MaxIter 3 -PoliticalUpdateWeight 0.005 -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(1.0) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 0 -TargetMaskMode "union_only"),
        (New-K6Candidate -StageName "hist_k6_uniononly_smallw_i3" -MaxIter 3 -PoliticalUpdateWeight 0.0025 -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(1.0) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 0 -TargetMaskMode "union_only")
    )

    $bestK6 = $null
    $classification = "k6_candidate_search_running"
    $nextStep = "search_k6_candidates"
    $k6Primary = $null
    $k6Followup = $null

    foreach ($candidate in $k6Candidates) {
        if (Test-StageImproved -StageResult $bestK6 -ReferenceVote $referenceK6SmokeVote) {
            break
        }

        $stageResult = Invoke-Stage-With-Reflow `
            -StageName $candidate.StageName `
            -MaxK $candidate.MaxK `
            -MaxIter $candidate.MaxIter `
            -PoliticalUpdateWeight $candidate.PoliticalUpdateWeight `
            -PoliticalUpdateRule $candidate.PoliticalUpdateRule `
            -OuterLineSearchScales $candidate.OuterLineSearchScales `
            -OuterLineSearchTol $candidate.OuterLineSearchTol `
            -MaxTargetedPeriods $candidate.MaxTargetedPeriods `
            -TargetBlockHalfWidth $candidate.TargetBlockHalfWidth `
            -TargetMaskMode $candidate.TargetMaskMode `
            -PriceGuessCsvPath $candidate.PriceGuessCsvPath `
            -OuterStepNormalization $candidate.OuterStepNormalization `
            -OuterTargetLogStep $candidate.OuterTargetLogStep
        $k6Attempts.Add($stageResult)
        $bestK6 = Compare-StageResult -Left $bestK6 -Right $stageResult
        if ($null -eq $k6Primary) {
            $k6Primary = $stageResult
        } elseif ($null -eq $k6Followup) {
            $k6Followup = $stageResult
        }
    }

    $k14Targeted = $null
    $k14Attempts = New-Object System.Collections.Generic.List[object]
    $continuationAttempts = New-Object System.Collections.Generic.List[object]
    $bestK14 = $null
    if (Test-StageImproved -StageResult $bestK6 -ReferenceVote $referenceK6SmokeVote) {
        $classification = "horizon_continuation_started"
        $nextStep = "search_horizon_continuation"
        $continuationSeedCsv = Get-StageFinalPricePathCsv -StageName $bestK6.name
        $continuationCandidates = @(
            (New-HorizonCandidate -MaxK 8 -StageName "hist_k8_segmentunion_cont_i2" -PoliticalUpdateWeight ([double]$bestK6.political_update_weight) -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(8.0, 4.0, 2.0, 1.0, 0.5) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 1 -TargetMaskMode "segment_union" -PriceGuessCsvPath $continuationSeedCsv),
            (New-HorizonCandidate -MaxK 10 -StageName "hist_k10_segmentunion_cont_i2" -PoliticalUpdateWeight ([double]$bestK6.political_update_weight) -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(8.0, 4.0, 2.0, 1.0, 0.5) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 1 -TargetMaskMode "segment_union" -PriceGuessCsvPath $continuationSeedCsv),
            (New-HorizonCandidate -MaxK 12 -StageName "hist_k12_segmentunion_cont_i2" -PoliticalUpdateWeight ([double]$bestK6.political_update_weight) -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(8.0, 4.0, 2.0, 1.0, 0.5) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 1 -TargetMaskMode "segment_union" -PriceGuessCsvPath $continuationSeedCsv)
        )

        foreach ($candidate in $continuationCandidates) {
            $candidate.PriceGuessCsvPath = $continuationSeedCsv
            $stageResult = Invoke-Stage-With-Reflow `
                -StageName $candidate.StageName `
                -MaxK $candidate.MaxK `
                -MaxIter $candidate.MaxIter `
                -PoliticalUpdateWeight $candidate.PoliticalUpdateWeight `
                -PoliticalUpdateRule $candidate.PoliticalUpdateRule `
                -OuterLineSearchScales $candidate.OuterLineSearchScales `
                -OuterLineSearchTol $candidate.OuterLineSearchTol `
                -MaxTargetedPeriods $candidate.MaxTargetedPeriods `
                -TargetBlockHalfWidth $candidate.TargetBlockHalfWidth `
                -TargetMaskMode $candidate.TargetMaskMode `
                -PriceGuessCsvPath $candidate.PriceGuessCsvPath `
                -OuterStepNormalization $candidate.OuterStepNormalization `
                -OuterTargetLogStep $candidate.OuterTargetLogStep
            $continuationAttempts.Add($stageResult)
            if ($stageResult.status -eq "completed") {
                $continuationSeedCsv = Get-StageFinalPricePathCsv -StageName $stageResult.name
            }
        }

        $classification = "k14_targeted_started"
        $nextStep = "search_k14_candidates"
        $k14Candidates = @(
            (New-HorizonCandidate -MaxK 14 -StageName "hist_k14_segmentunion_cont_i2" -PoliticalUpdateWeight ([double]$bestK6.political_update_weight) -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(8.0, 4.0, 2.0, 1.0, 0.5) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 1 -TargetMaskMode "segment_union" -PriceGuessCsvPath $continuationSeedCsv),
            (New-HorizonCandidate -MaxK 14 -StageName "hist_k14_activeclusters_cont_i2" -PoliticalUpdateWeight ([double]$bestK6.political_update_weight) -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(8.0, 4.0, 2.0, 1.0, 0.5) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 1 -TargetMaskMode "active_clusters" -PriceGuessCsvPath $continuationSeedCsv),
            (New-HorizonCandidate -MaxK 14 -StageName "hist_k14_unionblock_cont_i2" -PoliticalUpdateWeight ([double]$bestK6.political_update_weight) -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(8.0, 4.0, 2.0, 1.0, 0.5) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 1 -TargetMaskMode "union_and_block" -PriceGuessCsvPath $continuationSeedCsv),
            (New-HorizonCandidate -MaxK 14 -StageName "hist_k14_signsplit_smallw_cont_i2" -PoliticalUpdateWeight 0.0025 -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(8.0, 4.0, 2.0, 1.0, 0.5) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 0 -TargetMaskMode "sign_split" -PriceGuessCsvPath $continuationSeedCsv)
        )

        foreach ($candidate in $k14Candidates) {
            if (Test-StageImproved -StageResult $bestK14 -ReferenceVote $referenceK14SmokeVote) {
                break
            }

            $stageResult = Invoke-Stage-With-Reflow `
                -StageName $candidate.StageName `
                -MaxK $candidate.MaxK `
                -MaxIter $candidate.MaxIter `
                -PoliticalUpdateWeight $candidate.PoliticalUpdateWeight `
                -PoliticalUpdateRule $candidate.PoliticalUpdateRule `
                -OuterLineSearchScales $candidate.OuterLineSearchScales `
                -OuterLineSearchTol $candidate.OuterLineSearchTol `
                -MaxTargetedPeriods $candidate.MaxTargetedPeriods `
                -TargetBlockHalfWidth $candidate.TargetBlockHalfWidth `
                -TargetMaskMode $candidate.TargetMaskMode `
                -PriceGuessCsvPath $candidate.PriceGuessCsvPath `
                -OuterStepNormalization $candidate.OuterStepNormalization `
                -OuterTargetLogStep $candidate.OuterTargetLogStep
            $k14Attempts.Add($stageResult)
            $bestK14 = Compare-StageResult -Left $bestK14 -Right $stageResult
        }

        if (-not (Test-StageImproved -StageResult $bestK14 -ReferenceVote $referenceK14SmokeVote)) {
            $classification = "k14_recovery_started"
            $nextStep = "search_k14_recovery_candidates"
            if ($null -ne $bestK14 -and $bestK14.status -eq "completed") {
                $continuationSeedCsv = Get-StageFinalPricePathCsv -StageName $bestK14.name
            }

            $k14RecoveryCandidates = @(
                (New-HorizonCandidate -MaxK 14 -StageName "hist_k14_activeclusters_norm_i2" -PoliticalUpdateWeight ([double]$bestK6.political_update_weight) -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(4.0, 2.0, 1.0, 0.5) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 1 -TargetMaskMode "active_clusters" -PriceGuessCsvPath $continuationSeedCsv -OuterStepNormalization "maxabs" -OuterTargetLogStep 0.001),
                (New-HorizonCandidate -MaxK 14 -StageName "hist_k14_unionblock_norm_i2" -PoliticalUpdateWeight ([double]$bestK6.political_update_weight) -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(4.0, 2.0, 1.0, 0.5) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 1 -TargetMaskMode "union_and_block" -PriceGuessCsvPath $continuationSeedCsv -OuterStepNormalization "maxabs" -OuterTargetLogStep 0.001),
                (New-HorizonCandidate -MaxK 14 -StageName "hist_k14_segmentunion_norm_i2" -PoliticalUpdateWeight ([double]$bestK6.political_update_weight) -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(4.0, 2.0, 1.0, 0.5) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 1 -TargetMaskMode "segment_union" -PriceGuessCsvPath $continuationSeedCsv -OuterStepNormalization "maxabs" -OuterTargetLogStep 0.001),
                (New-HorizonCandidate -MaxK 14 -StageName "hist_k14_activeclusters_norm_i3" -MaxIter 3 -PoliticalUpdateWeight ([double]$bestK6.political_update_weight) -PoliticalUpdateRule "fixed_step_targeted_linesearch" -OuterLineSearchScales @(2.0, 1.0, 0.5) -MaxTargetedPeriods 3 -TargetBlockHalfWidth 1 -TargetMaskMode "active_clusters" -PriceGuessCsvPath $continuationSeedCsv -OuterStepNormalization "maxabs" -OuterTargetLogStep 0.001)
            )

            foreach ($candidate in $k14RecoveryCandidates) {
                if (Test-StageImproved -StageResult $bestK14 -ReferenceVote $referenceK14SmokeVote) {
                    break
                }

                $stageResult = Invoke-Stage-With-Reflow `
                    -StageName $candidate.StageName `
                    -MaxK $candidate.MaxK `
                    -MaxIter $candidate.MaxIter `
                    -PoliticalUpdateWeight $candidate.PoliticalUpdateWeight `
                    -PoliticalUpdateRule $candidate.PoliticalUpdateRule `
                    -OuterLineSearchScales $candidate.OuterLineSearchScales `
                    -OuterLineSearchTol $candidate.OuterLineSearchTol `
                    -MaxTargetedPeriods $candidate.MaxTargetedPeriods `
                    -TargetBlockHalfWidth $candidate.TargetBlockHalfWidth `
                    -TargetMaskMode $candidate.TargetMaskMode `
                    -PriceGuessCsvPath $candidate.PriceGuessCsvPath `
                    -OuterStepNormalization $candidate.OuterStepNormalization `
                    -OuterTargetLogStep $candidate.OuterTargetLogStep
                $k14Attempts.Add($stageResult)
                $bestK14 = Compare-StageResult -Left $bestK14 -Right $stageResult
                if ($stageResult.status -eq "completed") {
                    $continuationSeedCsv = Get-StageFinalPricePathCsv -StageName $stageResult.name
                }
            }
        }

        $k14Targeted = $bestK14
        if (Test-StageImproved -StageResult $bestK14 -ReferenceVote $referenceK14SmokeVote) {
            $classification = "k14_targeted_improved"
            $nextStep = "completed"
        } else {
            $classification = "k14_targeted_not_good_enough"
            $nextStep = "completed"
        }
    } else {
        $classification = "k6_candidate_search_exhausted"
        $nextStep = "completed"
    }

    $payload = [ordered]@{
        workflow = "historical_original_5yr_solver_stabilization"
        run_id = $runId
        demographic_source_mode = "historical_1950"
        reference_k6_smoke_vote = $referenceK6SmokeVote
        reference_k14_smoke_vote = $referenceK14SmokeVote
        classification = $classification
        next_step = $nextStep
        k6_primary = $k6Primary
        k6_followup = $k6Followup
        k6_attempts = $k6Attempts.ToArray()
        best_k6 = $bestK6
        continuation_attempts = $continuationAttempts.ToArray()
        k14_attempts = $k14Attempts.ToArray()
        best_k14 = $bestK14
        k14_targeted = $k14Targeted
        stage_results = (Get-StageResultsSnapshot)
        elapsed_hours = (Get-ElapsedHours)
    }

    $summaryLines = @(
        "# Original 5-year solver stabilization overnight workflow",
        "",
        "- Classification: $classification",
        "- Reference k6 smoke max |vote|: $referenceK6SmokeVote",
        "- Reference k14 smoke max |vote|: $referenceK14SmokeVote",
        "- Best k6 stage: $($bestK6.name)",
        "- Best k6 max |vote|: $($bestK6.max_abs_vote)",
        "- Best k6 iteration: $($bestK6.best_iteration)",
        "- Best k6 mask: $($bestK6.accepted_update_mask)",
        "- Best k6 probe accepted: $($bestK6.probe_accepted)",
        "- Elapsed hours: $([math]::Round((Get-ElapsedHours), 3))"
    )
    if ($null -ne $k14Targeted) {
        $summaryLines += "- k14 targeted max |vote|: $($k14Targeted.max_abs_vote)"
        $summaryLines += "- k14 targeted improved: $($k14Targeted.line_search_improved)"
        $summaryLines += "- k14 targeted probe accepted: $($k14Targeted.probe_accepted)"
        $summaryLines += "- Best k14 stage: $($k14Targeted.name)"
        $summaryLines += "- Best k14 mask mode: $($k14Targeted.target_mask_mode)"
        $summaryLines += "- Best k14 mask: $($k14Targeted.accepted_update_mask)"
    }
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
        workflow = "historical_original_5yr_solver_stabilization"
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
