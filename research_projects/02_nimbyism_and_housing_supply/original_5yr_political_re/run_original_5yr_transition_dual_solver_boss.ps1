param(
    [string]$LiveRoot = "",
    [string]$MatlabExe = "matlab",
    [double]$MaxHours = 24
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_dual_solver_boss_live"
}
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$runId = "dualboss_" + (Get-Date -Format "yyyyMMdd_HHmmss")
$runDir = Join-Path $LiveRoot ("r\" + $runId)
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
Set-Content -Path (Join-Path $LiveRoot "active_run.txt") -Value $runDir

$statusPath = Join-Path $LiveRoot "latest_status.json"
$reportPath = Join-Path $LiveRoot "latest_report.md"
$logPath = Join-Path $runDir "boss_log.txt"
$finalResultPath = Join-Path $runDir "final_result.json"
$startedAt = Get-Date

$fullHorizonBaselineVote = 0.0343491536712217
$fullHorizonBaselineGap = 0.00959574825273568
$defaultSeedCsv = Join-Path $scriptDir "original_5yr_transition_political_bellman_hist_k14_unionblock_cont_i2_final_price_path.csv"
$jointHamiltonStatePath = Join-Path $scriptDir "truth\hamilton_joint_supply_wedge_packet_latest.json"

$localStageResults = New-Object System.Collections.Generic.List[object]
$hamiltonPacketResults = New-Object System.Collections.Generic.List[object]
$bestGlobal = [ordered]@{
    source = "seed_incumbent"
    max_abs_vote = $fullHorizonBaselineVote
    max_abs_gap = $fullHorizonBaselineGap
    seed_price_csv = $defaultSeedCsv
    improved = $false
    updated_at = (Get-Date).ToString("s")
}

$localStages = @(
    [ordered]@{
        name = "local_redjac_from_dynare"
        kind = "redjac"
        attach_existing = $true
        token = "local_redjac_from_dynare"
        timeout_hours = 16.0
    },
    [ordered]@{
        name = "local_dynare_reduced_retry"
        kind = "dynare"
        attach_existing = $false
        basis_count = 4
        max_outer_iter = 2
        candidate_scales = @("1,0.5,0.25,0.1")
        trust_region_log_step = 0.003
        timeout_hours = 8.0
    },
    [ordered]@{
        name = "local_redjac_from_dynare_retry"
        kind = "redjac"
        attach_existing = $false
        basis_count = 4
        max_outer_iter = 2
        candidate_scales = @("1,0.5,0.25")
        trust_region_log_step = 0.003
        timeout_hours = 10.0
    }
)

$hamiltonPhases = @(
    [ordered]@{
        name = "joint_wedge_baseline"
        packet_kind = "joint_supply_wedge"
        profile = "baseline"
        state_path = $jointHamiltonStatePath
        submitter = (Join-Path $scriptDir "submit_original_5yr_hamilton_joint_supply_wedge_packet.ps1")
        attach_existing = $true
        submitted = $false
        completed = $false
        retries = 0
    },
    [ordered]@{
        name = "joint_wedge_repair"
        packet_kind = "joint_supply_wedge"
        profile = "repair"
        state_path = $jointHamiltonStatePath
        submitter = (Join-Path $scriptDir "submit_original_5yr_hamilton_joint_supply_wedge_packet.ps1")
        attach_existing = $false
        submitted = $false
        completed = $false
        retries = 0
    },
    [ordered]@{
        name = "joint_wedge_aggressive"
        packet_kind = "joint_supply_wedge"
        profile = "aggressive"
        state_path = $jointHamiltonStatePath
        submitter = (Join-Path $scriptDir "submit_original_5yr_hamilton_joint_supply_wedge_packet.ps1")
        attach_existing = $false
        submitted = $false
        completed = $false
        retries = 0
    }
)

$currentLocalStage = $null
$currentHamiltonPacket = $null

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

function Get-ElapsedHours {
    return ((Get-Date) - $startedAt).TotalHours
}

function Parse-Double {
    param($Value, [double]$DefaultValue = [double]::NaN)
    if ($null -eq $Value) { return $DefaultValue }
    $text = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) { return $DefaultValue }
    $parsed = 0.0
    if ([double]::TryParse($text, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
        return $parsed
    }
    return $DefaultValue
}

function Get-DateSafe {
    param($Value)
    try {
        if ($null -eq $Value) { return $null }
        return [datetime]::Parse([string]$Value, [System.Globalization.CultureInfo]::InvariantCulture)
    }
    catch {
        return $null
    }
}

function Get-LoggedHamiltonStageNames {
    return @(
        $hamiltonPacketResults.ToArray() |
            Where-Object { $_.stage_name } |
            ForEach-Object { [string]$_.stage_name }
    )
}

function Find-ProcessByToken {
    param([string]$Token)
    try {
        return @(
            Get-CimInstance Win32_Process -ErrorAction Stop |
                Where-Object {
                    ($_.Name -match '^(powershell|matlab|MATLAB)(\.exe)?$') -and
                    ($_.CommandLine -like ("*" + $Token + "*"))
                }
        )
    }
    catch {
        Write-Log "Find-ProcessByToken fallback: unable to inspect Win32_Process for token '$Token'."
        return @()
    }
}

function Stop-ProcessesByToken {
    param([string]$Token)
    $targets = @(Find-ProcessByToken -Token $Token)
    foreach ($target in $targets) {
        try {
            Stop-Process -Id $target.ProcessId -Force -ErrorAction Stop
        }
        catch {
        }
    }
}

function Get-LocalStagePaths {
    param(
        [string]$StageName,
        [string]$Kind
    )
    switch ($Kind) {
        "redjac" {
            $stageDir = Join-Path $scriptDir ("truth\reduced_path_jacobian\" + $StageName)
            return [ordered]@{
                stage_dir = $stageDir
                summary_csv = Join-Path $stageDir ($StageName + "_summary.csv")
                price_csv = Join-Path $stageDir ($StageName + "_final_price_path.csv")
                vote_csv = Join-Path $stageDir ($StageName + "_final_vote_path.csv")
            }
        }
        "dynare" {
            $stageDir = Join-Path $scriptDir ("truth\dynare_reduced_path\" + $StageName)
            return [ordered]@{
                stage_dir = $stageDir
                summary_csv = Join-Path $stageDir ($StageName + "_summary.csv")
                price_csv = Join-Path $stageDir ($StageName + "_final_price_path.csv")
                vote_csv = Join-Path $stageDir ($StageName + "_final_vote_path.csv")
            }
        }
        default {
            throw "Unknown local stage kind: $Kind"
        }
    }
}

function Read-LocalStageResult {
    param($Stage)

    $paths = Get-LocalStagePaths -StageName $Stage.name -Kind $Stage.kind
    if (-not (Test-Path $paths.summary_csv)) {
        return $null
    }

    $rows = @(Import-Csv -Path $paths.summary_csv)
    if ($rows.Count -eq 0) {
        return $null
    }

    $bestRow = $rows[-1]
    $maxAbsVote = if ($bestRow.PSObject.Properties.Name -contains "max_abs_vote") {
        Parse-Double $bestRow.max_abs_vote
    } else {
        Parse-Double $bestRow.accepted_max_abs_vote (Parse-Double $bestRow.current_max_abs_vote)
    }
    $maxAbsGap = if ($bestRow.PSObject.Properties.Name -contains "max_abs_gap") {
        Parse-Double $bestRow.max_abs_gap
    } else {
        Parse-Double $bestRow.accepted_max_abs_gap (Parse-Double $bestRow.current_max_abs_gap)
    }
    $merit = if ($bestRow.PSObject.Properties.Name -contains "merit") {
        Parse-Double $bestRow.merit
    } else {
        Parse-Double $bestRow.accepted_merit (Parse-Double $bestRow.current_merit)
    }

    return [ordered]@{
        name = $Stage.name
        kind = $Stage.kind
        status = "completed"
        completed_at = (Get-Date).ToString("s")
        max_abs_vote = $maxAbsVote
        max_abs_gap = $maxAbsGap
        merit = $merit
        best_price_csv = $paths.price_csv
        best_vote_csv = $paths.vote_csv
        summary_csv = $paths.summary_csv
        improved = ($maxAbsVote -lt ($bestGlobal.max_abs_vote - 1e-4))
    }
}

function Start-LocalStage {
    param(
        $Stage,
        [string]$SeedCsv
    )

    switch ($Stage.kind) {
        "redjac" {
            $runner = Join-Path $scriptDir "run_original_5yr_transition_reduced_path_jacobian.ps1"
            $proc = Start-Process powershell -ArgumentList @(
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-File", $runner,
                "-MatlabExe", $MatlabExe,
                "-MaxK", "14",
                "-MaxOuterIter", ([string]$Stage.max_outer_iter),
                "-BasisCount", ([string]$Stage.basis_count),
                "-SeedPriceCsvPath", $SeedCsv,
                "-RunTag", $Stage.name,
                "-CandidateScales", ($Stage.candidate_scales -join ","),
                "-TrustRegionLogStep", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $Stage.trust_region_log_step))
            ) -PassThru -WindowStyle Hidden
        }
        "dynare" {
            $runner = Join-Path $scriptDir "run_original_5yr_transition_dynare_reduced_path.ps1"
            $proc = Start-Process powershell -ArgumentList @(
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-File", $runner,
                "-MatlabExe", $MatlabExe,
                "-MaxK", "14",
                "-MaxOuterIter", ([string]$Stage.max_outer_iter),
                "-BasisCount", ([string]$Stage.basis_count),
                "-SeedPriceCsvPath", $SeedCsv,
                "-RunTag", $Stage.name,
                "-CandidateScales", ($Stage.candidate_scales -join ","),
                "-TrustRegionLogStep", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:R}", $Stage.trust_region_log_step))
            ) -PassThru -WindowStyle Hidden
        }
        default {
            throw "Unknown stage kind: $($Stage.kind)"
        }
    }

    $paths = Get-LocalStagePaths -StageName $Stage.name -Kind $Stage.kind
    return [ordered]@{
        name = $Stage.name
        kind = $Stage.kind
        started_at = (Get-Date).ToString("s")
        pid = $proc.Id
        timeout_hours = $Stage.timeout_hours
        summary_csv = $paths.summary_csv
        price_csv = $paths.price_csv
        vote_csv = $paths.vote_csv
        seed_csv = $SeedCsv
        attached = $false
    }
}

