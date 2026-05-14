param(
    [string]$RunLabel = "bellman_re_12_hour_workflow",
    [double]$TimeoutHours = 12,
    [string]$ResumeRunDir = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
$compiledRoot = Join-Path $projectRoot "compiled_sidecar"
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$isResume = -not [string]::IsNullOrWhiteSpace($ResumeRunDir)
if ($isResume) {
    $runDir = [System.IO.Path]::GetFullPath($ResumeRunDir)
    if (-not (Test-Path $runDir)) {
        throw "Resume run directory not found: $runDir"
    }
} else {
    $runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $runDir = Join-Path $logsRoot ("{0}_{1}" -f $RunLabel, $runStamp)
    New-Item -ItemType Directory -Path $runDir | Out-Null
}

$activePointer = Join-Path $logsRoot ("active_{0}.txt" -f $RunLabel)
$latestPointer = Join-Path $logsRoot ("latest_{0}.txt" -f $RunLabel)
$statusPath = Join-Path $runDir "status.txt"
$summaryPath = Join-Path $runDir "summary.txt"
$manifestPath = Join-Path $runDir "manifest.txt"
$canonicalNotePath = Join-Path $projectRoot "notes/build/compiled_sidecar_bellman_re_12_hour_packet.md"

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
    $rollbackMatch = [regex]::Match($Text, "rollbacks used:\s+([0-9]+)")

    if (-not $maxResidualMatch.Success) {
        throw "Failed to parse transition RE output.`n$Text"
    }

    $qLine = (($Text -split "`r?`n") | Where-Object { $_ -like "q path:*" } | Select-Object -First 1)
    $impliedLine = (($Text -split "`r?`n") | Where-Object { $_ -like "implied q path:*" } | Select-Object -First 1)
    $residualLine = (($Text -split "`r?`n") | Where-Object { $_ -like "residual path:*" } | Select-Object -First 1)

    [pscustomobject]@{
        maxres = [double]$maxResidualMatch.Groups[1].Value
        iterations = if ($iterationsMatch.Success) { [int]$iterationsMatch.Groups[1].Value } else { 0 }
        stalled = if ($stalledMatch.Success) { ([int]$stalledMatch.Groups[1].Value) -eq 1 } else { $false }
        converged = if ($convergedMatch.Success) { ([int]$convergedMatch.Groups[1].Value) -eq 1 } else { $false }
        rollback_count = if ($rollbackMatch.Success) { [int]$rollbackMatch.Groups[1].Value } else { 0 }
        q_path = if ($qLine) { Parse-NumericArrayLine -Line $qLine } else { @() }
        implied_q_path = if ($impliedLine) { Parse-NumericArrayLine -Line $impliedLine } else { @() }
        residual_path = if ($residualLine) { Parse-NumericArrayLine -Line $residualLine } else { @() }
        raw = $Text
    }
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
        "--coordinate-backtracking-improve-tol", "0",
        "--coordinate-min-damping-path", "0.0375,0.02,0.025,0.00001",
        "--coordinate-min-max-q-update-step", "0.03,0.0175,0.02,0.00005",
        "--coordinate-branch-continuity-mask", "0,0,0,1",
        "--coordinate-branch-continuity-q-tolerance", "0.03",
        "--pair-backtracking-line-search",
        "--pair-backtracking-activate-residual", "0.08",
        "--max-pair-backtracking-periods", "2",
        "--max-pair-backtracking-rounds", "8",
        "--pair-backtracking-improve-tol", "0",
        "--stall-probe-line-search",
        "--stall-probe-activate-residual", "0.08",
        "--max-stall-probe-periods", "2",
        "--max-stall-probe-rounds", "4",
        "--stall-probe-initial-step-fraction", "0.25",
        "--stall-probe-improve-tol", "0",
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
        [int]$MaxIter,
        [string[]]$ExtraArgs = @()
    )

    Test-Deadline

    $stdoutPath = Join-Path $runDir ("{0}_stdout.log" -f $StepName)
    $stderrPath = Join-Path $runDir ("{0}_stderr.log" -f $StepName)
    $args = @(
        $inputRoot,
        "--initial-q-path", (Format-QPath -Values $InitialQPath),
        "--max-iter", "$MaxIter"
    ) + (Get-DefaultReArgs) + $ExtraArgs

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
    $parsed = $null
    if (-not [string]::IsNullOrWhiteSpace($stdout)) {
        try {
            $parsed = Parse-ReOutput -Text $stdout
        }
        catch {
            $parsed = $null
        }
    }

    if ($null -eq $parsed) {
        if ($proc.ExitCode -ne 0) {
            Write-Status ("FAIL {0} exit={1}" -f $StepName, $proc.ExitCode)
            throw "Step failed: $StepName"
        }
        throw "Step output was not parseable: $StepName"
    }

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

