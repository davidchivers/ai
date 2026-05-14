Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sessionDir = Join-Path $PSScriptRoot 'truth\political_bellman_compiled_supervisor_live'
$pidPath = Join-Path $sessionDir 'watcher_pid.txt'
$stopPath = Join-Path $sessionDir 'stop.txt'

New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
Set-Content -LiteralPath $stopPath -Value 'stop'

$stopped = $false
if (Test-Path -LiteralPath $pidPath) {
    $existingPid = Get-Content -LiteralPath $pidPath | Select-Object -First 1
    if ($existingPid) {
        $proc = Get-Process -Id ([int]$existingPid) -ErrorAction SilentlyContinue
        if ($null -ne $proc) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            $stopped = $true
        }
    }
}

if ($stopped) {
    Write-Output 'Stopped political Bellman compiled supervisor watcher.'
} else {
    Write-Output 'Wrote stop file for political Bellman compiled supervisor watcher.'
}
