param(
    [double]$MaxHours = 48
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$liveRoot = Join-Path $scriptDir "truth\original_5yr_transition_solver_stabilization_live"
New-Item -ItemType Directory -Force -Path $liveRoot | Out-Null
Remove-Item -Path (Join-Path $liveRoot "keep_awake_stop.txt") -ErrorAction SilentlyContinue

$proc = Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $scriptDir "keep_original_5yr_transition_solver_awake.ps1"),
    "-LiveRoot", $liveRoot,
    "-MaxHours", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $MaxHours))
) -PassThru -WindowStyle Hidden

[ordered]@{
    pid = $proc.Id
    started_at = (Get-Date).ToString("s")
    max_hours = $MaxHours
} | ConvertTo-Json | Set-Content -Path (Join-Path $liveRoot "keep_awake_launcher_state.json")

Write-Output ("Started original 5-year transition solver keep-awake helper pid=" + $proc.Id)