function Attach-CurrentLocalStage {
    foreach ($stage in $localStages) {
        if ($stage.completed -or -not $stage.attach_existing) {
            continue
        }
        $token = if ($stage.token) { [string]$stage.token } else { [string]$stage.name }
        $paths = Get-LocalStagePaths -StageName $stage.name -Kind $stage.kind
        if (Test-Path $paths.summary_csv) {
            continue
        }

        $attachedProcesses = @(Find-ProcessByToken -Token $token)
        if ($attachedProcesses.Count -eq 0) {
            continue
        }

        $attachedPid = 0
        $attachedStartedAt = (Get-Date).ToString("s")
        $procStarts = @()
        foreach ($proc in $attachedProcesses) {
            try {
                $liveProc = Get-Process -Id $proc.ProcessId -ErrorAction Stop
                $procStarts += [pscustomobject]@{
                    pid = $proc.ProcessId
                    started_at = $liveProc.StartTime
                }
            }
            catch {
            }
        }
        if ($procStarts.Count -gt 0) {
            $oldest = $procStarts | Sort-Object started_at | Select-Object -First 1
            $attachedPid = [int]$oldest.pid
            $attachedStartedAt = ([datetime]$oldest.started_at).ToString("s")
        }

        return [ordered]@{
            name = $stage.name
            kind = $stage.kind
            started_at = $attachedStartedAt
            pid = $attachedPid
            timeout_hours = $stage.timeout_hours
            summary_csv = $paths.summary_csv
            price_csv = $paths.price_csv
            vote_csv = $paths.vote_csv
            seed_csv = $defaultSeedCsv
            attached = $true
        }
    }

    return $null
}

