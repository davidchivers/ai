param(
    [string]$RunLabel = "bellman_re_t11_supervisor_workflow",
    [double]$TimeoutHours = 16,
    [double]$TargetMaxRes = 0.0400000000,
    [double]$ImproveTol = 0.0002500000,
    [string]$BaselineRunDir = "",
    [string]$BaselineLabel = "baseline"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
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
$resultsPath = Join-Path $runDir "supervisor_cases.csv"
$notePath = Join-Path $projectRoot "notes/build/compiled_sidecar_bellman_re_t11_supervisor_packet.md"
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
        [string[]]$ExtraLines = @()
    )

    @(
        "started_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "phase=$Phase"
        "pid=$ProcessIds"
        "run_dir=$runDir"
        "status_path=$statusPath"
        "latest_pointer=$latestPointer"
    ) + $ExtraLines | Set-Content -Path $activePointer
}

function Test-Deadline {
    if ((Get-Date) -gt $deadline) {
        throw "Supervisor deadline reached."
    }
}

function Parse-PointerFile {
    param([string]$Path)
    $map = @{}
    if (-not (Test-Path $Path)) {
        return $map
    }
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^(?<k>[^=]+)=(?<v>.*)$') {
            $map[$matches.k] = $matches.v
        }
    }
    return $map
}

function Wait-ForExternalWorkflow {
    param(
        [string]$PointerPath,
        [string]$FallbackScriptPath
    )

    if (-not (Test-Path $PointerPath)) {
        Write-Status ("External workflow missing; running fallback script {0}" -f $FallbackScriptPath)
        & $FallbackScriptPath
    }

    $pointer = Parse-PointerFile -Path $PointerPath
    $phase = if ($pointer.ContainsKey("phase")) { $pointer["phase"] } else { "" }
    $pidText = if ($pointer.ContainsKey("pid")) { $pointer["pid"] } else { "" }
    $childIds = @($pidText -split "," | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ })

    if (($phase -ne "success") -and ($phase -ne "failed") -and $childIds.Count -eq 0) {
        Write-Status ("External workflow pointer stale; running fallback script {0}" -f $FallbackScriptPath)
        & $FallbackScriptPath
    }

    while ($true) {
        Test-Deadline
        $pointer = Parse-PointerFile -Path $PointerPath
        $phase = if ($pointer.ContainsKey("phase")) { $pointer["phase"] } else { "" }
        $pidText = if ($pointer.ContainsKey("pid")) { $pointer["pid"] } else { "" }
        $childIds = @($pidText -split "," | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ })
        $alive = $false
        foreach ($childId in $childIds) {
            if (Get-Process -Id $childId -ErrorAction SilentlyContinue) {
                $alive = $true
                break
            }
        }
        if (($phase -eq "success") -or ($phase -eq "failed") -or (-not $alive)) {
            break
        }
        Set-ActivePointer -Phase "waiting_external" -ProcessIds ($childIds -join ",") -ExtraLines @(
            "watched_pointer=$PointerPath"
            "watched_phase=$phase"
            "heartbeat_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        )
        Write-Status ("HEARTBEAT waiting_external phase={0}" -f $phase)
        Start-Sleep -Seconds 30
    }

    $pointer = Parse-PointerFile -Path $PointerPath
    $runDirValue = if ($pointer.ContainsKey("run_dir")) { $pointer["run_dir"] } else { "" }
    return $runDirValue
}

function Get-BestFromRunDir {
    param(
        [string]$WorkflowLabel,
        [string]$WorkflowRunDir
    )
    $csvPath = Join-Path $WorkflowRunDir "t11_cases.csv"
    if (-not (Test-Path $csvPath)) {
        throw "Missing results CSV for workflow {0}: {1}" -f $WorkflowLabel, $csvPath
    }
    $best = Import-Csv -LiteralPath $csvPath | Sort-Object { [double]$_.maxres }, case_name | Select-Object -First 1
    return [pscustomobject]@{
        source = $WorkflowLabel
        run_dir = $WorkflowRunDir
        csv_path = $csvPath
        case_name = $best.case_name
        maxres = [double]$best.maxres
        q_path = [string]$best.q_path
        implied_q_path = [string]$best.implied_q_path
        residual_path = [string]$best.residual_path
    }
}

