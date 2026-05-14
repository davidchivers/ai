param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "matlab",
    [double]$MaxHours = 24
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_re_24h_boss_live"
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

Write-Log "24-hour RE boss supervisor started."
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
        "-File", (Join-Path $scriptDir "run_original_5yr_transition_re_24h_boss.ps1"),
        "-LiveRoot", $LiveRoot,
        "-MatlabExe", $MatlabExe,
        "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $MaxHours))
    ) -PassThru -WindowStyle Hidden

    Write-State -State "running"
    Write-Log "Launched boss pid=$($proc.Id)"
    $proc.WaitForExit()

    $latestStatus = Join-Path $LiveRoot "latest_status.json"
    if (-not (Test-Path $latestStatus)) {
        Write-Log "Boss exited without latest_status.json; relaunching."
        Start-Sleep -Seconds 10
        continue
    }

    $status = Get-Content -Raw -Path $latestStatus | ConvertFrom-Json
    Write-Log "Boss exited with classification $($status.payload.classification)"
    if ($status.state -eq "completed" -and $status.payload.classification -in @("re_complete", "time_budget_reached")) {
        Write-State -State "completed"
        break
    }
    if ($status.payload.classification -eq "queue_exhausted") {
        Write-Log "Queue exhausted; relaunching boss with resumed best state."
    }

    Start-Sleep -Seconds 10
}
while ($true)