function Get-StageSeedPath {
    param([string]$StageName)

    $matching = @($localStageResults | Where-Object { $_.name -eq $StageName })
    if ($matching.Count -eq 0) {
        return $defaultSeedCsv
    }
    $last = $matching[-1]
    if ($last.best_price_csv -and (Test-Path $last.best_price_csv)) {
        return [string]$last.best_price_csv
    }
    return $defaultSeedCsv
}

function Get-PreferredHamiltonSeedPath {
    if ($currentLocalStage -and $currentLocalStage.price_csv -and (Test-Path $currentLocalStage.price_csv)) {
        return [string]$currentLocalStage.price_csv
    }

    $localSeedCandidates = @(
        $localStageResults.ToArray() |
            Where-Object {
                $_.best_price_csv -and
                (Test-Path $_.best_price_csv)
            } |
            Sort-Object completed_at -Descending
    )
    if ($localSeedCandidates.Count -gt 0) {
        return [string]$localSeedCandidates[0].best_price_csv
    }

    return [string]$bestGlobal.seed_price_csv
}

function Get-CurrentHamiltonPacketState {
    param($Phase)

    $statePath = [string]$Phase.state_path
    if (-not (Test-Path $statePath)) {
        return $null
    }

    $state = Get-Content -Raw -Path $statePath | ConvertFrom-Json
    if (-not $state.jobs -or @($state.jobs).Count -eq 0) {
        return $null
    }

    $ids = (@($state.jobs) | ForEach-Object { $_.job_id }) -join ','
    $sacctOutput = & ssh -tt hamilton8 "sacct -j $ids --format=JobID,State,Elapsed,ExitCode,JobName%60 -P"
    if ($LASTEXITCODE -ne 0) {
        return [ordered]@{
            phase = $Phase
            state = $state
            run_state = "query_failed"
            sacct_output = $sacctOutput
        }
    }

    $rows = @()
    foreach ($line in ($sacctOutput -split "`r?`n")) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line -like 'JobID|State*') {
            continue
        }
        $parts = $line.Split('|')
        if ($parts.Count -lt 5) { continue }
        if ($parts[0] -match '\.') { continue }
        $rows += [pscustomobject]@{
            JobID = $parts[0]
            State = $parts[1]
            Elapsed = $parts[2]
            ExitCode = $parts[3]
            JobName = $parts[4]
        }
    }

    $running = @($rows | Where-Object { $_.State -match 'RUNNING|PENDING|CONFIGURING|COMPLETING' })
    $failed = @($rows | Where-Object { $_.State -match 'FAILED|CANCELLED|TIMEOUT|NODE_FAIL|OUT_OF_MEMORY' })
    $completed = @($rows | Where-Object { $_.State -eq 'COMPLETED' })

    $runState = if ($running.Count -gt 0) {
        "running"
    } elseif ($failed.Count -gt 0 -and $completed.Count -eq 0) {
        "failed"
    } else {
        "completed"
    }

    return [ordered]@{
        phase = $Phase
        state = $state
        rows = $rows
        run_state = $runState
    }
}

