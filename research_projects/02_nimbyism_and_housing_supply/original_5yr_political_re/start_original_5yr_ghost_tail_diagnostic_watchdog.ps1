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

foreach ($proc in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
    $cmd = [string]$proc.CommandLine
    if (($proc.Name -match '^(powershell|pwsh)(\.exe)?$') -and
        ($cmd -like "*watch_original_5yr_ghost_tail_diagnostic.ps1*") -and
        ($cmd -like ("*" + $LiveRoot + "*")) -and
        ($cmd -notlike "*Get-CimInstance Win32_Process*")) {
        Write-Output "Ghost-tail watchdog already running pid=$($proc.ProcessId)"
        Write-Output "Live root: $LiveRoot"
        return
    }
}

$watchdog = Join-Path $scriptDir "watch_original_5yr_ghost_tail_diagnostic.ps1"
$stdout = Join-Path $LiveRoot "watchdog_stdout.log"
$stderr = Join-Path $LiveRoot "watchdog_stderr.log"
$argList = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$watchdog`"",
    "-LiveRoot", "`"$LiveRoot`"",
    "-MatlabExe", "`"$MatlabExe`"",
    "-Sigma", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $Sigma)),
    "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $MaxHours)),
    "-CheckSeconds", $CheckSeconds.ToString()
)

$proc = Start-Process -FilePath "powershell.exe" -ArgumentList $argList -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
[ordered]@{
    state = "launched"
    launched_at = (Get-Date).ToString("s")
    pid = $proc.Id
    live_root = $LiveRoot
    stdout = $stdout
    stderr = $stderr
    max_hours = $MaxHours
    check_seconds = $CheckSeconds
} | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $LiveRoot "watchdog_launcher_status.json")

Write-Output "Launched ghost-tail watchdog pid=$($proc.Id)"
Write-Output "Live root: $LiveRoot"
