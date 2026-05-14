param(
    [string]$RunLabel = "bellman_re_branch_lookahead_16_hour_workflow",
    [double]$TimeoutHours = 16
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
$stage2CsvPath = Join-Path $runDir "stage2_cases.csv"
$cliffCsvPath = Join-Path $runDir "cliff_cases.csv"
$canonicalNotePath = Join-Path $projectRoot "notes/build/compiled_sidecar_bellman_re_branch_lookahead_16_hour_packet.md"

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

function Invoke-ReCase {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [double[]]$InitialQPath,
        [Parameter(Mandatory = $true)]
        [int]$MaxIter,
        [Parameter(Mandatory = $true)]
        [string[]]$ExtraArgs
    )

    Test-Deadline

    $stdoutPath = Join-Path $runDir ("{0}_stdout.log" -f $StepName)
    $stderrPath = Join-Path $runDir ("{0}_stderr.log" -f $StepName)
    $args = @(
        $inputRoot,
        "--initial-q-path", (Format-QPath -Values $InitialQPath),
        "--max-iter", "$MaxIter"
    ) + $ExtraArgs

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
        throw "Empty stdout for step: $StepName"
    }

    $parsed = Parse-ReOutput -Text $stdout
    $exitSuffix = if ($proc.ExitCode -ne 0) { " exit=$($proc.ExitCode)" } else { "" }
    Write-Status ("DONE {0} maxres={1:F10} stalled={2}{3}" -f $StepName, $parsed.maxres, ([int]$parsed.stalled), $exitSuffix)
    return $parsed
}

function Get-Stage2Args {
    param(
        [string[]]$ExtraArgs = @()
    )

    return @(
        "--q-search-grid", "1.5,1.70,1.72,1.73,1.74,1.75,1.80,1.85,1.90,2.00,2.25,2.35,2.40,2.50",
        "--backtracking-line-search",
        "--backtracking-activate-residual", "0.05",
        "--backtracking-accept-worsen-ratio", "1.0",
        "--backtracking-accept-worsen-abs-tol", "0.0",
        "--backtracking-shrink-factor", "0.5",
        "--max-backtracking-rounds", "6",
        "--min-damping-path", "0.0125,0.0125,0.0125,0.0125",
        "--coordinate-backtracking-line-search",
        "--coordinate-backtracking-activate-residual", "0.012",
        "--max-coordinate-backtracking-periods", "1",
        "--max-coordinate-backtracking-rounds", "8",
        "--coordinate-backtracking-improve-tol", "0.0",
        "--coordinate-min-damping-path", "0.0015625,0.0015625,0.0015625,0.0015625"
    ) + $ExtraArgs
}

function Get-CoarseStageArgs {
    param(
        [string[]]$ExtraArgs = @()
    )

    return @(
        "--q-search-grid", "1.5,2.0,2.5",
        "--backtracking-line-search",
        "--backtracking-activate-residual", "0.05",
        "--backtracking-accept-worsen-ratio", "1.0",
        "--backtracking-accept-worsen-abs-tol", "0.0",
        "--backtracking-shrink-factor", "0.5",
        "--max-backtracking-rounds", "6",
        "--min-damping-path", "0.0125,0.0125,0.0125,0.0125",
        "--coordinate-backtracking-line-search",
        "--coordinate-backtracking-activate-residual", "0.012",
        "--max-coordinate-backtracking-periods", "1",
        "--max-coordinate-backtracking-rounds", "8",
        "--coordinate-backtracking-improve-tol", "0.0",
        "--coordinate-min-damping-path", "0.0015625,0.0015625,0.0015625,0.0015625"
    ) + $ExtraArgs
}

function Run-CliffGrid {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [double[]]$BaseQPath,
        [Parameter(Mandatory = $true)]
        [double[]]$Q4Values,
        [Parameter(Mandatory = $true)]
        [string[]]$ExtraArgs
    )

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($q4 in $Q4Values) {
        $trial = [double[]]@($BaseQPath[0], $BaseQPath[1], $BaseQPath[2], $q4)
        $stepName = "{0}_{1}" -f $Label, (($q4.ToString("F7")).Replace(".", "p"))
        $parsed = Invoke-ReCase -StepName $stepName -InitialQPath $trial -MaxIter 1 -ExtraArgs $ExtraArgs
        $rows.Add([pscustomobject]@{
            label = $Label
            q4 = $q4
            maxres = $parsed.maxres
            stalled = $parsed.stalled
            q_path = Format-QPath -Values $parsed.q_path
            implied_q_path = Format-QPath -Values $parsed.implied_q_path
            residual_path = Format-QPath -Values $parsed.residual_path
        })
    }
    return $rows
}