function Read-JointSupplyWedgePacketResults {
    param($PacketState)

    $results = @()
    $remoteProject = [string]$PacketState.state.remote_project

    foreach ($job in @($PacketState.state.jobs)) {
        $stageName = [string]$job.stage_name
        $remoteStageDir = "$remoteProject/original_5yr_political_re/truth/joint_supply_wedge/$stageName"
        $remoteSummary = "$remoteStageDir/${stageName}_summary.csv"
        $remotePrice = "$remoteStageDir/${stageName}_final_price_path.csv"
        $remoteVote = "$remoteStageDir/${stageName}_final_vote_path.csv"

        $localSummary = Join-Path $runDir ($stageName + "_summary.csv")
        $localPrice = Join-Path $runDir ($stageName + "_final_price_path.csv")
        $localVote = Join-Path $runDir ($stageName + "_final_vote_path.csv")

        & scp ("hamilton8:" + $remoteSummary) $localSummary | Out-Null
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $localSummary)) {
            $results += [ordered]@{
                stage_name = $stageName
                packet_kind = "joint_supply_wedge"
                packet_profile = [string]$PacketState.state.packet_profile
                status = "missing_summary"
            }
            continue
        }

        & scp ("hamilton8:" + $remotePrice) $localPrice | Out-Null
        & scp ("hamilton8:" + $remoteVote) $localVote | Out-Null
        $rows = @(Import-Csv -Path $localSummary)
        if ($rows.Count -eq 0) {
            $results += [ordered]@{
                stage_name = $stageName
                packet_kind = "joint_supply_wedge"
                packet_profile = [string]$PacketState.state.packet_profile
                status = "empty_summary"
            }
            continue
        }

        $row = $rows[-1]
        $results += [ordered]@{
            stage_name = $stageName
            packet_kind = "joint_supply_wedge"
            packet_profile = [string]$PacketState.state.packet_profile
            status = "completed"
            max_abs_vote = Parse-Double $row.final_max_abs_vote
            max_abs_gap = Parse-Double $row.final_max_abs_gap
            merit = Parse-Double $row.final_merit
            summary_csv = $localSummary
            price_csv = if (Test-Path $localPrice) { $localPrice } else { "" }
            vote_csv = if (Test-Path $localVote) { $localVote } else { "" }
            improved = $false
        }
    }

    foreach ($result in $results) {
        if ($result.status -eq "completed" -and $result.max_abs_vote -lt ($bestGlobal.max_abs_vote - 1e-4)) {
            $result.improved = $true
        }
    }

    return $results
}

