param(
    [Parameter(Mandatory = $true)]
    [string]$JobId,
    [Parameter(Mandatory = $true)]
    [string]$RemoteBundleRoot,
    [string]$OutputStem = "annual_transition_mechanism_scenarios_hamilton",
    [int]$PollMinutes = 10,
    [double]$MaxHours = 12
)

$ErrorActionPreference = "Stop"

$SshArgs = @(
    "-F", "NUL",
    "-l", "hfnt93",
    "-i", "C:/Users/Dave_/.ssh/id_ed25519",
    "-o", "IdentitiesOnly=yes",
    "-o", "StrictHostKeyChecking=accept-new",
    "hamilton8.dur.ac.uk"
)

function Write-Status {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Add-Content -Path $statusPath
}

function Invoke-Remote {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandText
    )

    & ssh @SshArgs $CommandText
}

function Get-JobRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteJobId
    )

    $raw = Invoke-Remote "sacct -j $RemoteJobId --format=JobID,State,ExitCode,Elapsed,NodeList -n -P"
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

    $cmd = "find $RemoteRoot/03_fertility_and_housing_supply/notes/build/logs -maxdepth 1 -type d -name 'annual_transition_mechanism_scenarios_hpc_*' | sort | tail -n 1"
    $runDir = Invoke-Remote $cmd
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

    & ssh @SshArgs "test -e '$RemoteFile'"
    if ($LASTEXITCODE -ne 0) {
        return
    }

    & scp -F NUL -i C:/Users/Dave_/.ssh/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new "hfnt93@hamilton8.dur.ac.uk:$RemoteFile" "$LocalDir\"
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
        [string]$LocalProjectRoot,
        [Parameter(Mandatory = $true)]
        [string]$Stem
    )

    $remoteBuild = "$RemoteRoot/03_fertility_and_housing_supply/notes/build"
    $localBuild = Join-Path $LocalProjectRoot "notes\build"
    $localLogs = Join-Path $localBuild "logs"
    if (-not (Test-Path $localBuild)) {
        New-Item -ItemType Directory -Path $localBuild | Out-Null
    }
    if (-not (Test-Path $localLogs)) {
        New-Item -ItemType Directory -Path $localLogs | Out-Null
    }

    $files = @(
        "$Stem.md",
        "$Stem.csv",
        "${Stem}_summary.csv",
        "${Stem}_peaks.csv"
    )

    foreach ($name in $files) {
        Sync-OptionalRemoteFile -RemoteFile "$remoteBuild/$name" -LocalDir $localBuild
    }

    if (-not [string]::IsNullOrWhiteSpace($RemoteRunDir)) {
        & scp -F NUL -i C:/Users/Dave_/.ssh/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -r "hfnt93@hamilton8.dur.ac.uk:$RemoteRunDir" "$localLogs\"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to sync remote transition run directory from Hamilton."
        }
    }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $logsRoot "hamilton_annual_transition_mechanism_handoff_$runStamp"
New-Item -ItemType Directory -Path $runDir | Out-Null

$statusPath = Join-Path $runDir "status.txt"
$summaryPath = Join-Path $runDir "summary.txt"
$manifestPath = Join-Path $runDir "manifest.txt"
$latestPointerPath = Join-Path $logsRoot "latest_hamilton_annual_transition_mechanism_handoff.txt"
$activePointerPath = Join-Path $logsRoot "active_hamilton_annual_transition_mechanism_handoff.txt"
$handoffNotePath = Join-Path $projectRoot "notes/build/${OutputStem}_handoff.md"

@(
    "Objective: monitor Hamilton annual transition mechanism packet and collect outputs once."
    "Project root: $projectRoot"
    "Job id: $JobId"
    "Remote bundle root: $RemoteBundleRoot"
    "Output stem: $OutputStem"
    "Poll minutes: $PollMinutes"
    "Max hours: $MaxHours"
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
        Sync-RemoteOutputs -RemoteRoot $RemoteBundleRoot -RemoteRunDir $remoteRunDir -LocalProjectRoot $projectRoot -Stem $OutputStem

        @(
            "# Hamilton annual transition mechanism handoff"
            ""
            ('- Job id: `' + $JobId + '`')
            ('- Final state: `' + $record.State + '`')
            ('- Exit code: `' + $record.ExitCode + '`')
            ('- Elapsed: `' + $record.Elapsed + '`')
            ('- Node: `' + $record.Node + '`')
            ('- Remote run dir: `' + $remoteRunDir + '`')
            ('- Output stem: `' + $OutputStem + '`')
            ""
            "## Synced outputs"
            ""
            ('- `notes/build/' + $OutputStem + '.md`')
            ('- `notes/build/' + $OutputStem + '.csv`')
            ('- `notes/build/' + $OutputStem + '_summary.csv`')
            ('- `notes/build/' + $OutputStem + '_peaks.csv`')
        ) | Set-Content -Path $handoffNotePath

        @(
            "Hamilton annual transition mechanism handoff completed."
            "Job id: $JobId"
            "State: $($record.State)"
            "Exit code: $($record.ExitCode)"
            "Elapsed: $($record.Elapsed)"
            "Node: $($record.Node)"
            "Remote run dir: $remoteRunDir"
            "Summary note: $handoffNotePath"
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
    "# Hamilton annual transition mechanism handoff monitor timeout"
    ""
    "Job id: $JobId"
    "Monitor deadline: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    ""
    "- The detached monitor reached its local time budget before the Hamilton job hit a final state."
    "- Recheck the queue before extending monitoring."
) | Set-Content -Path $handoffNotePath

@(
    "Hamilton annual transition mechanism handoff monitor timed out."
    "Job id: $JobId"
    "Run dir: $runDir"
    "Summary note: $handoffNotePath"
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
