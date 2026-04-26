param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "C:\Program Files\MATLAB\R2025b\bin\matlab.exe",
    [double]$Sigma = 0.20,
    [double]$MaxHours = 18
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\ghost_tail_k10_live"
}
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$runner = Join-Path $scriptDir "run_original_5yr_ghost_tail_diagnostic.ps1"
$stdout = Join-Path $LiveRoot "runner_stdout.log"
$stderr = Join-Path $LiveRoot "runner_stderr.log"
$argList = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$runner`"",
    "-LiveRoot", "`"$LiveRoot`"",
    "-MatlabExe", "`"$MatlabExe`"",
    "-Sigma", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $Sigma)),
    "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $MaxHours))
)

$proc = Start-Process -FilePath "powershell.exe" -ArgumentList $argList -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
[ordered]@{
    state = "launched"
    launched_at = (Get-Date).ToString("s")
    pid = $proc.Id
    live_root = $LiveRoot
    stdout = $stdout
    stderr = $stderr
} | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $LiveRoot "launcher_status.json")

Write-Output "Launched ghost-tail diagnostic pid=$($proc.Id)"
Write-Output "Live root: $LiveRoot"
