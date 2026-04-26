param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe",
    [double]$Sigma = 0.20,
    [double]$MaxHours = 24
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\entrant_survival_smooth_probe_local_queue_live"
}
$runner = Join-Path $scriptDir "run_original_5yr_entrant_survival_smooth_local_queue.ps1"
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null
$stdoutPath = Join-Path $LiveRoot "runner_stdout.log"
$stderrPath = Join-Path $LiveRoot "runner_stderr.log"

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
    "-Sigma", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:G17}", $Sigma)),
    "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:G17}", $MaxHours))
) -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru

[ordered]@{
    action = "started"
    live_root = $LiveRoot
    sigma = $Sigma
    runner_pid = $proc.Id
    stdout = $stdoutPath
    stderr = $stderrPath
} | ConvertTo-Json -Depth 4
