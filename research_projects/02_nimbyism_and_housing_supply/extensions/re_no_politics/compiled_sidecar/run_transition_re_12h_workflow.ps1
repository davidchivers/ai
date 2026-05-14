param(
    [double]$DurationHours = 12.0,
    [string]$WorkflowName = 'away_12h_workflow',
    [string]$OutputDir = '',
    [int]$MaxTasks = 0,
    [switch]$SkipBuild,
    [switch]$RefreshBasePack
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'tools\portable_toolchain.ps1')

$null = Set-NimbySidecarPortableToolchain

if (-not $OutputDir) {
    $OutputDir = Join-Path $scriptDir ("truth\{0}" -f $WorkflowName)
}

$logPath = Join-Path $OutputDir 'workflow_log.txt'
$summaryPath = Join-Path $OutputDir 'workflow_summary.md'
$manifestPath = Join-Path $OutputDir 'workflow_manifest.csv'

$anchorPathCsv = Join-Path $scriptDir 'truth\fixed_price_anchor_full_path.csv'
$basePackName = 'transition_re_frontier_base_k9_anchor_input_only'
$basePackDir = Join-Path $scriptDir ("truth\{0}" -f $basePackName)
$anchorSource = 'transition_re_k_step_policy_bridge_steady_state_fixed_price_2_0_results.final_price_path'

$coarseAlphaGrid = '0.18,0.180009765625,0.180078125,0.180625,0.18125,0.1825,0.185,0.19,0.2'
$refinedAlphaGrid = '0.18,0.180009765625,0.18001953125,0.1800390625,0.180078125,0.18015625,0.1803125,0.180625,0.18125'

$reserveMinutes = 15.0
$sessionStart = Get-Date
$deadline = $sessionStart.AddHours($DurationHours)

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

