param(
    [double]$Hours = 12,
    [string]$SessionName = 'tr_full_horizon_away_live',
    [string]$K8TemplatePackName = 'tr_k8_a01808362',
    [string]$K9TemplatePackName = 'tr_k9_a01808362_min',
    [double]$InitialStableAlpha = 0.18083620071411133,
    [double]$InitialUnstableAlpha = 0.18083824634552,
    [string]$InitialStableK8Path = '',
    [string]$InitialStableK9Path = '',
    [double]$TargetBracketWidth = 1.0e-6,
    [double]$GapCutoff = 0.05,
    [double]$PriceBoundTol = 1.0e-6,
    [int]$PerAttemptMaxIter = 25,
    [int]$MaxProbes = 2147483647,
    [double]$MinFreeSpaceGB = 0.05,
    [double]$ReserveMinutes = 10.0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$truthDir = Join-Path $scriptDir 'truth'
$sessionDir = Join-Path $truthDir $SessionName
$resultsDir = Join-Path $sessionDir 'r'
$stateDir = Join-Path $sessionDir 's'
$workDir = Join-Path $sessionDir 'w'
$statePath = Join-Path $sessionDir 'workflow_state.json'
$logPath = Join-Path $sessionDir 'workflow_log.csv'
$handoffPath = Join-Path $sessionDir 'workflow_handoff.md'
$workflowStart = Get-Date
$deadline = $workflowStart.AddHours($Hours)
$stopAt = $deadline.AddMinutes(-1.0 * $ReserveMinutes)
$invariant = [System.Globalization.CultureInfo]::InvariantCulture

if (-not $InitialStableK8Path) {
    $InitialStableK8Path = Join-Path $truthDir 'tr_k8_a01808362_retryaware\attempt1\sidecar_re_final_price_path.csv'
}
if (-not $InitialStableK9Path) {
    $InitialStableK9Path = Join-Path $truthDir 'tr_k9_a01808362_min_retryaware\attempt1\sidecar_re_final_price_path.csv'
}

function Format-Double([double]$Value) {
    return $Value.ToString('R', $script:invariant)
}

function Format-AlphaToken([double]$Value) {
    $token = Format-Double $Value
    if ($token.Contains('.')) {
        while ($token.EndsWith('0')) {
            $token = $token.Substring(0, $token.Length - 1)
        }
        if ($token.EndsWith('.')) {
            $token = $token.Substring(0, $token.Length - 1)
        }
    }
    return ($token.Replace('.', '_')).Replace('-', 'm')
}

function Read-NumericCsvVector([string]$Path) {
    $values = New-Object System.Collections.Generic.List[double]
    foreach ($line in Get-Content -LiteralPath $Path) {
        foreach ($field in ($line -split ',')) {
            $trimmed = $field.Trim()
            if ($trimmed.Length -gt 0) {
                $values.Add([double]::Parse($trimmed, $script:invariant))
            }
        }
    }
    return ,$values.ToArray()
}

function Write-NumericCsvVector([string]$Path, [double[]]$Values) {
    $lines = foreach ($value in $Values) { Format-Double $value }
    [System.IO.File]::WriteAllLines($Path, $lines)
}

function Read-NamedCsv([string]$Path) {
    $map = @{}
    $rows = Import-Csv -LiteralPath $Path
    foreach ($row in $rows) {
        $map[[string]$row.name] = [string]$row.value
    }
    return $map
}

function Write-NamedScalarCsv([string]$Path, [hashtable]$Map) {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('name,value')
    foreach ($key in $Map.Keys) {
        $value = $Map[$key]
        if ($value -is [double] -or $value -is [single] -or $value -is [int] -or $value -is [long]) {
            $rendered = Format-Double ([double]$value)
        } else {
            $rendered = [string]$value
        }
        $lines.Add(('{0},{1}' -f $key, $rendered))
    }
    [System.IO.File]::WriteAllLines($Path, $lines)
}

function Get-FreeSpaceGB {
    $drive = Get-PSDrive C
    return [math]::Round(($drive.Free / 1GB), 6)
}

function Ensure-PathExists([string]$Path, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Label not found: $Path"
    }
}

function Ensure-SessionScaffold {
    foreach ($dir in @($sessionDir, $resultsDir, $stateDir, $workDir)) {
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir | Out-Null
        }
    }
    if (-not (Test-Path -LiteralPath $logPath)) {
        Set-Content -LiteralPath $logPath -Value 'probe_index,alpha,k8_status,k8_looks_stable,k8_gap,k9_status,k9_looks_stable,k9_gap,lower_alpha_before,upper_alpha_before,lower_alpha_after,upper_alpha_after,bracket_width_after,free_space_gb_after,elapsed_seconds'
    }
}

