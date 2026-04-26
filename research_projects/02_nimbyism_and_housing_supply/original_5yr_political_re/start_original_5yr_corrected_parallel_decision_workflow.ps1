param(
    [string]$RunTag = "local_corrected_s020_flat_k4_10_i1"
)

$ErrorActionPreference = "Stop"

$ThisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Runner = Join-Path $ThisDir "run_original_5yr_corrected_parallel_decision_workflow.ps1"
$LiveRoot = Join-Path $ThisDir "truth\corrected_parallel_decision_live"
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$ExistingMatlab = Get-Process -Name MATLAB -ErrorAction SilentlyContinue
if ($ExistingMatlab) {
    $status = [ordered]@{
        state = "blocked"
        message = "MATLAB is already running; not launching a duplicate corrected workflow."
        run_tag = $RunTag
        matlab_pids = @($ExistingMatlab.Id)
        updated_at = (Get-Date).ToString("o")
    }
    $status | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $LiveRoot "latest_status.json") -Encoding UTF8
    Write-Output "Blocked: MATLAB already running."
    exit 2
}

$PowerShell = (Get-Command powershell.exe -ErrorAction Stop).Source
$Args = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$Runner`"",
    "-RunTag", "`"$RunTag`""
)
$Process = Start-Process -FilePath $PowerShell -ArgumentList $Args -WindowStyle Hidden -PassThru

$status = [ordered]@{
    state = "launched"
    message = "Corrected parallel decision workflow launched in a hidden PowerShell process."
    run_tag = $RunTag
    launcher_pid = $PID
    runner_pid = $Process.Id
    updated_at = (Get-Date).ToString("o")
}
$status | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $LiveRoot "latest_status.json") -Encoding UTF8

Write-Output "Launched corrected workflow PID $($Process.Id)."
