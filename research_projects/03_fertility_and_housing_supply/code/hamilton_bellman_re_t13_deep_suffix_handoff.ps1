param(
    [string]$JobId = "",
    [string]$RemoteRunDir = "",
    [string]$RemoteHost = "hfnt93@hamilton8.dur.ac.uk",
    [int]$PollMinutes = 10,
    [double]$MaxHours = 12
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Status {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Add-Content -Path $statusPath
}

function Parse-KeyValueFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $map = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match "^\s*([^=]+)=(.*)$") {
            $map[$matches[1].Trim()] = $matches[2]
        }
    }
    return $map
}

function Get-JobRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteJobId,
        [Parameter(Mandatory = $true)]
        [string]$RemoteHostName,
        [Parameter(Mandatory = $true)]
        [string]$KeyPath
    )

    $raw = & ssh -F NUL -o IdentitiesOnly=yes -i $KeyPath $RemoteHostName "sacct -j $RemoteJobId --format=JobID,State,ExitCode,Elapsed -n -P 2>/dev/null || true"
    if (-not $raw) {
        return $null
    }

    foreach ($line in $raw) {
        $parts = $line -split "\|"
        if ($parts.Length -lt 4) {
            continue
        }
        if ($parts[0] -eq $RemoteJobId) {
            return [pscustomobject]@{
                JobId = $parts[0]
                State = $parts[1]
                ExitCode = $parts[2]
                Elapsed = $parts[3]
            }
        }
    }

    return $null
}

function Sync-RemoteOutputs {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteHostName,
        [Parameter(Mandatory = $true)]
        [string]$KeyPath,
        [Parameter(Mandatory = $true)]
        [string]$RemoteDir,
        [Parameter(Mandatory = $true)]
        [string]$LocalDir
    )

    $remoteSnapshotDir = Join-Path $LocalDir "remote_snapshot"
    if (-not (Test-Path $remoteSnapshotDir)) {
        New-Item -ItemType Directory -Path $remoteSnapshotDir | Out-Null
    }

    & scp -F NUL -o IdentitiesOnly=yes -i $KeyPath "$RemoteHostName`:$RemoteDir/status.txt" "$remoteSnapshotDir\"
    & scp -F NUL -o IdentitiesOnly=yes -i $KeyPath "$RemoteHostName`:$RemoteDir/summary.txt" "$remoteSnapshotDir\" 2>$null
    & scp -F NUL -o IdentitiesOnly=yes -i $KeyPath "$RemoteHostName`:$RemoteDir/t13_deep_cases.csv" "$remoteSnapshotDir\" 2>$null
    & scp -F NUL -o IdentitiesOnly=yes -i $KeyPath "$RemoteHostName`:$RemoteDir/slurm-*.out" "$remoteSnapshotDir\" 2>$null
    & scp -F NUL -o IdentitiesOnly=yes -i $KeyPath "$RemoteHostName`:$RemoteDir/slurm-*.err" "$remoteSnapshotDir\" 2>$null
    & scp -F NUL -o IdentitiesOnly=yes -i $KeyPath -r "$RemoteHostName`:$RemoteDir/outputs" "$remoteSnapshotDir\" 2>$null

    return $remoteSnapshotDir
}

