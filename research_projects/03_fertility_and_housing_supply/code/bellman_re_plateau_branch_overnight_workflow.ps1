param(
    [string]$RunLabel = "bellman_re_plateau_branch_overnight_workflow",
    [double]$TimeoutHours = 12,
    [string]$SeedQPathCsv = "1.7294173376,1.7473345599,1.7525985237,2.1526853397",
    [string]$SeedLabel = "bridge plateau",
    [string]$CanonicalNoteName = "compiled_sidecar_bellman_re_plateau_branch_overnight_packet.md",
    [double]$ImprovementTolerance = 1.0e-10
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
$compiledRoot = Join-Path $projectRoot "compiled_sidecar"
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $logsRoot ("{0}_{1}" -f $RunLabel, $runStamp)
New-Item -ItemType Directory -Path $runDir | Out-Null

$activePointer = Join-Path $logsRoot ("active_{0}.txt" -f $RunLabel)
$latestPointer = Join-Path $logsRoot ("latest_{0}.txt" -f $RunLabel)
$statusPath = Join-Path $runDir "status.txt"
$summaryPath = Join-Path $runDir "summary.txt"
$manifestPath = Join-Path $runDir "manifest.txt"
$canonicalNotePath = Join-Path $projectRoot ("notes/build/{0}" -f $CanonicalNoteName)

$portableToolchain = Join-Path $compiledRoot "tools/portable_toolchain.ps1"
. $portableToolchain
$null = Set-FertilitySidecarPortableToolchain

$exe = Join-Path $compiledRoot "build/fertility_transition_re_cli.exe"
$inputRoot = Join-Path $compiledRoot "truth/transition_input_t4_diag"
if (-not (Test-Path $exe)) {
    throw "Transition RE executable not found: $exe"
}
if (-not (Test-Path $inputRoot)) {
    throw "Transition RE truth pack not found: $inputRoot"
}

$deadline = (Get-Date).AddHours($TimeoutHours)

function Write-Status {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamped = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $statusPath -Value $timestamped
    Set-Content -Path $latestPointer -Value $runDir
}

function Set-ActivePointer {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Phase,
        [string]$ProcessIds = "",
        [string]$StdoutPath = "",
        [string]$StderrPath = ""
    )

    @(
        "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "phase=$Phase"
        "pid=$ProcessIds"
        "run_dir=$runDir"
        "status_path=$statusPath"
        "stdout_path=$StdoutPath"
        "stderr_path=$StderrPath"
        "latest_pointer=$latestPointer"
    ) | Set-Content -Path $activePointer
}

function Test-Deadline {
    if ((Get-Date) -gt $deadline) {
        throw "Workflow deadline reached."
    }
}

function Format-QPath {
    param(
        [Parameter(Mandatory = $true)]
        [double[]]$Values
    )

    return (($Values | ForEach-Object { "{0:F10}" -f $_ }) -join ",")
}

function Parse-NumericArrayLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Line
    )

    $payload = ($Line -split ":\s+", 2)[1].Trim()
    if ([string]::IsNullOrWhiteSpace($payload)) {
        return @()
    }
    return @($payload -split "\s+" | Where-Object { $_ -ne "" } | ForEach-Object { [double]$_ })
}

function Parse-ReOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $maxResidualMatch = [regex]::Match($Text, "max abs residual:\s+([0-9Ee+\-\.]+)")
    $iterationsMatch = [regex]::Match($Text, "iterations run:\s+([0-9]+)")
    $stalledMatch = [regex]::Match($Text, "stalled:\s+([01])")
    $convergedMatch = [regex]::Match($Text, "converged:\s+([01])")

    if (-not $maxResidualMatch.Success) {
        throw "Failed to parse transition RE output.`n$Text"
    }

    $lines = $Text -split "`r?`n"
    $qLine = $lines | Where-Object { $_ -like "q path:*" } | Select-Object -First 1
    $impliedLine = $lines | Where-Object { $_ -like "implied q path:*" } | Select-Object -First 1
    $residualLine = $lines | Where-Object { $_ -like "residual path:*" } | Select-Object -First 1

    [pscustomobject]@{
        maxres = [double]$maxResidualMatch.Groups[1].Value
        iterations = if ($iterationsMatch.Success) { [int]$iterationsMatch.Groups[1].Value } else { 0 }
        stalled = if ($stalledMatch.Success) { ([int]$stalledMatch.Groups[1].Value) -eq 1 } else { $false }
        converged = if ($convergedMatch.Success) { ([int]$convergedMatch.Groups[1].Value) -eq 1 } else { $false }
        q_path = if ($qLine) { Parse-NumericArrayLine -Line $qLine } else { @() }
        implied_q_path = if ($impliedLine) { Parse-NumericArrayLine -Line $impliedLine } else { @() }
        residual_path = if ($residualLine) { Parse-NumericArrayLine -Line $residualLine } else { @() }
        raw = $Text
    }
}

