Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sessionDir = Join-Path $PSScriptRoot 'truth\house_price_compiled_supervisor_live'
$stopPath = Join-Path $sessionDir 'stop.txt'
$pidPath = Join-Path $sessionDir 'watcher_pid.txt'

New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
Set-Content -LiteralPath $stopPath -Value ('stop_requested_at={0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

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

Write-Output 'Stop signal written. No live watcher process was found.'
