param(
    [ValidateSet('quick','focused','deep','full')]
    [string]$Profile = 'quick',
    [int]$DefaultTimeoutSeconds = 1800
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$runner = Join-Path $root 'run_ai_calibration.ps1'
$outputDir = Join-Path $root 'runtime/data/output/ablation'
$caseLogDir = Join-Path $root 'runtime/data/output/case_1'

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
New-Item -ItemType Directory -Force -Path $caseLogDir | Out-Null

function Get-LastLogForTag {
    param([Parameter(Mandatory = $true)][string]$RunTag)
    $pattern = ("run_*_{0}_*.log" -f $RunTag)
    $latest = Get-ChildItem -Path $caseLogDir -Filter $pattern -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $latest) { return $null }
    return $latest.FullName
}

function Get-ThetaStats {
    param([Parameter(Mandatory = $true)][string]$RawText)
    $matches = [regex]::Matches($RawText, 'old theta:\s*([\-0-9Ee\.\+]+)\s+new theta:\s*([\-0-9Ee\.\+]+)')
    $signChanges = 0
    $prevSign = 0
    $count = 0
    $boundaryHits = 0
    foreach ($m in $matches) {
        $oldTheta = [double]$m.Groups[1].Value
        $newTheta = [double]$m.Groups[2].Value
        if ([math]::Abs($newTheta) -lt 1e-9 -or [math]::Abs($newTheta - 1.0) -lt 1e-9) {
            $boundaryHits += 1
        }
        $delta = $newTheta - $oldTheta
        $sign = 0
        if ($delta -gt 0) { $sign = 1 }
        elseif ($delta -lt 0) { $sign = -1 }
        if ($sign -ne 0 -and $prevSign -ne 0 -and $sign -ne $prevSign) {
            $signChanges += 1
        }
        if ($sign -ne 0) {
            $prevSign = $sign
        }
        $count += 1
    }
    return [pscustomobject]@{
        theta_obs = $count
        theta_sign_changes = $signChanges
        theta_boundary_hits = $boundaryHits
    }
}

function Classify-Run {
    param(
        [Parameter(Mandatory = $true)][string]$LogPath,
        [Parameter(Mandatory = $true)][bool]$TimedOut
    )
    $raw = Get-Content -Path $LogPath -Raw

    $solveStatus = ''
    $solveMatches = [regex]::Matches($raw, '\[ABLT\]\s+solve_model_status=([a-z_]+)')
    if ($solveMatches.Count -gt 0) {
        $solveStatus = $solveMatches[$solveMatches.Count - 1].Groups[1].Value
    }
    $transitionStatus = ''
    $transitionMatches = [regex]::Matches($raw, '\[ABLT\]\s+transition_status=([a-z_]+)')
    if ($transitionMatches.Count -gt 0) {
        $transitionStatus = $transitionMatches[$transitionMatches.Count - 1].Groups[1].Value
    }

    $solveConverged = ($solveStatus -eq 'converged')
    $transitionConverged = ($transitionStatus -eq 'converged')
    $transitionSkipped = ($transitionStatus -eq 'skipped')
    $warnCount = ([regex]::Matches($raw, '\[WARN\]')).Count
    $errorCount = ([regex]::Matches($raw, '\[ERROR\]')).Count
    $nanInfCount = ([regex]::Matches($raw, '(?i)(^|[^a-z])(nan|inf)([^a-z]|$)')).Count
    $thetaStats = Get-ThetaStats -RawText $raw

    if ($TimedOut) { return 'stalled_timeout' }
    if ($solveConverged -and ($transitionConverged -or $transitionSkipped)) { return 'converged' }

    $boundaryShare = 0.0
    if ($thetaStats.theta_obs -gt 0) {
        $boundaryShare = $thetaStats.theta_boundary_hits / $thetaStats.theta_obs
    }

    if ($errorCount -gt 0 -or $warnCount -gt 25 -or $nanInfCount -gt 20 -or $boundaryShare -ge 0.6) { return 'blowing_up' }
    if ($thetaStats.theta_obs -ge 8 -and $thetaStats.theta_sign_changes -ge 4) { return 'oscillating' }
    return 'not_converged'
}

