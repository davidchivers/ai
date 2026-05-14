$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$liveRoot = Join-Path $scriptDir "truth\original_5yr_political_re_live"
New-Item -ItemType Directory -Force -Path $liveRoot | Out-Null
Set-Content -Path (Join-Path $liveRoot "reporter_stop.txt") -Value "stop"
Write-Output "Stop requested for original 5-year political RE reporter."
