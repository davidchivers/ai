param(
    [string]$StatePath = "",
    [int]$PollSeconds = 300,
    [int]$MaxMinutes = 720,
    [switch]$AutoSubmitT20
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthDir = Join-Path $scriptDir "truth"
if ([string]::IsNullOrWhiteSpace($StatePath)) {
    $StatePath = Join-Path (Join-Path $truthDir "annual_full_re_hamilton") "annual_full_re_hamilton_latest.json"
}
if (-not (Test-Path -LiteralPath $StatePath)) {
    throw "State file not found: $StatePath"
}

$state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
$remoteAlias = $state.remote_alias
$remoteRunDir = $state.remote_run_dir
$jobId = [string]$state.slurm_array_job_id
$stageName = $state.stage_name
$localStageRoot = Join-Path (Join-Path $truthDir "annual_full_re_hamilton") $stageName
$watchStatus = Join-Path $localStageRoot "watch_status.json"
New-Item -ItemType Directory -Force -Path $localStageRoot | Out-Null

function Write-WatchStatus {
    param([string]$Status, [string]$Message)
    [pscustomobject]@{
        status = $Status
        message = $Message
        timestamp = (Get-Date).ToString("s")
        job_id = $jobId
        stage_name = $stageName
        remote_run_dir = $remoteRunDir
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $watchStatus
}

function Invoke-Checked {
    param([scriptblock]$Script, [string]$FailureMessage)
    & $Script
    if ($LASTEXITCODE -ne 0) {
        throw $FailureMessage
    }
}

Write-WatchStatus -Status "watching" -Message "Watching Hamilton full RE price-path job."
$deadline = (Get-Date).AddMinutes($MaxMinutes)
while ((Get-Date) -lt $deadline) {
    $queue = & ssh $remoteAlias "squeue -h -j $jobId -o '%T %M %R'" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-WatchStatus -Status "ssh_retry" -Message "Queue check failed; will retry."
        Start-Sleep -Seconds $PollSeconds
        continue
    }
    if ([string]::IsNullOrWhiteSpace(($queue | Out-String))) {
        break
    }
    Write-WatchStatus -Status "watching" -Message (($queue | Out-String).Trim())
    Start-Sleep -Seconds $PollSeconds
}

if ((Get-Date) -ge $deadline) {
    Write-WatchStatus -Status "timeout" -Message "Watcher timed out before Hamilton job left the queue."
    exit 2
}

Write-WatchStatus -Status "collecting" -Message "Hamilton job left queue; collecting result summaries."
$remoteTruth = "$remoteRunDir/annual/truth/annual_political_full_re_price_path"
$localResults = Join-Path $localStageRoot "annual_political_full_re_price_path"
if (Test-Path -LiteralPath $localResults) {
    Remove-Item -LiteralPath $localResults -Recurse -Force
}
Invoke-Checked -Script {
    & scp -r "${remoteAlias}:$remoteTruth" $localStageRoot
} -FailureMessage "Failed to download Hamilton full RE result directory."

$summaryFiles = Get-ChildItem -LiteralPath $localResults -Recurse -Filter "summary_all.csv"
if ($summaryFiles.Count -eq 0) {
    Write-WatchStatus -Status "failed" -Message "No summary_all.csv files were written."
    exit 3
}

$rows = foreach ($file in $summaryFiles) {
    Import-Csv -LiteralPath $file.FullName | ForEach-Object {
        $_ | Add-Member -NotePropertyName source_file -NotePropertyValue $file.FullName -Force
        $_
    }
}

$finalRows = $rows | Group-Object source_file | ForEach-Object {
    $_.Group | Sort-Object {[int]$_.outer_iter} -Descending | Select-Object -First 1
}

$fixed = $finalRows | Where-Object { $_.demographic_scenario -eq "fixed_age_share" } | Select-Object -First 1
if (-not $fixed) {
    Write-WatchStatus -Status "failed" -Message "Fixed-age unit-test task did not produce a final row."
    exit 4
}

$fixedPathGap = [double]$fixed.max_abs_path_gap
$fixedVoteGap = [double]$fixed.max_abs_vote_resid
$fixedPass = ($fixedPathGap -le 0.020) -and ($fixedVoteGap -le 0.020) -and ($fixed.verdict -ne "dead")

$shockRows = $finalRows | Where-Object { $_.demographic_scenario -in @("baby_boom", "secular_decline") }
$shockPass = ($shockRows.Count -eq 2) -and (($shockRows | Where-Object { ([double]$_.max_abs_path_gap -gt 0.020) -or ($_.verdict -ne "usable") }).Count -eq 0)

$combinedPath = Join-Path $localStageRoot "final_rows.csv"
$finalRows | Export-Csv -LiteralPath $combinedPath -NoTypeInformation

if (-not $fixedPass) {
    Write-WatchStatus -Status "stopped" -Message "Fixed-age unit test failed; not submitting T20."
    exit 5
}
if (-not $shockPass) {
    Write-WatchStatus -Status "stopped" -Message "Shock smoke did not pass usable screen; not submitting T20."
    exit 6
}

if ($AutoSubmitT20.IsPresent) {
    Write-WatchStatus -Status "submitting_T20" -Message "T4 smoke passed; submitting T20 full RE price-path stage."
    $submitScript = Join-Path $scriptDir "submit_annual_full_re_price_path_hamilton.ps1"
    & powershell -NoProfile -ExecutionPolicy Bypass -File $submitScript -Stage T20 -OuterIter 4 -TailYears 20 -PathRelaxation 0.20 -WallTime 18:00:00 -MemoryGb 24
    if ($LASTEXITCODE -ne 0) {
        Write-WatchStatus -Status "failed" -Message "T20 submission failed after T4 pass."
        exit 7
    }
    Write-WatchStatus -Status "complete" -Message "T4 passed and T20 was submitted."
} else {
    Write-WatchStatus -Status "complete" -Message "T4 passed. AutoSubmitT20 was not set."
}
