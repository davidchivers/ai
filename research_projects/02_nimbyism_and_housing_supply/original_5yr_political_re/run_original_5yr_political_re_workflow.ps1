param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "matlab",
    [double]$RbPos = 0.03,
    [double]$VoteTolerance = 1e-4,
    [double]$BracketWidthTolerance = 1e-5
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_political_re_live"
}
$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path (Join-Path $LiveRoot "r") ("oy_" + $runStamp)
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$statusPath = Join-Path $runDir "status.json"
$summaryPath = Join-Path $runDir "summary.md"
$logPath = Join-Path $runDir "workflow_log.txt"
$activePath = Join-Path $LiveRoot "active_run.txt"
$globalStatusPath = Join-Path $LiveRoot "latest_status.json"

Set-Content -Path $activePath -Value $runDir

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

function To-Bool {
    param($Value)
    $text = "$Value".Trim().ToLowerInvariant()
    return ($text -eq "true" -or $text -eq "1")
}

function Get-SweepAnalysis {
    param(
        [string]$SummaryCsv,
        [string]$DetailCsv,
        [string]$Name,
        [double]$PriceStart,
        [double]$PriceEnd,
        [double]$Rb
    )

    $summary = Import-Csv -Path $SummaryCsv | Select-Object -First 1
    $rows = Import-Csv -Path $DetailCsv
    $votes = @($rows | ForEach-Object { [double]$_.totalvote })
    $prices = @($rows | ForEach-Object { [double]$_.price })
    $minVote = ($votes | Measure-Object -Minimum).Minimum
    $maxVote = ($votes | Measure-Object -Maximum).Maximum
    $minAbsVote = ($votes | ForEach-Object { [Math]::Abs($_) } | Measure-Object -Minimum).Minimum
    $bestRow = $rows | Sort-Object { [Math]::Abs([double]$_.totalvote) } | Select-Object -First 1

    $signPattern = if ($maxVote -lt 0.0) {
        "all_negative"
    } elseif ($minVote -gt 0.0) {
        "all_positive"
    } elseif (To-Bool $summary.has_vote_bracket) {
        "bracket"
    } else {
        "mixed_no_adjacent_bracket"
    }

    return [pscustomobject]@{
        name = $Name
        rb_pos = $Rb
        price_start = $PriceStart
        price_end = $PriceEnd
        has_vote_bracket = To-Bool $summary.has_vote_bracket
        bracket_low_price = $summary.bracket_low_price
        bracket_high_price = $summary.bracket_high_price
        bracket_low_vote = $summary.bracket_low_vote
        bracket_high_vote = $summary.bracket_high_vote
        best_distance = $summary.best_distance
        best_distance_price = $summary.best_distance_price
        best_vote_abs = $summary.best_vote_abs
        best_vote_abs_price = $summary.best_vote_abs_price
        min_vote = $minVote
        max_vote = $maxVote
        min_abs_vote = $minAbsVote
        sign_pattern = $signPattern
        best_vote = [double]$bestRow.totalvote
        summary_csv = $SummaryCsv
        detail_csv = $DetailCsv
    }
}

