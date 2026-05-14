param(
    [string]$RunLabel = 'political_re_overnight',
    [string]$SessionName = 'political_re_overnight_live',
    [double]$MaxHours = 10.0,
    [switch]$SkipPoliticalPath,
    [switch]$SkipJointPriceVote,
    [switch]$SkipVoteWeightSweep
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthDir = Join-Path $scriptDir 'truth'
$sessionDir = Join-Path $truthDir $SessionName
$runsDir = Join-Path $sessionDir 'r'
$runStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$runDir = Join-Path $runsDir ("pr_{0}" -f $runStamp)
$statusPath = Join-Path $runDir 'status.txt'
$manifestPath = Join-Path $runDir 'manifest.csv'
$summaryPath = Join-Path $runDir 'summary.md'
$activePointer = Join-Path $sessionDir 'active_run.txt'
$latestPointer = Join-Path $sessionDir 'latest_run.txt'
$workflowStart = Get-Date
$workflowDeadline = $workflowStart.AddHours($MaxHours)
$summaryReserveMinutes = 10.0

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
        'deadline_at={0}' -f $workflowDeadline.ToString('yyyy-MM-dd HH:mm:ss')
        'phase={0}' -f $Phase
        'run_dir={0}' -f $runDir
        'status_path={0}' -f $statusPath
        'manifest_path={0}' -f $manifestPath
        'summary_path={0}' -f $summaryPath
        'note={0}' -f $Note
    ) | Set-Content -LiteralPath $activePointer
}

function Get-RemainingMinutes {
    return ($workflowDeadline - (Get-Date)).TotalMinutes
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

function Copy-ArtifactSet {
    param(
        [string]$StageSlug,
        [string[]]$Paths
    )

    $targetDir = Join-Path $runDir $StageSlug
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Expected artifact not found: $path"
        }
        Copy-Item -LiteralPath $path -Destination (Join-Path $targetDir ([System.IO.Path]::GetFileName($path))) -Force
    }
    return $targetDir
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

    $remaining = Get-RemainingMinutes
    if ($remaining -lt ($EstimateMinutes + $summaryReserveMinutes)) {
        $note = 'Skipped because remaining time is below the estimate plus summary reserve.'
        Add-ManifestRow -Rows $Rows -Task $Task -EstimateMinutes $EstimateMinutes -Cost $Cost -Status 'skipped' -ElapsedMinutes 0.0 -Note $note
        Write-Status ("SKIPPED {0}: {1}" -f $Task, $note)
        return
    }

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

function Get-NamedCsvMap {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $map = @{}
    foreach ($row in Import-Csv -LiteralPath $Path) {
        if ($null -ne $row.PSObject.Properties['name'] -and $null -ne $row.PSObject.Properties['value']) {
            $map[[string]$row.name] = [string]$row.value
        }
    }
    return $map
}