function Write-Log([string]$Message) {
    $line = ('[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message)
    Add-Content -LiteralPath $script:logPath -Value $line
    Write-Host $line
}

function Get-RemainingMinutes {
    return [math]::Max(0.0, ($script:deadline - (Get-Date)).TotalMinutes)
}

function Invoke-WorkflowCommand {
    param(
        [string]$Label,
        [scriptblock]$Command
    )

    Write-Log ("Running: {0}" -f $Label)
    $output = & $Command 2>&1
    foreach ($line in @($output)) {
        if ($null -ne $line -and [string]$line -ne '') {
            Write-Log ([string]$line)
        }
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Label"
    }
}

function Write-Manifest($Rows) {
    $Rows | Export-Csv -LiteralPath $script:manifestPath -NoTypeInformation
}

function Add-ManifestRow {
    param(
        [System.Collections.Generic.List[object]]$Rows,
        [string]$Task,
        [double]$EstimateMinutes,
        [string]$Cost,
        [string]$Status,
        [double]$ElapsedMinutes,
        [string]$Note
    )

    $Rows.Add([pscustomobject]@{
        task = $Task
        estimate_minutes = $EstimateMinutes
        cost = $Cost
        status = $Status
        elapsed_minutes = [math]::Round($ElapsedMinutes, 2)
        note = $Note
    }) | Out-Null
}

function Get-FrontierRows([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }
    return Import-Csv -LiteralPath $Path
}

function Get-RetrySummary([string]$Dir) {
    $statusPath = Join-Path $Dir 'sidecar_retryaware_status.txt'
    $summaryPath = Join-Path $Dir 'sidecar_retryaware_summary.csv'
    if (-not (Test-Path -LiteralPath $statusPath) -or -not (Test-Path -LiteralPath $summaryPath)) {
        return $null
    }
    $summaryRows = Import-Csv -LiteralPath $summaryPath
    $map = @{}
    foreach ($row in $summaryRows) {
        $map[$row.name] = $row.value
    }
    return [pscustomobject]@{
        status = (Get-Content -LiteralPath $statusPath | Select-Object -First 1).Trim()
        attempt_count = $map['attempt_count']
        selected_attempt = $map['selected_attempt']
        looks_stable = $map['looks_stable']
        final_max_abs_gap = $map['final_max_abs_gap']
        final_residual_norm = $map['final_residual_norm']
    }
}

function Write-WorkflowSummary {
    param(
        [System.Collections.Generic.List[object]]$ManifestRows,
        [string[]]$Blocked
    )

    $endTime = Get-Date
    $usedHours = [math]::Round(($endTime - $script:sessionStart).TotalHours, 2)
    $completedCount = @($ManifestRows | Where-Object { $_.status -eq 'completed' }).Count
    $skippedCount = @($ManifestRows | Where-Object { $_.status -like 'skipped*' }).Count
    $failedCount = @($ManifestRows | Where-Object { $_.status -eq 'failed' }).Count

    $coarseRows = Get-FrontierRows (Join-Path $script:OutputDir 'frontier_coarse_k9\sidecar_frontier.csv')
    $refinedRows = Get-FrontierRows (Join-Path $script:OutputDir 'frontier_refine_k9_edge\sidecar_frontier.csv')

    $retryDirs = @(
        @{ label = 'k4 stable 50+50'; path = (Join-Path $script:OutputDir 'retry_k4_stable_50') },
        @{ label = 'k4 unstable 50+50'; path = (Join-Path $script:OutputDir 'retry_k4_unstable_50') },
        @{ label = 'k5 stable 50+50'; path = (Join-Path $script:OutputDir 'retry_k5_stable_50') },
        @{ label = 'k5 unstable 50+50'; path = (Join-Path $script:OutputDir 'retry_k5_unstable_50') }
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# NIMBY compiled sidecar 12-hour workflow')
    $lines.Add('')
    $lines.Add('- Project: `extensions/re_no_politics/compiled_sidecar`')
    $lines.Add(('- Planned duration: `{0}` hours' -f $DurationHours))
    $lines.Add(('- Actual runtime so far: `{0}` hours' -f $usedHours))
    $lines.Add(('- Session start: `{0}`' -f $script:sessionStart.ToString('yyyy-MM-dd HH:mm:ss')))
    $lines.Add(('- Session end: `{0}`' -f $endTime.ToString('yyyy-MM-dd HH:mm:ss')))
    $lines.Add('')
    $lines.Add('## Task results')
    $lines.Add('')
    $lines.Add('| task | estimate min | cost | status | elapsed min | note |')
    $lines.Add('|---|---:|---|---|---:|---|')
    foreach ($row in $ManifestRows) {
        $lines.Add(('| {0} | {1} | {2} | {3} | {4} | {5} |' -f `
            $row.task, $row.estimate_minutes, $row.cost, $row.status, $row.elapsed_minutes, $row.note))
    }
    $lines.Add('')
    $lines.Add('## Frontier outputs')
    $lines.Add('')

    if (@($coarseRows).Count -gt 0) {
        $lines.Add('### Coarse k-to-9 frontier')
        $lines.Add('')
        $lines.Add('| k | max stable alpha | first unstable alpha | status |')
        $lines.Add('|---:|---:|---:|---|')
        foreach ($row in $coarseRows) {
            $lines.Add(('| {0} | {1} | {2} | {3} |' -f $row.k, $row.max_stable_alpha, $row.first_unstable_alpha, $row.frontier_status))
        }
        $lines.Add('')
    }

    if (@($refinedRows).Count -gt 0) {
        $lines.Add('### Refined edge frontier')
        $lines.Add('')
        $lines.Add('| k | max stable alpha | first unstable alpha | status |')
        $lines.Add('|---:|---:|---:|---|')
        foreach ($row in $refinedRows) {
            $lines.Add(('| {0} | {1} | {2} | {3} |' -f $row.k, $row.max_stable_alpha, $row.first_unstable_alpha, $row.frontier_status))
        }
        $lines.Add('')
    }

    $lines.Add('## Retry-aware robustness checks')
    $lines.Add('')
    $lines.Add('| case | status | selected attempt | max gap | residual norm |')
    $lines.Add('|---|---|---:|---:|---:|')
    foreach ($entry in $retryDirs) {
        $summary = Get-RetrySummary $entry.path
        if ($null -eq $summary) {
            $lines.Add(('| {0} | missing |  |  |  |' -f $entry.label))
        } else {
            $lines.Add(('| {0} | {1} | {2} | {3} | {4} |' -f `
                $entry.label, $summary.status, $summary.selected_attempt, $summary.final_max_abs_gap, $summary.final_residual_norm))
        }
    }
    $lines.Add('')
    $lines.Add('## Blocked')
    $lines.Add('')
    if ($Blocked.Count -eq 0) {
        $lines.Add('- None')
    } else {
        foreach ($item in $Blocked) {
            $lines.Add(('- ' + $item))
        }
    }
    $lines.Add('')
    $lines.Add('## Next 3 tasks')
    $lines.Add('')
    $lines.Add('1. Compare the coarse and refined compiled frontier envelopes and decide whether `0.18` remains the practical full-horizon continuation point.')
    $lines.Add('2. If the refined frontier still leaves a narrow unresolved bracket, export targeted MATLAB reference packets only for those surviving edge cases.')
    $lines.Add('3. Promote the compiled away workflow from sidecar utility to the canonical long-run NIMBY frontier driver once the longer-horizon parity packet is closed.')
    $lines.Add('')
    $lines.Add(('- Session summary: `~{0}h` of `{1}h` used, `{2}` completed, `{3}` skipped, `{4}` failed.' -f `
        $usedHours, $DurationHours, $completedCount, $skippedCount, $failedCount))

    [System.IO.File]::WriteAllLines($script:summaryPath, $lines)
}

if (-not (Test-Path -LiteralPath $anchorPathCsv)) {
    throw "Missing full-horizon anchor path: $anchorPathCsv"
}

if (-not $SkipBuild) {
    Write-Log 'Building compiled sidecar before the away workflow.'
    & (Join-Path $scriptDir 'build.ps1')
}

$manifestRows = New-Object System.Collections.Generic.List[object]
$blocked = New-Object System.Collections.Generic.List[string]
$completedTasks = 0

$tasks = @(
    [pscustomobject]@{
        Name = 'export_frontier_base_k9'
        EstimateMinutes = 25.0
        Cost = 'light'
        Run = {
            if ((Test-Path -LiteralPath $basePackDir) -and -not $RefreshBasePack) {
                Write-Log "Base pack already exists: $basePackDir"
                return 'base pack already present'
            }
            Invoke-WorkflowCommand -Label 'export_transition_re_input_only.ps1' -Command {
                & (Join-Path $scriptDir 'export_transition_re_input_only.ps1') `
                    -PackName $basePackName `
                    -Horizon 9 `
                    -TransitionPolicyMode 'steady_state_by_period_price' `
                    -PolicyReferencePrice 2.0 `
                    -TerminalReferenceMode 'fixed_price' `
                    -TerminalReferencePrice 2.0 `
                    -PolicyReferenceMode 'blended_current_and_fixed_price' `
                    -PolicyReferenceBlendWeight 0.20 `
                    -SolverProfile 'frontier_fertility_style' `
                    -InitialPricePathCsv $anchorPathCsv
            }
            return 'exported full-horizon frontier base pack'
        }
    },
    [pscustomobject]@{
        Name = 'frontier_coarse_k9'
        EstimateMinutes = 240.0
        Cost = 'light'
        Run = {
            $taskOutput = Join-Path $OutputDir 'frontier_coarse_k9'
            Invoke-WorkflowCommand -Label 'run_transition_re_frontier_cli.ps1 (coarse)' -Command {
                & (Join-Path $scriptDir 'run_transition_re_frontier_cli.ps1') `
                    -PackName $basePackName `
                    -OutputDir $taskOutput `
                    -MaxK 9 `
                    -AlphaGrid $coarseAlphaGrid `
                    -AnchorPathCsv $anchorPathCsv `
                    -AnchorSource $anchorSource `
                    -Resume `
                    -SkipBuild
            }
            return "wrote coarse frontier output to $taskOutput"
        }
    },
    [pscustomobject]@{
        Name = 'frontier_refine_k9_edge'
        EstimateMinutes = 240.0
        Cost = 'light'
        Run = {
            $taskOutput = Join-Path $OutputDir 'frontier_refine_k9_edge'
            Invoke-WorkflowCommand -Label 'run_transition_re_frontier_cli.ps1 (refined)' -Command {
                & (Join-Path $scriptDir 'run_transition_re_frontier_cli.ps1') `
                    -PackName $basePackName `
                    -OutputDir $taskOutput `
                    -MaxK 9 `
                    -AlphaGrid $refinedAlphaGrid `
                    -AnchorPathCsv $anchorPathCsv `
                    -AnchorSource $anchorSource `
                    -Resume `
                    -SkipBuild
            }
            return "wrote refined frontier output to $taskOutput"
        }
    },
    [pscustomobject]@{
        Name = 'retry_k4_stable_50'
        EstimateMinutes = 45.0
        Cost = 'light'
        Run = {
            $taskOutput = Join-Path $OutputDir 'retry_k4_stable_50'
            Invoke-WorkflowCommand -Label 'run_transition_re_retryaware.ps1 (k4 stable 50)' -Command {
                & (Join-Path $scriptDir 'run_transition_re_retryaware.ps1') `
                    -PackName 'transition_re_k4_frontier_alpha_0_190899658203125_input_only' `
                    -OutputDir $taskOutput `
                    -PerAttemptMaxIter 50 `
                    -SkipBuild
            }
            return "wrote retry-aware output to $taskOutput"
        }
    },
    [pscustomobject]@{
        Name = 'retry_k4_unstable_50'
        EstimateMinutes = 45.0
        Cost = 'light'
        Run = {
            $taskOutput = Join-Path $OutputDir 'retry_k4_unstable_50'
            Invoke-WorkflowCommand -Label 'run_transition_re_retryaware.ps1 (k4 unstable 50)' -Command {
                & (Join-Path $scriptDir 'run_transition_re_retryaware.ps1') `
                    -PackName 'transition_re_k4_frontier_alpha_0_19090576171875_input_only' `
                    -OutputDir $taskOutput `
                    -PerAttemptMaxIter 50 `
                    -SkipBuild
            }
            return "wrote retry-aware output to $taskOutput"
        }
    },
    [pscustomobject]@{
        Name = 'retry_k5_stable_50'
        EstimateMinutes = 45.0
        Cost = 'light'
        Run = {
            $taskOutput = Join-Path $OutputDir 'retry_k5_stable_50'
            Invoke-WorkflowCommand -Label 'run_transition_re_retryaware.ps1 (k5 stable 50)' -Command {
                & (Join-Path $scriptDir 'run_transition_re_retryaware.ps1') `
                    -PackName 'transition_re_k5_frontier_alpha_0_185_input_only' `
                    -OutputDir $taskOutput `
                    -PerAttemptMaxIter 50 `
                    -SkipBuild
            }
            return "wrote retry-aware output to $taskOutput"
        }
    },
    [pscustomobject]@{
        Name = 'retry_k5_unstable_50'
        EstimateMinutes = 45.0
        Cost = 'light'
        Run = {
            $taskOutput = Join-Path $OutputDir 'retry_k5_unstable_50'
            Invoke-WorkflowCommand -Label 'run_transition_re_retryaware.ps1 (k5 unstable 50)' -Command {
                & (Join-Path $scriptDir 'run_transition_re_retryaware.ps1') `
                    -PackName 'transition_re_k5_frontier_alpha_0_185625_input_only' `
                    -OutputDir $taskOutput `
                    -PerAttemptMaxIter 50 `
                    -SkipBuild
            }
            return "wrote retry-aware output to $taskOutput"
        }
    }
)

Write-Log ('Starting 12-hour away workflow in {0}' -f $OutputDir)
Write-Log ('Deadline: {0}' -f $deadline.ToString('yyyy-MM-dd HH:mm:ss'))

foreach ($task in $tasks) {
    if ($MaxTasks -gt 0 -and $completedTasks -ge $MaxTasks) {
        Add-ManifestRow -Rows $manifestRows -Task $task.Name -EstimateMinutes $task.EstimateMinutes -Cost $task.Cost -Status 'skipped_max_tasks' -ElapsedMinutes 0.0 -Note 'Stopped by MaxTasks guard.'
        continue
    }

    $remainingMinutes = Get-RemainingMinutes
    if ($remainingMinutes -lt ($task.EstimateMinutes + $reserveMinutes)) {
        $note = ('Skipped: only ~{0} minutes left, needs ~{1} minutes plus reserve.' -f `
            [math]::Round($remainingMinutes, 1), $task.EstimateMinutes)
        Write-Log ("$($task.Name): $note")
        Add-ManifestRow -Rows $manifestRows -Task $task.Name -EstimateMinutes $task.EstimateMinutes -Cost $task.Cost -Status 'skipped_time_guard' -ElapsedMinutes 0.0 -Note $note
        continue
    }

    $taskStart = Get-Date
    try {
        Write-Log ("Starting task: $($task.Name)")
        $note = & $task.Run
        $elapsedMinutes = ((Get-Date) - $taskStart).TotalMinutes
        Add-ManifestRow -Rows $manifestRows -Task $task.Name -EstimateMinutes $task.EstimateMinutes -Cost $task.Cost -Status 'completed' -ElapsedMinutes $elapsedMinutes -Note $note
        Write-Log ("Completed task: $($task.Name) in {0:N2} minutes" -f $elapsedMinutes)
        $completedTasks += 1
    } catch {
        $elapsedMinutes = ((Get-Date) - $taskStart).TotalMinutes
        $note = $_.Exception.Message
        Add-ManifestRow -Rows $manifestRows -Task $task.Name -EstimateMinutes $task.EstimateMinutes -Cost $task.Cost -Status 'failed' -ElapsedMinutes $elapsedMinutes -Note $note
        $blocked.Add("$($task.Name): $note") | Out-Null
        Write-Log ("Task failed: $($task.Name) -- $note")
        if ($task.Name -eq 'export_frontier_base_k9') {
            break
        }
    }

    Write-Manifest $manifestRows
}

Write-WorkflowSummary -ManifestRows $manifestRows -Blocked $blocked
Write-Manifest $manifestRows
Write-Log 'Away workflow complete.'
