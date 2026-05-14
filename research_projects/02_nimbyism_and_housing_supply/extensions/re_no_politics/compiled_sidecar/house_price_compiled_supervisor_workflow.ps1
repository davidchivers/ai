param(
    [string]$RunLabel = 'house_price_compiled_supervisor',
    [string]$SessionName = 'house_price_compiled_supervisor_live',
    [string]$SteadyStatePackName = 'steady_state_p2_rb0_03',
    [double]$PriceMin = 1.8,
    [double]$PriceMax = 2.2,
    [int]$PriceCount = 30,
    [string]$TransitionPassPackName = 'transition_pass_t4_diag',
    [string]$TransitionRePackName = 'transition_re_t4_fixed_terminal',
    [switch]$SkipBuild,
    [switch]$SkipTransitionPass,
    [switch]$SkipTransitionRe
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthDir = Join-Path $scriptDir 'truth'
$sessionDir = Join-Path $truthDir $SessionName
$runsDir = Join-Path $sessionDir 'r'
$runStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$runDir = Join-Path $runsDir ("hp_{0}" -f $runStamp)
$statusPath = Join-Path $runDir 'status.txt'
$manifestPath = Join-Path $runDir 'manifest.csv'
$summaryPath = Join-Path $runDir 'summary.md'
$activePointer = Join-Path $sessionDir 'active_run.txt'
$latestPointer = Join-Path $sessionDir 'latest_run.txt'
$steadyStateSweepDir = Join-Path $runDir 'ss'
$workflowStart = Get-Date

New-Item -ItemType Directory -Path $runDir -Force | Out-Null

function Write-Status {
    param([string]$Message)

    $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $statusPath -Value $line
    Set-Content -LiteralPath $latestPointer -Value $runDir
}

function Set-ActivePointer {
    param(
        [string]$Phase,
        [string]$Note = ''
    )

    @(
        'started_at={0}' -f $workflowStart.ToString('yyyy-MM-dd HH:mm:ss')
        'phase={0}' -f $Phase
        'run_dir={0}' -f $runDir
        'status_path={0}' -f $statusPath
        'manifest_path={0}' -f $manifestPath
        'summary_path={0}' -f $summaryPath
        'note={0}' -f $Note
    ) | Set-Content -LiteralPath $activePointer
}

function Invoke-WorkflowCommand {
    param(
        [string]$Label,
        [scriptblock]$Command
    )

    Write-Status ("RUN {0}" -f $Label)
    $output = & $Command 2>&1
    foreach ($line in @($output)) {
        if ($null -ne $line -and [string]$line -ne '') {
            Write-Status ([string]$line)
        }
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Label"
    }
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

function Get-NamedCsvMap {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $map = @{}
    foreach ($row in Import-Csv -LiteralPath $Path) {
        $map[[string]$row.name] = [string]$row.value
    }
    return $map
}

function Invoke-SupervisedTask {
    param(
        [System.Collections.Generic.List[object]]$Rows,
        [System.Collections.Generic.List[string]]$Blocked,
        [string]$Task,
        [double]$EstimateMinutes,
        [string]$Cost,
        [scriptblock]$Command
    )

    $started = Get-Date
    Set-ActivePointer -Phase $Task
    try {
        $note = & $Command
        $elapsed = ((Get-Date) - $started).TotalMinutes
        Add-ManifestRow -Rows $Rows -Task $Task -EstimateMinutes $EstimateMinutes -Cost $Cost -Status 'completed' -ElapsedMinutes $elapsed -Note ([string]$note)
        Write-Status ("DONE {0}" -f $Task)
    } catch {
        $elapsed = ((Get-Date) - $started).TotalMinutes
        $message = $_.Exception.Message
        $Blocked.Add($message) | Out-Null
        Add-ManifestRow -Rows $Rows -Task $Task -EstimateMinutes $EstimateMinutes -Cost $Cost -Status 'failed' -ElapsedMinutes $elapsed -Note $message
        Write-Status ("FAILED {0}: {1}" -f $Task, $message)
        throw
    }
}

function Write-WorkflowSummary {
    param(
        [System.Collections.Generic.List[object]]$ManifestRows,
        [System.Collections.Generic.List[string]]$Blocked
    )

    $endTime = Get-Date
    $usedHours = [math]::Round(($endTime - $workflowStart).TotalHours, 2)
    $completedCount = @($ManifestRows | Where-Object { $_.status -eq 'completed' }).Count
    $failedCount = @($ManifestRows | Where-Object { $_.status -eq 'failed' }).Count

    $steadyStateSummary = Get-NamedCsvMap -Path (Join-Path $scriptDir ("truth\{0}\sidecar_summary.csv" -f $SteadyStatePackName))
    $sweepBestSummary = Get-NamedCsvMap -Path (Join-Path $steadyStateSweepDir 'sidecar_best_summary.csv')
    $transitionPassSummary = if (-not $SkipTransitionPass) {
        Get-NamedCsvMap -Path (Join-Path $scriptDir ("truth\{0}\sidecar_summary.csv" -f $TransitionPassPackName))
    } else {
        $null
    }
    $transitionReSummary = if (-not $SkipTransitionRe) {
        Get-NamedCsvMap -Path (Join-Path $scriptDir ("truth\{0}\sidecar_summary.csv" -f $TransitionRePackName))
    } else {
        $null
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# House-price compiled supervisor')
    $lines.Add('')
    $lines.Add('- Project: `extensions/re_no_politics/compiled_sidecar`')
    $lines.Add(('- Session name: `{0}`' -f $SessionName))
    $lines.Add(('- Run directory: `{0}`' -f $runDir))
    $lines.Add(('- Session start: `{0}`' -f $workflowStart.ToString('yyyy-MM-dd HH:mm:ss')))
    $lines.Add(('- Session end: `{0}`' -f $endTime.ToString('yyyy-MM-dd HH:mm:ss')))
    $lines.Add(('- Runtime: `~{0}` hours' -f $usedHours))
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
    $lines.Add('## Key outputs')
    $lines.Add('')
    if ($steadyStateSummary) {
        $lines.Add(('- Steady state summary: `Hdemand = {0}`, `Hsupply = {1}`, `debtstock = {2}`' -f `
            $steadyStateSummary['Hdemand'], $steadyStateSummary['Hsupply'], $steadyStateSummary['debtstock']))
    }
    if ($sweepBestSummary) {
        $lines.Add(('- Sweep best price: `p = {0}` with distance `{1}`' -f `
            $sweepBestSummary['best_price'], $sweepBestSummary['best_distance']))
    }
    if ($transitionPassSummary) {
        $lines.Add(('- Transition-pass summary: `max_abs_gap = {0}`, `residual_norm = {1}`' -f `
            $transitionPassSummary['max_abs_gap'], $transitionPassSummary['residual_norm']))
    }
    if ($transitionReSummary) {
        $lines.Add(('- Transition-RE summary: `final_max_abs_gap = {0}`, `final_residual_norm = {1}`' -f `
            $transitionReSummary['final_max_abs_gap'], $transitionReSummary['final_residual_norm']))
    }
    $lines.Add(('- Sweep outputs: `{0}`' -f $steadyStateSweepDir))
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
    $lines.Add('1. Remove the MATLAB terminal-tail dependency from `export_transition_pass_input_pack.m` so `full_backward` runtime packs can rely on compiled steady-state references only.')
    $lines.Add('2. Add a lean runtime mode to `export_transition_re_input_pack.m` that skips MATLAB steady-state Bellman generation while preserving validation mode.')
    $lines.Add('3. Revalidate the bounded transition-RE pack after that exporter split, then promote the lean runtime pack to the default house-price workflow.')
    $lines.Add('')
    $lines.Add(('- Session summary: `{0}` completed, `{1}` failed.' -f $completedCount, $failedCount))

    [System.IO.File]::WriteAllLines($summaryPath, $lines)
}

Set-Content -LiteralPath $latestPointer -Value $runDir
Set-Content -LiteralPath $statusPath -Value ''
$manifestRows = New-Object System.Collections.Generic.List[object]
$blocked = New-Object System.Collections.Generic.List[string]
$runFailed = $false

try {
    Set-ActivePointer -Phase 'starting'

    if (-not $SkipBuild) {
        Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'build_sidecar' -EstimateMinutes 5.0 -Cost 'light' -Command {
            Invoke-WorkflowCommand -Label 'build.ps1' -Command {
                & (Join-Path $scriptDir 'build.ps1')
            }
            return 'rebuilt compiled sidecar executables'
        }
    }

    Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'steady_state_cli' -EstimateMinutes 3.0 -Cost 'light' -Command {
        Invoke-WorkflowCommand -Label 'run_steady_state_cli.ps1' -Command {
            & (Join-Path $scriptDir 'run_steady_state_cli.ps1') `
                -PackName $SteadyStatePackName `
                -SkipBuild
        }
        return ('refreshed steady-state sidecar outputs in truth\{0}' -f $SteadyStatePackName)
    }

    Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'steady_state_validate' -EstimateMinutes 1.0 -Cost 'light' -Command {
        Invoke-WorkflowCommand -Label 'validate_steady_state.ps1' -Command {
            & (Join-Path $scriptDir 'validate_steady_state.ps1') -PackName $SteadyStatePackName
        }
        return 'steady-state validation passed'
    }

    Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'steady_state_sweep' -EstimateMinutes 5.0 -Cost 'light' -Command {
        Invoke-WorkflowCommand -Label 'run_steady_state_sweep_cli.ps1' -Command {
            & (Join-Path $scriptDir 'run_steady_state_sweep_cli.ps1') `
                -PackName $SteadyStatePackName `
                -PriceMin $PriceMin `
                -PriceMax $PriceMax `
                -PriceCount $PriceCount `
                -OutputDir $steadyStateSweepDir `
                -SkipBuild
        }
        return ('wrote sweep outputs to {0}' -f $steadyStateSweepDir)
    }

    if (-not $SkipTransitionPass) {
        Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'transition_pass_cli' -EstimateMinutes 10.0 -Cost 'light' -Command {
            Invoke-WorkflowCommand -Label 'run_transition_pass_cli.ps1' -Command {
                & (Join-Path $scriptDir 'run_transition_pass_cli.ps1') `
                    -PackName $TransitionPassPackName `
                    -SkipBuild
            }
            return ('refreshed transition-pass outputs in truth\{0}' -f $TransitionPassPackName)
        }

        Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'transition_pass_validate' -EstimateMinutes 2.0 -Cost 'light' -Command {
            Invoke-WorkflowCommand -Label 'validate_transition_pass.ps1' -Command {
                & (Join-Path $scriptDir 'validate_transition_pass.ps1') -PackName $TransitionPassPackName
            }
            return 'transition-pass validation passed'
        }
    }

    if (-not $SkipTransitionRe) {
        Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'transition_re_cli' -EstimateMinutes 60.0 -Cost 'light' -Command {
            Invoke-WorkflowCommand -Label 'run_transition_re_cli.ps1' -Command {
                & (Join-Path $scriptDir 'run_transition_re_cli.ps1') `
                    -PackName $TransitionRePackName `
                    -SkipBuild
            }
            return ('refreshed transition-RE outputs in truth\{0}' -f $TransitionRePackName)
        }

        Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'transition_re_validate' -EstimateMinutes 2.0 -Cost 'light' -Command {
            Invoke-WorkflowCommand -Label 'validate_transition_re.ps1' -Command {
                & (Join-Path $scriptDir 'validate_transition_re.ps1') `
                    -PackName $TransitionRePackName `
                    -RunCli:$false
            }
            return 'transition-RE validation passed'
        }
    }
} catch {
    $runFailed = $true
} finally {
    $manifestRows | Export-Csv -LiteralPath $manifestPath -NoTypeInformation
    Write-WorkflowSummary -ManifestRows $manifestRows -Blocked $blocked
    if ($runFailed) {
        Set-ActivePointer -Phase 'failed' -Note 'See summary.md and status.txt'
    } else {
        Set-ActivePointer -Phase 'success' -Note 'Latest summary available in summary.md'
    }
}

if ($runFailed) {
    exit 1
}

exit 0