function Parse-ProbeOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $base = Parse-ReOutput -Text $Text
    $acceptedMatch = [regex]::Match($Text, "basin hop accepted:\s+([01])")
    $bestTrialMatch = [regex]::Match($Text, "best trial max residual:\s+([0-9Ee+\-\.]+)")
    $hopMatch = [regex]::Match($Text, "basin hop max residual:\s+([0-9Ee+\-\.]+)")
    $lines = $Text -split "`r?`n"

    $hopQLine = $lines | Where-Object { $_ -like "basin hop q path:*" } | Select-Object -First 1
    $hopImpliedLine = $lines | Where-Object { $_ -like "basin hop implied path:*" } | Select-Object -First 1
    $hopResidualLine = $lines | Where-Object { $_ -like "basin hop residual path:*" } | Select-Object -First 1
    $bestQLine = $lines | Where-Object { $_ -like "best trial q path:*" } | Select-Object -First 1
    $bestImpliedLine = $lines | Where-Object { $_ -like "best trial implied path:*" } | Select-Object -First 1
    $bestResidualLine = $lines | Where-Object { $_ -like "best trial residual path:*" } | Select-Object -First 1

    [pscustomobject]@{
        base = $base
        accepted = if ($acceptedMatch.Success) { ([int]$acceptedMatch.Groups[1].Value) -eq 1 } else { $false }
        basin_hop_maxres = if ($hopMatch.Success) { [double]$hopMatch.Groups[1].Value } else { [double]::PositiveInfinity }
        basin_hop_q_path = if ($hopQLine) { Parse-NumericArrayLine -Line $hopQLine } else { @() }
        basin_hop_implied_q_path = if ($hopImpliedLine) { Parse-NumericArrayLine -Line $hopImpliedLine } else { @() }
        basin_hop_residual_path = if ($hopResidualLine) { Parse-NumericArrayLine -Line $hopResidualLine } else { @() }
        best_trial_maxres = if ($bestTrialMatch.Success) { [double]$bestTrialMatch.Groups[1].Value } else { [double]::PositiveInfinity }
        best_trial_q_path = if ($bestQLine) { Parse-NumericArrayLine -Line $bestQLine } else { @() }
        best_trial_implied_q_path = if ($bestImpliedLine) { Parse-NumericArrayLine -Line $bestImpliedLine } else { @() }
        best_trial_residual_path = if ($bestResidualLine) { Parse-NumericArrayLine -Line $bestResidualLine } else { @() }
        raw = $Text
    }
}

function Get-AbsResidual {
    param(
        [Parameter(Mandatory = $true)]
        [double[]]$ResidualPath
    )
    return @($ResidualPath | ForEach-Object { [math]::Abs($_) })
}

function Test-ResidualGeometryBetter {
    param(
        [Parameter(Mandatory = $true)]
        [double[]]$TrialAbsResidual,
        [Parameter(Mandatory = $true)]
        [double[]]$CurrentAbsResidual,
        [double]$MaxresTol = 1.0e-10,
        [double]$SecondaryTol = 1.0e-12
    )

    if ($TrialAbsResidual.Count -ne $CurrentAbsResidual.Count -or $TrialAbsResidual.Count -eq 0) {
        return $false
    }

    $trialSorted = @($TrialAbsResidual | Sort-Object -Descending)
    $currentSorted = @($CurrentAbsResidual | Sort-Object -Descending)
    if ($trialSorted[0] -gt ($currentSorted[0] + $MaxresTol)) {
        return $false
    }

    for ($idx = 0; $idx -lt $trialSorted.Count; $idx++) {
        if ($trialSorted[$idx] -lt ($currentSorted[$idx] - $SecondaryTol)) {
            return $true
        }
        if ($trialSorted[$idx] -gt ($currentSorted[$idx] + $SecondaryTol)) {
            return $false
        }
    }
    return $false
}

