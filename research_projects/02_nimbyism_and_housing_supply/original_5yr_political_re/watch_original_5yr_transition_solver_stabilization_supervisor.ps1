param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "matlab",
    [double]$MaxHours = 48
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_solver_stabilization_live"
}
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$statePath = Join-Path $LiveRoot "watcher_state.json"
$logPath = Join-Path $LiveRoot "watcher_log.txt"
$stopPath = Join-Path $LiveRoot "stop.txt"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

function Write-State {
    param([string]$State, [string]$RunDir = "")
    [ordered]@{
        state = $State
        run_dir = $RunDir
        updated_at = (Get-Date).ToString("s")
    } | ConvertTo-Json -Depth 4 | Set-Content -Path $statePath
}

Write-Log "Solver-stabilization supervisor started."
Write-State -State "idle"

do {
    if (Test-Path $stopPath) {
        Write-Log "Stop file detected. Exiting supervisor."
        Write-State -State "stopped"
        break
    }

    Write-Log "Launching solver-stabilization workflow run."
    $proc = Start-Process powershell -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", (Join-Path $scriptDir "run_original_5yr_transition_solver_stabilization_overnight.ps1"),
        "-LiveRoot", $LiveRoot,
        "-MatlabExe", $MatlabExe,
        "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $MaxHours))
    ) -PassThru -WindowStyle Hidden
    Write-State -State "running" -RunDir ""

    $proc.WaitForExit()
    $latestStatus = Join-Path $LiveRoot "latest_status.json"
    if (Test-Path $latestStatus) {
        $status = Get-Content -Raw -Path $latestStatus | ConvertFrom-Json
        Write-State -State $status.state -RunDir $status.run_dir
        Write-Log "Workflow exited with state $($status.state)."
        $classification = ""
        if ($status.payload -and $status.payload.classification) {
            $classification = [string]$status.payload.classification
        }
        if ($status.state -eq "completed" -and $classification -eq "time_budget_reached") {
            Write-Log "Workflow hit time budget; relaunching after short pause."
            Start-Sleep -Seconds 10
            continue
        }
        if ($status.state -in @("completed", "blocked")) {
            break
        }
    } else {
        Write-State -State "failed"
        Write-Log "Workflow exited without a status file."
    }

    Start-Sleep -Seconds 10
}
while ($true)
