param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "matlab",
    [switch]$RunOnStart
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_political_re_live"
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

Write-Log "Supervisor started."
Write-State -State "idle"

do {
    if (Test-Path $stopPath) {
        Write-Log "Stop file detected. Exiting supervisor."
        Write-State -State "stopped"
        break
    }

    Write-Log "Launching workflow run."
    $proc = Start-Process powershell -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", (Join-Path $scriptDir "run_original_5yr_political_re_workflow.ps1"),
        "-LiveRoot", $LiveRoot,
        "-MatlabExe", $MatlabExe
    ) -PassThru -WindowStyle Hidden
    Write-State -State "running" -RunDir ""

    $proc.WaitForExit()
    $latestStatus = Join-Path $LiveRoot "latest_status.json"
    if (Test-Path $latestStatus) {
        $status = Get-Content -Raw -Path $latestStatus | ConvertFrom-Json
        Write-State -State $status.state -RunDir $status.run_dir
        Write-Log "Workflow exited with state $($status.state)."
        if ($status.state -eq "completed") {
            break
        }
    } else {
        Write-State -State "failed"
        Write-Log "Workflow exited without a status file."
    }

    Start-Sleep -Seconds 10
}
while ($true)