function Invoke-WorkflowAndParseBest {
    param(
        [string]$WorkflowLabel,
        [string]$ScriptPath,
        [hashtable]$Parameters
    )

    Test-Deadline
    Write-Status ("START {0}" -f $WorkflowLabel)
    Set-ActivePointer -Phase $WorkflowLabel
    & $ScriptPath @Parameters
    $runLabelValue = [string]$Parameters["RunLabel"]
    $latestPointerPath = Join-Path $logsRoot ("latest_{0}.txt" -f $runLabelValue)
    if (-not (Test-Path $latestPointerPath)) {
        throw "Missing latest pointer for workflow {0}: {1}" -f $WorkflowLabel, $latestPointerPath
    }
    $workflowRunDir = Get-Content -LiteralPath $latestPointerPath -ErrorAction Stop | Select-Object -First 1
    $best = Get-BestFromRunDir -WorkflowLabel $WorkflowLabel -WorkflowRunDir $workflowRunDir
    Write-Status ("DONE {0} best_case={1} maxres={2:F10}" -f $WorkflowLabel, $best.case_name, $best.maxres)
    return $best
}

function Maybe-PromoteResult {
    param(
        [pscustomobject]$CurrentBest,
        [pscustomobject]$Candidate,
        [double]$ImproveTolerance
    )

    if (($CurrentBest.maxres - $Candidate.maxres) -gt $ImproveTolerance) {
        Write-Status ("PROMOTE {0} improved_to={1:F10}" -f $Candidate.source, $Candidate.maxres)
        return $Candidate
    }

    return $CurrentBest
}

