param(
    [string]$RunLabel = "bellman_re_nano_wall_12_hour_workflow",
    [double]$TimeoutHours = 12,
    [string]$SeedQPathCsv = "1.7303548376,1.7483599506,1.7525998970,2.1532712772",
    [string]$SeedLabel = "nano wall",
    [string]$CanonicalNoteName = "",
    [double]$ImprovementTolerance = 1.0e-8
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$scriptPath = Join-Path $PSScriptRoot "bellman_re_nano_wall_12_hour_workflow.ps1"
$launcherStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$launcherStdout = Join-Path $logsRoot "${RunLabel}_launcher_$launcherStamp.stdout.log"
$launcherStderr = Join-Path $logsRoot "${RunLabel}_launcher_$launcherStamp.stderr.log"
$activeRunPath = Join-Path $logsRoot ("active_{0}.txt" -f $RunLabel)

$argumentList = @(
    "-ExecutionPolicy", "Bypass",
    "-File", $scriptPath,
    "-RunLabel", $RunLabel,
    "-TimeoutHours", "$TimeoutHours",
    "-SeedQPathCsv", $SeedQPathCsv,
    "-SeedLabel", $SeedLabel,
    "-ImprovementTolerance", "$ImprovementTolerance"
)
if (-not [string]::IsNullOrWhiteSpace($CanonicalNoteName)) {
    $argumentList += @("-CanonicalNoteName", $CanonicalNoteName)
}

$proc = Start-Process -FilePath "powershell.exe" `
    -ArgumentList $argumentList `
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
    "latest_pointer=$(Join-Path $logsRoot ('latest_{0}.txt' -f $RunLabel))"
) | Set-Content -Path $activeRunPath

Write-Output "Started Bellman RE workflow."
Write-Output "PID: $($proc.Id)"
Write-Output "Active run file: $activeRunPath"
