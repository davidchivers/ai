$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$liveRoot = Join-Path $scriptDir "truth\original_5yr_political_re_live"
New-Item -ItemType Directory -Force -Path $liveRoot | Out-Null
Remove-Item -Path (Join-Path $liveRoot "stop.txt") -ErrorAction SilentlyContinue

$proc = Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $scriptDir "watch_original_5yr_political_re_supervisor.ps1"),
    "-RunOnStart"
) -PassThru -WindowStyle Hidden

[ordered]@{
    pid = $proc.Id
    started_at = (Get-Date).ToString("s")
} | ConvertTo-Json | Set-Content -Path (Join-Path $liveRoot "launcher_state.json")

Write-Output ("Started original 5-year political RE supervisor pid=" + $proc.Id)
