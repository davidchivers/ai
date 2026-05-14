param(
    [int]$PollSeconds = 20,
    [int]$RestartDelaySeconds = 30,
    [double]$MaxHours = 10.0,
    [int]$MaxRestarts = 3,
    [string]$SessionName = 'political_re_overnight_live',
    [string]$RunLabel = 'political_re_overnight',
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
$activePointer = Join-Path $sessionDir 'active_run.txt'
$latestPointer = Join-Path $sessionDir 'latest_run.txt'
$workflowPath = Join-Path $scriptDir 'political_re_overnight_workflow.ps1'
$watcherStart = Get-Date
$deadline = $watcherStart.AddHours($MaxHours)

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

function Save-State {
    param(
        [System.Diagnostics.Process]$Child,
        [int]$RestartCount,
        [string]$Status,
        [string]$LastNote,
        [object]$LastExitCode
    )

    $state = [ordered]@{
        watcher_pid = $PID
        session_name = $SessionName
        run_label = $RunLabel
        status = $Status
        restart_count = $RestartCount
        max_restarts = $MaxRestarts
        started_at = $watcherStart.ToUniversalTime().ToString('o')
        deadline_at = $deadline.ToUniversalTime().ToString('o')
        child_pid = if ($null -ne $Child -and -not $Child.HasExited) { $Child.Id } else { $null }
        child_has_exited = if ($null -ne $Child) { $Child.HasExited } else { $true }
        last_exit_code = if ($null -ne $LastExitCode) { [int]$LastExitCode } else { $null }
        last_note = $LastNote
        latest_run_pointer = $latestPointer
        active_run_pointer = $activePointer
        stop_path = $stopPath
        updated_at = (Get-Date).ToUniversalTime().ToString('o')
    }
    Set-Content -LiteralPath $statePath -Value ($state | ConvertTo-Json -Depth 6)
}

function Start-OvernightRun {
    $args = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $workflowPath,
        '-RunLabel', $RunLabel,
        '-SessionName', $SessionName,
        '-MaxHours', $MaxHours
    )

    $proc = Start-Process -FilePath 'powershell.exe' `
        -ArgumentList $args `
        -WorkingDirectory $scriptDir `
        -PassThru `
        -WindowStyle Hidden
    return $proc
}

$restartCount = 0
$lastNote = if ($RunOnStart) { 'startup launch pending' } else { 'idle; waiting for manual intervention' }
$lastExitCode = $null
$status = if ($RunOnStart) { 'starting' } else { 'idle' }
$child = $null

Write-WatcherLog ("Overnight watcher started. session={0} run_label={1} max_hours={2}" -f $SessionName, $RunLabel, $MaxHours)

try {
    if ($RunOnStart) {
        $child = Start-OvernightRun
        $status = 'running'
        $lastNote = ("started overnight run pid={0}" -f $child.Id)
        Write-WatcherLog $lastNote
    }

    while ($true) {
        if ((Get-Date) -ge $deadline) {
            if ($null -ne $child) {
                $child.Refresh()
                if (-not $child.HasExited) {
                    Stop-Process -Id $child.Id -Force -ErrorAction SilentlyContinue
                    Write-WatcherLog ("Deadline reached. Stopped child pid={0}" -f $child.Id)
                }
            }
            $status = 'deadline_reached'
            $lastNote = 'Stopped because the overnight time budget was exhausted.'
            break
        }

        if (Test-Path -LiteralPath $stopPath) {
            if ($null -ne $child) {
                $child.Refresh()
                if (-not $child.HasExited) {
                    Stop-Process -Id $child.Id -Force -ErrorAction SilentlyContinue
                    Write-WatcherLog ("Stop requested. Stopped child pid={0}" -f $child.Id)
                }
            }
            $status = 'stopped'
            $lastNote = 'Stop file detected.'
            break
        }

        if ($null -ne $child) {
            $child.Refresh()
            if ($child.HasExited) {
                $lastExitCode = $child.ExitCode
                Write-WatcherLog ("Overnight run exited. pid={0} exit_code={1}" -f $child.Id, $child.ExitCode)
                $child = $null
                if ($lastExitCode -eq 0) {
                    $status = 'success'
                    $lastNote = 'Overnight milestone chain completed successfully.'
                    break
                }

                if ($restartCount -ge $MaxRestarts) {
                    $status = 'failed'
                    $lastNote = ("Reached restart cap after exit code {0}." -f $lastExitCode)
                    break
                }

                $restartCount += 1
                Write-WatcherLog ("Restarting overnight run after failure. restart={0}/{1}" -f $restartCount, $MaxRestarts)
                Start-Sleep -Seconds $RestartDelaySeconds
                $child = Start-OvernightRun
                $status = 'running'
                $lastNote = ("restarted overnight run pid={0}" -f $child.Id)
                Write-WatcherLog $lastNote
            }
        }

        Save-State -Child $child -RestartCount $restartCount -Status $status -LastNote $lastNote -LastExitCode $lastExitCode
        Start-Sleep -Seconds $PollSeconds
    }
} finally {
    Save-State -Child $child -RestartCount $restartCount -Status $status -LastNote $lastNote -LastExitCode $lastExitCode
}

exit 0
