param(
    [string]$StatePath = "",
    [string]$RemoteAlias = ""
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($StatePath)) {
    $StatePath = Join-Path $scriptRoot "truth\annual_political_hamilton\annual_political_hamilton_thin_latest.json"
}
if (-not (Test-Path -LiteralPath $StatePath)) {
    throw "State file not found: $StatePath"
}

$state = Get-Content -Raw -LiteralPath $StatePath | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($RemoteAlias)) {
    $RemoteAlias = [string]$state.remote_alias
}
$jobId = [string]$state.slurm_array_job_id
$remoteRunDir = [string]$state.remote_run_dir

Write-Output "Job: $jobId"
Write-Output "Stage: $($state.stage_name)"
Write-Output "Remote run dir: $remoteRunDir"
Write-Output ""
Write-Output "Queue:"
& ssh $RemoteAlias "squeue -j $jobId -o '%.18i %.9P %.40j %.8T %.10M %.9l %.6D %R'"
Write-Output ""
Write-Output "Accounting:"
& ssh $RemoteAlias "sacct -j $jobId --format=JobID,JobName%35,State,ExitCode,Elapsed,MaxRSS -P 2>/dev/null | head -40"
Write-Output ""
Write-Output "MEX path checks from logs:"
& ssh $RemoteAlias "grep -R 'lookup path:' '$remoteRunDir/hpc/logs' 2>/dev/null | sort || true"
Write-Output ""
Write-Output "Summaries present:"
& ssh $RemoteAlias "find '$remoteRunDir/annual/truth/annual_political_transition_fail_safe' -maxdepth 2 -name 'summary_all.csv' 2>/dev/null | sort"
Write-Output ""
Write-Output "Summary contents:"
& ssh $RemoteAlias "for f in `$(find '$remoteRunDir/annual/truth/annual_political_transition_fail_safe' -maxdepth 2 -name 'summary_all.csv' 2>/dev/null | sort); do echo ==== `"`$f`"; cat `"`$f`"; done"
