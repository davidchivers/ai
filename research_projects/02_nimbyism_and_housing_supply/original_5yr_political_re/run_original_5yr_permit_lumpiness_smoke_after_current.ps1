param(
    [int]$WaitForPid = 68092,
    [double]$MaxWaitHours = 10,
    [int]$SeedK = 6
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LiveDir = Join-Path $ScriptDir "truth\permit_lumpiness_smoke_live"
$RunTag = "local_permit_lumpiness_k$($SeedK)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$StatusPath = Join-Path $LiveDir "latest_status.json"
$MatlabLog = Join-Path $LiveDir "$($RunTag)_matlab.log"

New-Item -ItemType Directory -Force -Path $LiveDir | Out-Null

function Write-Status {
    param(
        [string]$State,
        [string]$Message,
        [int]$PidValue = $WaitForPid
    )
    [pscustomobject]@{
        state = $State
        message = $Message
        run_tag = $RunTag
        seed_k = $SeedK
        wait_for_pid = $PidValue
        updated_at = (Get-Date).ToString("o")
        matlab_log = $MatlabLog
    } | ConvertTo-Json -Depth 4 | Set-Content -Path $StatusPath
}

Write-Status -State "waiting" -Message "Waiting for current MATLAB run to exit before permit lumpiness smoke."

$Deadline = (Get-Date).AddHours($MaxWaitHours)
while ((Get-Date) -lt $Deadline) {
    $Process = Get-Process -Id $WaitForPid -ErrorAction SilentlyContinue
    if ($null -eq $Process) {
        break
    }
    Write-Status -State "waiting" -Message "Current MATLAB run still active; permit lumpiness smoke is queued."
    Start-Sleep -Seconds 60
}

$StillRunning = Get-Process -Id $WaitForPid -ErrorAction SilentlyContinue
if ($null -ne $StillRunning) {
    Write-Status -State "skipped" -Message "Smoke skipped because the current MATLAB run did not finish before the wait limit."
    exit 0
}

Write-Status -State "running" -Message "Starting permit lumpiness smoke."

$MatlabCmd = "cd('$($ScriptDir.Replace('\','/'))'); audit_original_5yr_political_permit_lumpiness_smoke($SeedK, '$RunTag');"
try {
    & matlab -batch $MatlabCmd *> $MatlabLog
    if ($LASTEXITCODE -eq 0) {
        Write-Status -State "completed" -Message "Permit lumpiness smoke completed."
    } else {
        Write-Status -State "failed" -Message "MATLAB exited with code $LASTEXITCODE."
        exit $LASTEXITCODE
    }
} catch {
    Write-Status -State "failed" -Message $_.Exception.Message
    throw
}