try {
    Set-Content -Path $statusPath -Value ""
    Set-Content -Path $summaryPath -Value ""
    Set-ActivePointer -Phase "starting"

    $defaultSeed = [double[]]@(2.0, 2.05, 2.08, 2.10)
    $coarseEndpoint = [double[]]@(1.7280288619, 1.7542903475, 1.8750762607, 2.3960221075)
    $balancedStage2Seed = [double[]]@(1.7293554408, 1.7542903475, 1.8750762607, 2.3960221075)
    $cliffQ4Values = [double[]]@(2.3960221075, 2.3960500000, 2.3960750000, 2.3961000000, 2.3961250000, 2.3961500000, 2.3961750000, 2.3962000000)

    @(
        "Objective: validate whether branch lookahead can beat the staged enriched Bellman RE wall near 0.0039779."
        "Run label: $RunLabel"
        "Scope lock:"
        " - project 03 only"
        " - compiled_sidecar Bellman RE branch only"
        " - no MATLAB, no annual branch, no benchmark-grid RE push, no paper drafting"
        "Deliverables:"
        " - staged frontier case table"
        " - cliff-seed case table"
        " - canonical packet note at notes/build/compiled_sidecar_bellman_re_branch_lookahead_16_hour_packet.md"
        "Stopping rule: stop after the packet note exists, at the first material blocker, or at the 16-hour cap."
    ) | Set-Content -Path $manifestPath

    Write-Status ("RUN_DIR {0}" -f $runDir)

    $caseTable = New-Object System.Collections.Generic.List[object]
    $cliffTable = New-Object System.Collections.Generic.List[object]

    $caseSpecs = @(
        [pscustomobject]@{
            name = "baseline_stage2"
            stage1_extra = @()
            stage2_extra = @()
        },
        [pscustomobject]@{
            name = "lookahead_stage2"
            stage1_extra = @()
            stage2_extra = @(
                "--root-selection-lookahead",
                "--root-selection-lookahead-min-brackets", "2"
            )
        },
        [pscustomobject]@{
            name = "lookahead_prev34_stage2"
            stage1_extra = @()
            stage2_extra = @(
                "--root-selection-lookahead",
                "--root-selection-lookahead-min-brackets", "2",
                "--root-selection-anchor", "previous_implied",
                "--root-selection-previous-implied-mask", "0,0,1,1",
                "--branch-hysteresis-mask", "0,0,1,1",
                "--branch-tie-break-mask", "0,0,1,1"
            )
        },
        [pscustomobject]@{
            name = "lookahead_prev234_stage2"
            stage1_extra = @()
            stage2_extra = @(
                "--root-selection-lookahead",
                "--root-selection-lookahead-min-brackets", "2",
                "--root-selection-anchor", "previous_implied",
                "--root-selection-previous-implied-mask", "0,1,1,1",
                "--branch-hysteresis-mask", "0,1,1,1",
                "--branch-tie-break-mask", "0,1,1,1"
            )
        }
    )

    foreach ($caseSpec in $caseSpecs) {
        $parsed = Invoke-ReCase -StepName $caseSpec.name `
            -InitialQPath $coarseEndpoint `
            -MaxIter 20 `
            -ExtraArgs (Get-Stage2Args -ExtraArgs $caseSpec.stage2_extra)

        $caseTable.Add([pscustomobject]@{
            case_name = $caseSpec.name
            maxres = $parsed.maxres
            iterations = $parsed.iterations
            stalled = $parsed.stalled
            q_path = Format-QPath -Values $parsed.q_path
            implied_q_path = Format-QPath -Values $parsed.implied_q_path
            residual_path = Format-QPath -Values $parsed.residual_path
        })
    }

    $caseTable | Sort-Object maxres, case_name | Export-Csv -Path $stage2CsvPath -NoTypeInformation
    $bestStage2 = $caseTable | Sort-Object maxres, case_name | Select-Object -First 1
    Write-Status ("BEST_STAGE2 {0} maxres={1:F10}" -f $bestStage2.case_name, [double]$bestStage2.maxres)

    $baselineCliffArgs = @(
        "--q-search-grid", "1.5,1.70,1.72,1.73,1.74,1.75,1.80,1.85,1.90,2.00,2.25,2.35,2.40,2.50",
        "--root-selection-anchor", "previous_implied",
        "--root-selection-previous-implied-mask", "0,0,1,1",
        "--branch-hysteresis-mask", "0,0,1,1",
        "--branch-tie-break-mask", "0,0,1,1",
        "--debug-root-selection"
    )
    $lookaheadCliffArgs = $baselineCliffArgs + @(
        "--root-selection-lookahead",
        "--root-selection-lookahead-min-brackets", "2"
    )

    foreach ($row in (Run-CliffGrid -Label "cliff_baseline" -BaseQPath $balancedStage2Seed -Q4Values $cliffQ4Values -ExtraArgs $baselineCliffArgs)) {
        $cliffTable.Add($row)
    }
    foreach ($row in (Run-CliffGrid -Label "cliff_lookahead" -BaseQPath $balancedStage2Seed -Q4Values $cliffQ4Values -ExtraArgs $lookaheadCliffArgs)) {
        $cliffTable.Add($row)
    }
    $cliffTable | Sort-Object label, q4 | Export-Csv -Path $cliffCsvPath -NoTypeInformation

    $promotedImprovement = ([double]$bestStage2.maxres) + 1.0e-6 -lt 0.0039778925
    $promotionSummary = "No promoted improvement."
    $validationRows = @()
    if ($promotedImprovement) {
        $winningSpec = $caseSpecs | Where-Object { $_.name -eq $bestStage2.case_name } | Select-Object -First 1
        $stage1 = Invoke-ReCase -StepName ("validate_{0}_stage1" -f $winningSpec.name) `
            -InitialQPath $defaultSeed `
            -MaxIter 60 `
            -ExtraArgs (Get-CoarseStageArgs -ExtraArgs $winningSpec.stage1_extra)
        $stage2 = Invoke-ReCase -StepName ("validate_{0}_stage2" -f $winningSpec.name) `
            -InitialQPath ([double[]]$stage1.q_path) `
            -MaxIter 20 `
            -ExtraArgs (Get-Stage2Args -ExtraArgs $winningSpec.stage2_extra)
        $validationRows = @(
            [pscustomobject]@{
                step = "stage1"
                maxres = $stage1.maxres
                stalled = $stage1.stalled
                q_path = Format-QPath -Values $stage1.q_path
            }
            [pscustomobject]@{
                step = "stage2"
                maxres = $stage2.maxres
                stalled = $stage2.stalled
                q_path = Format-QPath -Values $stage2.q_path
            }
        )
        $promotionSummary = "Promoted candidate $($winningSpec.name) beat the staged wall and was rerun from the default seed with baseline coarse stage 1 and case-specific stage 2."
    } else {
        Write-Status "NO_PROMOTED_IMPROVEMENT stage2_wall_intact"
    }

    $cliffBaselineWorst = $cliffTable | Where-Object { $_.label -eq "cliff_baseline" } | Sort-Object q4 | Select-Object -First 1
    $cliffLookaheadWorst = $cliffTable | Where-Object { $_.label -eq "cliff_lookahead" } | Sort-Object q4 | Select-Object -First 1

    $noteLines = @(
        "# Compiled sidecar Bellman RE branch lookahead 16-hour packet"
        ""
        "Date: $(Get-Date -Format 'yyyy-MM-dd')"
        ""
        "## Objective"
        ""
        "Test whether the newly activated live root-selection lookahead can beat the staged enriched Bellman RE wall near 0.0039778925 on the standalone compiled branch."
        ""
        "## Run"
        ""
        "- Run directory: $runDir"
        "- Stage-2 case table: $stage2CsvPath"
        "- Cliff case table: $cliffCsvPath"
        ""
        "## Stage-2 continuation cases from the promoted coarse endpoint"
        ""
    )

    foreach ($row in ($caseTable | Sort-Object maxres, case_name)) {
        $noteLines += ('- {0}: maxres ~= {1:F10}, stalled = {2}' -f $row.case_name, [double]$row.maxres, ([int][bool]$row.stalled))
        $noteLines += ('  - q ~= [{0}]' -f $row.q_path)
        $noteLines += ('  - qhat ~= [{0}]' -f $row.implied_q_path)
    }

    $noteLines += ""
    $noteLines += "## Cliff probe"
    $noteLines += ""
    $noteLines += "- The cliff grid scanned q4 values from 2.3960221075 to 2.3962000000 at the balanced stage-2 seed."
    $noteLines += "- Baseline and lookahead runs were both evaluated with root-selection-anchor = previous_implied and masks on periods 3-4."
    $noteLines += "- See the CSV for the full path table; this packet's purpose is to check whether lookahead preserves the low period-3 branch more often than the baseline selector."
    $noteLines += ""
    $noteLines += "## Promotion read"
    $noteLines += ""
    $noteLines += "- $promotionSummary"
    if ($validationRows.Count -gt 0) {
        foreach ($row in $validationRows) {
            $noteLines += ('- validation {0}: maxres ~= {1:F10}, stalled = {2}, q ~= [{3}]' -f $row.step, [double]$row.maxres, ([int][bool]$row.stalled), $row.q_path)
        }
    } else {
        $noteLines += "- The staged wall remains the benchmark to beat until a case improves on 0.0039778925 by a meaningful margin."
    }
    $noteLines += ""
    $noteLines += "## Bottom line"
    $noteLines += ""
    $noteLines += "- This packet is a branch-continuation validation pass, not a new solver redesign."
    $noteLines += "- If one lookahead case beats the wall, the next live task is to promote that rule into the canonical staged workflow."
    $noteLines += "- If none do, the next live task is a period-3 branch-continuity rule rather than more bridge-family probing."

    $noteLines | Set-Content -Path $canonicalNotePath

    @(
        "Workflow: success"
        "Best stage2 case: $($bestStage2.case_name)"
        "Best stage2 maxres: $([double]$bestStage2.maxres)"
        $promotionSummary
    ) | Set-Content -Path $summaryPath

    Write-Status ("SUCCESS note={0}" -f $canonicalNotePath)
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("FAIL {0}" -f $message)
    @(
        "Workflow: failed"
        "Message: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "failed"
    throw
}
