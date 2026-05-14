param(
    [string]$RunLabel = "bellman_re_t13_suffix_probe_workflow",
    [double]$TimeoutHours = 8
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
$resultsPath = Join-Path $runDir "t13_cases.csv"
$notePath = Join-Path $projectRoot "notes/build/compiled_sidecar_bellman_re_t13_suffix_probe.md"
$deadline = (Get-Date).AddHours($TimeoutHours)

function Write-Status {
    param([string]$Message)
    $timestamped = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $statusPath -Value $timestamped
    Set-Content -Path $latestPointer -Value $runDir
}

function Set-ActivePointer {
    param(
        [string]$Phase,
        [string]$ProcessIds = "",
        [string]$StdoutPath = "",
        [string]$StderrPath = "",
        [string[]]$ExtraLines = @()
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
    ) + $ExtraLines | Set-Content -Path $activePointer
}

function Test-Deadline {
    if ((Get-Date) -gt $deadline) {
        throw "Workflow deadline reached."
    }
}

function Parse-NumericArrayLine {
    param([string]$Line)
    $payload = ($Line -split ":\s+", 2)[1].Trim()
    if ([string]::IsNullOrWhiteSpace($payload)) {
        return @()
    }
    return @($payload -split "\s+" | Where-Object { $_ -ne "" } | ForEach-Object { [double]$_ })
}

function Parse-ReOutput {
    param([string]$Text)

    $maxResidualMatch = [regex]::Match($Text, "max abs residual:\s+([0-9Ee+\-\.]+)")
    $iterationsMatch = [regex]::Match($Text, "iterations run:\s+([0-9]+)")
    $stalledMatch = [regex]::Match($Text, "stalled:\s+([01])")
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
        q_path = if ($qLine) { Parse-NumericArrayLine -Line $qLine } else { @() }
        implied_q_path = if ($impliedLine) { Parse-NumericArrayLine -Line $impliedLine } else { @() }
        residual_path = if ($residualLine) { Parse-NumericArrayLine -Line $residualLine } else { @() }
        raw = $Text
    }
}

function Format-QPath {
    param([double[]]$Values)
    return (($Values | ForEach-Object { "{0:F10}" -f $_ }) -join ",")
}

