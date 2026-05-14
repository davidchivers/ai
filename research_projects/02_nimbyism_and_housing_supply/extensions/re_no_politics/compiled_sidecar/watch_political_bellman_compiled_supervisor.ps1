param(
    [int]$PollSeconds = 15,
    [int]$QuietSeconds = 20,
    [string]$SessionName = 'political_bellman_compiled_supervisor_live',
    [string]$RunLabel = 'political_bellman_compiled_supervisor',
    [string]$TransitionPassPackNameT4 = 'transition_pass_t4_political_diag',
    [string]$TransitionPassPackNameT9 = 'transition_pass_t9_political_diag',
    [double]$PriceLevel = 2.0,
    [switch]$SkipBuild,
    [switch]$RunOnStart
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthDir = Join-Path $scriptDir 'truth'
$sessionDir = Join-Path $truthDir $SessionName
$watcherLogPath = Join-Path $sessionDir 'watcher_log.txt'
$statePath = Join-Path $sessionDir 'watcher_state.json'
$pidPath = Join-Path $sessionDir 'watcher_pid.txt'
$stopPath = Join-Path $sessionDir 'stop.txt'
$workflowPath = Join-Path $scriptDir 'political_bellman_compiled_supervisor_workflow.ps1'

New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
Set-Content -LiteralPath $pidPath -Value $PID
if (Test-Path -LiteralPath $stopPath) {
    Remove-Item -LiteralPath $stopPath -Force
}

function Write-WatcherLog {
    param([string]$Message)

    $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $watcherLogPath -Value $line
}

function Get-WatchedFiles {
    $files = New-Object System.Collections.Generic.List[System.IO.FileInfo]

    foreach ($relative in @('src', 'include', 'matlab')) {
        $dir = Join-Path $scriptDir $relative
        if (Test-Path -LiteralPath $dir) {
            Get-ChildItem -LiteralPath $dir -Recurse -File | Where-Object {
                $_.Extension -in @('.cpp', '.hpp', '.h', '.m', '.ps1')
            } | ForEach-Object {
                $files.Add($_) | Out-Null
            }
        }
    }

    foreach ($pattern in @('*.ps1', '*.md')) {
        Get-ChildItem -LiteralPath $scriptDir -File -Filter $pattern | ForEach-Object {
            $files.Add($_) | Out-Null
        }
    }

    foreach ($name in @('CMakeLists.txt', 'README.md')) {
        $path = Join-Path $scriptDir $name
        if (Test-Path -LiteralPath $path) {
            $files.Add((Get-Item -LiteralPath $path)) | Out-Null
        }
    }

    return $files |
        Sort-Object FullName -Unique
}

function Get-SnapshotToken {
    $entries = foreach ($file in Get-WatchedFiles) {
        '{0}|{1}|{2}' -f $file.FullName, $file.LastWriteTimeUtc.Ticks, $file.Length
    }
    return ($entries -join "`n")
}

function Save-State {
    param(
        [System.Diagnostics.Process]$Child,
        [bool]$PendingRerun,
        [datetime]$LastChangeAt,
        [string]$BaselineSnapshot,
        [string]$LastTriggerReason
    )

    $state = [ordered]@{
        watcher_pid = $PID
        session_name = $SessionName
        run_label = $RunLabel
        pending_rerun = $PendingRerun
        last_change_at = $LastChangeAt.ToString('o')
        child_pid = if ($null -ne $Child -and -not $Child.HasExited) { $Child.Id } else { $null }
        child_has_exited = if ($null -ne $Child) { $Child.HasExited } else { $true }
        last_trigger_reason = $LastTriggerReason
        stop_path = $stopPath
        latest_run_pointer = (Join-Path $sessionDir 'latest_run.txt')
        baseline_snapshot_length = $BaselineSnapshot.Length
        updated_at = (Get-Date).ToUniversalTime().ToString('o')
    }
    Set-Content -LiteralPath $statePath -Value ($state | ConvertTo-Json -Depth 6)
}

function Start-SupervisorRun {
    $args = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $workflowPath,
        '-RunLabel', $RunLabel,
        '-SessionName', $SessionName,
        '-TransitionPassPackNameT4', $TransitionPassPackNameT4,
        '-TransitionPassPackNameT9', $TransitionPassPackNameT9,
        '-PriceLevel', $PriceLevel
    )
    if ($SkipBuild) {
        $args += '-SkipBuild'
    }

    $proc = Start-Process -FilePath 'powershell.exe' `
        -ArgumentList $args `
        -WorkingDirectory $scriptDir `
        -PassThru `
        -WindowStyle Hidden
    return $proc
}

$baselineSnapshot = Get-SnapshotToken
$pendingRerun = $RunOnStart.IsPresent
$lastChangeAt = Get-Date
$lastTriggerReason = if ($pendingRerun) { 'startup' } else { 'idle' }
$child = $null

Write-WatcherLog ("Watcher started. session={0} run_label={1}" -f $SessionName, $RunLabel)

try {
    while ($true) {
        if ($null -ne $child) {
            $child.Refresh()
            if ($child.HasExited) {
                Write-WatcherLog ("Supervisor run exited. pid={0} exit_code={1}" -f $child.Id, $child.ExitCode)
                $child = $null
            }
        }

        $currentSnapshot = Get-SnapshotToken
        if ($currentSnapshot -ne $baselineSnapshot) {
            $baselineSnapshot = $currentSnapshot
            $pendingRerun = $true
            $lastChangeAt = Get-Date
            $lastTriggerReason = 'source_change'
            Write-WatcherLog 'Detected source change. Queuing supervisor rerun.'
        }

        if (Test-Path -LiteralPath $stopPath) {
            if ($null -eq $child) {
                Write-WatcherLog 'Stop file detected and no child run active. Watcher exiting.'
                break
            }
            Write-WatcherLog 'Stop file detected. Waiting for active supervisor run to finish.'
        }

        if ($pendingRerun -and $null -eq $child) {
            $quietElapsed = ((Get-Date) - $lastChangeAt).TotalSeconds
            if ($quietElapsed -ge $QuietSeconds) {
                $child = Start-SupervisorRun
                $pendingRerun = $false
                Write-WatcherLog ("Started supervisor run. pid={0} reason={1}" -f $child.Id, $lastTriggerReason)
            }
        }

        Save-State -Child $child -PendingRerun $pendingRerun -LastChangeAt $lastChangeAt -BaselineSnapshot $baselineSnapshot -LastTriggerReason $lastTriggerReason
        Start-Sleep -Seconds $PollSeconds
    }
} finally {
    Save-State -Child $child -PendingRerun $pendingRerun -LastChangeAt $lastChangeAt -BaselineSnapshot $baselineSnapshot -LastTriggerReason $lastTriggerReason
}