function Harvest-HamiltonCompletedResults {
    param($PacketState)

    if ($null -eq $PacketState -or -not $PacketState.rows) {
        return @()
    }

    $loggedStageNames = Get-LoggedHamiltonStageNames
    $completedStageNames = @(
        $PacketState.rows |
            Where-Object { $_.State -eq "COMPLETED" } |
            ForEach-Object { [string]$_.JobName }
    )
    $pendingStageNames = @($completedStageNames | Where-Object { $_ -and ($_ -notin $loggedStageNames) })
    if ($pendingStageNames.Count -eq 0) {
        return @()
    }

    $packetClone = $PacketState | ConvertTo-Json -Depth 12 | ConvertFrom-Json
    $packetClone.state.jobs = @(
        $packetClone.state.jobs | Where-Object { $pendingStageNames -contains [string]$_.stage_name }
    )
    $packetClone.rows = @(
        $packetClone.rows | Where-Object { $pendingStageNames -contains [string]$_.JobName }
    )

    return @(Read-JointSupplyWedgePacketResults -PacketState $packetClone)
}

function Submit-HamiltonPacket {
    param(
        $Phase,
        [string]$SeedCsv
    )

    & $Phase.submitter -SeedPricePathCsv $SeedCsv -PacketProfile $Phase.profile | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Hamilton packet submit failed for profile $($Phase.profile)"
    }
    return Get-CurrentHamiltonPacketState -Phase $Phase
}

function Update-BestGlobal {
    param($Result)

    if ($null -eq $Result) {
        return
    }
    if (-not $Result.max_abs_vote) {
        return
    }
    if ($Result.max_abs_vote -lt ($bestGlobal.max_abs_vote - 1e-4)) {
        if ($Result.PSObject.Properties['name'] -and -not [string]::IsNullOrWhiteSpace([string]$Result.name)) {
            $bestGlobal.source = [string]$Result.name
        }
        elseif ($Result.PSObject.Properties['stage_name'] -and -not [string]::IsNullOrWhiteSpace([string]$Result.stage_name)) {
            $bestGlobal.source = [string]$Result.stage_name
        }
        else {
            $bestGlobal.source = "unknown"
        }
        $bestGlobal.max_abs_vote = $Result.max_abs_vote
        $bestGlobal.max_abs_gap = $Result.max_abs_gap
        $bestGlobal.seed_price_csv = if ($Result.best_price_csv) { $Result.best_price_csv } elseif ($Result.price_csv) { $Result.price_csv } else { $bestGlobal.seed_price_csv }
        $bestGlobal.improved = $true
        $bestGlobal.updated_at = (Get-Date).ToString("s")
    }
}

