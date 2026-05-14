param(
    [string]$RunLabel = 'political_bellman_compiled_supervisor',
    [string]$SessionName = 'political_bellman_compiled_supervisor_live',
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthDir = Join-Path $scriptDir 'truth'
$sessionDir = Join-Path $truthDir $SessionName
$runsDir = Join-Path $sessionDir 'r'
$runStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$runDir = Join-Path $runsDir ("pc_{0}" -f $runStamp)
$statusPath = Join-Path $runDir 'status.txt'
$manifestPath = Join-Path $runDir 'manifest.csv'
$summaryPath = Join-Path $runDir 'summary.md'
$activePointer = Join-Path $sessionDir 'active_run.txt'
$latestPointer = Join-Path $sessionDir 'latest_run.txt'
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

function Get-LastCsvRow {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $rows = @(Import-Csv -LiteralPath $Path)
    if ($rows.Count -eq 0) {
        return $null
    }
    return $rows[-1]
}

function Export-NoPoliticsPrefixCsv {
    param(
        [int]$Horizon,
        [string]$OutputPath
    )

    $matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
    if (-not (Test-Path -LiteralPath $matlab)) {
        throw "MATLAB executable not found: $matlab"
    }

    $sourceMat = Join-Path (Split-Path -Parent $scriptDir) 'transition_re_no_politics_results.mat'
    if (-not (Test-Path -LiteralPath $sourceMat)) {
        throw "No-politics results MAT file not found: $sourceMat"
    }

    $matlabSource = $sourceMat.Replace('\', '/').Replace("'", "''")
    $matlabOutput = $OutputPath.Replace('\', '/').Replace("'", "''")
    $batch = "load('$matlabSource'); writematrix(results.final_price_path(1:$Horizon), '$matlabOutput');"
    & $matlab -batch $batch
    if ($LASTEXITCODE -ne 0) {
        throw "MATLAB export failed with exit code $LASTEXITCODE."
    }
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

    $summaryT4 = Get-LastCsvRow -Path (Join-Path $scriptDir 'truth\political_bellman_t4_fixed_step_smoke\sidecar_summary.csv')
    $summaryT9 = Get-LastCsvRow -Path (Join-Path $scriptDir 'truth\political_bellman_t9_diagonal_secant_smoke\sidecar_summary.csv')

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Political Bellman compiled supervisor')
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
    if ($summaryT4) {
        $lines.Add(('- T4 fixed-step wrapper: `max_abs_vote = {0}`, `max_abs_gap = {1}`, `residual_norm = {2}`.' -f `
            $summaryT4.max_abs_vote, $summaryT4.max_abs_gap, $summaryT4.residual_norm))
    }
    if ($summaryT9) {
        $lines.Add(('- T9 diagonal-secant wrapper: `max_abs_vote = {0}`, `max_abs_gap = {1}`, `residual_norm = {2}`.' -f `
            $summaryT9.max_abs_vote, $summaryT9.max_abs_gap, $summaryT9.residual_norm))
    }
    $lines.Add(('- Latest source-validation artifacts live under `{0}`' -f $runDir))
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
    $lines.Add('1. Keep the fixed-step T=4 political wrapper matching the bounded MATLAB summary.')
    $lines.Add('2. Keep the diagonal-secant T=9 political wrapper matching the MATLAB smoke summary.')
    $lines.Add('3. If the wrapper remains stable, decide whether to add a tighter step rule or a line-search fallback.')
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

    $prefixT4 = Join-Path $runDir 'no_politics_prefix_t4.csv'
    $prefixT9 = Join-Path $runDir 'no_politics_prefix_t9.csv'

    Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'run_political_bellman_t4_fixed_step' -EstimateMinutes 3.0 -Cost 'light' -Command {
        Invoke-WorkflowCommand -Label 'run_political_bellman_cli.ps1 (T4 fixed-step)' -Command {
            Export-NoPoliticsPrefixCsv -Horizon 4 -OutputPath $prefixT4
            & (Join-Path $scriptDir 'run_political_bellman_cli.ps1') `
                -PackName 'transition_pass_t4_political_diag' `
                -OutputDir (Join-Path $scriptDir 'truth\political_bellman_t4_fixed_step_smoke') `
                -InitialPricePathCsv $prefixT4 `
                -MaxIter 2 `
                -PoliticalUpdateRule 'fixed_step' `
                -PoliticalUpdateWeight 0.005 `
                -SkipBuild
        }
        return 'refreshed compiled fixed-step political wrapper outputs for T=4'
    }

    Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'validate_political_bellman_t4_fixed_step' -EstimateMinutes 2.0 -Cost 'light' -Command {
        Invoke-WorkflowCommand -Label 'validate_political_bellman.ps1 (T4 fixed-step)' -Command {
            try {
                $output = & (Join-Path $scriptDir 'validate_political_bellman.ps1') `
                    -TruthSummaryPath (Join-Path (Split-Path -Parent $scriptDir) 'transition_political_bellman_bounded_summary.csv') `
                    -SidecarSummaryPath (Join-Path $scriptDir 'truth\political_bellman_t4_fixed_step_smoke\sidecar_summary.csv') 2>&1
                foreach ($line in @($output)) {
                    if ($null -ne $line -and [string]$line -ne '') {
                        Write-Status ([string]$line)
                    }
                }
                return 'T4 fixed-step political wrapper validation passed'
            } catch {
                Write-Status ("validation mismatch: {0}" -f $_.Exception.Message)
                return ("T4 fixed-step political wrapper validation mismatch: {0}" -f $_.Exception.Message)
            }
        }
    }

    Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'run_political_bellman_t9_diagonal_secant' -EstimateMinutes 4.0 -Cost 'light' -Command {
        Invoke-WorkflowCommand -Label 'run_political_bellman_cli.ps1 (T9 diagonal_secant)' -Command {
            Export-NoPoliticsPrefixCsv -Horizon 9 -OutputPath $prefixT9
            & (Join-Path $scriptDir 'run_political_bellman_cli.ps1') `
                -PackName 'transition_pass_t9_political_diag' `
                -OutputDir (Join-Path $scriptDir 'truth\political_bellman_t9_diagonal_secant_smoke') `
                -InitialPricePathCsv $prefixT9 `
                -MaxIter 4 `
                -PoliticalUpdateRule 'diagonal_secant' `
                -PoliticalUpdateWeight 0.005 `
                -SkipBuild
        }
        return 'refreshed compiled diagonal-secant political wrapper outputs for T=9'
    }

    Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'validate_political_bellman_t9_diagonal_secant' -EstimateMinutes 2.0 -Cost 'light' -Command {
        Invoke-WorkflowCommand -Label 'validate_political_bellman.ps1 (T9 diagonal_secant)' -Command {
            try {
                $output = & (Join-Path $scriptDir 'validate_political_bellman.ps1') `
                    -TruthSummaryPath (Join-Path (Split-Path -Parent $scriptDir) 'transition_political_bellman_t9_polonly_eqvote_i4_secant_summary.csv') `
                    -SidecarSummaryPath (Join-Path $scriptDir 'truth\political_bellman_t9_diagonal_secant_smoke\sidecar_summary.csv') 2>&1
                foreach ($line in @($output)) {
                    if ($null -ne $line -and [string]$line -ne '') {
                        Write-Status ([string]$line)
                    }
                }
                return 'T9 diagonal-secant political wrapper validation passed'
            } catch {
                Write-Status ("validation mismatch: {0}" -f $_.Exception.Message)
                return ("T9 diagonal-secant political wrapper validation mismatch: {0}" -f $_.Exception.Message)
            }
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
