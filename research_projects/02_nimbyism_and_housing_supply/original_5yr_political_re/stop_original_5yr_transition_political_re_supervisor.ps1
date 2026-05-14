$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$liveRoot = Join-Path $scriptDir "truth\original_5yr_transition_political_live"
New-Item -ItemType Directory -Force -Path $liveRoot | Out-Null
Set-Content -Path (Join-Path $liveRoot "stop.txt") -Value "stop"
Write-Output "Requested stop for original 5-year transition political RE supervisor."