function Write-CompletionSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteRunDir,
        [Parameter(Mandatory = $true)]
        [string]$RemoteSnapshotDir,
        [Parameter(Mandatory = $true)]
        [string]$SummaryPath,
        [Parameter(Mandatory = $true)]
        [string]$RemoteJobId,
        [Parameter(Mandatory = $true)]
        [string]$FinalState,
        [Parameter(Mandatory = $true)]
        [string]$ExitCode,
        [Parameter(Mandatory = $true)]
        [string]$Elapsed
    )

    $remoteCasesPath = Join-Path $RemoteSnapshotDir "t13_deep_cases.csv"
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# Hamilton T13 deep suffix handoff")
    $lines.Add("")
    $lines.Add("Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $lines.Add("")
    $lines.Add("## Remote run")
    $lines.Add("")
    $lines.Add(('- job id: `{0}`' -f $RemoteJobId))
    $lines.Add(('- state: `{0}`' -f $FinalState))
    $lines.Add(('- exit code: `{0}`' -f $ExitCode))
    $lines.Add(('- elapsed: `{0}`' -f $Elapsed))
    $lines.Add(('- remote run dir: `{0}`' -f $RemoteRunDir))
    $lines.Add("")

    if (Test-Path $remoteCasesPath) {
        $rows = Import-Csv -LiteralPath $remoteCasesPath | Sort-Object { [double]$_.max_abs_residual }, case_label
        if ($rows.Count -gt 0) {
            $best = $rows[0]
            $lines.Add("## Best case")
            $lines.Add("")
            $lines.Add(('- best case: `{0}`' -f $best.case_label))
            $lines.Add(("- maxres ~= {0}" -f $best.max_abs_residual))
            $lines.Add(('- continuity mask: `{0}`' -f $best.continuity_mask))
            $lines.Add(('- previous-implied mask: `{0}`' -f $best.previous_implied_mask))
            $lines.Add("- q ~= [$($best.q_path)]")
            $lines.Add("- qhat ~= [$($best.implied_q_path)]")
            $lines.Add("")
        }
    }
    else {
        $lines.Add("## Best case")
        $lines.Add("")
        $lines.Add("- No case table was synced back from Hamilton.")
        $lines.Add("")
    }

    $lines.Add("## Synced files")
    $lines.Add("")
    $lines.Add(('- remote snapshot: `{0}`' -f $RemoteSnapshotDir))

    Set-Content -LiteralPath $SummaryPath -Value $lines
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$remotePointerPath = Join-Path $logsRoot "active_bellman_re_t13_deep_suffix_hamilton.txt"
if (([string]::IsNullOrWhiteSpace($JobId) -or [string]::IsNullOrWhiteSpace($RemoteRunDir)) -and (-not (Test-Path $remotePointerPath))) {
    throw "Missing remote pointer file: $remotePointerPath"
}
if ([string]::IsNullOrWhiteSpace($JobId) -or [string]::IsNullOrWhiteSpace($RemoteRunDir)) {
    $pointer = Parse-KeyValueFile -Path $remotePointerPath
    if ([string]::IsNullOrWhiteSpace($JobId)) {
        $JobId = $pointer["job_id"]
    }
    if ([string]::IsNullOrWhiteSpace($RemoteRunDir)) {
        $RemoteRunDir = $pointer["remote_run_dir"]
    }
}

$keyPath = Join-Path $HOME ".ssh\id_ed25519"
if (-not (Test-Path $keyPath)) {
    throw "SSH key not found: $keyPath"
}

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $logsRoot "hamilton_bellman_re_t13_deep_suffix_handoff_$runStamp"
New-Item -ItemType Directory -Path $runDir | Out-Null

$statusPath = Join-Path $runDir "status.txt"
$summaryPath = Join-Path $runDir "summary.txt"
$manifestPath = Join-Path $runDir "manifest.txt"
$latestPointerPath = Join-Path $logsRoot "latest_hamilton_bellman_re_t13_deep_suffix_handoff.txt"
$activePointerPath = Join-Path $logsRoot "active_hamilton_bellman_re_t13_deep_suffix_handoff.txt"
$notePath = Join-Path $projectRoot "notes/build/compiled_sidecar_bellman_re_t13_deep_suffix_hamilton_handoff.md"

@(
    "Objective: monitor Hamilton T13 deep suffix ladder and sync the result when it finishes."
    "Project root: $projectRoot"
    "Job id: $JobId"
    "Remote host: $RemoteHost"
    "Remote run dir: $RemoteRunDir"
    "Poll minutes: $PollMinutes"
    "Max hours: $MaxHours"
) | Set-Content -LiteralPath $manifestPath

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "job_id=$JobId"
    "remote_host=$RemoteHost"
    "remote_run_dir=$RemoteRunDir"
    "run_dir=$runDir"
    "status_path=$statusPath"
    "summary_path=$summaryPath"
    "manifest_path=$manifestPath"
) | Set-Content -LiteralPath $latestPointerPath

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "job_id=$JobId"
    "remote_host=$RemoteHost"
    "remote_run_dir=$RemoteRunDir"
    "run_dir=$runDir"
    "status_path=$statusPath"
    "summary_path=$summaryPath"
    "manifest_path=$manifestPath"
) | Set-Content -LiteralPath $activePointerPath

$deadline = (Get-Date).AddHours($MaxHours)
Write-Status "START monitor job=$JobId remote_dir=$RemoteRunDir"

while ((Get-Date) -lt $deadline) {
    $record = Get-JobRecord -RemoteJobId $JobId -RemoteHostName $RemoteHost -KeyPath $keyPath
    if ($null -eq $record) {
        Write-Status "WAIT job=$JobId state=missing"
        Start-Sleep -Seconds ($PollMinutes * 60)
        continue
    }

    Write-Status "POLL job=$($record.JobId) state=$($record.State) exit=$($record.ExitCode) elapsed=$($record.Elapsed)"
    if ($record.State -in @("COMPLETED", "FAILED", "CANCELLED", "TIMEOUT", "OUT_OF_MEMORY", "BOOT_FAIL", "NODE_FAIL", "PREEMPTED")) {
        $remoteSnapshotDir = Sync-RemoteOutputs -RemoteHostName $RemoteHost -KeyPath $keyPath -RemoteDir $RemoteRunDir -LocalDir $runDir
        Write-CompletionSummary -RemoteRunDir $RemoteRunDir -RemoteSnapshotDir $remoteSnapshotDir -SummaryPath $summaryPath -RemoteJobId $JobId -FinalState $record.State -ExitCode $record.ExitCode -Elapsed $record.Elapsed
        Copy-Item -LiteralPath $summaryPath -Destination $notePath -Force

        Write-Status "STOP job=$($record.JobId) state=$($record.State)"
        @(
            "stopped_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            "job_id=$JobId"
            "remote_host=$RemoteHost"
            "remote_run_dir=$RemoteRunDir"
            "run_dir=$runDir"
            "final_state=$($record.State)"
            "summary_path=$summaryPath"
            "note_path=$notePath"
        ) | Set-Content -LiteralPath $activePointerPath
        exit 0
    }

    Start-Sleep -Seconds ($PollMinutes * 60)
}

@(
    "# Hamilton T13 deep suffix handoff monitor timeout"
    ""
    "Job id: $JobId"
    "Remote run dir: $RemoteRunDir"
    "Summary note: $notePath"
    ""
    "- The detached monitor reached its local time budget before the Hamilton job hit a final state."
) | Set-Content -LiteralPath $summaryPath

Write-Status "STOP job=$JobId state=MONITOR_TIMEOUT"
@(
    "stopped_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "job_id=$JobId"
    "remote_host=$RemoteHost"
    "remote_run_dir=$RemoteRunDir"
    "run_dir=$runDir"
    "final_state=MONITOR_TIMEOUT"
    "summary_path=$summaryPath"
    "note_path=$notePath"
) | Set-Content -LiteralPath $activePointerPath
exit 0
