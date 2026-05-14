param(
    [string]$JobId = "16604880",
    [string]$RemoteBundleRoot = "/nobackup/hfnt93/fert_runs/annual_nimby_bundle_20260327_142434",
    [int]$PollMinutes = 10,
    [double]$MaxHours = 24
)

$ErrorActionPreference = "Stop"

function Write-Status {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Add-Content -Path $statusPath
}

function Get-JobRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteJobId
    )

    $raw = & ssh -o BatchMode=yes -o ConnectTimeout=10 hamilton8 "sacct -j $RemoteJobId --format=JobID,State,ExitCode,Elapsed,NodeList -n -P"
    if (-not $raw) {
        return $null
    }

    foreach ($line in $raw) {
        $parts = $line -split "\|"
        if ($parts.Length -lt 5) {
            continue
        }
        if ($parts[0] -eq $RemoteJobId) {
            return [pscustomobject]@{
                JobId = $parts[0]
                State = $parts[1]
                ExitCode = $parts[2]
                Elapsed = $parts[3]
                Node = $parts[4]
            }
        }
    }

    return $null
}

function Find-RemoteRunDir {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteRoot
    )

    $cmd = "find $RemoteRoot/annual_nimby_bundle_*/03_fertility_and_housing_supply/notes/build/logs -maxdepth 1 -type d -name 'fertility_benchmark_refresh_hpc_*' | sort | tail -n 1"
    $runDir = (& ssh -o BatchMode=yes -o ConnectTimeout=10 hamilton8 $cmd)
    if (-not $runDir) {
        return ""
    }
    return ($runDir | Select-Object -First 1).Trim()
}

function Sync-OptionalRemoteFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteFile,
        [Parameter(Mandatory = $true)]
        [string]$LocalDir
    )

    & ssh -o BatchMode=yes -o ConnectTimeout=10 hamilton8 "test -e '$RemoteFile'"
    if ($LASTEXITCODE -ne 0) {
        return
    }

    & scp -o BatchMode=yes "hamilton8:$RemoteFile" "$LocalDir\"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to sync remote file: $RemoteFile"
    }
}

function Sync-RemoteOutputs {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteRoot,
        [string]$RemoteRunDir,
        [Parameter(Mandatory = $true)]
        [string]$LocalProjectRoot
    )

    $remoteProjectRoot = "$RemoteRoot/annual_nimby_bundle_*/03_fertility_and_housing_supply"
    $remoteBuild = "$remoteProjectRoot/notes/build"
    $localBuild = Join-Path $LocalProjectRoot "notes\build"
    $localLogs = Join-Path $localBuild "logs"
    if (-not (Test-Path $localBuild)) {
        New-Item -ItemType Directory -Path $localBuild | Out-Null
    }
    if (-not (Test-Path $localLogs)) {
        New-Item -ItemType Directory -Path $localLogs | Out-Null
    }

    $files = @(
        "fertility_run_ge_report.md",
        "fertility_reproduction_check.csv",
        "fertility_price_sweep.csv",
        "fertility_market_clearing_grid.csv",
        "fertility_local_benchmark_search.csv",
        "fertility_run_ge_results.mat",
        "fertility_vs_nimby_reproduction_check.csv",
        "fertility_vs_nimby_benchmark_report.md",
        "fertility_vs_nimby_benchmark_summary.csv",
        "fertility_vs_nimby_common_price_grid.csv",
        "fertility_first_birth_timing_profiles.csv",
        "nimby_market_clearing_grid.csv",
        "fertility_vs_nimby_benchmark_panels.png",
        "fertility_vs_nimby_benchmark_panels.pdf",
        "fertility_vs_nimby_benchmark_report.pdf"
    )

    foreach ($name in $files) {
        Sync-OptionalRemoteFile -RemoteFile "$remoteBuild/$name" -LocalDir $localBuild
    }

    if (-not [string]::IsNullOrWhiteSpace($RemoteRunDir)) {
        & scp -o BatchMode=yes -r "hamilton8:$RemoteRunDir" "$localLogs\"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to sync remote benchmark-refresh run directory from Hamilton."
        }
    }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $logsRoot "hamilton_fertility_benchmark_handoff_$runStamp"
New-Item -ItemType Directory -Path $runDir | Out-Null

$statusPath = Join-Path $runDir "status.txt"
$summaryPath = Join-Path $runDir "summary.txt"
$manifestPath = Join-Path $runDir "manifest.txt"
$latestPointerPath = Join-Path $logsRoot "latest_hamilton_fertility_benchmark_handoff.txt"
$activePointerPath = Join-Path $logsRoot "active_hamilton_fertility_benchmark_handoff.txt"

