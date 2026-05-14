param(
    [int]$StartingHorizon = 13,
    [string]$CurrentJobId = "",
    [string]$CurrentRemoteRunDir = "",
    [string]$CurrentProfileName = "standard_tail",
    [int]$CurrentAttemptIndex = 0,
    [string]$RemoteHost = "hfnt93@hamilton8.dur.ac.uk",
    [double]$PromoteThreshold = 0.05,
    [int]$MaxHorizon = 15,
    [int]$PollMinutes = 10,
    [double]$MaxHours = 48
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

function Write-Status {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Add-Content -LiteralPath $statusPath
}

function Write-PointerState {
    param(
        [string]$LifecycleState,
        [int]$CurrentHorizon,
        [string]$CurrentJobId,
        [string]$CurrentRemoteRunDir,
        [string]$CurrentProfileName,
        [int]$CurrentAttemptIndex,
        [string]$LastEvent,
        [string]$BestCase = "",
        [string]$BestMaxRes = ""
    )

    $payload = @(
        "updated_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "state=$LifecycleState"
        "starting_horizon=$StartingHorizon"
        "current_horizon=$CurrentHorizon"
        "current_job_id=$CurrentJobId"
        "current_remote_run_dir=$CurrentRemoteRunDir"
        "current_profile_name=$CurrentProfileName"
        "current_attempt_index=$CurrentAttemptIndex"
        "promote_threshold=$PromoteThreshold"
        "max_horizon=$MaxHorizon"
        "run_dir=$runDir"
        "status_path=$statusPath"
        "summary_path=$summaryPath"
        "last_event=$LastEvent"
        "best_case=$BestCase"
        "best_maxres=$BestMaxRes"
    )

    $payload | Set-Content -LiteralPath $latestPointerPath
    $payload | Set-Content -LiteralPath $activePointerPath
}

function Parse-KeyValueFile {
    param([string]$Path)
    $map = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match "^\s*([^=]+)=(.*)$") {
            $map[$matches[1].Trim()] = $matches[2]
        }
    }
    return $map
}

function Invoke-RemoteCapture {
    param(
        [string]$RemoteHostName,
        [string]$KeyPath,
        [string]$RemoteCommand,
        [int]$MaxAttempts = 4,
        [int]$RetryDelaySeconds = 20,
        [switch]$AllowFailure
    )

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $output = & ssh -tt -F NUL -o IdentitiesOnly=yes -o ConnectTimeout=10 -i $KeyPath $RemoteHostName $RemoteCommand 2>$null
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        if ($LASTEXITCODE -eq 0) {
            return (Normalize-RemoteOutput -OutputLines $output)
        }
        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    if ($AllowFailure) {
        return @()
    }
    throw "Remote command failed after $MaxAttempts attempts: $RemoteCommand"
}

