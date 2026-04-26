param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe",
    [double]$Sigma = 0.20,
    [double]$MaxHours = 20,
    [int]$CheckSeconds = 300
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\ghost_tail_k10_live"
}
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$statusPath = Join-Path $LiveRoot "latest_status.json"
$watchdogStatusPath = Join-Path $LiveRoot "watchdog_status.json"
$watchdogLogPath = Join-Path $LiveRoot "watchdog_log.txt"
$stopPath = Join-Path $LiveRoot "stop.txt"
$runner = Join-Path $scriptDir "run_original_5yr_ghost_tail_diagnostic.ps1"
$startedAt = Get-Date

function Write-WatchdogLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $watchdogLogPath -Value "[$timestamp] $Message"
}

function Write-WatchdogStatus {
    param(
        [string]$State,
        [string]$Message,
        [object[]]$RunnerProcesses,
        [object[]]$MatlabProcesses
    )
    [ordered]@{
        state = $State
        started_at = $startedAt.ToString("s")
        updated_at = (Get-Date).ToString("s")
        max_hours = $MaxHours
        check_seconds = $CheckSeconds
        live_root = $LiveRoot
        runner_count = @($RunnerProcesses).Count
        matlab_count = @($MatlabProcesses).Count
        message = $Message
    } | ConvertTo-Json -Depth 5 | Set-Content -Path $watchdogStatusPath
}

function Get-LiveState {
    if (-not (Test-Path $statusPath)) {
        return ""
    }
    try {
        $status = Get-Content -Path $statusPath -Raw | ConvertFrom-Json
        return [string]$status.state
    }
    catch {
        return ""
    }
}

function Find-RunnerProcesses {
    $rows = @()
    foreach ($proc in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
        $cmd = [string]$proc.CommandLine
        if (($proc.Name -match '^(powershell|pwsh)(\.exe)?$') -and
            ($cmd -like "*run_original_5yr_ghost_tail_diagnostic.ps1*") -and
            ($cmd -like ("*" + $LiveRoot + "*")) -and
            ($cmd -notlike "*Get-CimInstance Win32_Process*")) {
            $rows += $proc
        }
    }
    return $rows
}

function Find-GhostTailMatlabProcesses {
    $rows = @()
    foreach ($proc in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
        $cmd = [string]$proc.CommandLine
        if (($proc.Name -match '^(matlab|MATLAB)(\.exe)?$') -and
            (($cmd -like "*ghost_tail_k10_live*") -or ($cmd -like "*gt_k10_g*")) -and
            ($cmd -notlike "*Get-CimInstance Win32_Process*")) {
            $rows += $proc
        }
    }
    return $rows
}

function Start-GhostTailRunner {
    $stdout = Join-Path $LiveRoot ("watchdog_relaunch_stdout_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")
    $stderr = Join-Path $LiveRoot ("watchdog_relaunch_stderr_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")
    $remainingHours = [Math]::Max(1.0, $MaxHours - ((Get-Date) - $startedAt).TotalHours)
    $argList = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$runner`"",
        "-LiveRoot", "`"$LiveRoot`"",
        "-MatlabExe", "`"$MatlabExe`"",
        "-Sigma", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $Sigma)),
        "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $remainingHours))
    )
    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList $argList -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    Write-WatchdogLog "Relaunched runner pid=$($proc.Id) remaining_hours=$remainingHours stdout=$stdout stderr=$stderr"
    return $proc
}

Write-WatchdogLog "Ghost-tail watchdog started."

while ($true) {
    $elapsed = (Get-Date) - $startedAt
    $state = Get-LiveState
    $runnerProcesses = @(Find-RunnerProcesses)
    $matlabProcesses = @(Find-GhostTailMatlabProcesses)

    if (Test-Path $stopPath) {
        Write-WatchdogStatus -State "stopped" -Message "Stop file detected; watchdog exiting." -RunnerProcesses $runnerProcesses -MatlabProcesses $matlabProcesses
        Write-WatchdogLog "Stop file detected; exiting."
        break
    }

    if ($state -eq "completed") {
        Write-WatchdogStatus -State "completed" -Message "Ghost-tail queue completed; watchdog exiting." -RunnerProcesses $runnerProcesses -MatlabProcesses $matlabProcesses
        Write-WatchdogLog "Queue completed; exiting."
        break
    }

    if ($elapsed.TotalHours -gt $MaxHours) {
        Write-WatchdogStatus -State "timed_out" -Message "Watchdog max-hours reached; exiting without killing any process." -RunnerProcesses $runnerProcesses -MatlabProcesses $matlabProcesses
        Write-WatchdogLog "MaxHours reached; exiting."
        break
    }

    if ($runnerProcesses.Count -eq 0 -and $matlabProcesses.Count -eq 0) {
        Write-WatchdogStatus -State "relaunching" -Message "No runner or MATLAB process found; relaunching bounded ghost-tail queue." -RunnerProcesses $runnerProcesses -MatlabProcesses $matlabProcesses
        Start-GhostTailRunner | Out-Null
    }
    else {
        Write-WatchdogStatus -State "watching" -Message "Runner or MATLAB process is alive; no action taken." -RunnerProcesses $runnerProcesses -MatlabProcesses $matlabProcesses
    }

    Start-Sleep -Seconds $CheckSeconds
}
