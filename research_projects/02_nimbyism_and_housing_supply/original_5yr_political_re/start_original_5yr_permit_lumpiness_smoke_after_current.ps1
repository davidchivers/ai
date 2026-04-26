param(
    [int]$WaitForPid = 68092,
    [double]$MaxWaitHours = 10,
    [int]$SeedK = 6
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Runner = Join-Path $ScriptDir "run_original_5yr_permit_lumpiness_smoke_after_current.ps1"

$Arguments = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$Runner`"",
    "-WaitForPid", $WaitForPid,
    "-MaxWaitHours", $MaxWaitHours,
    "-SeedK", $SeedK
)

$Process = Start-Process -FilePath "powershell.exe" -ArgumentList $Arguments -WindowStyle Hidden -PassThru

[pscustomobject]@{
    pid = $Process.Id
    runner = $Runner
    wait_for_pid = $WaitForPid
    max_wait_hours = $MaxWaitHours
    seed_k = $SeedK
}