try {
    Set-Content -Path $statusPath -Value ""
    Set-Content -Path $summaryPath -Value ""
    Set-ActivePointer -Phase "starting"

    $suffixScript = Join-Path $PSScriptRoot "bellman_re_t11_suffix_ladder_workflow.ps1"

    if ([string]::IsNullOrWhiteSpace($BaselineRunDir)) {
        $lateTailPointer = Join-Path $logsRoot "active_bellman_re_t11_late_tail_workflow.txt"
        $lateTailScript = Join-Path $PSScriptRoot "bellman_re_t11_late_tail_workflow.ps1"
        $initialRunDir = Wait-ForExternalWorkflow -PointerPath $lateTailPointer -FallbackScriptPath $lateTailScript
        $best = Get-BestFromRunDir -WorkflowLabel "late_tail" -WorkflowRunDir $initialRunDir
    }
    else {
        $best = Get-BestFromRunDir -WorkflowLabel $BaselineLabel -WorkflowRunDir $BaselineRunDir
    }
    Write-Status ("BASELINE source={0} case={1} maxres={2:F10}" -f $best.source, $best.case_name, $best.maxres)

    $rows = New-Object System.Collections.Generic.List[object]
    $rows.Add($best)
    $round = 0
    $noImproveRounds = 0

    while (($best.maxres -gt $TargetMaxRes) -and ($noImproveRounds -lt 2)) {
        Test-Deadline
        $round += 1

        $narrowLabel = "suffix_narrow_round_{0}" -f $round
        $narrowRunLabel = "bellman_re_t11_suffix_ladder_workflow_narrow_r{0}" -f $round
        $narrow = Invoke-WorkflowAndParseBest -WorkflowLabel $narrowLabel -ScriptPath $suffixScript -Parameters @{
            RunLabel = $narrowRunLabel
            TimeoutHours = 6
            CaseSet = "narrow"
            SeedQPath = $best.q_path
        }
        $rows.Add($narrow)

        if (($best.maxres - $narrow.maxres) -gt $ImproveTol) {
            $best = $narrow
            $noImproveRounds = 0
            Write-Status ("PROMOTE {0} improved_to={1:F10}" -f $narrow.source, $best.maxres)
            continue
        }

        $broadLabel = "suffix_broad_round_{0}" -f $round
        $broadRunLabel = "bellman_re_t11_suffix_ladder_workflow_broad_r{0}" -f $round
        $broad = Invoke-WorkflowAndParseBest -WorkflowLabel $broadLabel -ScriptPath $suffixScript -Parameters @{
            RunLabel = $broadRunLabel
            TimeoutHours = 6
            CaseSet = "broad"
            SeedQPath = $best.q_path
        }
        $rows.Add($broad)

        $bestAfterBroad = Maybe-PromoteResult -CurrentBest $best -Candidate $broad -ImproveTolerance $ImproveTol
        $broadImproved = $bestAfterBroad.maxres -lt $best.maxres
        $best = $bestAfterBroad

        if ($broadImproved) {
            $noImproveRounds = 0

            $deepLabel = "suffix_deep_round_{0}" -f $round
            $deepRunLabel = "bellman_re_t11_suffix_ladder_workflow_deep_r{0}" -f $round
            $deep = Invoke-WorkflowAndParseBest -WorkflowLabel $deepLabel -ScriptPath $suffixScript -Parameters @{
                RunLabel = $deepRunLabel
                TimeoutHours = 6
                CaseSet = "deep"
                SeedQPath = $best.q_path
            }
            $rows.Add($deep)

            $bestAfterDeep = Maybe-PromoteResult -CurrentBest $best -Candidate $deep -ImproveTolerance $ImproveTol
            if ($bestAfterDeep.maxres -lt $best.maxres) {
                $best = $bestAfterDeep
                $noImproveRounds = 0
            }
            else {
                $terminalLabel = "suffix_terminal_round_{0}" -f $round
                $terminalRunLabel = "bellman_re_t11_suffix_ladder_workflow_terminal_r{0}" -f $round
                $terminal = Invoke-WorkflowAndParseBest -WorkflowLabel $terminalLabel -ScriptPath $suffixScript -Parameters @{
                    RunLabel = $terminalRunLabel
                    TimeoutHours = 4
                    CaseSet = "terminal"
                    SeedQPath = $best.q_path
                }
                $rows.Add($terminal)

                $bestAfterTerminal = Maybe-PromoteResult -CurrentBest $best -Candidate $terminal -ImproveTolerance $ImproveTol
                if ($bestAfterTerminal.maxres -lt $best.maxres) {
                    $best = $bestAfterTerminal
                    $noImproveRounds = 0
                }
            }
        }
        else {
            $noImproveRounds += 1
            Write-Status ("STALL round={0} best_still={1:F10}" -f $round, $best.maxres)
        }
    }

    $rows | Export-Csv -Path $resultsPath -NoTypeInformation

    @(
        "# Compiled sidecar Bellman RE T11 supervisor packet"
        ""
        "Date: $(Get-Date -Format 'yyyy-MM-dd')"
        ""
        "## Objective"
        ""
        "Keep the `T = 11` Bellman RE frontier moving without stopping at packet boundaries by chaining late-tail and suffix-control workflows."
        ""
        "## Run"
        ""
        "- Run directory: $runDir"
        "- Case table: $resultsPath"
        ""
        "## Best observed point"
        ""
        "- source: $($best.source)"
        "- best case: $($best.case_name)"
        ("- maxres ~= {0:F10}" -f [double]$best.maxres)
        "- q ~= [$($best.q_path)]"
        "- qhat ~= [$($best.implied_q_path)]"
        ""
        "## Stop reason"
        ""
        ("- target max residual: {0:F10}" -f $TargetMaxRes)
        ("- no-improvement rounds: {0}" -f $noImproveRounds)
        ""
        "## Bottom line"
        ""
        "- This supervisor chained the live late-tail packet into narrow and broad suffix ladders."
        "- Use the CSV for the full sequence of promoted and non-promoted cases."
    ) | Set-Content -Path $notePath

    @(
        "Workflow: success"
        "Best source: $($best.source)"
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
