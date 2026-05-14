[CmdletBinding()]
param(
    [string]$KListCsv = '1,2,3,4,5,6,7,8,9',
    [int]$MaxIter = 2,
    [int]$MaxParallel = 3,
    [string]$PriceUpdateMode = 'political_only',
    [string]$PoliticalTarget = 'equal_weight_vote',
    [double]$PoliticalUpdateWeight = 0.005,
    [string]$PoliticalUpdateRule = 'fixed_step',
    [string]$WorkflowName = 'political_bellman_parallel_k_live'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$runnerPath = Join-Path $scriptDir 'run_transition_political_bellman_bounded.ps1'
$truthDir = Join-Path $scriptDir 'truth'
$workflowDir = Join-Path $truthDir $WorkflowName
$logPath = Join-Path $workflowDir 'workflow_log.txt'
$statusPath = Join-Path $workflowDir 'status.txt'
$manifestPath = Join-Path $workflowDir 'manifest.csv'
$summaryPath = Join-Path $workflowDir 'summary.md'
$statePath = Join-Path $workflowDir 'workflow_state.json'
$stopPath = Join-Path $workflowDir 'stop.txt'

if (-not (Test-Path -LiteralPath $workflowDir)) {
    New-Item -ItemType Directory -Path $workflowDir | Out-Null
}

function Parse-KList {
    param([string]$Csv)
    $values = @()
    foreach ($token in ($Csv -split '[,\s;]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
        $parsed = 0
        if (-not [int]::TryParse($token, [ref]$parsed)) {
            throw "Invalid k value in KListCsv: $token"
        }
        $values += $parsed
    }
    if ($values.Count -eq 0) {
        throw 'KListCsv must contain at least one integer horizon.'
    }
    return @($values | Sort-Object -Unique)
}

$kValues = Parse-KList -Csv $KListCsv

function Write-WorkflowLine {
    param([string]$Message)
    $timestamped = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $logPath -Value $timestamped
    Add-Content -LiteralPath $statusPath -Value $timestamped
    Write-Host $timestamped
}

function Write-WorkflowState {
    param(
        [array]$Jobs,
        [string]$Phase,
        [int]$CompletedCount,
        [int]$FailedCount
    )

    $state = [ordered]@{
        workflow_name = $WorkflowName
        phase = $Phase
        updated_at = (Get-Date).ToString('o')
        stop_path = $stopPath
        completed_count = $CompletedCount
        failed_count = $FailedCount
        jobs = @(
            foreach ($job in $Jobs) {
                [ordered]@{
                    k = $job.K
                    run_tag = $job.RunTag
                    pid = $job.ProcessId
                    state = $job.State
                    exit_code = $job.ExitCode
                    summary_csv = $job.SummaryCsv
                    results_mat = $job.ResultsMat
                }
            }
        )
    }
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statePath
}

function Export-Manifest {
    param([array]$Jobs)
    $rows = foreach ($job in $Jobs) {
        [pscustomobject]@{
            k = $job.K
            run_tag = $job.RunTag
            state = $job.State
            pid = $job.ProcessId
            exit_code = $job.ExitCode
            summary_csv = $job.SummaryCsv
            results_mat = $job.ResultsMat
            stdout = $job.StdOut
            stderr = $job.StdErr
        }
    }
    $rows | Export-Csv -NoTypeInformation -LiteralPath $manifestPath
}

function Get-CompletedJobSummary {
    param([hashtable]$Job)
    if (-not (Test-Path -LiteralPath $Job.SummaryCsv)) {
        return $null
    }
    $rows = @(Import-Csv -LiteralPath $Job.SummaryCsv)
    if ($rows.Count -eq 0) {
        return $null
    }
    return $rows[-1]
}

function Resolve-JobExitCode {
    param([hashtable]$Job)

    $exitCode = $null
    try {
        if ($Job.Process) {
            $Job.Process.WaitForExit()
            $Job.Process.Refresh()
            $exitCode = [int]$Job.Process.ExitCode
        }
    } catch {
        $exitCode = $null
    }

    if ($null -ne $exitCode) {
        return $exitCode
    }

    $stderrEmpty = (Test-Path -LiteralPath $Job.StdErr) -and ((Get-Item -LiteralPath $Job.StdErr).Length -eq 0)
    $stdoutText = if (Test-Path -LiteralPath $Job.StdOut) { Get-Content -Raw -LiteralPath $Job.StdOut } else { '' }
    $hasSuccessMarker = $stdoutText -match 'finished successfully'
    $hasSummary = Test-Path -LiteralPath $Job.SummaryCsv

    if ($stderrEmpty -and $hasSuccessMarker -and $hasSummary) {
        return 0
    }

    return 1
}

function Write-MarkdownSummary {
    param(
        [array]$Jobs,
        [datetime]$StartedAt,
        [datetime]$EndedAt
    )

    $completed = @($Jobs | Where-Object { $_.State -eq 'completed' })
    $failed = @($Jobs | Where-Object { $_.State -eq 'failed' })

    $lines = @()
    $lines += '# Parallel MATLAB political Bellman k sweep'
    $lines += ''
    $lines += ('- Workflow: `{0}`' -f $WorkflowName)
    $lines += ('- Start: `{0}`' -f $StartedAt.ToString('yyyy-MM-dd HH:mm:ss'))
    $lines += ('- End: `{0}`' -f $EndedAt.ToString('yyyy-MM-dd HH:mm:ss'))
    $lines += ('- K grid: `{0}`' -f (($kValues | Sort-Object) -join ', '))
    $lines += ('- Max parallel MATLAB jobs: `{0}`' -f $MaxParallel)
    $lines += ('- Update mode: `{0}`' -f $PriceUpdateMode)
    $lines += ('- Target: `{0}`' -f $PoliticalTarget)
    $lines += ('- Rule: `{0}`' -f $PoliticalUpdateRule)
    $lines += ('- Iterations per job: `{0}`' -f $MaxIter)
    $lines += ''
    $lines += '## Job summary'
    $lines += ''
    $lines += '| k | status | exit | final vote | final gap | residual norm |'
    $lines += '|---:|---|---:|---:|---:|---:|'

    foreach ($job in ($Jobs | Sort-Object K)) {
        $row = Get-CompletedJobSummary -Job $job
        $finalVote = if ($row) { $row.max_abs_vote } else { '' }
        $finalGap = if ($row) { $row.max_abs_gap } else { '' }
        $residual = if ($row) { $row.residual_norm } else { '' }
        $lines += ('| {0} | {1} | {2} | {3} | {4} | {5} |' -f $job.K, $job.State, $job.ExitCode, $finalVote, $finalGap, $residual)
    }

    $lines += ''
    $lines += ('- Completed jobs: `{0}`' -f $completed.Count)
    $lines += ('- Failed jobs: `{0}`' -f $failed.Count)
    $lines += ('- Manifest: `{0}`' -f $manifestPath)
    $lines += ('- State: `{0}`' -f $statePath)
    $lines += ('- Log: `{0}`' -f $logPath)

    Set-Content -LiteralPath $summaryPath -Value $lines
}

if (Test-Path -LiteralPath $stopPath) {
    Remove-Item -LiteralPath $stopPath -Force
}
Set-Content -LiteralPath $statusPath -Value ''
Set-Content -LiteralPath $logPath -Value ''

$startedAt = Get-Date
$jobs = @()
$completedCount = 0
$failedCount = 0

foreach ($k in $kValues) {
    $runTag = ('parallel_k_{0}_i{1}_{2}_{3}_{4}_w{5}' -f `
        $k, `
        $MaxIter, `
        (($PriceUpdateMode -replace '[^A-Za-z0-9]+', '_').ToLower()), `
        (($PoliticalTarget -replace '[^A-Za-z0-9]+', '_').ToLower()), `
        (($PoliticalUpdateRule -replace '[^A-Za-z0-9]+', '_').ToLower()), `
        ((('{0:N4}' -f $PoliticalUpdateWeight) -replace '[^0-9]+', 'p').Trim('p')))

    $summaryCsv = Join-Path $scriptDir ('transition_political_bellman_{0}_summary.csv' -f $runTag)
    $resultsMat = Join-Path $scriptDir ('transition_political_bellman_{0}_results.mat' -f $runTag)
    $stdout = Join-Path $workflowDir ('k{0}_stdout.log' -f $k)
    $stderr = Join-Path $workflowDir ('k{0}_stderr.log' -f $k)

    $jobs += @{
        K = $k
        RunTag = $runTag
        State = 'pending'
        ProcessId = $null
        Process = $null
        ExitCode = $null
        SummaryCsv = $summaryCsv
        ResultsMat = $resultsMat
        StdOut = $stdout
        StdErr = $stderr
    }
}

Write-WorkflowLine ("Starting parallel MATLAB political sweep over k = {0}" -f (($jobs.K | Sort-Object) -join ', '))
Export-Manifest -Jobs $jobs
Write-WorkflowState -Jobs $jobs -Phase 'starting' -CompletedCount $completedCount -FailedCount $failedCount

while ($true) {
    foreach ($job in $jobs) {
        if ($job.State -eq 'running' -and $job.Process) {
            $job.Process.Refresh()
        }
        if ($job.State -eq 'running' -and $job.Process -and $job.Process.HasExited) {
            $job.ExitCode = Resolve-JobExitCode -Job $job
            if ($job.ExitCode -eq 0) {
                $job.State = 'completed'
                $completedCount += 1
                Write-WorkflowLine ("Completed k={0} pid={1} exit={2}" -f $job.K, $job.ProcessId, $job.ExitCode)
            } else {
                $job.State = 'failed'
                $failedCount += 1
                Write-WorkflowLine ("Failed k={0} pid={1} exit={2}" -f $job.K, $job.ProcessId, $job.ExitCode)
            }
        }
    }

    if (Test-Path -LiteralPath $stopPath) {
        Write-WorkflowLine 'Stop file detected. Terminating remaining MATLAB jobs.'
        foreach ($job in $jobs | Where-Object { $_.State -eq 'running' }) {
            try {
                Stop-Process -Id $job.ProcessId -Force -ErrorAction SilentlyContinue
            } catch {
            }
            $job.State = 'stopped'
        }
        break
    }

    $runningCount = @($jobs | Where-Object { $_.State -eq 'running' }).Count
    $pendingJobs = @($jobs | Where-Object { $_.State -eq 'pending' })

    while ($runningCount -lt $MaxParallel -and $pendingJobs.Count -gt 0) {
        $job = $pendingJobs[0]
        $args = @(
            '-ExecutionPolicy', 'Bypass',
            '-File', $runnerPath,
            '-MaxK', $job.K,
            '-MaxIter', $MaxIter,
            '-PriceUpdateMode', $PriceUpdateMode,
            '-PoliticalTarget', $PoliticalTarget,
            '-PoliticalUpdateWeight', ('{0:R}' -f $PoliticalUpdateWeight),
            '-RunTag', $job.RunTag,
            '-PoliticalUpdateRule', $PoliticalUpdateRule
        )

        $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WorkingDirectory $scriptDir `
            -RedirectStandardOutput $job.StdOut -RedirectStandardError $job.StdErr -WindowStyle Hidden -PassThru

        $job.Process = $proc
        $job.ProcessId = $proc.Id
        $job.State = 'running'
        Write-WorkflowLine ("Started k={0} pid={1} run_tag={2}" -f $job.K, $job.ProcessId, $job.RunTag)

        $runningCount += 1
        $pendingJobs = @($jobs | Where-Object { $_.State -eq 'pending' })
    }

    Export-Manifest -Jobs $jobs
    Write-WorkflowState -Jobs $jobs -Phase 'running' -CompletedCount $completedCount -FailedCount $failedCount

    if (@($jobs | Where-Object { $_.State -in @('pending', 'running') }).Count -eq 0) {
        break
    }

    Start-Sleep -Seconds 5
}

$endedAt = Get-Date
Export-Manifest -Jobs $jobs
Write-WorkflowState -Jobs $jobs -Phase 'finished' -CompletedCount $completedCount -FailedCount $failedCount
Write-MarkdownSummary -Jobs $jobs -StartedAt $startedAt -EndedAt $endedAt
Write-WorkflowLine ("Workflow finished. completed={0} failed={1}" -f $completedCount, $failedCount)
