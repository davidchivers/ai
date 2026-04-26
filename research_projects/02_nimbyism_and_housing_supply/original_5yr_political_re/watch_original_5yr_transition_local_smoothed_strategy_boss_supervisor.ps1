param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "matlab",
    [double]$MaxHours = 24
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_local_smoothed_strategy_boss_live"
}
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$statePath = Join-Path $LiveRoot "supervisor_state.json"
$logPath = Join-Path $LiveRoot "supervisor_log.txt"
$stopPath = Join-Path $LiveRoot "stop.txt"
$startedAt = Get-Date

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

function Write-State {
    param([string]$State)
    [ordered]@{
        state = $State
        updated_at = (Get-Date).ToString("s")
    } | ConvertTo-Json -Depth 4 | Set-Content -Path $statePath
}

Write-Log "Local smoothed strategy boss supervisor started."
Write-State -State "idle"

do {
    if (Test-Path $stopPath) {
        Write-Log "Stop file detected. Exiting supervisor."
        Write-State -State "stopped"
        break
    }

    if (((Get-Date) - $startedAt).TotalHours -gt $MaxHours) {
        Write-Log "Supervisor max-hours reached."
        Write-State -State "completed"
        break
    }

    $proc = Start-Process powershell -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", (Join-Path $scriptDir "run_original_5yr_transition_local_smoothed_strategy_boss.ps1"),
        "-LiveRoot", $LiveRoot,
        "-MatlabExe", $MatlabExe,
        "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $MaxHours))
    ) -PassThru -WindowStyle Hidden

    Write-State -State "running"
    Write-Log "Launched smoothed local boss pid=$($proc.Id)"
    $proc.WaitForExit()

    $latestStatus = Join-Path $LiveRoot "latest_status.json"
    if (-not (Test-Path $latestStatus)) {
        Write-Log "Smoothed local boss exited without latest_status.json; relaunching."
        Start-Sleep -Seconds 10
        continue
    }

    $status = Get-Content -Raw -Path $latestStatus | ConvertFrom-Json
    $classification = [string]$status.payload.classification
    Write-Log "Smoothed local boss exited with classification $classification"
    if ($status.state -eq "completed" -and $classification -in @("re_complete", "time_budget_reached", "queue_exhausted")) {
        Write-State -State "completed"
        break
    }

    Start-Sleep -Seconds 10
}
while ($true)
