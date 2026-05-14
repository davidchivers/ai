Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'watch_political_bellman_compiled_supervisor.ps1'
$sessionDir = Join-Path $PSScriptRoot 'truth\political_bellman_compiled_supervisor_live'
$pidPath = Join-Path $sessionDir 'watcher_pid.txt'
$stopPath = Join-Path $sessionDir 'stop.txt'

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Watcher script not found: $scriptPath"
}

if (Test-Path -LiteralPath $pidPath) {
    $existingPid = Get-Content -LiteralPath $pidPath | Select-Object -First 1
    if ($existingPid) {
        $proc = Get-Process -Id ([int]$existingPid) -ErrorAction SilentlyContinue
        if ($null -ne $proc) {
            Write-Output ("Watcher already running. pid={0}" -f $proc.Id)
            exit 0
        }
    }
}

if (Test-Path -LiteralPath $stopPath) {
    Remove-Item -LiteralPath $stopPath -Force
}

Start-Process -FilePath 'powershell.exe' `
    -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $scriptPath,
        '-RunOnStart'
    ) `
    -WorkingDirectory $PSScriptRoot `
    -WindowStyle Hidden | Out-Null

Write-Output 'Started political Bellman compiled supervisor watcher.'
