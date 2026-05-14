param(
    [ValidateRange(1, 7)]
    [int]$StartAtStep = 1,
    [ValidateRange(1, 7)]
    [int]$EndAtStep = 7,
    [string]$RunLabel = "transition_benchmark_validation",
    [double]$StepTimeoutHours = 1.5
)

$ErrorActionPreference = "Stop"

if ($StartAtStep -gt $EndAtStep) {
    throw "StartAtStep must be less than or equal to EndAtStep."
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$tempDrive = Get-PSDrive -PSProvider FileSystem |
    Where-Object { $_.Free -gt 5GB } |
    Sort-Object Free -Descending |
    Select-Object -First 1
if ($null -eq $tempDrive) {
    throw "No filesystem drive with at least 5 GB free was found for workflow temp space."
}
$workflowTempRoot = Join-Path $tempDrive.Root "codex_temp\\03_fertility_and_housing_supply\\transition_benchmark_validation"
if (-not (Test-Path $workflowTempRoot)) {
    New-Item -ItemType Directory -Path $workflowTempRoot -Force | Out-Null
}
$env:TEMP = $workflowTempRoot
$env:TMP = $workflowTempRoot

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $logsRoot ("{0}_{1}" -f $RunLabel, $runStamp)
New-Item -ItemType Directory -Path $runDir | Out-Null

$activePointer = Join-Path $logsRoot ("active_{0}.txt" -f $RunLabel)
$latestPointer = Join-Path $logsRoot ("latest_{0}.txt" -f $RunLabel)
$statusPath = Join-Path $runDir "status.txt"
$summaryPath = Join-Path $runDir "summary.txt"
$manifestPath = Join-Path $runDir "manifest.txt"

function Write-Status {
    param([Parameter(Mandatory = $true)][string]$Message)
    $timestamped = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $statusPath -Value $timestamped
    Set-Content -Path $latestPointer -Value $runDir
}

function Set-ActivePointer {
    param(
        [Parameter(Mandatory = $true)][string]$Phase,
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

function Invoke-LoggedProcess {
    param(
        [Parameter(Mandatory = $true)][string]$StepName,
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][double]$TimeoutHours
    )

    $stdoutPath = Join-Path $runDir ("{0}_stdout.log" -f $StepName)
    $stderrPath = Join-Path $runDir ("{0}_stderr.log" -f $StepName)

    Write-Status ("START {0}" -f $StepName)

    $job = Start-Job -ScriptBlock {
        param($InnerFilePath, $InnerArgumentList, $InnerStdoutPath, $InnerStderrPath)
        $env:TEMP = $env:TMP
        & $InnerFilePath @InnerArgumentList 1> $InnerStdoutPath 2> $InnerStderrPath
        return $LASTEXITCODE
    } -ArgumentList $FilePath, $ArgumentList, $stdoutPath, $stderrPath
    Set-ActivePointer -Phase $StepName -ProcessIds $job.Id -StdoutPath $stdoutPath -StderrPath $stderrPath

    $deadline = (Get-Date).AddHours($TimeoutHours)
    $nextPing = (Get-Date).AddMinutes(15)
    while ($true) {
        $jobState = $job.State
        if ($jobState -eq "Completed" -or $jobState -eq "Failed" -or $jobState -eq "Stopped") {
            break
        }

        if ((Get-Date) -gt $deadline) {
            Stop-Job -Job $job | Out-Null
            Wait-Job -Job $job -Timeout 30 | Out-Null
            Remove-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
            Write-Status ("TIMEOUT {0}" -f $StepName)
            throw "Timeout waiting for $StepName"
        }

        if ((Get-Date) -ge $nextPing) {
            Write-Status ("WAIT {0} state={1}" -f $StepName, $jobState)
            Set-ActivePointer -Phase $StepName -ProcessIds $job.Id -StdoutPath $stdoutPath -StderrPath $stderrPath
            $nextPing = (Get-Date).AddMinutes(15)
        }

        Start-Sleep -Seconds 60
    }

    $exitCode = Receive-Job -Job $job -Keep | Select-Object -Last 1
    Remove-Job -Job $job -ErrorAction SilentlyContinue | Out-Null

    if ($null -eq $exitCode) {
        $exitCode = 1
    }
    if ([int]$exitCode -ne 0) {
        Write-Status ("FAIL {0} exit={1}" -f $StepName, $exitCode)
        throw "Step failed: $StepName"
    }

    Write-Status ("DONE {0}" -f $StepName)
}

function Invoke-MatlabBatchStep {
    param(
        [Parameter(Mandatory = $true)][string]$StepName,
        [Parameter(Mandatory = $true)][string]$BatchCommand,
        [Parameter(Mandatory = $true)][double]$TimeoutHours
    )

    $codeMatlabPath = ($PSScriptRoot -replace "\\", "/")
    $batch = "cd('$codeMatlabPath'); $BatchCommand;"
    Invoke-LoggedProcess -StepName $StepName -FilePath "matlab" -ArgumentList @("-batch", $batch) -TimeoutHours $TimeoutHours
}

try {
    Set-Content -Path $statusPath -Value ""
    Set-Content -Path $summaryPath -Value ""
    Set-ActivePointer -Phase "starting"
    Write-Status "RUN_DIR $runDir"
    Write-Status ("SELECTED_STEPS {0}-{1}" -f $StartAtStep, $EndAtStep)

    @(
        "Objective: run the benchmark-only transition validation in fresh MATLAB sessions, one case per step.",
        "Run label: $RunLabel",
        "Temp root: $workflowTempRoot",
        "Scope lock:",
        " - stay inside the five-year structural Bellman transition validation",
        " - do not start the outer RE loop",
        " - do not reopen annual Python bridge work",
        "Selected steps: $StartAtStep-$EndAtStep",
        "Planned steps:",
        " 1. paths case 3 smooth_front_loaded",
        " 2. paths case 4 smooth_even_ramp",
        " 3. paths case 5 smooth_back_loaded",
        " 4. sensitivity case 1 base_step_2p10",
        " 5. sensitivity case 2 higher_transaction_cost",
        " 6. sensitivity case 3 higher_owner_spread",
        " 7. sensitivity case 4 positive_amortization",
        "Outputs refreshed incrementally:",
        " - notes/build/structural_transition_benchmark_validation_paths.csv",
        " - notes/build/structural_transition_benchmark_validation_sensitivities.csv",
        " - notes/build/structural_transition_benchmark_validation.md",
        "Stopping rule: stop after the selected chunk of cases finishes once, or after the first logged blocker or timeout."
    ) | Set-Content -Path $manifestPath

    $steps = @(
        @{ Index = 1; Name = "01_paths_case3"; Command = "run_transition_benchmark_validation_packet_fertility_main('paths', 3)"; TimeoutHours = $StepTimeoutHours },
        @{ Index = 2; Name = "02_paths_case4"; Command = "run_transition_benchmark_validation_packet_fertility_main('paths', 4)"; TimeoutHours = $StepTimeoutHours },
        @{ Index = 3; Name = "03_paths_case5"; Command = "run_transition_benchmark_validation_packet_fertility_main('paths', 5)"; TimeoutHours = $StepTimeoutHours },
        @{ Index = 4; Name = "04_sensitivity_case1"; Command = "run_transition_benchmark_validation_packet_fertility_main('sensitivity', 1)"; TimeoutHours = $StepTimeoutHours },
        @{ Index = 5; Name = "05_sensitivity_case2"; Command = "run_transition_benchmark_validation_packet_fertility_main('sensitivity', 2)"; TimeoutHours = $StepTimeoutHours },
        @{ Index = 6; Name = "06_sensitivity_case3"; Command = "run_transition_benchmark_validation_packet_fertility_main('sensitivity', 3)"; TimeoutHours = $StepTimeoutHours },
        @{ Index = 7; Name = "07_sensitivity_case4"; Command = "run_transition_benchmark_validation_packet_fertility_main('sensitivity', 4)"; TimeoutHours = $StepTimeoutHours }
    )

    foreach ($step in $steps) {
        if ($step.Index -lt $StartAtStep -or $step.Index -gt $EndAtStep) {
            Write-Status ("SKIP {0}" -f $step.Name)
            continue
        }

        Invoke-MatlabBatchStep -StepName $step.Name -BatchCommand $step.Command -TimeoutHours $step.TimeoutHours
    }

    @(
        "Transition benchmark validation workflow completed successfully.",
        "Run directory: $runDir",
        "Latest pointer: $latestPointer",
        "Outputs refreshed incrementally: benchmark path and sensitivity validation files."
    ) | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("ERROR {0}" -f $message)
    @(
        "Transition benchmark validation workflow stopped with an error.",
        "Run directory: $runDir",
        "Error: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "error"
    throw
}