function Normalize-WorkflowLog([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return 0
    }

    $rows = @(Import-Csv -LiteralPath $Path)
    if ($rows.Count -eq 0) {
        return 0
    }

    $byProbe = @{}
    foreach ($row in $rows) {
        $byProbe[[int]$row.probe_index] = $row
    }

    $ordered = $byProbe.GetEnumerator() |
        Sort-Object Name |
        ForEach-Object { $_.Value }

    $header = 'probe_index,alpha,k8_status,k8_looks_stable,k8_gap,k9_status,k9_looks_stable,k9_gap,lower_alpha_before,upper_alpha_before,lower_alpha_after,upper_alpha_after,bracket_width_after,free_space_gb_after,elapsed_seconds'
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add($header)
    foreach ($row in $ordered) {
        $lines.Add((
            '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14}' -f
            $row.probe_index,
            $row.alpha,
            $row.k8_status,
            $row.k8_looks_stable,
            $row.k8_gap,
            $row.k9_status,
            $row.k9_looks_stable,
            $row.k9_gap,
            $row.lower_alpha_before,
            $row.upper_alpha_before,
            $row.lower_alpha_after,
            $row.upper_alpha_after,
            $row.bracket_width_after,
            $row.free_space_gb_after,
            $row.elapsed_seconds))
    }
    [System.IO.File]::WriteAllLines($Path, $lines)

    return ($ordered | Measure-Object -Property probe_index -Maximum).Maximum
}

function Get-SelectedAttemptName([hashtable]$SummaryMap) {
    if (-not $SummaryMap.ContainsKey('selected_attempt')) {
        throw "Retry-aware summary is missing selected_attempt."
    }
    return ('attempt{0}' -f [int]$SummaryMap['selected_attempt'])
}

function Truncate-Vector([double[]]$Values, [int]$Count) {
    if ($Values.Length -lt $Count) {
        throw "Cannot truncate vector of length $($Values.Length) to $Count."
    }
    return ,($Values[0..($Count - 1)])
}

function Extend-Vector([double[]]$Prefix, [double[]]$Anchor, [int]$Count) {
    if ($Anchor.Length -lt $Count) {
        throw "Anchor vector length $($Anchor.Length) is shorter than requested count $Count."
    }
    if ($Prefix.Length -ge $Count) {
        return ,($Prefix[0..($Count - 1)])
    }
    $values = New-Object System.Collections.Generic.List[double]
    foreach ($value in $Prefix) {
        $values.Add($value)
    }
    for ($i = $Prefix.Length; $i -lt $Count; $i++) {
        $values.Add($Anchor[$i])
    }
    return ,$values.ToArray()
}

function New-MinimalPackFromTemplate(
    [string]$TemplateDir,
    [string]$DestinationDir,
    [double]$Alpha,
    [double[]]$WarmStart
) {
    Ensure-PathExists $TemplateDir 'Template pack'
    if (Test-Path -LiteralPath $DestinationDir) {
        Remove-Item -LiteralPath $DestinationDir -Recurse -Force
    }
    Copy-Item -LiteralPath $TemplateDir -Destination $DestinationDir -Recurse

    $metaScalarsPath = Join-Path $DestinationDir 'meta_scalars.csv'
    $metaScalars = Read-NamedCsv $metaScalarsPath
    $metaScalars['policy_reference_blend_weight'] = (Format-Double $Alpha)
    Write-NamedScalarCsv $metaScalarsPath $metaScalars

    Write-NumericCsvVector (Join-Path $DestinationDir 'price_path.csv') $WarmStart
    Write-NumericCsvVector (Join-Path $DestinationDir 're_initial_price_path.csv') $WarmStart
}

function Invoke-RetryAwareRun(
    [string]$InputDir,
    [string]$OutputDir,
    [double]$GapCutoff,
    [double]$PriceBoundTol,
    [int]$PerAttemptMaxIter
) {
    & (Join-Path $script:scriptDir 'run_transition_re_retryaware.ps1') `
        -InputDir $InputDir `
        -OutputDir $OutputDir `
        -GapCutoff $GapCutoff `
        -PriceBoundTol $PriceBoundTol `
        -PerAttemptMaxIter $PerAttemptMaxIter `
        -SkipBuild
}

