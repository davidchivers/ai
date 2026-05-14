$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$liveRoot = Join-Path $scriptDir "truth\original_5yr_transition_solver_stabilization_live"
New-Item -ItemType Directory -Force -Path $liveRoot | Out-Null
Set-Content -Path (Join-Path $liveRoot "keep_awake_stop.txt") -Value ((Get-Date).ToString("s"))
Write-Output "Requested stop for original 5-year transition solver keep-awake helper."