function Build-Matrix {
    param(
        [Parameter(Mandatory = $true)][string]$ProfileName,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds
    )

    $quick = @(
        [pscustomobject]@{ run_id='s00_baseline_probe'; scenario='baseline'; ui_override=''; skip_transition=$true;  fixed_theta='';    fixed_rho='';   max_iter_agg=3;  max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds },
        [pscustomobject]@{ run_id='s01_ui005_probe';    scenario='ui_005';   ui_override=''; skip_transition=$true;  fixed_theta='';    fixed_rho='';   max_iter_agg=3;  max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds },
        [pscustomobject]@{ run_id='s02_ui000_probe';    scenario='ui_000';   ui_override=''; skip_transition=$true;  fixed_theta='';    fixed_rho='';   max_iter_agg=3;  max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds },
        [pscustomobject]@{ run_id='s10_fixmatch_base';  scenario='baseline'; ui_override=''; skip_transition=$true;  fixed_theta='0.25'; fixed_rho='0.03'; max_iter_agg=3;  max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds },
        [pscustomobject]@{ run_id='s11_fixmatch_ui000'; scenario='ui_000';   ui_override=''; skip_transition=$true;  fixed_theta='0.25'; fixed_rho='0.03'; max_iter_agg=3;  max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds },
        [pscustomobject]@{ run_id='s20_baseline_long';  scenario='baseline'; ui_override=''; skip_transition=$true;  fixed_theta='';    fixed_rho='';   max_iter_agg=6; max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds }
    )

    if ($ProfileName -eq 'full') {
        $extra = @(
            [pscustomobject]@{ run_id='f30_ui010_long'; scenario='ui_010'; scenario_name='ui_010'; ui_override=''; skip_transition=$true; fixed_theta=''; fixed_rho=''; max_iter_agg=30; max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds },
            [pscustomobject]@{ run_id='f31_ui020_long'; scenario='ui_020'; scenario_name='ui_020'; ui_override=''; skip_transition=$true; fixed_theta=''; fixed_rho=''; max_iter_agg=30; max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds },
            [pscustomobject]@{ run_id='f40_transition_short'; scenario='baseline'; ui_override=''; skip_transition=$false; fixed_theta=''; fixed_rho=''; max_iter_agg=6; max_transition_iter=1; transition_tol=0.005; rng_seed=12345; timeout_seconds=$TimeoutSeconds }
        )
        return @($quick + $extra)
    }

    if ($ProfileName -eq 'focused') {
        return @(
            [pscustomobject]@{ run_id='g00_baseline_m15';        scenario='baseline'; ui_override=''; skip_transition=$true; fixed_theta='';    fixed_rho='';    max_iter_agg=15; max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds },
            [pscustomobject]@{ run_id='g01_ui000_m15';           scenario='ui_000';   ui_override=''; skip_transition=$true; fixed_theta='';    fixed_rho='';    max_iter_agg=15; max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds },
            [pscustomobject]@{ run_id='g02_ui000_fixmatch_m15';  scenario='ui_000';   ui_override=''; skip_transition=$true; fixed_theta='0.25'; fixed_rho='0.03'; max_iter_agg=15; max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds }
        )
    }

    if ($ProfileName -eq 'deep') {
        return @(
            [pscustomobject]@{ run_id='d00_baseline_m40';        scenario='baseline'; ui_override=''; skip_transition=$true; fixed_theta='';    fixed_rho='';    max_iter_agg=40; max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds },
            [pscustomobject]@{ run_id='d01_ui000_m40';           scenario='ui_000';   ui_override=''; skip_transition=$true; fixed_theta='';    fixed_rho='';    max_iter_agg=40; max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds },
            [pscustomobject]@{ run_id='d02_ui000_fixmatch_m40';  scenario='ui_000';   ui_override=''; skip_transition=$true; fixed_theta='0.25'; fixed_rho='0.03'; max_iter_agg=40; max_transition_iter=-1; transition_tol=-1.0; rng_seed=12345; timeout_seconds=$TimeoutSeconds }
        )
    }

    return $quick
}

$matrix = Build-Matrix -ProfileName $Profile -TimeoutSeconds $DefaultTimeoutSeconds
$matrixPath = Join-Path $outputDir 'run_matrix.csv'
$summaryPath = Join-Path $outputDir 'ablation_summary.csv'
$reportPath = Join-Path $outputDir 'ablation_report.md'

$matrix | Export-Csv -Path $matrixPath -NoTypeInformation

$results = @()
$skipCompile = $false