function Run-ExactGrid2D {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [double[]]$CenterQ,
        [Parameter(Mandatory = $true)]
        [int]$IndexA,
        [Parameter(Mandatory = $true)]
        [int]$IndexB,
        [Parameter(Mandatory = $true)]
        [double[]]$DeltasA,
        [Parameter(Mandatory = $true)]
        [double[]]$DeltasB
    )

    Write-Status ("START {0}" -f $StepName)
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($deltaA in $DeltasA) {
        foreach ($deltaB in $DeltasB) {
            $trialQ = [double[]]@($CenterQ[0], $CenterQ[1], $CenterQ[2], $CenterQ[3])
            $trialQ[$IndexA] += [double]$deltaA
            $trialQ[$IndexB] += [double]$deltaB
            $parsed = Invoke-ExactEval -QPath $trialQ
            $rows.Add([pscustomobject]@{
                delta_a = $deltaA
                delta_b = $deltaB
                maxres = $parsed.maxres
                stalled = $parsed.stalled
                q_path = Format-QPath -Values $parsed.q_path
                implied_q_path = Format-QPath -Values $parsed.implied_q_path
            })
        }
    }
    $csvPath = Join-Path $runDir ("{0}.csv" -f $StepName)
    $rows | Sort-Object maxres, delta_a, delta_b | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Status ("DONE {0} rows={1}" -f $StepName, $rows.Count)
    return [pscustomobject]@{
        step_name = $StepName
        csv_path = $csvPath
        best = $rows | Sort-Object maxres, delta_a, delta_b | Select-Object -First 5
        row_count = $rows.Count
    }
}

function Run-ExactGrid3D {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [double[]]$CenterQ,
        [Parameter(Mandatory = $true)]
        [int]$IndexA,
        [Parameter(Mandatory = $true)]
        [int]$IndexB,
        [Parameter(Mandatory = $true)]
        [int]$IndexC,
        [Parameter(Mandatory = $true)]
        [double[]]$DeltasA,
        [Parameter(Mandatory = $true)]
        [double[]]$DeltasB,
        [Parameter(Mandatory = $true)]
        [double[]]$DeltasC
    )

    Write-Status ("START {0}" -f $StepName)
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($deltaA in $DeltasA) {
        foreach ($deltaB in $DeltasB) {
            foreach ($deltaC in $DeltasC) {
                $trialQ = [double[]]@($CenterQ[0], $CenterQ[1], $CenterQ[2], $CenterQ[3])
                $trialQ[$IndexA] += [double]$deltaA
                $trialQ[$IndexB] += [double]$deltaB
                $trialQ[$IndexC] += [double]$deltaC
                $parsed = Invoke-ExactEval -QPath $trialQ
                $rows.Add([pscustomobject]@{
                    delta_a = $deltaA
                    delta_b = $deltaB
                    delta_c = $deltaC
                    maxres = $parsed.maxres
                    q_path = Format-QPath -Values $parsed.q_path
                    implied_q_path = Format-QPath -Values $parsed.implied_q_path
                })
            }
        }
    }
    $csvPath = Join-Path $runDir ("{0}.csv" -f $StepName)
    $rows | Sort-Object maxres, delta_a, delta_b, delta_c | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Status ("DONE {0} rows={1}" -f $StepName, $rows.Count)
    return [pscustomobject]@{
        step_name = $StepName
        csv_path = $csvPath
        best = $rows | Sort-Object maxres, delta_a, delta_b, delta_c | Select-Object -First 5
        row_count = $rows.Count
    }
}

function Import-ExistingExactGrid {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName
    )

    $csvPath = Join-Path $runDir ("{0}.csv" -f $StepName)
    if (-not (Test-Path $csvPath)) {
        return $null
    }

    $rows = @(Import-Csv $csvPath)
    if ($rows.Count -eq 0) {
        throw "Existing exact-grid CSV is empty: $csvPath"
    }

    Write-Status ("SKIP {0} reuse_csv rows={1}" -f $StepName, $rows.Count)
    return [pscustomobject]@{
        step_name = $StepName
        csv_path = $csvPath
        best = $rows | Sort-Object @{ Expression = { [double]$_.maxres } } | Select-Object -First 5
        row_count = $rows.Count
    }
}

