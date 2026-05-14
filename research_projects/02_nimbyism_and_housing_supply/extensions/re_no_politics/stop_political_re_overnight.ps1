Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sessionDir = Join-Path $PSScriptRoot 'truth\political_re_overnight_live'
$stopPath = Join-Path $sessionDir 'stop.txt'
$pidPath = Join-Path $sessionDir 'watcher_pid.txt'
$statePath = Join-Path $sessionDir 'watcher_state.json'

New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
Set-Content -LiteralPath $stopPath -Value ('stop_requested_at={0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$childStopped = $false
if (Test-Path -LiteralPath $statePath) {
    try {
        $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        if ($null -ne $state.child_pid) {
            $childProc = Get-Process -Id ([int]$state.child_pid) -ErrorAction SilentlyContinue
            if ($null -ne $childProc) {
                Stop-Process -Id $childProc.Id -Force
                $childStopped = $true
                Write-Output ("Stopped child process pid={0}" -f $childProc.Id)
            }
        }
    } catch {
    }
}

if (Test-Path -LiteralPath $pidPath) {
    $existingPid = Get-Content -LiteralPath $pidPath | Select-Object -First 1
    if ($existingPid) {
        $proc = Get-Process -Id ([int]$existingPid) -ErrorAction SilentlyContinue
        if ($null -ne $proc) {
            Stop-Process -Id $proc.Id -Force
            Write-Output ("Stopped watcher process pid={0}" -f $proc.Id)
            exit 0
        }
    }
}

if (-not $childStopped) {
    Write-Output 'Stop signal written. No live watcher process was found.'
} else {
    Write-Output 'Stop signal written. Child process was stopped; no live watcher process was found.'
}
