$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$tempDrive = Get-PSDrive -PSProvider FileSystem |
    Where-Object { $_.Free -gt 5GB } |
    Sort-Object Free -Descending |
    Select-Object -First 1
if ($null -eq $tempDrive) {
    throw "No filesystem drive with at least 5 GB free was found for launcher temp space."
}
$launcherTempRoot = Join-Path $tempDrive.Root "codex_temp\\03_fertility_and_housing_supply\\transition_benchmark_validation"
if (-not (Test-Path $launcherTempRoot)) {
    New-Item -ItemType Directory -Path $launcherTempRoot -Force | Out-Null
}
$env:TEMP = $launcherTempRoot
$env:TMP = $launcherTempRoot

$scriptPath = Join-Path $PSScriptRoot "transition_benchmark_validation_workflow.ps1"
$launcherStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$launcherStdout = Join-Path $logsRoot "transition_benchmark_validation_launcher_$launcherStamp.stdout.log"
$launcherStderr = Join-Path $logsRoot "transition_benchmark_validation_launcher_$launcherStamp.stderr.log"
$activeRunPath = Join-Path $logsRoot "active_transition_benchmark_validation.txt"

$proc = Start-Process -FilePath "powershell.exe" `
    -ArgumentList @("-ExecutionPolicy", "Bypass", "-File", $scriptPath) `
    -PassThru `
    -WindowStyle Hidden `
    -RedirectStandardOutput $launcherStdout `
    -RedirectStandardError $launcherStderr

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "pid=$($proc.Id)"
    "script=$scriptPath"
    "launcher_stdout=$launcherStdout"
    "launcher_stderr=$launcherStderr"
    "latest_pointer=$(Join-Path $logsRoot 'latest_transition_benchmark_validation.txt')"
) | Set-Content -Path $activeRunPath

Write-Output "Started transition benchmark validation workflow."
Write-Output "PID: $($proc.Id)"
Write-Output "Active run file: $activeRunPath"
