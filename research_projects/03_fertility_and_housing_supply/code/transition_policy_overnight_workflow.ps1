param(
    [ValidateRange(1, 3)]
    [int]$StartAtStep = 1,
    [ValidateRange(1, 3)]
    [int]$EndAtStep = 3,
    [string]$RunLabel = "transition_policy_overnight",
    [double]$Step1TimeoutHours = 2,
    [double]$Step2TimeoutHours = 1,
    [double]$Step3TimeoutHours = 6
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
$workflowTempRoot = Join-Path $tempDrive.Root "codex_temp\\03_fertility_and_housing_supply\\transition_policy_overnight"
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

function Invoke-LoggedProcess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,
        [Parameter(Mandatory = $true)]
        [double]$TimeoutHours
    )

    $stdoutPath = Join-Path $runDir ("{0}_stdout.log" -f $StepName)
    $stderrPath = Join-Path $runDir ("{0}_stderr.log" -f $StepName)

    Write-Status ("START {0}" -f $StepName)

    $job = Start-Job -ScriptBlock {
        param($InnerFilePath, $InnerArgumentList, $InnerStdoutPath, $InnerStderrPath)
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
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [string]$BatchCommand,
        [Parameter(Mandatory = $true)]
        [double]$TimeoutHours
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
        "Objective: run one bounded overnight transition-policy diagnostic chain for the structural Bellman transition path.",
        "Run label: $RunLabel",
        "Temp root: $workflowTempRoot",
        "Scope lock:",
        " - stay inside the project-03 structural Bellman transition diagnostics",
        " - do not start the outer RE loop",
        " - do not reopen annual Python bridge work",
        " - do not touch Hamilton or external sync",
        "Selected steps: $StartAtStep-$EndAtStep",
        "Planned steps:",
        " 1. run_transition_anticipation_menu_fertility_main('medium')",
        " 2. run_transition_value_wedge_audit_fertility_main",
        " 3. run_transition_anticipation_menu_fertility_main('benchmark')",
        "Expected outputs:",
        " - notes/build/structural_transition_anticipation_menu_medium_summary.csv",
        " - notes/build/structural_transition_anticipation_menu_medium_z_summary.csv",
        " - notes/build/structural_transition_anticipation_menu_medium.md",
        " - notes/build/structural_transition_value_wedge_audit.csv",
        " - notes/build/structural_transition_value_wedge_audit.md",
        " - notes/build/structural_transition_anticipation_menu_benchmark_summary.csv",
        " - notes/build/structural_transition_anticipation_menu_benchmark_z_summary.csv",
        " - notes/build/structural_transition_anticipation_menu_benchmark.md",
        "Stopping rule: stop after this three-step diagnostic chain finishes once, or after the first logged blocker or timeout."
    ) | Set-Content -Path $manifestPath

    $steps = @(
        @{ Index = 1; Name = "01_anticipation_menu_medium"; Command = "run_transition_anticipation_menu_fertility_main('medium')"; TimeoutHours = $Step1TimeoutHours },
        @{ Index = 2; Name = "02_value_wedge_audit"; Command = "run_transition_value_wedge_audit_fertility_main"; TimeoutHours = $Step2TimeoutHours },
        @{ Index = 3; Name = "03_anticipation_menu_benchmark"; Command = "run_transition_anticipation_menu_fertility_main('benchmark')"; TimeoutHours = $Step3TimeoutHours }
    )

    foreach ($step in $steps) {
        if ($step.Index -lt $StartAtStep -or $step.Index -gt $EndAtStep) {
            Write-Status ("SKIP {0}" -f $step.Name)
            continue
        }

        Invoke-MatlabBatchStep -StepName $step.Name -BatchCommand $step.Command -TimeoutHours $step.TimeoutHours
    }

    @(
        "Transition-policy overnight workflow completed successfully.",
        "Run directory: $runDir",
        "Latest pointer: $latestPointer",
        "Outputs refreshed: medium anticipation menu, value-wedge audit, and benchmark anticipation menu."
    ) | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("ERROR {0}" -f $message)
    @(
        "Transition-policy overnight workflow stopped with an error.",
        "Run directory: $runDir",
        "Error: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "error"
    throw
}
