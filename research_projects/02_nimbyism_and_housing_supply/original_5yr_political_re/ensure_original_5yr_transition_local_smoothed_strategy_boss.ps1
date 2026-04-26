param(
    [double]$MaxHours = 24,
    [string]$MatlabExe = "matlab"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logPath = Join-Path $scriptDir "truth\original_5yr_transition_local_smoothed_strategy_watchdog_log.txt"

$starter = Join-Path $scriptDir "start_original_5yr_transition_local_smoothed_strategy_boss.ps1"
$liveRoot = Join-Path $scriptDir "truth\original_5yr_transition_local_smoothed_strategy_boss_live"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

function Get-StatusClassification {
    param([string]$LiveRoot)
    $statusPath = Join-Path $LiveRoot "latest_status.json"
    if (-not (Test-Path $statusPath)) {
        return $null
    }
    try {
        $status = Get-Content -Raw -Path $statusPath | ConvertFrom-Json
        return [pscustomobject]@{
            state = [string]$status.state
            current_step = [string]$status.current_step
            classification = [string]$status.payload.classification
            updated_at = [string]$status.updated_at
        }
    }
    catch {
        Write-Log "Failed to parse status file $statusPath"
        return $null
    }
}

function Test-ProcessCommandLine {
    param([string]$Pattern)
    try {
        $matches = @(
            Get-CimInstance Win32_Process -ErrorAction Stop |
                Where-Object {
                    $_.Name -match '^(powershell|pwsh)(\.exe)?$' -and
                    $_.CommandLine -like ("*" + $Pattern + "*")
                }
        )
        return ($matches.Count -gt 0)
    }
    catch {
        Write-Log "Command-line process inspection failed for pattern $Pattern"
        return $false
    }
}

Write-Log "Smooth local watchdog tick."

$pattern = "watch_original_5yr_transition_local_smoothed_strategy_boss_supervisor.ps1"
$status = Get-StatusClassification -LiveRoot $liveRoot
$hasSupervisor = Test-ProcessCommandLine -Pattern $pattern

if ($hasSupervisor) {
    Write-Log "Smooth local boss already has a live supervisor."
    return
}

if ($status -and $status.state -eq "completed" -and $status.classification -in @("queue_exhausted", "re_complete", "time_budget_reached")) {
    Write-Log "Smooth local boss is $($status.classification); not relaunching automatically."
    return
}

if ($status -and $status.state -eq "running") {
    Write-Log "Smooth local boss status says running but supervisor is missing; relaunching."
}
elseif ($status) {
    Write-Log "Smooth local boss status is $($status.state)/$($status.classification); relaunching."
}
else {
    Write-Log "Smooth local boss has no readable status; launching fresh."
}

Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $starter,
    "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $MaxHours)),
    "-MatlabExe", $MatlabExe
) -WindowStyle Hidden | Out-Null