function Run-StagedCase {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CaseName,
        [Parameter(Mandatory = $true)]
        [double[]]$InitialQPath,
        [Parameter(Mandatory = $true)]
        [int[]]$StageIters,
        [string[]]$ExtraArgs = @()
    )

    $currentQ = [double[]]@($InitialQPath[0], $InitialQPath[1], $InitialQPath[2], $InitialQPath[3])
    $stages = New-Object System.Collections.Generic.List[object]
    $stageIdx = 0
    foreach ($iterCount in $StageIters) {
        $stageIdx += 1
        $result = Invoke-ReCase -StepName ("{0}_stage{1}" -f $CaseName, $stageIdx) `
            -InitialQPath $currentQ `
            -MaxIter $iterCount `
            -ExtraArgs $ExtraArgs
        $stages.Add([pscustomobject]@{
            stage = $stageIdx
            max_iter = $iterCount
            maxres = $result.maxres
            stalled = $result.stalled
            converged = $result.converged
            q_path = $result.q_path
            implied_q_path = $result.implied_q_path
        })
        $currentQ = [double[]]$result.q_path
        if ($result.stalled -or $result.converged) {
            break
        }
    }

    $finalStage = $stages[$stages.Count - 1]
    return [pscustomobject]@{
        case_name = $CaseName
        stage_count = $stages.Count
        stages = $stages
        final_maxres = $finalStage.maxres
        final_stalled = $finalStage.stalled
        final_converged = $finalStage.converged
        final_q_path = $finalStage.q_path
        final_implied_q_path = $finalStage.implied_q_path
        extra_args = $ExtraArgs
    }
}

try {
    if (-not $isResume) {
        Set-Content -Path $statusPath -Value ""
        Set-Content -Path $summaryPath -Value ""
    } else {
        if (-not (Test-Path $statusPath)) {
            Set-Content -Path $statusPath -Value ""
        }
        if (-not (Test-Path $summaryPath)) {
            Set-Content -Path $summaryPath -Value ""
        }
    }
    Set-ActivePointer -Phase "starting"
    if ($isResume) {
        Write-Status "RESUME existing run directory"
    }

    $frontLoadedSeed = [double[]]@(2.0, 2.05, 2.08, 2.10)
    $promotedWallSeed = [double[]]@(1.7303548376, 1.7483599506, 1.7530002876, 2.1532712772)

    if (-not $isResume) {
        @(
            "Objective: run a bounded 12-hour compiled-sidecar Bellman RE packet beyond the promoted ~0.04744 wall.",
            "Run label: $RunLabel",
            "Scope lock:",
            " - project 03 only",
            " - standalone compiled-sidecar Bellman RE branch only",
            " - no MATLAB, no annual branch, no benchmark-grid RE push",
            "Deliverables:",
            " - exact local probe CSVs around the promoted wall",
            " - staged continuation sweep note",
            " - one canonical packet note at notes/build/compiled_sidecar_bellman_re_12_hour_packet.md",
            "Stopping rule: stop after the packet note exists, or at the first timeout/error."
        ) | Set-Content -Path $manifestPath
    }

    Write-Status ("RUN_DIR {0}" -f $runDir)

    $exactBaseline = Invoke-ExactEval -QPath $promotedWallSeed
    Write-Status ("BASELINE_EXACT maxres={0:F10}" -f $exactBaseline.maxres)

    $deltaQ = [double[]]@(-0.0050, -0.0025, -0.00125, 0.0, 0.00125, 0.0025, 0.0050)
    $deltaQ4 = [double[]]@(-0.0025, -0.00125, -0.000625, 0.0, 0.000625, 0.00125, 0.0025)
    $coarseQ = [double[]]@(-0.0025, 0.0, 0.0025, 0.0050)
    $coarseQ4 = [double[]]@(-0.00125, 0.0, 0.00125)

    $grid23 = Import-ExistingExactGrid -StepName "01_wall_exact_grid_q23"
    if ($null -eq $grid23) {
        $grid23 = Run-ExactGrid2D -StepName "01_wall_exact_grid_q23" `
            -CenterQ $promotedWallSeed `
            -IndexA 1 `
            -IndexB 2 `
            -DeltasA $deltaQ `
            -DeltasB $deltaQ
    }

    $grid24 = Import-ExistingExactGrid -StepName "02_wall_exact_grid_q24"
    if ($null -eq $grid24) {
        $grid24 = Run-ExactGrid2D -StepName "02_wall_exact_grid_q24" `
            -CenterQ $promotedWallSeed `
            -IndexA 1 `
            -IndexB 3 `
            -DeltasA $deltaQ `
            -DeltasB $deltaQ4
    }

    $grid34 = Import-ExistingExactGrid -StepName "03_wall_exact_grid_q34"
    if ($null -eq $grid34) {
        $grid34 = Run-ExactGrid2D -StepName "03_wall_exact_grid_q34" `
            -CenterQ $promotedWallSeed `
            -IndexA 2 `
            -IndexB 3 `
            -DeltasA $deltaQ `
            -DeltasB $deltaQ4
    }

    $grid234 = Import-ExistingExactGrid -StepName "04_wall_exact_grid_q234_coarse"
    if ($null -eq $grid234) {
        $grid234 = Run-ExactGrid3D -StepName "04_wall_exact_grid_q234_coarse" `
            -CenterQ $promotedWallSeed `
            -IndexA 1 `
            -IndexB 2 `
            -IndexC 3 `
            -DeltasA $coarseQ `
            -DeltasB $coarseQ `
            -DeltasC $coarseQ4
    }

    $allBestExactRows = @(
        $grid23.best
        $grid24.best
        $grid34.best
        $grid234.best
    ) | Select-Object *
    $bestExactRow = $allBestExactRows | Sort-Object maxres | Select-Object -First 1

    $bestExactSeed = [double[]]($bestExactRow.q_path -split "," | ForEach-Object { [double]$_ })
    $bestExactContinuation = $null
    if ([double]$bestExactRow.maxres -lt ($exactBaseline.maxres - 1.0e-6)) {
        $bestExactContinuation = Run-StagedCase -CaseName "05_best_exact_candidate" `
            -InitialQPath $bestExactSeed `
            -StageIters @(4) `
            -ExtraArgs @()
    }

    $wallVariants = @(
        [pscustomobject]@{ name = "baseline_wall"; extra = @() },
        [pscustomobject]@{ name = "stall_periods3"; extra = @("--max-stall-probe-periods", "3") },
        [pscustomobject]@{ name = "stall_rounds6"; extra = @("--max-stall-probe-rounds", "6") },
        [pscustomobject]@{ name = "stall_step0125"; extra = @("--stall-probe-initial-step-fraction", "0.125") },
        [pscustomobject]@{ name = "stall_step0500"; extra = @("--stall-probe-initial-step-fraction", "0.5") },
        [pscustomobject]@{ name = "stall_periods3_rounds6"; extra = @("--max-stall-probe-periods", "3", "--max-stall-probe-rounds", "6") }
    )

    $variantResults = New-Object System.Collections.Generic.List[object]
    foreach ($variant in $wallVariants) {
        $variantCase = Run-StagedCase -CaseName ("06_variant_{0}" -f $variant.name) `
            -InitialQPath $promotedWallSeed `
            -StageIters @(4) `
            -ExtraArgs $variant.extra
        $variantResults.Add([pscustomobject]@{
            name = $variant.name
            extra = ($variant.extra -join " ")
            maxres = $variantCase.final_maxres
            stalled = $variantCase.final_stalled
            q_path = Format-QPath -Values $variantCase.final_q_path
            implied_q_path = Format-QPath -Values $variantCase.final_implied_q_path
        })
    }
    $variantCsvPath = Join-Path $runDir "06_variant_wall_sweep.csv"
    $variantResults | Sort-Object maxres, name | Export-Csv -Path $variantCsvPath -NoTypeInformation
    Write-Status ("DONE 06_variant_wall_sweep rows={0}" -f $variantResults.Count)

    $baselineStaged = Run-StagedCase -CaseName "07_front_loaded_baseline" `
        -InitialQPath $frontLoadedSeed `
        -StageIters @(20, 12, 4, 2) `
        -ExtraArgs @()

    $bestVariant = $variantResults | Sort-Object maxres, name | Select-Object -First 1
    $bestVariantFullSeed = $null
    if ([double]$bestVariant.maxres -lt ($exactBaseline.maxres - 1.0e-6)) {
        $bestVariantArgs = @()
        if (-not [string]::IsNullOrWhiteSpace($bestVariant.extra)) {
            $bestVariantArgs = @($bestVariant.extra -split "\s+" | Where-Object { $_ -ne "" })
        }
        $bestVariantFullSeed = Run-StagedCase -CaseName "08_front_loaded_best_variant" `
            -InitialQPath $frontLoadedSeed `
            -StageIters @(20, 12, 4, 2) `
            -ExtraArgs $bestVariantArgs
    }

    $noteLines = New-Object System.Collections.Generic.List[string]
    $noteLines.Add("# Compiled sidecar Bellman RE 12-hour packet")
    $noteLines.Add("")
    $noteLines.Add(("Date: {0}" -f (Get-Date -Format "yyyy-MM-dd")))
    $noteLines.Add("")
    $noteLines.Add("## Scope")
    $noteLines.Add("")
    $noteLines.Add("- standalone compiled-sidecar Bellman RE branch only")
    $noteLines.Add("- promoted local wall seed: [1.730355, 1.748360, 1.753000, 2.153271]")
    $noteLines.Add("- no MATLAB, no annual branch, no benchmark-grid RE push")
    $noteLines.Add("")
    $noteLines.Add("## Exact wall baseline")
    $noteLines.Add("")
    $noteLines.Add(("- exact max residual about {0:F10}" -f $exactBaseline.maxres))
    $noteLines.Add(("- exact implied path: [{0}]" -f ((($exactBaseline.implied_q_path | ForEach-Object { "{0:F6}" -f $_ }) -join ", "))))
    $noteLines.Add("")
    $noteLines.Add("## Exact local grids")
    $noteLines.Add("")
    foreach ($gridSummary in @($grid23, $grid24, $grid34, $grid234)) {
        $top = $gridSummary.best | Select-Object -First 1
        $noteLines.Add(("- {0}: best exact max residual about {1:F10}" -f $gridSummary.step_name, [double]$top.maxres))
        $noteLines.Add(("  - csv: {0}" -f $gridSummary.csv_path.Replace($projectRoot + "\", "")))
        $noteLines.Add(("  - q path: [{0}]" -f $top.q_path))
    }
    $noteLines.Add("")
    $noteLines.Add("## Best exact candidate continuation")
    $noteLines.Add("")
    if ($null -ne $bestExactContinuation) {
        $noteLines.Add(("- best exact candidate seed: [{0}]" -f (Format-QPath -Values $bestExactSeed)))
        $noteLines.Add(("- continuation max residual about {0:F10}" -f $bestExactContinuation.final_maxres))
        $noteLines.Add(("- continuation q path: [{0}]" -f (Format-QPath -Values $bestExactContinuation.final_q_path)))
    } else {
        $noteLines.Add("- no exact local candidate beat the promoted wall by more than the acceptance tolerance")
    }
    $noteLines.Add("")
    $noteLines.Add("## Wall variant sweep")
    $noteLines.Add("")
    $noteLines.Add(("CSV: {0}" -f $variantCsvPath.Replace($projectRoot + "\", "")))
    foreach ($variantRow in ($variantResults | Sort-Object maxres, name | Select-Object -First 6)) {
        $noteLines.Add(("- {0}: max residual {1:F10} | stalled {2}" -f $variantRow.name, [double]$variantRow.maxres, $variantRow.stalled))
    }
    $noteLines.Add("")
    $noteLines.Add("## Front-loaded staged baseline")
    $noteLines.Add("")
    foreach ($stage in $baselineStaged.stages) {
        $noteLines.Add(("- stage {0}: max residual {1:F10} | q [{2}]" -f $stage.stage, [double]$stage.maxres, (Format-QPath -Values $stage.q_path)))
    }
    $noteLines.Add(("- final implied path: [{0}]" -f (Format-QPath -Values $baselineStaged.final_implied_q_path)))
    $noteLines.Add("")
    $noteLines.Add("## Best variant full-seed rerun")
    $noteLines.Add("")
    if ($null -ne $bestVariantFullSeed) {
        $noteLines.Add(("- best wall variant: {0}" -f $bestVariant.name))
        foreach ($stage in $bestVariantFullSeed.stages) {
            $noteLines.Add(("- stage {0}: max residual {1:F10} | q [{2}]" -f $stage.stage, [double]$stage.maxres, (Format-QPath -Values $stage.q_path)))
        }
        $noteLines.Add(("- final implied path: [{0}]" -f (Format-QPath -Values $bestVariantFullSeed.final_implied_q_path)))
    } else {
        $noteLines.Add("- no wall variant beat the promoted wall enough to justify a full-seed rerun")
    }
    $noteLines.Add("")
    $noteLines.Add("## Read")
    $noteLines.Add("")
    $noteLines.Add("- This packet is meant to identify one narrow next local-rule direction beyond the promoted ~0.04744 wall.")
    $noteLines.Add("- Promote only clean improvements that survive a continuation or full-seed rerun.")
    $noteLines.Add(("- Run directory: {0}" -f $runDir.Replace($projectRoot + "\", "")))

    $noteLines | Set-Content -Path $canonicalNotePath
    $noteLines | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("ERROR {0}" -f $message)
    @(
        "Bellman RE 12-hour workflow stopped with an error.",
        "Run directory: $runDir",
        "Error: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "error"
    throw
}
