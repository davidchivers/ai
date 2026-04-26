param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe",
    [double]$MaxHours = 18
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\entrant_survival_hard_local_queue_live"
}
$runner = Join-Path $scriptDir "run_original_5yr_entrant_survival_hard_local_queue.ps1"

$existing = @(
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match '^(powershell|pwsh)(\.exe)?$' -and
            ([string]$_.CommandLine) -like ("*" + $runner + "*") -and
            ([string]$_.CommandLine) -like ("*" + $LiveRoot + "*")
        }
)

if ($existing.Count -gt 0) {
    [ordered]@{
        action = "already_running"
        live_root = $LiveRoot
        pids = @($existing | ForEach-Object { $_.ProcessId })
    } | ConvertTo-Json -Depth 4
    exit 0
}

$proc = Start-Process -FilePath "powershell.exe" -ArgumentList @(
    "-ExecutionPolicy", "Bypass",
    "-File", $runner,
    "-LiveRoot", $LiveRoot,
    "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:G17}", $MaxHours))
) -WindowStyle Hidden -PassThru

[ordered]@{
    action = "started"
    live_root = $LiveRoot
    runner_pid = $proc.Id
} | ConvertTo-Json -Depth 4