function Copy-RemoteItem {
    param(
        [string]$RemoteHostName,
        [string]$KeyPath,
        [string]$RemotePath,
        [string]$LocalTarget,
        [switch]$Recurse,
        [int]$MaxAttempts = 4,
        [int]$RetryDelaySeconds = 20,
        [switch]$AllowFailure
)

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        if ($Recurse) {
            if ($AllowFailure) {
                return $false
            }
            throw "Recursive remote copy is disabled in the autopilot transport path: $RemotePath"
        } else {
            $remoteCommand = "if [ -f '$RemotePath' ]; then cat '$RemotePath'; fi"
            $content = Invoke-RemoteCapture -RemoteHostName $RemoteHostName -KeyPath $KeyPath -RemoteCommand $remoteCommand -AllowFailure
            if ($content) {
                $targetPath = $LocalTarget
                if ((Test-Path $LocalTarget -PathType Container) -or $LocalTarget.EndsWith('\') -or $LocalTarget.EndsWith('/')) {
                    $targetPath = Join-Path $LocalTarget ([System.IO.Path]::GetFileName($RemotePath))
                }
                [System.IO.File]::WriteAllText($targetPath, ([string]::Join("`n", @($content)) + "`n"), (New-Object System.Text.UTF8Encoding($false)))
                return $true
            }
        }
        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    if ($AllowFailure) {
        return $false
    }
    throw "Remote copy failed after $MaxAttempts attempts: $RemotePath"
}

function Get-JobRecord {
    param(
        [string]$RemoteJobId,
        [string]$RemoteHostName,
        [string]$KeyPath
    )

    $raw = Invoke-RemoteCapture -RemoteHostName $RemoteHostName -KeyPath $KeyPath -RemoteCommand "sacct -j $RemoteJobId --format=JobID,State,ExitCode,Elapsed -n -P 2>/dev/null || true" -AllowFailure
    if (-not $raw) {
        return $null
    }
    foreach ($line in $raw) {
        $parts = $line -split "\|"
        if ($parts.Length -lt 4) { continue }
        if ($parts[0] -eq $RemoteJobId) {
            return [pscustomobject]@{
                JobId = $parts[0]
                State = $parts[1]
                ExitCode = $parts[2]
                Elapsed = $parts[3]
            }
        }
    }
    return $null
}

function Sync-RemoteResults {
    param(
        [int]$Horizon,
        [string]$RemoteRunDir,
        [string]$RemoteHostName,
        [string]$KeyPath,
        [string]$LocalTargetDir
    )

    if (-not (Test-Path $LocalTargetDir)) {
        New-Item -ItemType Directory -Path $LocalTargetDir | Out-Null
    }
    Copy-RemoteItem -RemoteHostName $RemoteHostName -KeyPath $KeyPath -RemotePath "$RemoteRunDir/status.txt" -LocalTarget "$LocalTargetDir\" -AllowFailure | Out-Null
    Copy-RemoteItem -RemoteHostName $RemoteHostName -KeyPath $KeyPath -RemotePath "$RemoteRunDir/summary.txt" -LocalTarget "$LocalTargetDir\" -AllowFailure | Out-Null
    $standardCsvExists = Invoke-RemoteCapture -RemoteHostName $RemoteHostName -KeyPath $KeyPath -RemoteCommand "if [ -f '$RemoteRunDir/t${Horizon}_cases.csv' ]; then echo yes; fi" -AllowFailure
    if ($standardCsvExists -match 'yes') {
        Copy-RemoteItem -RemoteHostName $RemoteHostName -KeyPath $KeyPath -RemotePath "$RemoteRunDir/t${Horizon}_cases.csv" -LocalTarget "$LocalTargetDir\" -AllowFailure | Out-Null
    }
    $legacyCsvExists = Invoke-RemoteCapture -RemoteHostName $RemoteHostName -KeyPath $KeyPath -RemoteCommand "if [ -f '$RemoteRunDir/t${Horizon}_deep_cases.csv' ]; then echo yes; fi" -AllowFailure
    if ($legacyCsvExists -match 'yes') {
        Copy-RemoteItem -RemoteHostName $RemoteHostName -KeyPath $KeyPath -RemotePath "$RemoteRunDir/t${Horizon}_deep_cases.csv" -LocalTarget "$LocalTargetDir\" -AllowFailure | Out-Null
    }
}

function Build-NextSeed {
    param([string]$QPath)
    $vals = @(
        $QPath -split "\s+" |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne "" }
    )
    if ($vals.Count -eq 0) {
        throw "Could not parse q_path from best row."
    }
    $vals += $vals[-1]
    return ($vals -join ",")
}

