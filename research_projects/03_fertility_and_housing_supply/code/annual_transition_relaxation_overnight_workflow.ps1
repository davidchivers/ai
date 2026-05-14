param(
    [ValidateRange(1, 4)]
    [int]$StartAtStep = 1,
    [ValidateRange(1, 4)]
    [int]$EndAtStep = 4,
    [string]$RunLabel = "annual_transition_relaxation_overnight",
    [double]$Step1TimeoutHours = 1,
    [double]$Step2TimeoutHours = 1,
    [double]$Step3TimeoutHours = 2,
    [double]$Step4TimeoutHours = 2
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

function Invoke-PythonStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [Parameter(Mandatory = $true)]
        [double]$TimeoutHours
    )

    $scriptPath = Join-Path $PSScriptRoot $ScriptName
    Invoke-LoggedProcess -StepName $StepName -FilePath "python" -ArgumentList @($scriptPath) -TimeoutHours $TimeoutHours
}

try {
    Set-Content -Path $statusPath -Value ""
    Set-Content -Path $summaryPath -Value ""
    Set-ActivePointer -Phase "starting"
    Write-Status "RUN_DIR $runDir"
    Write-Status ("SELECTED_STEPS {0}-{1}" -f $StartAtStep, $EndAtStep)

    @(
        "Objective: run one bounded overnight annual transition relaxation packet.",
        "Run label: $RunLabel",
        "Scope lock:",
        " - stay inside the annual transition-path branch only",
        " - no steady-state finance reruns",
        " - no entrant-mixture reruns",
        " - no mortgage-state reruns",
        " - no 5-year benchmark work",
        " - no Hamilton work",
        "Selected steps: $StartAtStep-$EndAtStep",
        "Planned steps:",
        " 1. run_fertility_annual_transition_path_prep",
        " 2. run_fertility_annual_transition_path_bucket_mapping",
        " 3. run_fertility_annual_transition_path_state_grid_mapping",
        " 4. build_annual_transition_path_constant_price_relaxation.py",
        "Expected outputs:",
        " - notes/build/fertility_annual_transition_path_prep.md",
        " - notes/build/fertility_annual_transition_path_bucket_mapping.md",
        " - notes/build/fertility_annual_transition_path_state_grid_mapping.md",
        " - notes/build/annual_transition_path_constant_price_relaxation.md",
        " - notes/build/annual_transition_path_constant_price_relaxation.csv",
        " - notes/build/annual_transition_path_constant_price_relaxation_summary.csv",
        " - notes/build/annual_transition_path_constant_price_relaxation_initial_mass.csv",
        "Stopping rule: stop after one clean constant-price relaxation milestone, or after the first logged blocker/timeout."
    ) | Set-Content -Path $manifestPath

    $steps = @(
        @{ Index = 1; Name = "01_transition_prep"; Kind = "matlab"; Command = "run_fertility_annual_transition_path_prep"; TimeoutHours = $Step1TimeoutHours },
        @{ Index = 2; Name = "02_transition_bucket_mapping"; Kind = "matlab"; Command = "run_fertility_annual_transition_path_bucket_mapping"; TimeoutHours = $Step2TimeoutHours },
        @{ Index = 3; Name = "03_transition_state_grid_mapping"; Kind = "matlab"; Command = "run_fertility_annual_transition_path_state_grid_mapping"; TimeoutHours = $Step3TimeoutHours },
        @{ Index = 4; Name = "04_constant_price_relaxation"; Kind = "python"; Command = "build_annual_transition_path_constant_price_relaxation.py"; TimeoutHours = $Step4TimeoutHours }
    )

    foreach ($step in $steps) {
        if ($step.Index -lt $StartAtStep -or $step.Index -gt $EndAtStep) {
            Write-Status ("SKIP {0}" -f $step.Name)
            continue
        }

        if ($step.Kind -eq "matlab") {
            Invoke-MatlabBatchStep -StepName $step.Name -BatchCommand $step.Command -TimeoutHours $step.TimeoutHours
        }
        else {
            Invoke-PythonStep -StepName $step.Name -ScriptName $step.Command -TimeoutHours $step.TimeoutHours
        }
    }

    @(
        "Annual transition relaxation overnight workflow completed successfully.",
        "Run directory: $runDir",
        "Latest pointer: $latestPointer",
        "Outputs refreshed: transition prep, bucket mapping, state-grid mapping, and constant-price relaxation files."
    ) | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("ERROR {0}" -f $message)
    @(
        "Annual transition relaxation overnight workflow stopped with an error.",
        "Run directory: $runDir",
        "Error: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "error"
    throw
}
