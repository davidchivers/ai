param(
    [string]$RunLabel = "bellman_re_t11_overnight_supervisor_workflow",
    [double]$TimeoutHours = 12,
    [double]$TargetMaxRes = 0.0300000000,
    [double]$ImproveTol = 0.0002500000
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
$resultsPath = Join-Path $runDir "overnight_supervisor_summary.csv"
$notePath = Join-Path $projectRoot "notes/build/compiled_sidecar_bellman_re_t11_overnight_supervisor_packet.md"
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
        throw "Overnight supervisor deadline reached."
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

function Wait-ForPointerWorkflow {
    param([string]$PointerPath)

    if (-not (Test-Path $PointerPath)) {
        return
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
        Set-ActivePointer -Phase "waiting_current_run" -ProcessIds ($childIds -join ",") -ExtraLines @(
            "watched_pointer=$PointerPath"
            "watched_phase=$phase"
            "heartbeat_at=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        )
        Write-Status ("HEARTBEAT waiting_current_run phase={0}" -f $phase)
        Start-Sleep -Seconds 30
    }
}

function Get-BestCandidateRun {
    $rows = New-Object System.Collections.Generic.List[object]

    $dirs = Get-ChildItem -LiteralPath $logsRoot -Directory | Where-Object {
        ($_.Name -like "bellman_re_t11_late_tail_workflow_*") -or
        ($_.Name -like "bellman_re_t11_suffix_ladder_workflow_*")
    }

    foreach ($dir in $dirs) {
        $csvPath = Join-Path $dir.FullName "t11_cases.csv"
        if (-not (Test-Path $csvPath)) {
            continue
        }
        try {
            $best = Import-Csv -LiteralPath $csvPath | Sort-Object { [double]$_.maxres }, case_name | Select-Object -First 1
            if ($null -ne $best) {
                $rows.Add([pscustomobject]@{
                    run_dir = $dir.FullName
                    source = $dir.Name
                    case_name = $best.case_name
                    maxres = [double]$best.maxres
                    q_path = [string]$best.q_path
                })
            }
        }
        catch {
        }
    }

    if ($rows.Count -eq 0) {
        throw "No completed T11 run with t11_cases.csv was found."
    }

    $rows | Sort-Object maxres, source | Export-Csv -Path $resultsPath -NoTypeInformation
    return $rows | Sort-Object maxres, source | Select-Object -First 1
}

try {
    Set-Content -Path $statusPath -Value ""
    Set-Content -Path $summaryPath -Value ""
    Set-ActivePointer -Phase "starting"

    $currentDeepPointer = Join-Path $logsRoot "active_bellman_re_t11_suffix_ladder_workflow_deep_resume.txt"
    Wait-ForPointerWorkflow -PointerPath $currentDeepPointer

    $bestCandidate = Get-BestCandidateRun
    Write-Status ("BASELINE source={0} case={1} maxres={2:F10}" -f $bestCandidate.source, $bestCandidate.case_name, $bestCandidate.maxres)

    $remainingHours = [math]::Max(1.0, [math]::Floor(((($deadline - (Get-Date)).TotalMinutes) / 60.0) * 100) / 100)
    $supervisorScript = Join-Path $PSScriptRoot "bellman_re_t11_supervisor_workflow.ps1"
    Set-ActivePointer -Phase "handoff_supervisor"
    & $supervisorScript `
        -RunLabel "bellman_re_t11_supervisor_overnight_core" `
        -TimeoutHours $remainingHours `
        -TargetMaxRes $TargetMaxRes `
        -ImproveTol $ImproveTol `
        -BaselineRunDir $bestCandidate.run_dir `
        -BaselineLabel $bestCandidate.source

    $coreLatestPointer = Join-Path $logsRoot "latest_bellman_re_t11_supervisor_overnight_core.txt"
    $coreRunDir = Get-Content -LiteralPath $coreLatestPointer -ErrorAction Stop | Select-Object -First 1

    @(
        "# Compiled sidecar Bellman RE T11 overnight supervisor packet"
        ""
        "Date: $(Get-Date -Format 'yyyy-MM-dd')"
        ""
        "## Objective"
        ""
        "Wait for the live `T = 11` suffix run to finish, select the best completed `T = 11` frontier, and hand it off into the chained supervisor automatically."
        ""
        "## Baseline used"
        ""
        "- source: $($bestCandidate.source)"
        "- case: $($bestCandidate.case_name)"
        ("- maxres ~= {0:F10}" -f $bestCandidate.maxres)
        "- run dir: $($bestCandidate.run_dir)"
        ""
        "## Supervisor handoff"
        ""
        "- supervisor run dir: $coreRunDir"
    ) | Set-Content -Path $notePath

    @(
        "Workflow: success"
        "Baseline source: $($bestCandidate.source)"
        "Baseline case: $($bestCandidate.case_name)"
        "Baseline maxres: $([double]$bestCandidate.maxres)"
        "Supervisor run directory: $coreRunDir"
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
