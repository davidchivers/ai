param(
    [double]$MaxHours = 24,
    [string]$MatlabExe = "matlab"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$liveRoot = Join-Path $scriptDir "truth\original_5yr_transition_local_smoothed_strategy_boss_live"
New-Item -ItemType Directory -Force -Path $liveRoot | Out-Null
Remove-Item -Path (Join-Path $liveRoot "stop.txt") -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path $liveRoot "keep_awake_stop.txt") -ErrorAction SilentlyContinue

$bossProc = Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $scriptDir "watch_original_5yr_transition_local_smoothed_strategy_boss_supervisor.ps1"),
    "-LiveRoot", $liveRoot,
    "-MatlabExe", $MatlabExe,
    "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $MaxHours))
) -PassThru -WindowStyle Hidden

$keepProc = Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $scriptDir "keep_original_5yr_transition_smooth_awake.ps1"),
    "-LiveRoot", $liveRoot,
    "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $MaxHours))
) -PassThru -WindowStyle Hidden

[ordered]@{
    boss_pid = $bossProc.Id
    keep_awake_pid = $keepProc.Id
    started_at = (Get-Date).ToString("s")
    max_hours = $MaxHours
} | ConvertTo-Json | Set-Content -Path (Join-Path $liveRoot "launcher_state.json")

Write-Output ("Started local smoothed strategy boss supervisor pid=" + $bossProc.Id + " keep-awake pid=" + $keepProc.Id)
