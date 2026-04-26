param(
    [string]$LiveRoot = "",
    [string]$RunnerScript = "",
    [int]$PollSeconds = 120,
    [double]$RunnerMaxHours = 24,
    [double]$SupervisorMaxHours = 48
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_smoothed_tail_fail_safe_live"
}
if ([string]::IsNullOrWhiteSpace($RunnerScript)) {
    $RunnerScript = Join-Path $scriptDir "run_original_5yr_transition_smoothed_tail_fail_safe.ps1"
}

New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$stopPath = Join-Path $LiveRoot "stop.txt"
$finalResultPath = Join-Path $LiveRoot "final_result.json"
$statusPath = Join-Path $LiveRoot "supervisor_status.json"
$logPath = Join-Path $LiveRoot "supervisor_log.txt"
$startedAt = Get-Date

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

function Write-Status {
    param(
        [string]$State,
        [string]$Message,
        [int[]]$RunnerPids = @()
    )

    [ordered]@{
        state = $State
        updated_at = (Get-Date).ToString("s")
        started_at = $startedAt.ToString("s")
        live_root = $LiveRoot
        runner_script = $RunnerScript
        runner_pids = $RunnerPids
        message = $Message
    } | ConvertTo-Json -Depth 5 | Set-Content -Path $statusPath
}

function Find-RunnerProcesses {
    $escapedLiveRoot = [regex]::Escape($LiveRoot)
    $escapedRunner = [regex]::Escape($RunnerScript)
    $liveRootPattern = '(?i)(?:^|\s)-LiveRoot\s+"?' + $escapedLiveRoot + '(?:"|\s|$)'
    try {
        return @(
            Get-CimInstance Win32_Process -ErrorAction Stop |
                Where-Object {
                    $_.Name -match '^(powershell|pwsh)(\.exe)?$' -and
                    $_.CommandLine -match $escapedRunner -and
                    $_.CommandLine -match $liveRootPattern
                }
        )
    }
    catch {
        return @()
    }
}

function Start-Runner {
    $proc = Start-Process -FilePath "powershell.exe" `
        -ArgumentList @(
            "-ExecutionPolicy", "Bypass",
            "-File", $RunnerScript,
            "-LiveRoot", $LiveRoot,
            "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:G17}", $RunnerMaxHours))
        ) `
        -WindowStyle Hidden `
        -PassThru
    Write-Log "Launched fail-safe runner pid=$($proc.Id)"
    return $proc.Id
}

Write-Log "Smoothed tail fail-safe supervisor started."
Write-Status -State "running" -Message "Supervisor started; watching fail-safe runner."

while ($true) {
    if ((Get-Date) - $startedAt -gt [TimeSpan]::FromHours($SupervisorMaxHours)) {
        Write-Log "Supervisor max hours reached."
        Write-Status -State "completed" -Message "Supervisor max hours reached; exiting."
        break
    }

    if (Test-Path $stopPath) {
        Write-Log "Stop file detected."
        Write-Status -State "stopped" -Message "Stop file detected; supervisor exiting."
        break
    }

    if (Test-Path $finalResultPath) {
        Write-Log "Final result detected; supervisor exiting without relaunch."
        Write-Status -State "completed" -Message "Fail-safe runner finished and wrote final_result.json."
        break
    }

    $runnerProcs = @(Find-RunnerProcesses)
    if ($runnerProcs.Count -eq 0) {
        $runnerPid = Start-Runner
        Write-Status -State "running" -Message "Fail-safe runner was missing; relaunched hidden." -RunnerPids @($runnerPid)
        Start-Sleep -Seconds 10
    }
    else {
        Write-Status -State "running" -Message "Fail-safe runner is alive." -RunnerPids @($runnerProcs | ForEach-Object { $_.ProcessId })
    }

    Start-Sleep -Seconds $PollSeconds
}

Write-Log "Smoothed tail fail-safe supervisor finished."
