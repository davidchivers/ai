param(
    [string]$LiveRoot = "",
    [int]$PollSeconds = 120,
    [double]$RunnerMaxHours = 24,
    [double]$SupervisorMaxHours = 48
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_smoothed_tail_fail_safe_live"
}

$supervisorScript = Join-Path $scriptDir "watch_original_5yr_transition_smoothed_tail_fail_safe_supervisor.ps1"

function Find-SupervisorProcesses {
    $escapedLiveRoot = [regex]::Escape($LiveRoot)
    $escapedSupervisor = [regex]::Escape($supervisorScript)
    $liveRootPattern = '(?i)(?:^|\s)-LiveRoot\s+"?' + $escapedLiveRoot + '(?:"|\s|$)'
    try {
        return @(
            Get-CimInstance Win32_Process -ErrorAction Stop |
                Where-Object {
                    $_.Name -match '^(powershell|pwsh)(\.exe)?$' -and
                    $_.CommandLine -match $escapedSupervisor -and
                    $_.CommandLine -match $liveRootPattern
                }
        )
    }
    catch {
        return @()
    }
}

$existing = @(Find-SupervisorProcesses)
if ($existing.Count -gt 0) {
    [ordered]@{
        action = "already_running"
        live_root = $LiveRoot
        supervisor_pids = @($existing | ForEach-Object { $_.ProcessId })
    } | ConvertTo-Json -Depth 4
    exit 0
}

$proc = Start-Process -FilePath "powershell.exe" `
    -ArgumentList @(
        "-ExecutionPolicy", "Bypass",
        "-File", $supervisorScript,
        "-LiveRoot", $LiveRoot,
        "-PollSeconds", $PollSeconds,
        "-RunnerMaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:G17}", $RunnerMaxHours)),
        "-SupervisorMaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:G17}", $SupervisorMaxHours))
    ) `
    -WindowStyle Hidden `
    -PassThru

[ordered]@{
    action = "started"
    live_root = $LiveRoot
    supervisor_pid = $proc.Id
} | ConvertTo-Json -Depth 4