function Test-ExactImprovement {
    param(
        [Parameter(Mandatory = $true)]
        $Trial,
        [Parameter(Mandatory = $true)]
        $Current,
        [double]$Tolerance = 1.0e-10
    )

    if ($Trial.maxres -lt ($Current.maxres - $Tolerance)) {
        return $true
    }
    if ([math]::Abs($Trial.maxres - $Current.maxres) -le $Tolerance) {
        return (Test-ResidualGeometryBetter -TrialAbsResidual (Get-AbsResidual -ResidualPath $Trial.residual_path) `
            -CurrentAbsResidual (Get-AbsResidual -ResidualPath $Current.residual_path) `
            -MaxresTol $Tolerance `
            -SecondaryTol 1.0e-12)
    }
    return $false
}

function Get-DefaultReArgs {
    return @(
        "--q-search-grid", "1.5,2.0,2.5",
        "--damping", "0.15",
        "--damping-path", "0.15,0.08,0.10,0.04",
        "--max-q-update-step", "0.12,0.07,0.08,0.03",
        "--root-selection-anchor", "current_guess",
        "--branch-tie-break-mask", "0,0,0,1",
        "--branch-tie-break-q-tolerance", "0.03",
        "--adaptive-update-control",
        "--adaptive-worsen-ratio", "1.05",
        "--adaptive-worsen-abs-tol", "0.01",
        "--adaptive-shrink-factor", "0.75",
        "--min-damping-path", "0.0375,0.02,0.025,0.01",
        "--min-max-q-update-step", "0.03,0.0175,0.02,0.0075",
        "--backtracking-line-search",
        "--backtracking-activate-residual", "0.15",
        "--backtracking-shrink-factor", "0.5",
        "--backtracking-accept-worsen-ratio", "1.1",
        "--backtracking-accept-worsen-abs-tol", "0.01",
        "--max-backtracking-rounds", "3",
        "--coordinate-backtracking-line-search",
        "--coordinate-backtracking-activate-residual", "0.1",
        "--max-coordinate-backtracking-periods", "2",
        "--max-coordinate-backtracking-rounds", "6",
        "--coordinate-backtracking-require-improvement",
        "--coordinate-backtracking-improve-tol", "0",
        "--coordinate-min-damping-path", "0.0375,0.02,0.025,0.00001",
        "--coordinate-min-max-q-update-step", "0.03,0.0175,0.02,0.00005",
        "--coordinate-branch-continuity-mask", "0,0,0,1",
        "--coordinate-branch-continuity-q-tolerance", "0.03",
        "--pair-backtracking-line-search",
        "--pair-backtracking-activate-residual", "0.08",
        "--max-pair-backtracking-periods", "2",
        "--max-pair-backtracking-rounds", "8",
        "--pair-backtracking-require-improvement",
        "--pair-backtracking-improve-tol", "0",
        "--stall-probe-line-search",
        "--stall-probe-activate-residual", "0.08",
        "--max-stall-probe-periods", "2",
        "--max-stall-probe-rounds", "4",
        "--stall-probe-initial-step-fraction", "0.25",
        "--stall-probe-improve-tol", "0",
        "--stall-probe-allow-plateau-geometry",
        "--plateau-maxres-tol", "1e-8",
        "--plateau-secondary-tol", "1e-10",
        "--basin-hop-line-search",
        "--basin-hop-activate-residual", "0.08",
        "--max-basin-hop-rounds", "1",
        "--basin-hop-initial-step-fraction", "0.5",
        "--basin-hop-pivot-step-multipliers", "0.015625",
        "--basin-hop-partner-step-multipliers", "0.0078125",
        "--stop-on-backtracking-stall",
        "--max-backtracking-stall-iters", "2",
        "--backtracking-stall-q-tolerance", "1e-6",
        "--tolerance", "0.005",
        "--q-refine-points", "5"
    )
}

function Invoke-ReCase {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [double[]]$InitialQPath,
        [Parameter(Mandatory = $true)]
        [int]$MaxIter
    )

    Test-Deadline

    $stdoutPath = Join-Path $runDir ("{0}_stdout.log" -f $StepName)
    $stderrPath = Join-Path $runDir ("{0}_stderr.log" -f $StepName)
    $args = @(
        $inputRoot,
        "--initial-q-path", (Format-QPath -Values $InitialQPath),
        "--max-iter", "$MaxIter"
    ) + (Get-DefaultReArgs)

    Write-Status ("START {0}" -f $StepName)
    $proc = Start-Process -FilePath $exe `
        -ArgumentList $args `
        -WorkingDirectory $compiledRoot `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath

    Set-ActivePointer -Phase $StepName -ProcessIds $proc.Id -StdoutPath $stdoutPath -StderrPath $stderrPath

    while (-not $proc.HasExited) {
        Test-Deadline
        Start-Sleep -Seconds 10
        $proc.Refresh()
    }

    $stdout = if (Test-Path $stdoutPath) { Get-Content -Path $stdoutPath -Raw } else { "" }
    if ([string]::IsNullOrWhiteSpace($stdout)) {
        throw "Step output was empty: $StepName"
    }
    $parsed = Parse-ReOutput -Text $stdout
    $exitSuffix = if ($proc.ExitCode -ne 0) { " exit=$($proc.ExitCode)" } else { "" }
    Write-Status ("DONE {0} maxres={1:F10} stalled={2}{3}" -f $StepName, $parsed.maxres, ([int]$parsed.stalled), $exitSuffix)
    return $parsed
}

function Invoke-ExactEval {
    param(
        [Parameter(Mandatory = $true)]
        [double[]]$QPath
    )

    Test-Deadline

    $args = @(
        $inputRoot,
        "--initial-q-path", (Format-QPath -Values $QPath),
        "--max-iter", "1",
        "--q-search-grid", "1.5,2.0,2.5",
        "--damping", "0",
        "--damping-path", "0,0,0,0",
        "--root-selection-anchor", "current_guess",
        "--branch-tie-break-mask", "0,0,0,1",
        "--branch-tie-break-q-tolerance", "0.03",
        "--tolerance", "0.005",
        "--q-refine-points", "5"
    )
    $text = (& $exe @args | Out-String)
    if ($LASTEXITCODE -ne 0) {
        throw "Exact evaluation failed."
    }
    return Parse-ReOutput -Text $text
}

function Invoke-ProbeCase {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [double[]]$InitialQPath
    )

    Test-Deadline

    $stdoutPath = Join-Path $runDir ("{0}_stdout.log" -f $StepName)
    $stderrPath = Join-Path $runDir ("{0}_stderr.log" -f $StepName)
    $args = @(
        $inputRoot,
        "--initial-q-path", (Format-QPath -Values $InitialQPath),
        "--max-iter", "1",
        "--probe-basin-hop-only"
    ) + (Get-DefaultReArgs)

    Write-Status ("START {0}" -f $StepName)
    $proc = Start-Process -FilePath $exe `
        -ArgumentList $args `
        -WorkingDirectory $compiledRoot `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath

    Set-ActivePointer -Phase $StepName -ProcessIds $proc.Id -StdoutPath $stdoutPath -StderrPath $stderrPath

    while (-not $proc.HasExited) {
        Test-Deadline
        Start-Sleep -Seconds 10
        $proc.Refresh()
    }

    $stdout = if (Test-Path $stdoutPath) { Get-Content -Path $stdoutPath -Raw } else { "" }
    if ([string]::IsNullOrWhiteSpace($stdout)) {
        throw "Probe output was empty: $StepName"
    }
    $parsed = Parse-ProbeOutput -Text $stdout
    $exitSuffix = if ($proc.ExitCode -ne 0) { " exit=$($proc.ExitCode)" } else { "" }
    Write-Status ("DONE {0} accepted={1} best={2:F10}{3}" -f $StepName, ([int]$parsed.accepted), $parsed.best_trial_maxres, $exitSuffix)
    return $parsed
}

try {
    Set-Content -Path $statusPath -Value ""
    Set-Content -Path $summaryPath -Value ""
    Set-ActivePointer -Phase "starting"

    $seedQ = [double[]]@($SeedQPathCsv -split "," | ForEach-Object { [double]($_.Trim()) })

    @(
        ("Objective: run a bounded overnight compiled-sidecar Bellman RE plateau-branch packet from the {0} seed." -f $SeedLabel),
        "Run label: $RunLabel",
        "Seed q path: $(Format-QPath -Values $seedQ)",
        "Scope lock:",
        " - project 03 only",
        " - standalone compiled-sidecar Bellman RE branch only",
        " - no MATLAB, no annual branch, no benchmark-grid RE push",
        "Deliverables:",
        " - exact baseline and repeated exact continuation points along the accepted micro-hop plateau branch",
        " - one final micro q3/q4 basin-hop probe from the last exact seed",
        " - one canonical packet note at notes/build/$CanonicalNoteName",
        "Stopping rule:",
        " - stop when a cycle of accepted micro-hop plus bounded continuation no longer improves the exact seed",
        " - or when the canonical packet note exists",
        " - or at the first timeout/error"
    ) | Set-Content -Path $manifestPath

    Write-Status ("RUN_DIR {0}" -f $runDir)

    $currentExact = Invoke-ExactEval -QPath $seedQ
    Write-Status ("BASELINE_EXACT maxres={0:F10}" -f $currentExact.maxres)

    $cycleRows = New-Object System.Collections.Generic.List[object]
    $maxCycles = 40
    $continuationImproved = $false
    for ($cycleIdx = 1; $cycleIdx -le $maxCycles; $cycleIdx++) {
        $probe = Invoke-ProbeCase -StepName ("01_cycle_{0}_probe" -f $cycleIdx) -InitialQPath $currentExact.q_path
        if (-not $probe.accepted) {
            $cycleRows.Add([pscustomobject]@{
                cycle = $cycleIdx
                probe_accepted = $false
                probe_maxres = $probe.best_trial_maxres
                probe_q_path = if ($probe.best_trial_q_path.Count -gt 0) { Format-QPath -Values $probe.best_trial_q_path } else { "" }
                stage_maxres = [double]::NaN
                stage_stalled = $false
                stage_q_path = ""
                exact_maxres = $currentExact.maxres
                exact_q_path = Format-QPath -Values $currentExact.q_path
                exact_implied_q_path = Format-QPath -Values $currentExact.implied_q_path
                exact_residual_path = Format-QPath -Values $currentExact.residual_path
                accepted_as_new_seed = $false
            })
            Write-Status ("STOP cycle={0} probe_not_accepted" -f $cycleIdx)
            break
        }

        $probeSeed = [double[]]$probe.basin_hop_q_path
        $stage = Invoke-ReCase -StepName ("02_cycle_{0}_continue" -f $cycleIdx) -InitialQPath $probeSeed -MaxIter 4
        $exact = Invoke-ExactEval -QPath $stage.q_path
        $accepted = Test-ExactImprovement -Trial $exact -Current $currentExact -Tolerance $ImprovementTolerance

        $cycleRows.Add([pscustomobject]@{
            cycle = $cycleIdx
            probe_accepted = $true
            probe_maxres = $probe.basin_hop_maxres
            probe_q_path = Format-QPath -Values $probe.basin_hop_q_path
            stage_maxres = $stage.maxres
            stage_stalled = $stage.stalled
            stage_q_path = Format-QPath -Values $stage.q_path
            exact_maxres = $exact.maxres
            exact_q_path = Format-QPath -Values $exact.q_path
            exact_implied_q_path = Format-QPath -Values $exact.implied_q_path
            exact_residual_path = Format-QPath -Values $exact.residual_path
            accepted_as_new_seed = $accepted
        })

        if ($accepted) {
            $currentExact = $exact
            $continuationImproved = $true
            Write-Status ("ACCEPT cycle={0} exact_maxres={1:F10}" -f $cycleIdx, $exact.maxres)
            continue
        }

        Write-Status ("STOP cycle={0} no_exact_improvement" -f $cycleIdx)
        break
    }

    $roundCsvPath = Join-Path $runDir "01_plateau_branch_cycles.csv"
    $cycleRows | Export-Csv -Path $roundCsvPath -NoTypeInformation

    $probe = Invoke-ProbeCase -StepName "02_final_micro_probe" -InitialQPath $currentExact.q_path

    $noteLines = New-Object System.Collections.Generic.List[string]
    $noteLines.Add("# Compiled sidecar Bellman RE plateau branch overnight packet")
    $noteLines.Add("")
    $noteLines.Add(("Date: {0}" -f (Get-Date -Format "yyyy-MM-dd")))
    $noteLines.Add("")
    $noteLines.Add("## Scope")
    $noteLines.Add("")
    $noteLines.Add("- standalone compiled-sidecar Bellman RE branch only")
    $noteLines.Add(("- starting exact seed: [{0}]" -f (Format-QPath -Values $seedQ)))
    $noteLines.Add("- no MATLAB, no annual branch, no benchmark-grid RE push")
    $noteLines.Add("")
    $noteLines.Add("## Exact baseline")
    $noteLines.Add("")
    $noteLines.Add(("- exact max residual about {0:F10}" -f $currentExact.maxres))
    $noteLines.Add(("- exact q path: [{0}]" -f (Format-QPath -Values $currentExact.q_path)))
    $noteLines.Add(("- exact implied path: [{0}]" -f (Format-QPath -Values $currentExact.implied_q_path)))
    $noteLines.Add(("- exact residuals: [{0}]" -f (Format-QPath -Values $currentExact.residual_path)))
    $noteLines.Add("")
    $noteLines.Add("## Plateau branch cycles")
    $noteLines.Add("")
    $noteLines.Add(("- csv: {0}" -f $roundCsvPath.Replace($projectRoot + "\", "")))
    foreach ($row in $cycleRows) {
        if (-not $row.probe_accepted) {
            $noteLines.Add(("- cycle {0}: probe not accepted | best trial max residual {1:F10}" -f $row.cycle, [double]$row.probe_maxres))
            if (-not [string]::IsNullOrWhiteSpace($row.probe_q_path)) {
                $noteLines.Add(("  - best trial q path: [{0}]" -f $row.probe_q_path))
            }
            continue
        }
        $noteLines.Add(("- cycle {0}: probe max residual {1:F10} | stage max residual {2:F10} | exact max residual {3:F10} | accepted {4}" -f $row.cycle, [double]$row.probe_maxres, [double]$row.stage_maxres, [double]$row.exact_maxres, $row.accepted_as_new_seed))
        $noteLines.Add(("  - probe q path: [{0}]" -f $row.probe_q_path))
        $noteLines.Add(("  - exact q path: [{0}]" -f $row.exact_q_path))
        $noteLines.Add(("  - exact residuals: [{0}]" -f $row.exact_residual_path))
    }
    $noteLines.Add("")
    $noteLines.Add("## Final exact seed")
    $noteLines.Add("")
    $noteLines.Add(("- final exact max residual about {0:F10}" -f $currentExact.maxres))
    $noteLines.Add(("- final exact q path: [{0}]" -f (Format-QPath -Values $currentExact.q_path)))
    $noteLines.Add(("- final exact implied path: [{0}]" -f (Format-QPath -Values $currentExact.implied_q_path)))
    $noteLines.Add(("- final exact residuals: [{0}]" -f (Format-QPath -Values $currentExact.residual_path)))
    $noteLines.Add("")
    $noteLines.Add("## Final micro-hop probe")
    $noteLines.Add("")
    $noteLines.Add(("- probe accepted: {0}" -f $probe.accepted))
    if ($probe.accepted) {
        $noteLines.Add(("- accepted micro-hop max residual about {0:F10}" -f $probe.basin_hop_maxres))
        $noteLines.Add(("- accepted micro-hop q path: [{0}]" -f (Format-QPath -Values $probe.basin_hop_q_path)))
        $noteLines.Add(("- accepted micro-hop residuals: [{0}]" -f (Format-QPath -Values $probe.basin_hop_residual_path)))
    } elseif ($probe.best_trial_q_path.Count -gt 0) {
        $noteLines.Add(("- best trial max residual about {0:F10}" -f $probe.best_trial_maxres))
        $noteLines.Add(("- best trial q path: [{0}]" -f (Format-QPath -Values $probe.best_trial_q_path)))
        $noteLines.Add(("- best trial residuals: [{0}]" -f (Format-QPath -Values $probe.best_trial_residual_path)))
    } else {
        $noteLines.Add("- no basin-hop trial was available")
    }
    $noteLines.Add("")
    $noteLines.Add("## Read")
    $noteLines.Add("")
    if ($continuationImproved) {
        $noteLines.Add("- The accepted micro-hop branch continued to improve the exact support plateau while the top period-3 residual stayed pinned.")
    } else {
        $noteLines.Add("- No exact improvement survived beyond the starting seed on the accepted micro-hop branch.")
    }
    $noteLines.Add("- This packet is meant to decide whether the improved exact plateau seed keeps improving through repeated accepted micro-hop cycles before any new solver redesign.")
    $noteLines.Add(("- Run directory: {0}" -f $runDir.Replace($projectRoot + "\", "")))

    $noteLines | Set-Content -Path $canonicalNotePath
    $noteLines | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("FAIL {0}" -f $message)
    @(
        "# Compiled sidecar Bellman RE plateau branch overnight packet",
        "",
        ("Date: {0}" -f (Get-Date -Format "yyyy-MM-dd")),
        "",
        "## Failure",
        "",
        ("- message: {0}" -f $message),
        ("- run directory: {0}" -f $runDir.Replace($projectRoot + "\", ""))
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "failed"
    throw
}
