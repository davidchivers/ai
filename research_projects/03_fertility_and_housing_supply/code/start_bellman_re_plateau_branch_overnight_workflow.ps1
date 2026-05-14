param(
    [string]$RunLabel = "bellman_re_plateau_branch_overnight_workflow",
    [double]$TimeoutHours = 12,
    [string]$SeedQPathCsv = "1.7294173376,1.7473345599,1.7525985237,2.1526853397",
    [string]$SeedLabel = "bridge plateau",
    [string]$CanonicalNoteName = "compiled_sidecar_bellman_re_plateau_branch_overnight_packet.md",
    [double]$ImprovementTolerance = 1.0e-10
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$scriptPath = Join-Path $PSScriptRoot "bellman_re_plateau_branch_overnight_workflow.ps1"
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
    "-CanonicalNoteName", $CanonicalNoteName,
    "-ImprovementTolerance", "$ImprovementTolerance"
)

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

Write-Output "Started Bellman RE plateau-branch overnight workflow."
Write-Output "PID: $($proc.Id)"
Write-Output "Active run file: $activeRunPath"