function Invoke-Sweep {
    param(
        [string]$Name,
        [double]$PriceStart,
        [double]$PriceEnd,
        [int]$NumPoints,
        [double]$Rb
    )

    $outputDir = Join-Path $runDir $Name
    Write-Status -CurrentStep $Name -State "running" -Payload @{
        note = "Running steady-state vote sweep."
        output_dir = $outputDir
        price_start = $PriceStart
        price_end = $PriceEnd
        num_points = $NumPoints
        rb_pos = $Rb
    }
    Write-Log "Running sweep $Name on [$PriceStart, $PriceEnd] with $NumPoints points and rb=$Rb."

    & (Join-Path $scriptDir "run_original_5yr_steady_state_vote_sweep.ps1") `
        -MatlabExe $MatlabExe `
        -RbPos $Rb `
        -PriceStart $PriceStart `
        -PriceEnd $PriceEnd `
        -NumPoints $NumPoints `
        -OutputDir $outputDir

    $analysis = Get-SweepAnalysis `
        -SummaryCsv (Join-Path $outputDir "steady_state_vote_sweep_summary.csv") `
        -DetailCsv (Join-Path $outputDir "steady_state_vote_sweep.csv") `
        -Name $Name `
        -PriceStart $PriceStart `
        -PriceEnd $PriceEnd `
        -Rb $Rb

    Write-Log ("Sweep {0} complete. best|vote|={1} at p={2}; sign pattern={3}; bracket={4}" -f `
        $Name, $analysis.best_vote_abs, $analysis.best_vote_abs_price, $analysis.sign_pattern, $analysis.has_vote_bracket)

    return $analysis
}

function Select-BestRun {
    param([object[]]$Runs)
    $usable = @($Runs | Where-Object { $_ -ne $null })
    if ($usable.Count -eq 0) {
        return $null
    }
    return $usable | Sort-Object { [double]$_.best_vote_abs } | Select-Object -First 1
}

$results = [ordered]@{
    coarse = $null
    lower_expand = $null
    upper_expand = $null
    broad_full = $null
    rb_sensitivity = @()
    refined = $null
    dense = $null
    local_refinements = @()
}

try {
    Write-Log "Starting original 5-year political RE workflow."

    $results.coarse = Invoke-Sweep -Name "coarse_ss" -PriceStart 1.8 -PriceEnd 2.2 -NumPoints 30 -Rb $RbPos
    $targetSweep = $null

    if ($results.coarse.has_vote_bracket) {
        $targetSweep = $results.coarse
        Write-Log "Coarse sweep found a bracket."
    } else {
        if ($results.coarse.sign_pattern -eq "all_negative") {
            $results.lower_expand = Invoke-Sweep -Name "lower_expand_ss" -PriceStart 0.2 -PriceEnd 1.8 -NumPoints 49 -Rb $RbPos
            if ($results.lower_expand.has_vote_bracket) {
                $targetSweep = $results.lower_expand
                Write-Log "Lower-price expansion found a bracket."
            }
        } elseif ($results.coarse.sign_pattern -eq "all_positive") {
            $results.upper_expand = Invoke-Sweep -Name "upper_expand_ss" -PriceStart 2.2 -PriceEnd 3.8 -NumPoints 49 -Rb $RbPos
            if ($results.upper_expand.has_vote_bracket) {
                $targetSweep = $results.upper_expand
                Write-Log "Upper-price expansion found a bracket."
            }
        }

        if (-not $targetSweep) {
            $results.broad_full = Invoke-Sweep -Name "broad_full_ss" -PriceStart 0.2 -PriceEnd 3.8 -NumPoints 81 -Rb $RbPos
            if ($results.broad_full.has_vote_bracket) {
                $targetSweep = $results.broad_full
                Write-Log "Broad sweep found a bracket."
            }
        }

        if (-not $targetSweep) {
            foreach ($rb in @(0.01, 0.02, 0.03, 0.04, 0.05)) {
                if ([Math]::Abs($rb - $RbPos) -lt 1e-12) {
                    continue
                }
                $name = "rb_" + ($rb.ToString("0.00").Replace(".", "p")) + "_broad"
                $rbRun = Invoke-Sweep -Name $name -PriceStart 0.2 -PriceEnd 3.8 -NumPoints 81 -Rb $rb
                $results.rb_sensitivity += $rbRun
                if ($rbRun.has_vote_bracket) {
                    $targetSweep = $rbRun
                    Write-Log "RB sensitivity sweep at rb=$rb found a bracket."
                    break
                }
            }
        }
    }

    if ($targetSweep) {
        $localStages = @(
            @{ name = "refined_ss"; points = 41 },
            @{ name = "dense_ss"; points = 81 },
            @{ name = "micro_ss"; points = 81 },
            @{ name = "ultra_ss"; points = 81 }
        )
        $currentBracket = $targetSweep

        foreach ($stage in $localStages) {
            if (-not $currentBracket.has_vote_bracket) {
                break
            }

            $stageRun = Invoke-Sweep `
                -Name $stage.name `
                -PriceStart ([double]$currentBracket.bracket_low_price) `
                -PriceEnd ([double]$currentBracket.bracket_high_price) `
                -NumPoints ([int]$stage.points) `
                -Rb ([double]$currentBracket.rb_pos)

            $results.local_refinements += $stageRun
            if (-not $results.refined) {
                $results.refined = $stageRun
            } elseif (-not $results.dense) {
                $results.dense = $stageRun
            }

            $stageWidth = [double]$stageRun.bracket_high_price - [double]$stageRun.bracket_low_price
            if ($stageRun.has_vote_bracket -and `
                ([Math]::Abs([double]$stageRun.best_vote_abs) -le $VoteTolerance -or `
                 $stageWidth -le $BracketWidthTolerance)) {
                Write-Log ("Stopping local refinement after {0}: width={1}, best|vote|={2}" -f `
                    $stage.name, $stageWidth, $stageRun.best_vote_abs)
                break
            }

            $currentBracket = $stageRun
        }
    }

    $allRuns = @(
        $results.coarse,
        $results.lower_expand,
        $results.upper_expand,
        $results.broad_full
    ) + @($results.rb_sensitivity) + @($results.local_refinements)

    $bestRun = Select-BestRun -Runs $allRuns
    $classification = if ($targetSweep) { "bracket_found" } else { "no_bracket_on_tested_domain" }

    $handoff = [ordered]@{
        classification = $classification
        rb_pos = if ($bestRun) { $bestRun.rb_pos } else { $RbPos }
        recommended_target_price = if ($bestRun) { $bestRun.best_vote_abs_price } else { $null }
        best_vote_abs = if ($bestRun) { $bestRun.best_vote_abs } else { $null }
        best_run_name = if ($bestRun) { $bestRun.name } else { $null }
        target_sweep = $targetSweep
        coarse = $results.coarse
        lower_expand = $results.lower_expand
        upper_expand = $results.upper_expand
        broad_full = $results.broad_full
        rb_sensitivity = $results.rb_sensitivity
        refined = $results.refined
        dense = $results.dense
        local_refinements = $results.local_refinements
        workflow_run_dir = $runDir
    }
    ($handoff | ConvertTo-Json -Depth 8) | Set-Content -Path (Join-Path $runDir "c_port_handoff.json")
    Write-Log "Wrote C-port handoff."

    $lines = @(
        "# Original 5-Year Political RE Workflow",
        "",
        "- Run: $runStamp",
        "- Classification: $classification"
    )
    foreach ($run in $allRuns | Where-Object { $_ -ne $null }) {
        $lines += "- $($run.name): best |vote| = $($run.best_vote_abs) at p = $($run.best_vote_abs_price); sign pattern = $($run.sign_pattern); bracket = $($run.has_vote_bracket)"
    }
    if ($bestRun) {
        $lines += "- Recommended target price: $($bestRun.best_vote_abs_price) from $($bestRun.name)"
    }
    if ($targetSweep) {
        $lines += "- Bracket source: $($targetSweep.name) with rb = $($targetSweep.rb_pos)"
    } else {
        $lines += "- No bracket found on tested price/rb domains."
    }
    $lines += "- C handoff: c_port_handoff.json"
    Set-Content -Path $summaryPath -Value ($lines -join [Environment]::NewLine)

    Write-Status -CurrentStep "complete" -State "completed" -Payload @{
        summary_path = $summaryPath
        classification = $classification
        recommended_target_price = if ($bestRun) { $bestRun.best_vote_abs_price } else { $null }
        best_vote_abs = if ($bestRun) { $bestRun.best_vote_abs } else { $null }
        best_run_name = if ($bestRun) { $bestRun.name } else { $null }
        coarse = $results.coarse
        lower_expand = $results.lower_expand
        upper_expand = $results.upper_expand
        broad_full = $results.broad_full
        rb_sensitivity = $results.rb_sensitivity
        refined = $results.refined
        dense = $results.dense
        local_refinements = $results.local_refinements
    }
    Write-Log "Workflow completed successfully."
}
catch {
    Write-Log ("Workflow failed: " + $_.Exception.Message)
    Write-Status -CurrentStep "failed" -State "failed" -Payload @{
        error = $_.Exception.Message
        summary_path = $summaryPath
    }
    throw
}