function Get-AttemptProfiles {
    return @(
        [pscustomobject]@{
            Name = "standard_tail"
            CaseStarts = "6,5,4,3"
            IncludeSuffixAnchor = $true
            CoordinateEdgePolish = $true
            CoordinateEdgeHeadPeriods = 3
            CoordinateEdgeTailPeriods = 1
            MaxIter = 5
            WallTime = "08:00:00"
        },
        [pscustomobject]@{
            Name = "broad_tail"
            CaseStarts = "7,6,5,4,3,2"
            IncludeSuffixAnchor = $true
            CoordinateEdgePolish = $true
            CoordinateEdgeHeadPeriods = 3
            CoordinateEdgeTailPeriods = 1
            MaxIter = 5
            WallTime = "10:00:00"
        },
        [pscustomobject]@{
            Name = "deep_tail"
            CaseStarts = "8,7,6,5,4,3,2"
            IncludeSuffixAnchor = $true
            CoordinateEdgePolish = $true
            CoordinateEdgeHeadPeriods = 3
            CoordinateEdgeTailPeriods = 1
            MaxIter = 6
            WallTime = "12:00:00"
        },
        [pscustomobject]@{
            Name = "edge_plus"
            CaseStarts = "8,7,6,5,4,3,2,1"
            IncludeSuffixAnchor = $true
            CoordinateEdgePolish = $true
            CoordinateEdgeHeadPeriods = 4
            CoordinateEdgeTailPeriods = 2
            MaxIter = 7
            WallTime = "14:00:00"
        },
        [pscustomobject]@{
            Name = "tail_polish"
            CaseStarts = "10,9,8,7,6,5,4,3,2,1"
            IncludeSuffixAnchor = $true
            CoordinateEdgePolish = $true
            CoordinateEdgeHeadPeriods = 1
            CoordinateEdgeTailPeriods = 6
            MaxIter = 8
            WallTime = "16:00:00"
        }
    )
}

