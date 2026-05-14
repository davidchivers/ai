param(
    [ValidateRange(1, 4)]
    [int]$StartAtStep = 1,
    [ValidateRange(1, 4)]
    [int]$EndAtStep = 4,
    [double]$Step1TimeoutHours = 4,
    [double]$Step2TimeoutHours = 2,
    [double]$Step3TimeoutHours = 8,
    [double]$Step4TimeoutHours = 18
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
$runDir = Join-Path $logsRoot "annual_nimby_away_$runStamp"
New-Item -ItemType Directory -Path $runDir | Out-Null

$activePointer = Join-Path $logsRoot "active_annual_nimby_away.txt"
$latestPointer = Join-Path $logsRoot "latest_annual_nimby_away.txt"
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
        "Objective: continue the annual NIMBY workflow unattended for up to 24 hours.",
        "Scope lock:",
        " - stay on annual NIMBY steady-state work only",
        " - do not touch annual fertility",
        " - do not touch RE / transition work",
        "Selected steps: $StartAtStep-$EndAtStep",
        "Planned steps:",
        " 1. run_nimby_annual_recalibration_stage2('full')",
        " 2. compare_nimby_local_age_block_periodization_main('benchmark')",
        " 3. run_nimby_annual_housing_access_screen('fast')",
        " 4. run_nimby_annual_housing_access_screen('full')",
        "Expected outputs:",
        " - notes/build/nimby_annual_recalibration_stage2_candidates.csv",
        " - notes/build/nimby_local_age_block_periodization.csv",
        " - notes/build/nimby_annual_housing_access_screen_candidates.csv",
        " - notes/build/nimby_annual_housing_access_screen_candidate_blocks.csv",
        " - notes/build/nimby_annual_housing_access_screen.md",
        "Stopping rule: stop after the screen bundle finishes once, or after a logged blocker/timeout."
    ) | Set-Content -Path $manifestPath

    $steps = @(
        @{ Index = 1; Name = "01_stage2_full"; Command = "run_nimby_annual_recalibration_stage2('full')"; TimeoutHours = $Step1TimeoutHours },
        @{ Index = 2; Name = "02_age_block_benchmark"; Command = "compare_nimby_local_age_block_periodization_main('benchmark')"; TimeoutHours = $Step2TimeoutHours },
        @{ Index = 3; Name = "03_housing_access_fast"; Command = "run_nimby_annual_housing_access_screen('fast')"; TimeoutHours = $Step3TimeoutHours },
        @{ Index = 4; Name = "04_housing_access_full"; Command = "run_nimby_annual_housing_access_screen('full')"; TimeoutHours = $Step4TimeoutHours }
    )

    foreach ($step in $steps) {
        if ($step.Index -lt $StartAtStep -or $step.Index -gt $EndAtStep) {
            Write-Status ("SKIP {0}" -f $step.Name)
            continue
        }

        Invoke-MatlabBatchStep -StepName $step.Name -BatchCommand $step.Command -TimeoutHours $step.TimeoutHours
    }

    @(
        "Annual NIMBY away workflow completed successfully.",
        "Run directory: $runDir",
        "Latest pointer: $latestPointer",
        "Primary report: $(Join-Path $projectRoot 'notes/build/nimby_annual_housing_access_screen.md')"
    ) | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("ERROR {0}" -f $message)
    @(
        "Annual NIMBY away workflow stopped with an error.",
        "Run directory: $runDir",
        "Error: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "error"
    throw
}