function Write-LiveState {
    param(
        [string]$State,
        [string]$Classification
    )

    $payload = [ordered]@{
        workflow = "original_5yr_transition_dual_solver_boss"
        run_id = $runId
        classification = $Classification
        elapsed_hours = [math]::Round((Get-ElapsedHours), 3)
        best_global = $bestGlobal
        local_current = $currentLocalStage
        local_results = @($localStageResults.ToArray())
        hamilton_current = $currentHamiltonPacket
        hamilton_results = @($hamiltonPacketResults.ToArray())
        local_queue = $localStages
        hamilton_queue = $hamiltonPhases
    }

    [ordered]@{
        state = $State
        current_step = if ($currentLocalStage) { $currentLocalStage.name } elseif ($currentHamiltonPacket) { $currentHamiltonPacket.phase.name } else { "idle" }
        updated_at = (Get-Date).ToString("s")
        run_dir = $runDir
        payload = $payload
    } | ConvertTo-Json -Depth 12 | Set-Content -Path $statusPath

    $reportLines = @(
        "# Original 5-year dual solver boss",
        "",
        "- State: $State",
        "- Classification: $Classification",
        "- Updated: $((Get-Date).ToString('s'))",
        "- Elapsed hours: $([math]::Round((Get-ElapsedHours), 2))",
        "- Best max |vote|: $($bestGlobal.max_abs_vote)",
        "- Best max gap: $($bestGlobal.max_abs_gap)",
        "- Best source: $($bestGlobal.source)",
        "- Local current: $(if ($currentLocalStage) { $currentLocalStage.name } else { 'none' })",
        "- Hamilton current: $(if ($currentHamiltonPacket) { $currentHamiltonPacket.phase.name } else { 'none' })",
        "- Local completed: $($localStageResults.Count)",
        "- Hamilton results logged: $($hamiltonPacketResults.Count)"
    )
    Set-Content -Path $reportPath -Value ($reportLines -join [Environment]::NewLine)
}

Write-Log "Dual solver boss started."

if (Test-Path $statusPath) {
    try {
        $priorStatus = Get-Content -Raw -Path $statusPath | ConvertFrom-Json
        if ($priorStatus.payload) {
            foreach ($result in @($priorStatus.payload.local_results)) {
                if ($result.name) {
                    $localStageResults.Add($result)
                }
            }
            foreach ($result in @($priorStatus.payload.hamilton_results)) {
                if ($result.stage_name) {
                    $hamiltonPacketResults.Add($result)
                }
            }

            foreach ($stage in $localStages) {
                $priorStage = @($priorStatus.payload.local_queue | Where-Object { $_.name -eq $stage.name } | Select-Object -First 1)
                if ($priorStage.Count -gt 0 -and $priorStage[0].PSObject.Properties['completed']) {
                    $stage.completed = [bool]$priorStage[0].completed
                }
            }

            foreach ($phase in $hamiltonPhases) {
                $priorPhase = @($priorStatus.payload.hamilton_queue | Where-Object { $_.name -eq $phase.name } | Select-Object -First 1)
                if ($priorPhase.Count -gt 0) {
                    if ($priorPhase[0].PSObject.Properties['submitted']) {
                        $phase.submitted = [bool]$priorPhase[0].submitted
                    }
                    if ($priorPhase[0].PSObject.Properties['completed']) {
                        $phase.completed = [bool]$priorPhase[0].completed
                    }
                    if ($priorPhase[0].PSObject.Properties['retries']) {
                        $phase.retries = [int]$priorPhase[0].retries
                    }
                }
            }

            $priorBestVote = Parse-Double $priorStatus.payload.best_global.max_abs_vote
            $priorBestGap = Parse-Double $priorStatus.payload.best_global.max_abs_gap
            if (-not [double]::IsNaN($priorBestVote) -and $priorBestVote -lt $bestGlobal.max_abs_vote) {
                $bestGlobal.source = [string]$priorStatus.payload.best_global.source
                $bestGlobal.max_abs_vote = $priorBestVote
                $bestGlobal.max_abs_gap = $priorBestGap
                $bestGlobal.seed_price_csv = if ($priorStatus.payload.best_global.seed_price_csv) {
                    [string]$priorStatus.payload.best_global.seed_price_csv
                } else {
                    $bestGlobal.seed_price_csv
                }
                $bestGlobal.improved = [bool]$priorStatus.payload.best_global.improved
                $bestGlobal.updated_at = [string]$priorStatus.payload.best_global.updated_at
            }
        }
    }
    catch {
        Write-Log "Failed to resume prior status; starting fresh."
    }
}

$attachedLocalStage = Attach-CurrentLocalStage
if ($attachedLocalStage) {
    $currentLocalStage = $attachedLocalStage
    Write-Log "Attached to current local stage $($currentLocalStage.name)."
}