foreach ($row in $matrix) {
    $invoke = @{
        Scenario = $row.scenario
        RunTag = $row.run_id
        TimeoutSeconds = $row.timeout_seconds
    }

    if ($row.skip_transition) { $invoke.SkipTransition = $true }
    if ($row.max_iter_agg -gt 0) { $invoke.MaxIterAgg = $row.max_iter_agg }
    if ($row.max_transition_iter -gt 0) { $invoke.MaxTransitionIter = $row.max_transition_iter }
    if ($row.transition_tol -gt 0) { $invoke.TransitionTol = $row.transition_tol }
    if ($row.rng_seed -ge 0) { $invoke.RngSeed = $row.rng_seed }
    if (-not [string]::IsNullOrWhiteSpace($row.ui_override)) { $invoke.UiOverride = $row.ui_override }
    if (-not [string]::IsNullOrWhiteSpace($row.fixed_theta)) { $invoke.FixedTheta = $row.fixed_theta }
    if (-not [string]::IsNullOrWhiteSpace($row.fixed_rho)) { $invoke.FixedRho = $row.fixed_rho }
    if ($skipCompile) { $invoke.SkipCompile = $true }

    $timedOut = $false
    $runnerError = ''
    try {
        & $runner @invoke
    } catch {
        $runnerError = $_.Exception.Message
        if ($runnerError -match 'timed out') {
            $timedOut = $true
        }
    }

    $skipCompile = $true
    $logPath = Get-LastLogForTag -RunTag $row.run_id
    if ($null -eq $logPath) {
        $results += [pscustomobject]@{
            run_id = $row.run_id
            scenario = $row.scenario
            status = 'missing_log'
            stop_rule = 'missing_log'
            timed_out = $timedOut
            log_path = ''
            note = $runnerError
        }
        continue
    }

    $raw = Get-Content -Path $logPath -Raw
    $thetaStats = Get-ThetaStats -RawText $raw
    $stopRule = Classify-Run -LogPath $logPath -TimedOut $timedOut
    $solveStatus = ''
    $transitionStatus = ''

    $solveMatches = [regex]::Matches($raw, '\[ABLT\]\s+solve_model_status=([a-z_]+)')
    if ($solveMatches.Count -gt 0) { $solveStatus = $solveMatches[$solveMatches.Count - 1].Groups[1].Value }

    $transitionMatches = [regex]::Matches($raw, '\[ABLT\]\s+transition_status=([a-z_]+)')
    if ($transitionMatches.Count -gt 0) { $transitionStatus = $transitionMatches[$transitionMatches.Count - 1].Groups[1].Value }

    $results += [pscustomobject]@{
        run_id = $row.run_id
        scenario = $row.scenario
        status = $solveStatus
        transition_status = $transitionStatus
        stop_rule = $stopRule
        timed_out = $timedOut
        theta_obs = $thetaStats.theta_obs
        theta_sign_changes = $thetaStats.theta_sign_changes
        theta_boundary_hits = $thetaStats.theta_boundary_hits
        log_path = $logPath
        note = $runnerError
    }
}

$results | Export-Csv -Path $summaryPath -NoTypeInformation

$report = @()
$report += '# AI calibration ablation report'
$report += ''
$report += ('Profile: ' + $Profile)
$report += ("Generated (UTC): {0}Z" -f ((Get-Date).ToUniversalTime().ToString('s')))
$report += ''
$report += '## Stop rules'
$report += '- `converged`: solver converged, and transition is either converged or intentionally skipped.'
$report += '- `stalled_timeout`: run exceeded timeout.'
$report += '- `blowing_up`: explicit errors, NaN/Inf traces, or high warning count.'
$report += '- `oscillating`: repeated sign flips in theta updates (`old theta` vs `new theta`).'
$report += '- `not_converged`: none of the above and no convergence signal.'
$report += ''
$report += '## Runs'
$report += '| run_id | scenario | solve | transition | stop_rule | timed_out | theta_obs | sign_changes | boundary_hits |'
$report += '|---|---|---|---|---|---:|---:|---:|---:|'
foreach ($r in $results) {
    $timedOutFlag = [int][bool]$r.timed_out
    $report += ("| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} |" -f $r.run_id, $r.scenario, $r.status, $r.transition_status, $r.stop_rule, $timedOutFlag, $r.theta_obs, $r.theta_sign_changes, $r.theta_boundary_hits)
}
$report += ''
$report += '## Artifacts'
$report += ('- Matrix: ' + $matrixPath)
$report += ('- Summary: ' + $summaryPath)
$report += ('- Raw logs: ' + $caseLogDir)

Set-Content -Path $reportPath -Value $report

Write-Host ("Ablation matrix complete. Summary: {0}" -f $summaryPath) -ForegroundColor Green
Write-Host ("Report: {0}" -f $reportPath) -ForegroundColor Green