function Invoke-ReCase {
    param(
        [string]$StepName,
        [double[]]$InitialQPath,
        [string]$ContinuityMask,
        [string]$PreviousImpliedMask
    )

    Test-Deadline

    $stdoutPath = Join-Path $runDir ("{0}_stdout.log" -f $StepName)
    $stderrPath = Join-Path $runDir ("{0}_stderr.log" -f $StepName)
    $procArgs = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", (Join-Path $compiledRoot "run_transition_re_cli.ps1"),
        "-Mode", "t13_diag",
        "-InitialQPath", (Format-QPath -Values $InitialQPath),
        "-QSearchGrid", "1.5,1.70,1.72,1.73,1.74,1.75,1.80,1.85,1.90,2.00,2.25,2.35,2.40,2.50",
        "-MaxIter", "5",
        "-BacktrackingLineSearch",
        "-BacktrackingActivateResidual", "0.5",
        "-BacktrackingAcceptWorsenRatio", "1.0",
        "-BacktrackingAcceptWorsenAbsTol", "0.0",
        "-BacktrackingShrinkFactor", "0.5",
        "-MaxBacktrackingRounds", "6",
        "-MinDampingPath", "0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125,0.0125",
        "-CoordinateBacktrackingLineSearch",
        "-CoordinateBacktrackingActivateResidual", "0.2",
        "-MaxCoordinateBacktrackingPeriods", "1",
        "-MaxCoordinateBacktrackingRounds", "8",
        "-CoordinateBacktrackingImproveTol", "0.0",
        "-CoordinateMinDampingPath", "0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625,0.0015625",
        "-BranchContinuityMask", $ContinuityMask,
        "-BranchContinuityVoteSlack", "1.0",
        "-RootSelectionLookahead",
        "-RootSelectionLookaheadMinBrackets", "2",
        "-RootSelectionAnchor", "previous_implied",
        "-RootSelectionPreviousImpliedMask", $PreviousImpliedMask,
        "-BranchHysteresisMask", "0,1,1,1,1,1,1,1,1,1,1,1,1",
        "-BranchTieBreakMask", "0,1,1,1,1,1,1,1,1,1,1,1,1",
        "-SkipBuild"
    )

    Write-Status ("START {0}" -f $StepName)
    $proc = Start-Process -FilePath "powershell.exe" `
        -ArgumentList $procArgs `
        -WorkingDirectory $compiledRoot `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath

    Set-ActivePointer -Phase $StepName -ProcessIds $proc.Id -StdoutPath $stdoutPath -StderrPath $stderrPath
    $heartbeatDue = (Get-Date).AddSeconds(60)
    $caseStartTime = Get-Date

    while (-not $proc.HasExited) {
        Test-Deadline
        Start-Sleep -Seconds 10
        $proc.Refresh()
        if ((Get-Date) -ge $heartbeatDue) {
            $elapsedSeconds = [int]((Get-Date) - $caseStartTime).TotalSeconds
            $cliChild = Get-CimInstance Win32_Process -Filter ("ParentProcessId = {0}" -f $proc.Id) |
                Where-Object { $_.Name -eq "fertility_transition_re_cli.exe" } |
                Select-Object -First 1
            $extraLines = @(
                "heartbeat_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                "elapsed_seconds=$elapsedSeconds"
            )
            if ($cliChild) {
                $extraLines += "cli_pid=$($cliChild.ProcessId)"
            }
            Set-ActivePointer -Phase $StepName -ProcessIds $proc.Id -StdoutPath $stdoutPath -StderrPath $stderrPath -ExtraLines $extraLines
            Write-Status ("HEARTBEAT {0} elapsed_seconds={1}" -f $StepName, $elapsedSeconds)
            $heartbeatDue = (Get-Date).AddSeconds(60)
        }
    }

    $stdout = if (Test-Path $stdoutPath) { Get-Content -Path $stdoutPath -Raw } else { "" }
    if ([string]::IsNullOrWhiteSpace($stdout)) {
        throw "Empty stdout for step: $StepName"
    }

    $parsed = Parse-ReOutput -Text $stdout
    Write-Status ("DONE {0} maxres={1:F10} stalled={2}" -f $StepName, $parsed.maxres, ([int]$parsed.stalled))
    return $parsed
}

try {
    Set-Content -Path $statusPath -Value ""
    Set-Content -Path $summaryPath -Value ""
    Set-ActivePointer -Phase "starting"

    $seed = [double[]]@(2.2466822737,2.2613496523,2.2858505356,2.3016953730,2.3236256760,2.4000044888,2.4009632928,2.3615630257,2.3976989307,2.3505260199,2.4061451849,2.4012054578,2.4012054578)
    $caseSpecs = @(
        [pscustomobject]@{ name = "late7_13"; continuity = "0,0,0,0,0,0,1,1,1,1,1,1,1"; prev = "0,1,1,1,1,1,1,1,1,1,1,1,1" },
        [pscustomobject]@{ name = "late6_13"; continuity = "0,0,0,0,0,1,1,1,1,1,1,1,1"; prev = "0,1,1,1,1,1,1,1,1,1,1,1,1" },
        [pscustomobject]@{ name = "late7_13_suffix_anchor"; continuity = "0,0,0,0,0,0,1,1,1,1,1,1,1"; prev = "0,0,0,0,0,0,1,1,1,1,1,1,1" }
    )

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($caseSpec in $caseSpecs) {
        $parsed = Invoke-ReCase -StepName $caseSpec.name -InitialQPath $seed -ContinuityMask $caseSpec.continuity -PreviousImpliedMask $caseSpec.prev
        $rows.Add([pscustomobject]@{
            case_name = $caseSpec.name
            continuity_mask = $caseSpec.continuity
            previous_implied_mask = $caseSpec.prev
            maxres = $parsed.maxres
            iterations = $parsed.iterations
            stalled = $parsed.stalled
            q_path = Format-QPath -Values $parsed.q_path
            implied_q_path = Format-QPath -Values $parsed.implied_q_path
            residual_path = Format-QPath -Values $parsed.residual_path
        })
    }

    $rows | Sort-Object maxres, case_name | Export-Csv -Path $resultsPath -NoTypeInformation
    $best = $rows | Sort-Object maxres, case_name | Select-Object -First 1

    @(
        "# Compiled sidecar Bellman RE T13 suffix probe"
        ""
        "Date: $(Get-Date -Format 'yyyy-MM-dd')"
        ""
        "## Objective"
        ""
        "Test whether the improved T12 late-tail seed carries into T13 under the smallest plausible tail-focused continuity masks."
        ""
        "## Best case"
        ""
        "- best case: $($best.case_name)"
        ('- continuity mask: `{0}`' -f $best.continuity_mask)
        ('- previous-implied mask: `{0}`' -f $best.previous_implied_mask)
        ("- maxres ~= {0:F10}" -f [double]$best.maxres)
        "- q ~= [$($best.q_path)]"
        "- qhat ~= [$($best.implied_q_path)]"
        ""
        "## Files"
        ""
        "- Run directory: $runDir"
        "- Case table: $resultsPath"
    ) | Set-Content -Path $notePath

    @(
        "Workflow: success"
        "Best case: $($best.case_name)"
        "Best maxres: $([double]$best.maxres)"
        "Run directory: $runDir"
    ) | Set-Content -Path $summaryPath

    Write-Status ("SUCCESS note={0}" -f $notePath)
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
