$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $thisDir 'workflow_logs'
$queueLog = Join-Path $logDir 'candidate_selection_followup_queue.log'
$runner = Join-Path $thisDir 'run_transition_re_candidate_selection_followup.ps1'

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

function Write-QueueLog {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $queueLog -Value "[$timestamp] $Message"
}

function Get-BatchMatlabProcesses {
    Get-CimInstance Win32_Process |
        Where-Object {
            ($_.Name -ieq 'MATLAB.exe' -or $_.Name -ieq 'matlab.exe') -and
            $_.CommandLine -and
            $_.CommandLine -match '-batch'
        }
}

Write-QueueLog 'Queue watcher started.'

while ($true) {
    $batchMatlab = Get-BatchMatlabProcesses |
        Where-Object { $_.ProcessId -ne $PID }

    if (-not $batchMatlab) {
        Write-QueueLog 'No active batch MATLAB processes detected. Starting candidate-selection follow-up.'
        break
    }

    $summary = ($batchMatlab | Select-Object -ExpandProperty ProcessId) -join ', '
    Write-QueueLog "Waiting for batch MATLAB processes: $summary"
    Start-Sleep -Seconds 120
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runner

Write-QueueLog 'Queue watcher finished.'