function Get-CompactRetryAwareResult(
    [string]$OutputDir,
    [string]$CompactDir,
    [int]$Horizon,
    [double]$Alpha
) {
    $summaryPath = Join-Path $OutputDir 'sidecar_retryaware_summary.csv'
    $attemptsPath = Join-Path $OutputDir 'sidecar_retryaware_attempts.csv'
    $statusPath = Join-Path $OutputDir 'sidecar_retryaware_status.txt'
    Ensure-PathExists $summaryPath 'Retry-aware summary'
    Ensure-PathExists $attemptsPath 'Retry-aware attempts'
    Ensure-PathExists $statusPath 'Retry-aware status'

    if (-not (Test-Path -LiteralPath $CompactDir)) {
        New-Item -ItemType Directory -Path $CompactDir | Out-Null
    }

    $summaryMap = Read-NamedCsv $summaryPath
    $selectedAttemptName = Get-SelectedAttemptName $summaryMap
    $selectedAttemptDir = Join-Path $OutputDir $selectedAttemptName
    $selectedPath = Join-Path $selectedAttemptDir 'sidecar_re_final_price_path.csv'
    $selectedPolicyRefPath = Join-Path $selectedAttemptDir 'sidecar_re_policy_reference_price_path_used.csv'
    Ensure-PathExists $selectedPath 'Selected final price path'

    Copy-Item -LiteralPath $summaryPath -Destination (Join-Path $CompactDir 'sidecar_retryaware_summary.csv') -Force
    Copy-Item -LiteralPath $attemptsPath -Destination (Join-Path $CompactDir 'sidecar_retryaware_attempts.csv') -Force
    Copy-Item -LiteralPath $statusPath -Destination (Join-Path $CompactDir 'sidecar_retryaware_status.txt') -Force
    Copy-Item -LiteralPath $selectedPath -Destination (Join-Path $CompactDir 'selected_final_price_path.csv') -Force
    if (Test-Path -LiteralPath $selectedPolicyRefPath) {
        Copy-Item -LiteralPath $selectedPolicyRefPath -Destination (Join-Path $CompactDir 'selected_policy_reference_price_path_used.csv') -Force
    }

    $metadata = [ordered]@{
        horizon = $Horizon
        alpha = $Alpha
        selected_attempt = [int]$summaryMap['selected_attempt']
        looks_stable = [bool]([int]$summaryMap['looks_stable'])
        final_max_abs_gap = [double]$summaryMap['final_max_abs_gap']
        final_residual_norm = [double]$summaryMap['final_residual_norm']
        price_min = [double]$summaryMap['price_min']
        price_max = [double]$summaryMap['price_max']
        retryaware_status = (Get-Content -LiteralPath $statusPath -Raw).Trim()
    }
    Set-Content -LiteralPath (Join-Path $CompactDir 'compact_metadata.json') -Value ($metadata | ConvertTo-Json -Depth 4)

    return [pscustomobject]@{
        Horizon = $Horizon
        Alpha = $Alpha
        LooksStable = [bool]([int]$summaryMap['looks_stable'])
        FinalMaxAbsGap = [double]$summaryMap['final_max_abs_gap']
        FinalResidualNorm = [double]$summaryMap['final_residual_norm']
        PriceMin = [double]$summaryMap['price_min']
        PriceMax = [double]$summaryMap['price_max']
        RetryAwareStatus = (Get-Content -LiteralPath $statusPath -Raw).Trim()
        SelectedAttempt = [int]$summaryMap['selected_attempt']
        SelectedFinalPricePathCsv = (Join-Path $CompactDir 'selected_final_price_path.csv')
    }
}