function Get-FirstCsvRow {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    return Import-Csv -LiteralPath $Path | Select-Object -First 1
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
    $skippedCount = @($ManifestRows | Where-Object { $_.status -eq 'skipped' }).Count

    $politicalSummary = Get-FirstCsvRow -Path (Join-Path $runDir 'political_path\transition_re_political_path_summary.csv')
    $jointSummary = Get-FirstCsvRow -Path (Join-Path $runDir 'joint_price_vote\transition_re_joint_price_vote_summary.csv')
    $sweepSummary = if (Test-Path -LiteralPath (Join-Path $runDir 'vote_weight_sweep\transition_re_joint_price_vote_weight_sweep_summary.csv')) {
        Import-Csv -LiteralPath (Join-Path $runDir 'vote_weight_sweep\transition_re_joint_price_vote_weight_sweep_summary.csv') |
            Sort-Object { [double]$_.vote_weight }
    } else {
        $null
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Political RE overnight workflow')
    $lines.Add('')
    $lines.Add(('- Project: `extensions/re_no_politics`'))
    $lines.Add(('- Session name: `{0}`' -f $SessionName))
    $lines.Add(('- Run label: `{0}`' -f $RunLabel))
    $lines.Add(('- Run directory: `{0}`' -f $runDir))
    $lines.Add(('- Session start: `{0}`' -f $workflowStart.ToString('yyyy-MM-dd HH:mm:ss')))
    $lines.Add(('- Session end: `{0}`' -f $endTime.ToString('yyyy-MM-dd HH:mm:ss')))
    $lines.Add(('- Runtime: `~{0}` hours' -f $usedHours))
    $lines.Add(('- Budget: `~{0}` hours' -f ([math]::Round($MaxHours, 2))))
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
    if ($politicalSummary) {
        $lines.Add(('- Political-path packet: residual norm `{0}`, max gap `{1}`, max weighted vote `{2}`, hardest price period `{3}`.' -f `
            $politicalSummary.residual_norm, $politicalSummary.max_abs_gap, $politicalSummary.max_abs_weighted_vote, $politicalSummary.worst_gap_period))
    }
    if ($jointSummary) {
        $lines.Add(('- Joint price-vote packet: vote weight `{0}`, residual norm `{1}`, max gap `{2}`, price range `[{3}, {4}]`.' -f `
            $jointSummary.vote_weight, $jointSummary.residual_norm, $jointSummary.max_abs_gap, $jointSummary.price_min, $jointSummary.price_max))
    }
    if ($sweepSummary) {
        $lastSweep = $sweepSummary | Select-Object -Last 1
        $lines.Add(('- Vote-weight sweep: tested `{0}` weights, highest weight `{1}`, conflict share `{2}`, adjusted price range `[{3}, {4}]`.' -f `
            @($sweepSummary).Count, $lastSweep.vote_weight, $lastSweep.conflict_period_share, $lastSweep.price_min, $lastSweep.price_max))
    }
    $lines.Add(('- Snapshot artifacts: `{0}`' -f $runDir))
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
    $lines.Add('1. Decide whether to promote the bounded vote-weight sweep into a paper-facing diagnostic or keep it as internal hardness evidence only.')
    $lines.Add('2. If we keep pushing the political RE object, add one bounded update-rule variant that changes the political mapping rather than only the vote weight.')
    $lines.Add('3. If the resubmission path dominates, use the bounded political packet only as negative evidence and return the write-up to the house-price-only object.')
    $lines.Add('')
    $lines.Add(('- Session summary: `{0}` completed, `{1}` failed, `{2}` skipped.' -f $completedCount, $failedCount, $skippedCount))

    [System.IO.File]::WriteAllLines($summaryPath, $lines)
}

Set-Content -LiteralPath $latestPointer -Value $runDir
Set-Content -LiteralPath $statusPath -Value ''
$manifestRows = New-Object System.Collections.Generic.List[object]
$blocked = New-Object System.Collections.Generic.List[string]
$runFailed = $false

$politicalPathWorkflow = Join-Path $scriptDir 'run_transition_re_political_path_workflow.ps1'
$jointPriceVoteWorkflow = Join-Path $scriptDir 'run_transition_re_joint_price_vote_workflow.ps1'
$voteWeightSweepWorkflow = Join-Path $scriptDir 'run_transition_re_joint_price_vote_weight_sweep_workflow.ps1'

try {
    Set-ActivePointer -Phase 'starting'

    if (-not $SkipPoliticalPath) {
        Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'bounded_political_path' -EstimateMinutes 30.0 -Cost 'light' -Command {
            Invoke-WorkflowCommand -Label 'run_transition_re_political_path_workflow.ps1' -Command {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $politicalPathWorkflow
            }
            $artifactDir = Copy-ArtifactSet -StageSlug 'political_path' -Paths @(
                (Join-Path $scriptDir 'transition_re_political_path_summary.csv'),
                (Join-Path $scriptDir 'transition_re_political_path_periods.csv'),
                (Join-Path $scriptDir 'transition_re_political_path_results.mat'),
                (Join-Path $scriptDir 'transition_re_political_path_report.md')
            )
            return ('refreshed bounded political-path packet and copied artifacts to {0}' -f $artifactDir)
        }
    }

    if (-not $SkipJointPriceVote) {
        Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'bounded_joint_price_vote' -EstimateMinutes 30.0 -Cost 'light' -Command {
            Invoke-WorkflowCommand -Label 'run_transition_re_joint_price_vote_workflow.ps1' -Command {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $jointPriceVoteWorkflow
            }
            $artifactDir = Copy-ArtifactSet -StageSlug 'joint_price_vote' -Paths @(
                (Join-Path $scriptDir 'transition_re_joint_price_vote_summary.csv'),
                (Join-Path $scriptDir 'transition_re_joint_price_vote_periods.csv'),
                (Join-Path $scriptDir 'transition_re_joint_price_vote_results.mat'),
                (Join-Path $scriptDir 'transition_re_joint_price_vote_report.md')
            )
            return ('refreshed bounded joint price-vote packet and copied artifacts to {0}' -f $artifactDir)
        }
    }

    if (-not $SkipVoteWeightSweep) {
        Invoke-SupervisedTask -Rows $manifestRows -Blocked $blocked -Task 'vote_weight_robustness_sweep' -EstimateMinutes 25.0 -Cost 'light' -Command {
            Invoke-WorkflowCommand -Label 'run_transition_re_joint_price_vote_weight_sweep_workflow.ps1' -Command {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $voteWeightSweepWorkflow
            }
            $artifactDir = Copy-ArtifactSet -StageSlug 'vote_weight_sweep' -Paths @(
                (Join-Path $scriptDir 'transition_re_joint_price_vote_weight_sweep_summary.csv'),
                (Join-Path $scriptDir 'transition_re_joint_price_vote_weight_sweep_periods.csv'),
                (Join-Path $scriptDir 'transition_re_joint_price_vote_weight_sweep_results.mat'),
                (Join-Path $scriptDir 'transition_re_joint_price_vote_weight_sweep_report.md')
            )
            return ('refreshed vote-weight robustness sweep and copied artifacts to {0}' -f $artifactDir)
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