function Submit-HorizonRun {
    param(
        [int]$TargetHorizon,
        [string]$InitialQPath,
        [pscustomobject]$Profile
    )

    $submissionOutput = & (Join-Path $PSScriptRoot "submit_hamilton_bellman_re_suffix_ladder.ps1") `
        -Horizon $TargetHorizon `
        -InitialQPath $InitialQPath `
        -ProfileName $Profile.Name `
        -CaseStarts $Profile.CaseStarts `
        -IncludeSuffixAnchor:([bool]$Profile.IncludeSuffixAnchor) `
        -CoordinateEdgePolish:([bool]$Profile.CoordinateEdgePolish) `
        -CoordinateEdgeHeadPeriods $Profile.CoordinateEdgeHeadPeriods `
        -CoordinateEdgeTailPeriods $Profile.CoordinateEdgeTailPeriods `
        -MaxIter $Profile.MaxIter `
        -WallTime $Profile.WallTime `
        -RemoteHost $RemoteHost

    $submissionOutputPath = @($submissionOutput | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) | Select-Object -Last 1
    if ([string]::IsNullOrWhiteSpace($submissionOutputPath)) {
        throw "Hamilton submission script returned no submission path for horizon $TargetHorizon."
    }
    return (Parse-KeyValueFile -Path $submissionOutputPath)
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$keyPath = Join-Path $HOME ".ssh\id_ed25519"
if (-not (Test-Path $keyPath)) {
    throw "SSH key not found: $keyPath"
}

if ([string]::IsNullOrWhiteSpace($CurrentJobId) -or [string]::IsNullOrWhiteSpace($CurrentRemoteRunDir)) {
    $startingPointer = Join-Path $logsRoot ("active_bellman_re_t{0}_deep_suffix_hamilton.txt" -f $StartingHorizon)
    if (-not (Test-Path $startingPointer)) {
        $startingPointer = Join-Path $logsRoot ("active_bellman_re_t{0}_suffix_ladder_hamilton.txt" -f $StartingHorizon)
    }
    if (-not (Test-Path $startingPointer)) {
        $startingPointer = Join-Path $logsRoot "active_bellman_re_t13_deep_suffix_hamilton.txt"
    }
    $map = Parse-KeyValueFile -Path $startingPointer
    if ([string]::IsNullOrWhiteSpace($CurrentJobId)) {
        $CurrentJobId = $map["job_id"]
    }
    if ([string]::IsNullOrWhiteSpace($CurrentRemoteRunDir)) {
        $CurrentRemoteRunDir = $map["remote_run_dir"]
    }
    if ($map.ContainsKey("profile_name") -and [string]::IsNullOrWhiteSpace($CurrentProfileName)) {
        $CurrentProfileName = $map["profile_name"]
    }
}

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $logsRoot "bellman_re_horizon_autopilot_$runStamp"
New-Item -ItemType Directory -Path $runDir | Out-Null
$statusPath = Join-Path $runDir "status.txt"
$summaryPath = Join-Path $runDir "summary.txt"
$manifestPath = Join-Path $runDir "manifest.txt"
$latestPointerPath = Join-Path $logsRoot "latest_bellman_re_horizon_autopilot.txt"
$activePointerPath = Join-Path $logsRoot "active_bellman_re_horizon_autopilot.txt"

@(
    "Objective: watch the live Bellman RE Hamilton rung, promote on success, and escalate to a stronger same-horizon profile on failure."
    "Starting horizon: $StartingHorizon"
    "Promote threshold: $PromoteThreshold"
    "Max horizon: $MaxHorizon"
    "Current job id: $CurrentJobId"
    "Current remote run dir: $CurrentRemoteRunDir"
    "Current profile name: $CurrentProfileName"
    "Current attempt index: $CurrentAttemptIndex"
) | Set-Content -LiteralPath $manifestPath

$deadline = (Get-Date).AddHours($MaxHours)
$profiles = Get-AttemptProfiles
$horizon = $StartingHorizon
$jobId = $CurrentJobId
$remoteRunDir = $CurrentRemoteRunDir
$profileName = $CurrentProfileName
$attemptIndex = $CurrentAttemptIndex
if ($attemptIndex -lt 0) { $attemptIndex = 0 }
if ($attemptIndex -ge $profiles.Count) { $attemptIndex = $profiles.Count - 1 }

Write-PointerState -LifecycleState "RUNNING" -CurrentHorizon $horizon -CurrentJobId $jobId -CurrentRemoteRunDir $remoteRunDir -CurrentProfileName $profileName -CurrentAttemptIndex $attemptIndex -LastEvent "START"
Write-Status "START horizon=$horizon profile=$profileName attempt=$attemptIndex job=$jobId remote_dir=$remoteRunDir"

while ((Get-Date) -lt $deadline) {
    $record = Get-JobRecord -RemoteJobId $jobId -RemoteHostName $RemoteHost -KeyPath $keyPath
    if ($null -eq $record) {
        Write-Status "WAIT horizon=$horizon profile=$profileName attempt=$attemptIndex job=$jobId state=missing"
        Write-PointerState -LifecycleState "RUNNING" -CurrentHorizon $horizon -CurrentJobId $jobId -CurrentRemoteRunDir $remoteRunDir -CurrentProfileName $profileName -CurrentAttemptIndex $attemptIndex -LastEvent "WAIT"
        Start-Sleep -Seconds ($PollMinutes * 60)
        continue
    }

    Write-Status "POLL horizon=$horizon profile=$profileName attempt=$attemptIndex job=$jobId state=$($record.State) exit=$($record.ExitCode) elapsed=$($record.Elapsed)"
    Write-PointerState -LifecycleState "RUNNING" -CurrentHorizon $horizon -CurrentJobId $jobId -CurrentRemoteRunDir $remoteRunDir -CurrentProfileName $profileName -CurrentAttemptIndex $attemptIndex -LastEvent ("POLL:{0}" -f $record.State)
    if ($record.State -notin @("COMPLETED", "FAILED", "CANCELLED", "TIMEOUT", "OUT_OF_MEMORY", "BOOT_FAIL", "NODE_FAIL", "PREEMPTED")) {
        Start-Sleep -Seconds ($PollMinutes * 60)
        continue
    }

    $snapshotDir = Join-Path $runDir ("horizon_{0}" -f $horizon)
    Sync-RemoteResults -Horizon $horizon -RemoteRunDir $remoteRunDir -RemoteHostName $RemoteHost -KeyPath $keyPath -LocalTargetDir $snapshotDir
    $csvPath = Join-Path $snapshotDir ("t{0}_cases.csv" -f $horizon)
    if (-not (Test-Path $csvPath)) {
        $legacyCsvPath = Join-Path $snapshotDir ("t{0}_deep_cases.csv" -f $horizon)
        if (Test-Path $legacyCsvPath) {
            $csvPath = $legacyCsvPath
        }
    }
    if (-not (Test-Path $csvPath)) {
        Write-Status "STOP horizon=$horizon profile=$profileName attempt=$attemptIndex job=$jobId reason=no_csv state=$($record.State)"
        break
    }

    $rows = Import-Csv -LiteralPath $csvPath | Sort-Object { [double]$_.max_abs_residual }, case_label
    if ($rows.Count -eq 0) {
        Write-Status "STOP horizon=$horizon profile=$profileName attempt=$attemptIndex job=$jobId reason=empty_csv state=$($record.State)"
        break
    }

    $best = $rows[0]
    $bestMaxRes = [double]$best.max_abs_residual
    Write-Status "RESULT horizon=$horizon profile=$profileName attempt=$attemptIndex best_case=$($best.case_label) maxres=$bestMaxRes"
    Write-PointerState -LifecycleState "RUNNING" -CurrentHorizon $horizon -CurrentJobId $jobId -CurrentRemoteRunDir $remoteRunDir -CurrentProfileName $profileName -CurrentAttemptIndex $attemptIndex -LastEvent "RESULT" -BestCase $best.case_label -BestMaxRes $best.max_abs_residual

    if (($record.State -eq "COMPLETED" -or $record.State -eq "FAILED") -and $bestMaxRes -le $PromoteThreshold -and $horizon -lt $MaxHorizon) {
        $nextHorizon = $horizon + 1
        $nextSeed = Build-NextSeed -QPath $best.q_path
        $nextProfile = $profiles[0]
        Write-Status "PROMOTE horizon=$horizon -> next_horizon=$nextHorizon best_case=$($best.case_label) maxres=$bestMaxRes next_profile=$($nextProfile.Name)"
        try {
            $submissionMap = Submit-HorizonRun -TargetHorizon $nextHorizon -InitialQPath $nextSeed -Profile $nextProfile
        } catch {
            $submitError = ($_.Exception.Message -replace '\s+', ' ').Trim()
            Write-Status "SUBMIT_WAIT horizon=$nextHorizon profile=$($nextProfile.Name) reason=$submitError"
            Write-PointerState -LifecycleState "RUNNING" -CurrentHorizon $horizon -CurrentJobId $jobId -CurrentRemoteRunDir $remoteRunDir -CurrentProfileName $profileName -CurrentAttemptIndex $attemptIndex -LastEvent "SUBMIT_WAIT" -BestCase $best.case_label -BestMaxRes $best.max_abs_residual
            Start-Sleep -Seconds ($PollMinutes * 60)
            continue
        }
        $jobId = $submissionMap["job_id"]
        $remoteRunDir = $submissionMap["remote_run_dir"]
        $horizon = $nextHorizon
        $profileName = $submissionMap["profile_name"]
        $attemptIndex = 0
        Write-Status "SUBMIT horizon=$horizon profile=$profileName attempt=$attemptIndex job=$jobId remote_dir=$remoteRunDir"
        Write-PointerState -LifecycleState "RUNNING" -CurrentHorizon $horizon -CurrentJobId $jobId -CurrentRemoteRunDir $remoteRunDir -CurrentProfileName $profileName -CurrentAttemptIndex $attemptIndex -LastEvent "SUBMIT" -BestCase $best.case_label -BestMaxRes $best.max_abs_residual
        continue
    }

    if (($record.State -eq "COMPLETED" -or $record.State -eq "FAILED") -and $bestMaxRes -gt $PromoteThreshold -and $attemptIndex -lt ($profiles.Count - 1)) {
        $retryProfile = $profiles[$attemptIndex + 1]
        $retrySeed = ($best.q_path -replace '\s+', ',').Trim(',')
        Write-Status "RETRY horizon=$horizon best_case=$($best.case_label) maxres=$bestMaxRes next_profile=$($retryProfile.Name)"
        try {
            $submissionMap = Submit-HorizonRun -TargetHorizon $horizon -InitialQPath $retrySeed -Profile $retryProfile
        } catch {
            $submitError = ($_.Exception.Message -replace '\s+', ' ').Trim()
            Write-Status "SUBMIT_WAIT horizon=$horizon profile=$($retryProfile.Name) reason=$submitError"
            Write-PointerState -LifecycleState "RUNNING" -CurrentHorizon $horizon -CurrentJobId $jobId -CurrentRemoteRunDir $remoteRunDir -CurrentProfileName $profileName -CurrentAttemptIndex $attemptIndex -LastEvent "SUBMIT_WAIT" -BestCase $best.case_label -BestMaxRes $best.max_abs_residual
            Start-Sleep -Seconds ($PollMinutes * 60)
            continue
        }
        $jobId = $submissionMap["job_id"]
        $remoteRunDir = $submissionMap["remote_run_dir"]
        $profileName = $submissionMap["profile_name"]
        $attemptIndex = [Array]::IndexOf($profiles.Name, $profileName)
        if ($attemptIndex -lt 0) { $attemptIndex = 0 }
        Write-Status "SUBMIT horizon=$horizon profile=$profileName attempt=$attemptIndex job=$jobId remote_dir=$remoteRunDir"
        Write-PointerState -LifecycleState "RUNNING" -CurrentHorizon $horizon -CurrentJobId $jobId -CurrentRemoteRunDir $remoteRunDir -CurrentProfileName $profileName -CurrentAttemptIndex $attemptIndex -LastEvent "RETRY_SUBMIT" -BestCase $best.case_label -BestMaxRes $best.max_abs_residual
        continue
    }

    @(
        "Bellman RE horizon autopilot stopped."
        "Final horizon: $horizon"
        "Final job id: $jobId"
        "Final profile: $profileName"
        "Final attempt index: $attemptIndex"
        "Final state: $($record.State)"
        "Best case: $($best.case_label)"
        "Best maxres: $bestMaxRes"
        "Snapshot dir: $snapshotDir"
    ) | Set-Content -LiteralPath $summaryPath
    Write-Status "STOP horizon=$horizon profile=$profileName attempt=$attemptIndex job=$jobId state=$($record.State) best_case=$($best.case_label) maxres=$bestMaxRes"
    Write-PointerState -LifecycleState "STOPPED" -CurrentHorizon $horizon -CurrentJobId $jobId -CurrentRemoteRunDir $remoteRunDir -CurrentProfileName $profileName -CurrentAttemptIndex $attemptIndex -LastEvent "STOP" -BestCase $best.case_label -BestMaxRes $best.max_abs_residual
    break
}

if (-not (Test-Path $summaryPath)) {
    @(
        "Bellman RE horizon autopilot timed out."
        "Last horizon: $horizon"
        "Last job id: $jobId"
        "Last profile: $profileName"
        "Last attempt index: $attemptIndex"
        "Remote run dir: $remoteRunDir"
    ) | Set-Content -LiteralPath $summaryPath
    Write-Status "STOP horizon=$horizon profile=$profileName attempt=$attemptIndex job=$jobId state=AUTOPILOT_TIMEOUT"
    Write-PointerState -LifecycleState "STOPPED" -CurrentHorizon $horizon -CurrentJobId $jobId -CurrentRemoteRunDir $remoteRunDir -CurrentProfileName $profileName -CurrentAttemptIndex $attemptIndex -LastEvent "AUTOPILOT_TIMEOUT"
}