@(
    "Objective: monitor Hamilton 5-year benchmark refresh and stop after one clean milestone."
    "Project root: $projectRoot"
    "Job id: $JobId"
    "Remote bundle root: $RemoteBundleRoot"
    "Poll minutes: $PollMinutes"
    "Max hours: $MaxHours"
    "Stopping rule: collect outputs, write handoff summary, update STATUS.md and memory.md, then stop."
) | Set-Content -Path $manifestPath

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "job_id=$JobId"
    "run_dir=$runDir"
    "status_path=$statusPath"
    "summary_path=$summaryPath"
    "manifest_path=$manifestPath"
) | Set-Content -Path $latestPointerPath

@(
    "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "job_id=$JobId"
    "run_dir=$runDir"
    "status_path=$statusPath"
    "summary_path=$summaryPath"
    "manifest_path=$manifestPath"
) | Set-Content -Path $activePointerPath

$deadline = (Get-Date).AddHours($MaxHours)
Write-Status "START monitor job=$JobId"

while ((Get-Date) -lt $deadline) {
    $record = Get-JobRecord -RemoteJobId $JobId
    if ($null -eq $record) {
        Write-Status "WAIT job=$JobId state=missing"
        Start-Sleep -Seconds ($PollMinutes * 60)
        continue
    }

    Write-Status "POLL job=$($record.JobId) state=$($record.State) exit=$($record.ExitCode) elapsed=$($record.Elapsed) node=$($record.Node)"

    if ($record.State -in @("COMPLETED", "FAILED", "CANCELLED", "TIMEOUT", "OUT_OF_MEMORY", "BOOT_FAIL", "NODE_FAIL", "PREEMPTED")) {
        $remoteRunDir = Find-RemoteRunDir -RemoteRoot $RemoteBundleRoot
        Sync-RemoteOutputs -RemoteRoot $RemoteBundleRoot -RemoteRunDir $remoteRunDir -LocalProjectRoot $projectRoot

        $completionScript = Join-Path $PSScriptRoot "complete_fertility_benchmark_handoff.py"
        & python $completionScript --job-id $JobId --state $record.State --exit-code $record.ExitCode --elapsed $record.Elapsed --node $record.Node --remote-run-dir $remoteRunDir --sync-trackers
        if ($LASTEXITCODE -ne 0) {
            throw "Completion script failed for benchmark-refresh handoff."
        }

        @(
            "Hamilton benchmark-refresh handoff completed."
            "Job id: $JobId"
            "State: $($record.State)"
            "Exit code: $($record.ExitCode)"
            "Elapsed: $($record.Elapsed)"
            "Node: $($record.Node)"
            "Remote run dir: $remoteRunDir"
            "Summary note: $(Join-Path $projectRoot 'notes/build/fertility_benchmark_refresh_handoff.md')"
        ) | Set-Content -Path $summaryPath

        Write-Status "STOP job=$($record.JobId) state=$($record.State)"
        @(
            "stopped_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            "job_id=$JobId"
            "run_dir=$runDir"
            "final_state=$($record.State)"
            "summary_path=$summaryPath"
        ) | Set-Content -Path $activePointerPath
        exit 0
    }

    Start-Sleep -Seconds ($PollMinutes * 60)
}

@(
    "# Hamilton fertility benchmark handoff monitor timeout"
    ""
    "Job id: $JobId"
    "Monitor deadline: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    ""
    "- The detached monitor reached its local time budget before the Hamilton job hit a final state."
    "- Read the live queue state directly before deciding whether to extend monitoring."
) | Set-Content -Path (Join-Path $projectRoot "notes/build/fertility_benchmark_refresh_handoff.md")

@(
    "Hamilton fertility benchmark handoff monitor timed out."
    "Job id: $JobId"
    "Run dir: $runDir"
    "Summary note: $(Join-Path $projectRoot 'notes/build/fertility_benchmark_refresh_handoff.md')"
) | Set-Content -Path $summaryPath

Write-Status "STOP job=$JobId state=MONITOR_TIMEOUT"
@(
    "stopped_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "job_id=$JobId"
    "run_dir=$runDir"
    "final_state=MONITOR_TIMEOUT"
    "summary_path=$summaryPath"
) | Set-Content -Path $activePointerPath
exit 0
