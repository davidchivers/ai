param(
    [string]$RunLabel = "bellman_re_nano_wall_12_hour_workflow",
    [double]$TimeoutHours = 12,
    [string]$SeedQPathCsv = "1.7303548376,1.7483599506,1.7525998970,2.1532712772",
    [string]$SeedLabel = "nano wall",
    [string]$CanonicalNoteName = "",
    [double]$ImprovementTolerance = 1.0e-8
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
if ([string]::IsNullOrWhiteSpace($CanonicalNoteName)) {
    $canonicalNoteName = ("compiled_sidecar_{0}_packet.md" -f ($RunLabel -replace "_12_hour_workflow$", ""))
} else {
    $canonicalNoteName = $CanonicalNoteName
}
$canonicalNotePath = Join-Path $projectRoot ("notes/build/{0}" -f $canonicalNoteName)

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

function Run-ExactLine1D {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [double[]]$CenterQ,
        [Parameter(Mandatory = $true)]
        [int]$IndexA,
        [Parameter(Mandatory = $true)]
        [double[]]$DeltasA
    )

    Write-Status ("START {0}" -f $StepName)
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($deltaA in $DeltasA) {
        $trialQ = [double[]]@($CenterQ[0], $CenterQ[1], $CenterQ[2], $CenterQ[3])
        $trialQ[$IndexA] += [double]$deltaA
        $parsed = Invoke-ExactEval -QPath $trialQ
        $rows.Add([pscustomobject]@{
            delta_a = $deltaA
            maxres = $parsed.maxres
            stalled = $parsed.stalled
            q_path = Format-QPath -Values $parsed.q_path
            implied_q_path = Format-QPath -Values $parsed.implied_q_path
        })
    }
    $csvPath = Join-Path $runDir ("{0}.csv" -f $StepName)
    $rows | Sort-Object maxres, delta_a | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Status ("DONE {0} rows={1}" -f $StepName, $rows.Count)
    return [pscustomobject]@{
        step_name = $StepName
        csv_path = $csvPath
        best = $rows | Sort-Object maxres, delta_a | Select-Object -First 5
        row_count = $rows.Count
    }
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
    Set-Content -Path $statusPath -Value ""
    Set-Content -Path $summaryPath -Value ""
    Set-ActivePointer -Phase "starting"

    $nanoSeed = [double[]]@($SeedQPathCsv -split "," | ForEach-Object { [double]($_.Trim()) })

    @(
        ("Objective: run a bounded 12-hour compiled-sidecar Bellman RE packet around the {0} frontier." -f $SeedLabel),
        "Run label: $RunLabel",
        "Seed q path: $(Format-QPath -Values $nanoSeed)",
        "Scope lock:",
        " - project 03 only",
        " - standalone compiled-sidecar Bellman RE branch only",
        " - no MATLAB, no annual branch, no benchmark-grid RE push",
        "Deliverables:",
        " - exact nano-wall probe CSVs around the improved endpoint",
        " - bounded continuation sweep under still smaller stall-probe steps",
        " - one canonical packet note at notes/build/compiled_sidecar_bellman_re_nano_wall_packet.md",
        "Stopping rule: stop after the packet note exists, or at the first timeout/error."
    ) | Set-Content -Path $manifestPath

    Write-Status ("RUN_DIR {0}" -f $runDir)

    $exactBaseline = Invoke-ExactEval -QPath $nanoSeed
    Write-Status ("BASELINE_EXACT maxres={0:F10}" -f $exactBaseline.maxres)

    $q2Nano = [double[]]@(-0.00015625, -0.000078125, -0.0000390625, 0.0, 0.0000390625, 0.000078125, 0.00015625)
    $q3Nano = [double[]]@(-0.00001953125, -0.000009765625, -0.0000048828125, 0.0, 0.0000048828125, 0.000009765625, 0.00001953125)
    $q4Nano = [double[]]@(-0.000078125, -0.0000390625, -0.00001953125, 0.0, 0.00001953125, 0.0000390625, 0.000078125)
    $q2Nano3D = [double[]]@(-0.000078125, 0.0, 0.000078125)
    $q3Nano3D = [double[]]@(-0.000009765625, 0.0, 0.000009765625)
    $q4Nano3D = [double[]]@(-0.0000390625, 0.0, 0.0000390625)

    $lineQ3 = Run-ExactLine1D -StepName "01_nano_exact_line_q3" `
        -CenterQ $nanoSeed `
        -IndexA 2 `
        -DeltasA $q3Nano

    $grid23 = Run-ExactGrid2D -StepName "02_nano_exact_grid_q23" `
        -CenterQ $nanoSeed `
        -IndexA 1 `
        -IndexB 2 `
        -DeltasA $q2Nano `
        -DeltasB $q3Nano

    $grid34 = Run-ExactGrid2D -StepName "03_nano_exact_grid_q34" `
        -CenterQ $nanoSeed `
        -IndexA 2 `
        -IndexB 3 `
        -DeltasA $q3Nano `
        -DeltasB $q4Nano

    $grid234 = Run-ExactGrid3D -StepName "04_nano_exact_grid_q234" `
        -CenterQ $nanoSeed `
        -IndexA 1 `
        -IndexB 2 `
        -IndexC 3 `
        -DeltasA $q2Nano3D `
        -DeltasB $q3Nano3D `
        -DeltasC $q4Nano3D

    $allBestExactRows = @(
        $lineQ3.best
        $grid23.best
        $grid34.best
        $grid234.best
    ) | Select-Object *
    $bestExactRow = $allBestExactRows | Sort-Object maxres | Select-Object -First 1

    $bestExactSeed = [double[]]($bestExactRow.q_path -split "," | ForEach-Object { [double]$_ })
    $bestExactContinuation = $null
    if ([double]$bestExactRow.maxres -lt ($exactBaseline.maxres - $ImprovementTolerance)) {
        $bestExactContinuation = Run-StagedCase -CaseName "05_best_nano_exact_candidate" `
            -InitialQPath $bestExactSeed `
            -StageIters @(4, 4) `
            -ExtraArgs @("--max-stall-probe-periods", "3", "--max-stall-probe-rounds", "10", "--stall-probe-initial-step-fraction", "0.015625")
    }

    $nanoVariants = @(
        [pscustomobject]@{ name = "nano_p3_r10_step0015625"; extra = @("--max-stall-probe-periods", "3", "--max-stall-probe-rounds", "10", "--stall-probe-initial-step-fraction", "0.015625") },
        [pscustomobject]@{ name = "nano_p4_r10_step003125"; extra = @("--max-stall-probe-periods", "4", "--max-stall-probe-rounds", "10", "--stall-probe-initial-step-fraction", "0.03125") },
        [pscustomobject]@{ name = "nano_p3_r10_step00234375"; extra = @("--max-stall-probe-periods", "3", "--max-stall-probe-rounds", "10", "--stall-probe-initial-step-fraction", "0.0234375") },
        [pscustomobject]@{ name = "nano_p4_r10_step0046875"; extra = @("--max-stall-probe-periods", "4", "--max-stall-probe-rounds", "10", "--stall-probe-initial-step-fraction", "0.046875") },
        [pscustomobject]@{ name = "nano_p3_r12_step0015625"; extra = @("--max-stall-probe-periods", "3", "--max-stall-probe-rounds", "12", "--stall-probe-initial-step-fraction", "0.015625") },
        [pscustomobject]@{ name = "nano_p4_r12_step003125"; extra = @("--max-stall-probe-periods", "4", "--max-stall-probe-rounds", "12", "--stall-probe-initial-step-fraction", "0.03125") }
    )

    $variantResults = New-Object System.Collections.Generic.List[object]
    foreach ($variant in $nanoVariants) {
        $variantCase = Run-StagedCase -CaseName ("06_variant_{0}" -f $variant.name) `
            -InitialQPath $nanoSeed `
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
    $variantCsvPath = Join-Path $runDir "06_nano_variant_sweep.csv"
    $variantResults | Sort-Object maxres, name | Export-Csv -Path $variantCsvPath -NoTypeInformation
    Write-Status ("DONE 06_nano_variant_sweep rows={0}" -f $variantResults.Count)

    $bestVariant = $variantResults | Sort-Object `
        @{ Expression = { [double]$_.maxres }; Ascending = $true }, `
        @{ Expression = { if ([bool]$_.stalled) { 1 } else { 0 } }; Ascending = $true }, `
        @{ Expression = { [string]$_.name }; Ascending = $true } | Select-Object -First 1
    $bestVariantContinuation = $null
    if ([double]$bestVariant.maxres -lt ($exactBaseline.maxres - $ImprovementTolerance)) {
        $bestVariantArgs = @()
        if (-not [string]::IsNullOrWhiteSpace($bestVariant.extra)) {
            $bestVariantArgs = @($bestVariant.extra -split "\s+" | Where-Object { $_ -ne "" })
        }
        $bestVariantSeed = [double[]]($bestVariant.q_path -split "," | ForEach-Object { [double]$_ })
        $bestVariantContinuation = Run-StagedCase -CaseName "07_best_nano_variant_continuation" `
            -InitialQPath $bestVariantSeed `
            -StageIters @(4, 4) `
            -ExtraArgs $bestVariantArgs
    }

    $continuationGrid = $null
    if (($null -ne $bestVariantContinuation) -and ($bestVariantContinuation.final_maxres -lt ($bestVariant.maxres - $ImprovementTolerance))) {
        $continuationGrid = Run-ExactGrid2D -StepName "08_best_nano_variant_exact_grid_q34_followup" `
            -CenterQ $bestVariantContinuation.final_q_path `
            -IndexA 2 `
            -IndexB 3 `
            -DeltasA $q3Nano3D `
            -DeltasB $q4Nano3D
    }

    $noteLines = New-Object System.Collections.Generic.List[string]
    $noteLines.Add(("# Compiled sidecar Bellman RE {0} 12-hour packet" -f $SeedLabel))
    $noteLines.Add("")
    $noteLines.Add(("Date: {0}" -f (Get-Date -Format "yyyy-MM-dd")))
    $noteLines.Add("")
    $noteLines.Add("## Scope")
    $noteLines.Add("")
    $noteLines.Add("- standalone compiled-sidecar Bellman RE branch only")
    $noteLines.Add(("- {0} seed: [{1}]" -f $SeedLabel, (Format-QPath -Values $nanoSeed)))
    $noteLines.Add("- no MATLAB, no annual branch, no benchmark-grid RE push")
    $noteLines.Add("")
    $noteLines.Add("## Exact nano baseline")
    $noteLines.Add("")
    $noteLines.Add(("- exact max residual about {0:F10}" -f $exactBaseline.maxres))
    $noteLines.Add(("- exact implied path: [{0}]" -f ((($exactBaseline.implied_q_path | ForEach-Object { "{0:F6}" -f $_ }) -join ", "))))
    $noteLines.Add("")
    $noteLines.Add("## Exact nano probes")
    $noteLines.Add("")
    foreach ($gridSummary in @($lineQ3, $grid23, $grid34, $grid234)) {
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
        $noteLines.Add("- no exact nano candidate beat the baseline by more than the acceptance tolerance")
    }
    $noteLines.Add("")
    $noteLines.Add("## Nano variant sweep")
    $noteLines.Add("")
    $noteLines.Add(("CSV: {0}" -f $variantCsvPath.Replace($projectRoot + "\", "")))
    foreach ($variantRow in ($variantResults | Sort-Object `
            @{ Expression = { [double]$_.maxres }; Ascending = $true }, `
            @{ Expression = { if ([bool]$_.stalled) { 1 } else { 0 } }; Ascending = $true }, `
            @{ Expression = { [string]$_.name }; Ascending = $true } | Select-Object -First 6)) {
        $noteLines.Add(("- {0}: max residual {1:F10} | stalled {2}" -f $variantRow.name, [double]$variantRow.maxres, $variantRow.stalled))
    }
    $noteLines.Add("")
    $noteLines.Add("## Best nano variant continuation")
    $noteLines.Add("")
    if ($null -ne $bestVariantContinuation) {
        $noteLines.Add(("- best nano variant: {0}" -f $bestVariant.name))
        foreach ($stage in $bestVariantContinuation.stages) {
            $noteLines.Add(("- stage {0}: max residual {1:F10} | q [{2}]" -f $stage.stage, [double]$stage.maxres, (Format-QPath -Values $stage.q_path)))
        }
        $noteLines.Add(("- final implied path: [{0}]" -f (Format-QPath -Values $bestVariantContinuation.final_implied_q_path)))
    } else {
        $noteLines.Add("- no nano variant beat the baseline enough to justify a continuation run")
    }
    $noteLines.Add("")
    $noteLines.Add("## Follow-up exact grid")
    $noteLines.Add("")
    if ($null -ne $continuationGrid) {
        $top = $continuationGrid.best | Select-Object -First 1
        $noteLines.Add(("- {0}: best exact max residual about {1:F10}" -f $continuationGrid.step_name, [double]$top.maxres))
        $noteLines.Add(("  - csv: {0}" -f $continuationGrid.csv_path.Replace($projectRoot + "\", "")))
        $noteLines.Add(("  - q path: [{0}]" -f $top.q_path))
    } else {
        $noteLines.Add("- no continuation follow-up grid was justified")
    }
    $noteLines.Add("")
    $noteLines.Add("## Read")
    $noteLines.Add("")
    $noteLines.Add("- This packet is meant to decide whether the smaller q3 nano step opens a real local continuation beyond the ultra-micro wall.")
    $noteLines.Add("- Promote only improvements that survive at least one continuation stage.")
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
        "Bellman RE nano wall 12-hour workflow stopped with an error.",
        "Run directory: $runDir",
        "Error: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "error"
    throw
}
