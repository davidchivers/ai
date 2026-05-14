$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$scriptPath = Join-Path $PSScriptRoot "annual_owner_finance_overnight_workflow.ps1"
$launcherStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$launcherStdout = Join-Path $logsRoot "annual_owner_finance_parallel_launcher_$launcherStamp.stdout.log"
$launcherStderr = Join-Path $logsRoot "annual_owner_finance_parallel_launcher_$launcherStamp.stderr.log"
$activeRunPath = Join-Path $logsRoot "active_annual_owner_finance_parallel.txt"

$financeArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-File", $scriptPath,
    "-StartAtStep", "1",
    "-EndAtStep", "1",
    "-RunLabel", "annual_finance_confirm",
    "-Step1TimeoutHours", "9"
)

$reanchorArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-File", $scriptPath,
    "-StartAtStep", "2",
    "-EndAtStep", "2",
    "-RunLabel", "annual_joint_reanchor_confirm",
    "-Step2TimeoutHours", "7"
)

$financeStdout = Join-Path $logsRoot "annual_finance_confirm_launcher_$launcherStamp.stdout.log"
$financeStderr = Join-Path $logsRoot "annual_finance_confirm_launcher_$launcherStamp.stderr.log"
$reanchorStdout = Join-Path $logsRoot "annual_joint_reanchor_confirm_launcher_$launcherStamp.stdout.log"
$reanchorStderr = Join-Path $logsRoot "annual_joint_reanchor_confirm_launcher_$launcherStamp.stderr.log"

$financeProc = Start-Process -FilePath "powershell.exe" `
    -ArgumentList $financeArgs `
    -PassThru `
    -WindowStyle Hidden `
    -RedirectStandardOutput $financeStdout `
    -RedirectStandardError $financeStderr

$reanchorProc = Start-Process -FilePath "powershell.exe" `
    -ArgumentList $reanchorArgs `
    -PassThru `
    -WindowStyle Hidden `
    -RedirectStandardOutput $reanchorStdout `
    -RedirectStandardError $reanchorStderr

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "launcher_stdout=$launcherStdout"
    "launcher_stderr=$launcherStderr"
    "finance_pid=$($financeProc.Id)"
    "finance_active_pointer=$(Join-Path $logsRoot 'active_annual_finance_confirm.txt')"
    "finance_latest_pointer=$(Join-Path $logsRoot 'latest_annual_finance_confirm.txt')"
    "reanchor_pid=$($reanchorProc.Id)"
    "reanchor_active_pointer=$(Join-Path $logsRoot 'active_annual_joint_reanchor_confirm.txt')"
    "reanchor_latest_pointer=$(Join-Path $logsRoot 'latest_annual_joint_reanchor_confirm.txt')"
) | Set-Content -Path $activeRunPath

Write-Output "Started parallel annual owner-finance overnight workflow."
Write-Output "Finance lane PID: $($financeProc.Id)"
Write-Output "Re-anchor lane PID: $($reanchorProc.Id)"
Write-Output "Parallel active run file: $activeRunPath"