function Remove-IfExists([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

function Save-State([hashtable]$State) {
    $State.updated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    Set-Content -LiteralPath $statePath -Value ($State | ConvertTo-Json -Depth 8)
}

function Write-Handoff([hashtable]$State, [string]$StopReason) {
    $width = [double]$State.upper_alpha_full - [double]$State.lower_alpha_full
    $lines = @(
        '# Compiled full-horizon away workflow',
        '',
        ('- Session: {0}' -f $State.session_name),
        ('- Stop reason: {0}' -f $StopReason),
        ('- Probes completed this session: {0}' -f $State.probes_completed_this_session),
        ('- Total probes recorded: {0}' -f $State.probes_completed_total),
        ('- Current full-horizon bracket: [{0}, {1}]' -f
            (Format-Double ([double]$State.lower_alpha_full)),
            (Format-Double ([double]$State.upper_alpha_full))),
        ('- Current bracket width: {0}' -f (Format-Double $width)),
        ('- Best stable k = 8 alpha: {0}' -f (Format-Double ([double]$State.stable_alpha_k8))),
        ('- Best stable k = 9 alpha: {0}' -f (Format-Double ([double]$State.stable_alpha_k9))),
        ('- Last probe alpha: {0}' -f $State.last_probe_alpha),
        ('- Last probe k = 8 status: {0}' -f $State.last_probe_k8_status),
        ('- Last probe k = 9 status: {0}' -f $State.last_probe_k9_status),
        ('- Free disk on C: at stop: {0} GB' -f (Format-Double ([double]$State.free_space_gb_at_stop))),
        '',
        '## Resume',
        '',
        'Run:',
        '',
        '```powershell',
        ('.\run_transition_re_full_horizon_away_workflow.ps1 -SessionName {0} -Hours 12' -f $State.session_name),
        '```',
        '',
        '## Files',
        '',
        ('- State: {0}' -f (Split-Path -Leaf $statePath)),
        ('- Log: {0}' -f (Split-Path -Leaf $logPath)),
        '- Stable k = 8 path: s\stable_k8_selected_final_price_path.csv',
        '- Stable k = 9 path: s\stable_k9_selected_final_price_path.csv'
    )
    Set-Content -LiteralPath $handoffPath -Value ($lines -join [Environment]::NewLine)
}

Ensure-PathExists (Join-Path $truthDir $K8TemplatePackName) 'k=8 template pack'
Ensure-PathExists (Join-Path $truthDir $K9TemplatePackName) 'k=9 template pack'
Ensure-PathExists $InitialStableK8Path 'Initial stable k=8 path'
Ensure-PathExists $InitialStableK9Path 'Initial stable k=9 path'

Ensure-SessionScaffold
$maxProbeIndexInLog = Normalize-WorkflowLog -Path $logPath

$exePath = Join-Path $scriptDir 'build\nimby_transition_re_retryaware_cli.exe'
if (-not (Test-Path -LiteralPath $exePath)) {
    & (Join-Path $scriptDir 'build.ps1')
}
Ensure-PathExists $exePath 'Compiled retry-aware CLI'

$state =
    if (Test-Path -LiteralPath $statePath) {
        $loaded = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        [ordered]@{
            session_name = [string]$loaded.session_name
            session_created_at_utc = [string]$loaded.session_created_at_utc
            last_run_started_at_utc = $workflowStart.ToUniversalTime().ToString('o')
            deadline_utc = $deadline.ToUniversalTime().ToString('o')
            hours = $Hours
            reserve_minutes = $ReserveMinutes
            target_bracket_width = [double]$loaded.target_bracket_width
            min_free_space_gb = [double]$loaded.min_free_space_gb
            lower_alpha_full = [double]$loaded.lower_alpha_full
            upper_alpha_full = [double]$loaded.upper_alpha_full
            stable_alpha_k8 = [double]$loaded.stable_alpha_k8
            stable_alpha_k9 = [double]$loaded.stable_alpha_k9
            stable_k8_path_csv = [string]$loaded.stable_k8_path_csv
            stable_k9_path_csv = [string]$loaded.stable_k9_path_csv
            probes_completed_total = [Math]::Max([int]$loaded.probes_completed_total, [int]$maxProbeIndexInLog)
            probes_completed_this_session = 0
            last_probe_alpha = [string]$loaded.last_probe_alpha
            last_probe_k8_status = [string]$loaded.last_probe_k8_status
            last_probe_k9_status = [string]$loaded.last_probe_k9_status
            last_stop_reason = [string]$loaded.last_stop_reason
            free_space_gb_at_stop = [double](Get-FreeSpaceGB)
        }
    } else {
        $stableK8StatePath = Join-Path $stateDir 'stable_k8_selected_final_price_path.csv'
        $stableK9StatePath = Join-Path $stateDir 'stable_k9_selected_final_price_path.csv'
        Copy-Item -LiteralPath $InitialStableK8Path -Destination $stableK8StatePath -Force
        Copy-Item -LiteralPath $InitialStableK9Path -Destination $stableK9StatePath -Force
        [ordered]@{
            session_name = $SessionName
            session_created_at_utc = $workflowStart.ToUniversalTime().ToString('o')
            last_run_started_at_utc = $workflowStart.ToUniversalTime().ToString('o')
            deadline_utc = $deadline.ToUniversalTime().ToString('o')
            hours = $Hours
            reserve_minutes = $ReserveMinutes
            target_bracket_width = $TargetBracketWidth
            min_free_space_gb = $MinFreeSpaceGB
            lower_alpha_full = $InitialStableAlpha
            upper_alpha_full = $InitialUnstableAlpha
            stable_alpha_k8 = $InitialStableAlpha
            stable_alpha_k9 = $InitialStableAlpha
            stable_k8_path_csv = $stableK8StatePath
            stable_k9_path_csv = $stableK9StatePath
            probes_completed_total = 0
            probes_completed_this_session = 0
            last_probe_alpha = ''
            last_probe_k8_status = ''
            last_probe_k9_status = ''
            last_stop_reason = ''
            free_space_gb_at_stop = [double](Get-FreeSpaceGB)
        }
    }

Ensure-PathExists $state.stable_k8_path_csv 'Stable k=8 state path'
Ensure-PathExists $state.stable_k9_path_csv 'Stable k=9 state path'

$stopReason = 'no_work_started'

try {
    Save-State $state

    while ($true) {
        $currentWidth = [double]$state.upper_alpha_full - [double]$state.lower_alpha_full
        if ($state.probes_completed_this_session -ge $MaxProbes) {
            $stopReason = 'max_probes_reached'
            break
        }
        if ($currentWidth -le [double]$state.target_bracket_width) {
            $stopReason = 'target_bracket_width_reached'
            break
        }
        if ((Get-Date) -ge $stopAt) {
            $stopReason = 'time_budget_reached'
            break
        }
        $freeSpaceGB = Get-FreeSpaceGB
        if ($freeSpaceGB -lt [double]$state.min_free_space_gb) {
            $stopReason = 'disk_guard_triggered'
            break
        }

        $probeIndex = [int]$state.probes_completed_total + 1
        $alpha = ([double]$state.lower_alpha_full + [double]$state.upper_alpha_full) / 2.0
        $alphaToken = Format-AlphaToken $alpha
        $probeName = ('p{0:D4}_a_{1}' -f $probeIndex, $alphaToken)
        $probeResultDir = Join-Path $resultsDir $probeName
        $probeWorkDir = Join-Path $workDir $probeName
        $k8InputDir = Join-Path $probeWorkDir 'k8i'
        $k8OutputDir = Join-Path $probeWorkDir 'k8o'
        $k9InputDir = Join-Path $probeWorkDir 'k9i'
        $k9OutputDir = Join-Path $probeWorkDir 'k9o'
        New-Item -ItemType Directory -Path $probeWorkDir -Force | Out-Null
        New-Item -ItemType Directory -Path $probeResultDir -Force | Out-Null

        $lowerBefore = [double]$state.lower_alpha_full
        $upperBefore = [double]$state.upper_alpha_full
        $probeStart = Get-Date

        $stableK8WarmStart = Truncate-Vector (Read-NumericCsvVector $state.stable_k8_path_csv) 8
        New-MinimalPackFromTemplate `
            -TemplateDir (Join-Path $truthDir $K8TemplatePackName) `
            -DestinationDir $k8InputDir `
            -Alpha $alpha `
            -WarmStart $stableK8WarmStart
        Invoke-RetryAwareRun `
            -InputDir $k8InputDir `
            -OutputDir $k8OutputDir `
            -GapCutoff $GapCutoff `
            -PriceBoundTol $PriceBoundTol `
            -PerAttemptMaxIter $PerAttemptMaxIter
        $k8Compact = Get-CompactRetryAwareResult `
            -OutputDir $k8OutputDir `
            -CompactDir (Join-Path $probeResultDir 'k8') `
            -Horizon 8 `
            -Alpha $alpha
        Remove-IfExists $k8InputDir
        Remove-IfExists $k8OutputDir

        $k9Compact = $null
        if ($k8Compact.LooksStable) {
            if ($alpha -gt [double]$state.stable_alpha_k8) {
                Copy-Item -LiteralPath $k8Compact.SelectedFinalPricePathCsv -Destination $state.stable_k8_path_csv -Force
                $state.stable_alpha_k8 = $alpha
            }

            if ((Get-Date) -lt $stopAt -and (Get-FreeSpaceGB) -ge [double]$state.min_free_space_gb) {
                $k9WarmStart = Extend-Vector `
                    -Prefix (Read-NumericCsvVector $k8Compact.SelectedFinalPricePathCsv) `
                    -Anchor (Read-NumericCsvVector $state.stable_k9_path_csv) `
                    -Count 9
                New-MinimalPackFromTemplate `
                    -TemplateDir (Join-Path $truthDir $K9TemplatePackName) `
                    -DestinationDir $k9InputDir `
                    -Alpha $alpha `
                    -WarmStart $k9WarmStart
                Invoke-RetryAwareRun `
                    -InputDir $k9InputDir `
                    -OutputDir $k9OutputDir `
                    -GapCutoff $GapCutoff `
                    -PriceBoundTol $PriceBoundTol `
                    -PerAttemptMaxIter $PerAttemptMaxIter
                $k9Compact = Get-CompactRetryAwareResult `
                    -OutputDir $k9OutputDir `
                    -CompactDir (Join-Path $probeResultDir 'k9') `
                    -Horizon 9 `
                    -Alpha $alpha
                Remove-IfExists $k9InputDir
                Remove-IfExists $k9OutputDir

                if ($k9Compact.LooksStable) {
                    Copy-Item -LiteralPath $k9Compact.SelectedFinalPricePathCsv -Destination $state.stable_k9_path_csv -Force
                    $state.stable_alpha_k9 = $alpha
                    $state.lower_alpha_full = $alpha
                } else {
                    $state.upper_alpha_full = $alpha
                }
            } else {
                $stopReason = 'time_or_disk_guard_after_k8'
            }
        } else {
            $state.upper_alpha_full = $alpha
        }

        $probeElapsed = ((Get-Date) - $probeStart).TotalSeconds
        $freeAfter = Get-FreeSpaceGB
        $k9Status = if ($null -eq $k9Compact) { 'not_run' } else { $k9Compact.RetryAwareStatus }
        $k9LooksStable = if ($null -eq $k9Compact) { '' } else { [int]$k9Compact.LooksStable }
        $k9Gap = if ($null -eq $k9Compact) { '' } else { Format-Double $k9Compact.FinalMaxAbsGap }
        Add-Content -LiteralPath $logPath -Value (
            ('{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14}' -f
                $probeIndex,
                (Format-Double $alpha),
                $k8Compact.RetryAwareStatus,
                ([int]$k8Compact.LooksStable),
                (Format-Double $k8Compact.FinalMaxAbsGap),
                $k9Status,
                $k9LooksStable,
                $k9Gap,
                (Format-Double $lowerBefore),
                (Format-Double $upperBefore),
                (Format-Double ([double]$state.lower_alpha_full)),
                (Format-Double ([double]$state.upper_alpha_full)),
                (Format-Double (([double]$state.upper_alpha_full) - ([double]$state.lower_alpha_full))),
                (Format-Double $freeAfter),
                (Format-Double $probeElapsed)))

        $state.probes_completed_total = [int]$state.probes_completed_total + 1
        $state.probes_completed_this_session = [int]$state.probes_completed_this_session + 1
        $state.last_probe_alpha = Format-Double $alpha
        $state.last_probe_k8_status = $k8Compact.RetryAwareStatus
        $state.last_probe_k9_status = $k9Status
        $state.free_space_gb_at_stop = $freeAfter
        Save-State $state

        Remove-IfExists $probeWorkDir

        if ($stopReason -eq 'time_or_disk_guard_after_k8') {
            break
        }
    }
} finally {
    $state.last_stop_reason = $stopReason
    $state.free_space_gb_at_stop = Get-FreeSpaceGB
    Save-State $state
    Write-Handoff -State $state -StopReason $stopReason
}

Write-Output "Compiled full-horizon away workflow complete"
Write-Output ("  session_name: {0}" -f $state.session_name)
Write-Output ("  stop_reason: {0}" -f $stopReason)
Write-Output ("  lower_alpha_full: {0}" -f (Format-Double ([double]$state.lower_alpha_full)))
Write-Output ("  upper_alpha_full: {0}" -f (Format-Double ([double]$state.upper_alpha_full)))
Write-Output ("  stable_alpha_k8: {0}" -f (Format-Double ([double]$state.stable_alpha_k8)))
Write-Output ("  stable_alpha_k9: {0}" -f (Format-Double ([double]$state.stable_alpha_k9)))
Write-Output ("  probes_completed_this_session: {0}" -f $state.probes_completed_this_session)
Write-Output ("  free_space_gb_at_stop: {0}" -f (Format-Double ([double]$state.free_space_gb_at_stop)))