$baselinePhase = $hamiltonPhases | Where-Object { $_.name -eq "joint_wedge_baseline" } | Select-Object -First 1
$hamState = Get-CurrentHamiltonPacketState -Phase $baselinePhase
if ($hamState -and $hamState.run_state -eq "running") {
    $currentHamiltonPacket = $hamState
    $baselinePhase.submitted = $true
    Write-Log "Attached to current Hamilton joint-supply-wedge packet (baseline)."
}

Write-LiveState -State "running" -Classification "active"

while ((Get-ElapsedHours) -lt $MaxHours) {
    if ($currentLocalStage) {
        $localResult = Read-LocalStageResult -Stage $currentLocalStage
        if ($localResult) {
            $localStageResults.Add($localResult)
            Update-BestGlobal -Result $localResult
            Write-Log "Local stage $($currentLocalStage.name) completed. max |vote|=$($localResult.max_abs_vote)"
            foreach ($stage in $localStages) {
                if ($stage.name -eq $currentLocalStage.name) {
                    $stage.completed = $true
                }
            }
            $currentLocalStage = $null
        }
        else {
            $stageStartedAt = Get-DateSafe $currentLocalStage.started_at
            $stageAgeHours = if ($stageStartedAt) { ((Get-Date) - $stageStartedAt).TotalHours } else { 0.0 }
            if ($stageAgeHours -ge [double]$currentLocalStage.timeout_hours) {
                Stop-ProcessesByToken -Token $currentLocalStage.name
                $timedOut = [ordered]@{
                    name = $currentLocalStage.name
                    kind = $currentLocalStage.kind
                    status = "timed_out_without_summary"
                    completed_at = (Get-Date).ToString("s")
                    best_price_csv = ""
                    max_abs_vote = [double]::NaN
                    max_abs_gap = [double]::NaN
                    improved = $false
                }
                $localStageResults.Add($timedOut)
                Write-Log "Local stage $($currentLocalStage.name) timed out after $([math]::Round($stageAgeHours,2))h; advancing."
                foreach ($stage in $localStages) {
                    if ($stage.name -eq $currentLocalStage.name) {
                        $stage.completed = $true
                    }
                }
                $currentLocalStage = $null
            }
        }
        if ($currentLocalStage -and (Find-ProcessByToken -Token $currentLocalStage.name).Count -eq 0 -and -not (Test-Path $currentLocalStage.summary_csv)) {
            $failed = [ordered]@{
                name = $currentLocalStage.name
                kind = $currentLocalStage.kind
                status = "failed_without_summary"
                completed_at = (Get-Date).ToString("s")
                best_price_csv = ""
                max_abs_vote = [double]::NaN
                max_abs_gap = [double]::NaN
                improved = $false
            }
            $localStageResults.Add($failed)
            Write-Log "Local stage $($currentLocalStage.name) failed without summary; advancing."
            foreach ($stage in $localStages) {
                if ($stage.name -eq $currentLocalStage.name) {
                    $stage.completed = $true
                }
            }
            $currentLocalStage = $null
        }
    }

    if (-not $currentLocalStage) {
        foreach ($stage in $localStages) {
            if ($stage.completed) { continue }
            if ($stage.attach_existing) {
                $stage.completed = $true
                $skipped = [ordered]@{
                    name = $stage.name
                    kind = $stage.kind
                    status = "skipped_no_attach"
                    completed_at = (Get-Date).ToString("s")
                    best_price_csv = ""
                    max_abs_vote = [double]::NaN
                    max_abs_gap = [double]::NaN
                    improved = $false
                }
                $localStageResults.Add($skipped)
                Write-Log "Attach-only local stage $($stage.name) not found; skipping."
                continue
            }

            $seedCsv = switch ($stage.name) {
                "local_dynare_reduced_retry" { $bestGlobal.seed_price_csv }
                "local_redjac_from_dynare_retry" { Get-StageSeedPath -StageName "local_dynare_reduced_retry" }
                default { $bestGlobal.seed_price_csv }
            }
            $currentLocalStage = Start-LocalStage -Stage $stage -SeedCsv $seedCsv
            Write-Log "Started local stage $($stage.name) with seed $seedCsv"
            break
        }
    }

    if ($currentHamiltonPacket) {
        $packetState = Get-CurrentHamiltonPacketState -Phase $currentHamiltonPacket.phase
        if ($packetState -and $packetState.run_state -eq "running") {
            $currentHamiltonPacket = $packetState
            $freshResults = @(Harvest-HamiltonCompletedResults -PacketState $packetState)
            foreach ($packetResult in $freshResults) {
                $hamiltonPacketResults.Add($packetResult)
                if ($packetResult.status -eq "completed") {
                    Update-BestGlobal -Result $packetResult
                    Write-Log "Hamilton job $($packetResult.stage_name) finished while packet still running. max |vote|=$($packetResult.max_abs_vote)"
                }
            }
        }
        else {
            if ($packetState) {
                $packetResults = @(Harvest-HamiltonCompletedResults -PacketState $packetState)
                foreach ($packetResult in $packetResults) {
                    $hamiltonPacketResults.Add($packetResult)
                    if ($packetResult.status -eq "completed") {
                        Update-BestGlobal -Result $packetResult
                    }
                }

                foreach ($phase in $hamiltonPhases) {
                    if ($phase.name -eq $currentHamiltonPacket.phase.name -and -not $phase.completed) {
                        $phase.completed = $true
                        break
                    }
                }

                $completedCount = @($packetResults | Where-Object { $_.status -eq 'completed' }).Count
                Write-Log "Hamilton phase $($currentHamiltonPacket.phase.name) finished with $completedCount completed summaries."
            }
            else {
                Write-Log "Current Hamilton phase $($currentHamiltonPacket.phase.name) lost state file; advancing."
            }
            $currentHamiltonPacket = $null
        }
    }

    if (-not $currentHamiltonPacket) {
        $nextPhase = $null
        foreach ($phase in $hamiltonPhases) {
            if ($phase.completed) { continue }
            if ($phase.submitted) { continue }
            $nextPhase = $phase
            break
        }

        if ($nextPhase) {
            if ($nextPhase.attach_existing) {
                $attached = Get-CurrentHamiltonPacketState -Phase $nextPhase
                if ($attached -and $attached.run_state -eq "running") {
                    $currentHamiltonPacket = $attached
                    $nextPhase.submitted = $true
                    Write-Log "Re-attached to running Hamilton phase $($nextPhase.name)."
                }
                else {
                    $seedCsv = Get-PreferredHamiltonSeedPath
                    $currentHamiltonPacket = Submit-HamiltonPacket -Phase $nextPhase -SeedCsv $seedCsv
                    $nextPhase.submitted = $true
                    Write-Log "Submitted Hamilton phase $($nextPhase.name) with seed $seedCsv"
                }
            }
            else {
                $seedCsv = Get-PreferredHamiltonSeedPath
                $currentHamiltonPacket = Submit-HamiltonPacket -Phase $nextPhase -SeedCsv $seedCsv
                $nextPhase.submitted = $true
                Write-Log "Submitted Hamilton phase $($nextPhase.name) with seed $seedCsv"
            }
        }
    }

    $allLocalDone = @($localStages | Where-Object { -not $_.completed }).Count -eq 0 -and (-not $currentLocalStage)
    $allHamiltonDone = @($hamiltonPhases | Where-Object { -not $_.completed -and -not $_.submitted }).Count -eq 0 -and (-not $currentHamiltonPacket)

    if ($bestGlobal.max_abs_vote -le 0.001) {
        Write-LiveState -State "completed" -Classification "re_complete"
        Write-Log "Stop condition reached: RE complete."
        break
    }
    if ($allLocalDone -and $allHamiltonDone) {
        Write-LiveState -State "completed" -Classification "queue_exhausted"
        Write-Log "Stop condition reached: queue exhausted."
        break
    }

    Write-LiveState -State "running" -Classification "active"
    Start-Sleep -Seconds 60
}

if ((Get-ElapsedHours) -ge $MaxHours) {
    Write-LiveState -State "completed" -Classification "time_budget_reached"
    Write-Log "Time budget reached."
}

$finalPayload = Get-Content -Raw -Path $statusPath | ConvertFrom-Json
$finalPayload | ConvertTo-Json -Depth 12 | Set-Content -Path $finalResultPath
