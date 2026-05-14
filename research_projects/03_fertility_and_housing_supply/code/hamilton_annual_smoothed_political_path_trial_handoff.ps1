param(
    [Parameter(Mandatory = $true)]
    [string]$JobId,
    [Parameter(Mandatory = $true)]
    [string]$RemoteRunDir,
    [string]$OutputStem = "nimby_vs_fertility_smoothed_political_path_trial",
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

function Normalize-RemoteOutput {
    param([object[]]$OutputLines)

    $clean = New-Object System.Collections.Generic.List[string]
    foreach ($entry in @($OutputLines)) {
        if ($null -eq $entry) {
            continue
        }
        $text = ([string]$entry) -replace "`r", ""
        if ($text -match '^(Connection|Shared connection) to .+ closed\.$') {
            continue
        }
        if ($text -match '^client_loop: send disconnect: ') {
            continue
        }
        $clean.Add($text)
    }
    return $clean
}

function Invoke-Remote {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandText
    )

    $output = & ssh -tt @SshArgs $CommandText 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Remote command failed: $CommandText"
    }
    return (Normalize-RemoteOutput -OutputLines $output)
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

function Get-RemoteFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteFile,
        [Parameter(Mandatory = $true)]
        [string]$LocalFile
    )

    $escaped = $RemoteFile -replace "'", "'\''"
    $content = Invoke-Remote "if [ -f '$escaped' ]; then base64 '$escaped'; fi"
    if (-not $content) {
        return
    }
    $joined = ($content | Where-Object { $_ -and $_.Trim() -ne "" }) -join ""
    if ([string]::IsNullOrWhiteSpace($joined)) {
        return
    }
    [System.IO.File]::WriteAllBytes($LocalFile, [Convert]::FromBase64String($joined))
}

function Find-RemoteExecutionDir {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseRunDir
    )

    $escaped = $BaseRunDir -replace "'", "'\''"
    $output = Invoke-Remote "find '$escaped/03_fertility_and_housing_supply/notes/build/logs' -maxdepth 1 -type d -name 'annual_smoothed_political_path_trial_hpc_*' | sort | tail -n 1"
    if (-not $output) {
        return ""
    }
    return ($output | Select-Object -Last 1).Trim()
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $logsRoot "hamilton_annual_smoothed_political_path_trial_handoff_$runStamp"
New-Item -ItemType Directory -Path $runDir | Out-Null

$statusPath = Join-Path $runDir "status.txt"
$summaryPath = Join-Path $runDir "summary.txt"
$manifestPath = Join-Path $runDir "manifest.txt"
$latestPointerPath = Join-Path $logsRoot "latest_hamilton_annual_smoothed_political_path_trial_handoff.txt"
$activePointerPath = Join-Path $logsRoot "active_hamilton_annual_smoothed_political_path_trial_handoff.txt"
$handoffNotePath = Join-Path $projectRoot "notes/build/${OutputStem}_hamilton_handoff.md"

@(
    "Objective: monitor Hamilton annual smoothed political-path trial and collect outputs once."
    "Project root: $projectRoot"
    "Job id: $JobId"
    "Remote run dir: $RemoteRunDir"
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
    try {
        $record = Get-JobRecord -RemoteJobId $JobId
    } catch {
        Write-Status "WAIT job=$JobId state=transport_error"
        Start-Sleep -Seconds ($PollMinutes * 60)
        continue
    }

    if ($null -eq $record) {
        Write-Status "WAIT job=$JobId state=missing"
        Start-Sleep -Seconds ($PollMinutes * 60)
        continue
    }

    Write-Status "POLL job=$($record.JobId) state=$($record.State) exit=$($record.ExitCode) elapsed=$($record.Elapsed) node=$($record.Node)"

    if ($record.State -in @("COMPLETED", "FAILED", "CANCELLED", "TIMEOUT", "OUT_OF_MEMORY", "BOOT_FAIL", "NODE_FAIL", "PREEMPTED")) {
        $localBuild = Join-Path $projectRoot "notes/build"
        if (-not (Test-Path $localBuild)) {
            New-Item -ItemType Directory -Path $localBuild | Out-Null
        }
        $remoteExecDir = ""
        try {
            $remoteExecDir = Find-RemoteExecutionDir -BaseRunDir $RemoteRunDir
        } catch {
            $remoteExecDir = ""
        }

        foreach ($name in @(
            "$OutputStem.md",
            "$OutputStem.csv",
            "${OutputStem}_paths.csv",
            "$OutputStem.png",
            "$OutputStem.pdf"
        )) {
            Get-RemoteFile -RemoteFile "$RemoteRunDir/03_fertility_and_housing_supply/notes/build/$name" -LocalFile (Join-Path $localBuild $name)
        }

        if (-not [string]::IsNullOrWhiteSpace($remoteExecDir)) {
            foreach ($name in @("status.txt", "summary.txt", "stdout.log", "stderr.log", "manifest.txt")) {
                Get-RemoteFile -RemoteFile "$remoteExecDir/$name" -LocalFile (Join-Path $runDir $name)
            }
        }

        @(
            "# Hamilton annual smoothed political-path trial handoff"
            ""
            ('- Job id: `' + $JobId + '`')
            ('- Final state: `' + $record.State + '`')
            ('- Exit code: `' + $record.ExitCode + '`')
            ('- Elapsed: `' + $record.Elapsed + '`')
            ('- Node: `' + $record.Node + '`')
            ('- Remote run dir: `' + $RemoteRunDir + '`')
            ('- Output stem: `' + $OutputStem + '`')
            ""
            "## Synced outputs"
            ""
            ('- `notes/build/' + $OutputStem + '.md`')
            ('- `notes/build/' + $OutputStem + '.csv`')
            ('- `notes/build/' + $OutputStem + '_paths.csv`')
            ('- `notes/build/' + $OutputStem + '.png`')
            ('- `notes/build/' + $OutputStem + '.pdf`')
        ) | Set-Content -Path $handoffNotePath

        @(
            "Hamilton annual smoothed political-path trial handoff completed."
            "Job id: $JobId"
            "State: $($record.State)"
            "Exit code: $($record.ExitCode)"
            "Elapsed: $($record.Elapsed)"
            "Node: $($record.Node)"
            "Remote run dir: $RemoteRunDir"
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
    "# Hamilton annual smoothed political-path trial handoff monitor timeout"
    ""
    "Job id: $JobId"
    "Monitor deadline: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    ""
    "- The detached monitor reached its local time budget before the Hamilton job hit a final state."
) | Set-Content -Path $handoffNotePath

@(
    "Hamilton annual smoothed political-path trial handoff monitor timed out."
    "Job id: $JobId"
    "Summary note: $handoffNotePath"
) | Set-Content -Path $summaryPath

Write-Status "TIMEOUT job=$JobId"
throw "Hamilton annual smoothed political-path trial handoff timed out."
