param(
    [ValidateRange(1, 3)]
    [int]$StartAtStep = 1,
    [ValidateRange(1, 3)]
    [int]$EndAtStep = 3,
    [string]$RunLabel = "annual_owner_finance_overnight",
    [double]$Step1TimeoutHours = 5,
    [double]$Step2TimeoutHours = 5,
    [double]$Step3TimeoutHours = 8
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

try {
    Set-Content -Path $statusPath -Value ""
    Set-Content -Path $summaryPath -Value ""
    Set-ActivePointer -Phase "starting"
    Write-Status "RUN_DIR $runDir"
    Write-Status ("SELECTED_STEPS {0}-{1}" -f $StartAtStep, $EndAtStep)

    @(
        "Objective: run one bounded overnight annual owner-finance confirm chain.",
        "Run label: $RunLabel",
        "Scope lock:",
        " - stay on annual fertility owner-finance diagnostics only",
        " - do not touch the 5-year benchmark workflow",
        " - do not touch Hamilton jobs or external sync",
        " - do not broaden into new structural mortgage-state branches",
        "Selected steps: $StartAtStep-$EndAtStep",
        "Planned steps:",
        " 1. run_fertility_annual_finance_micro_screen('confirm')",
        " 2. run_fertility_annual_joint_reanchor_screen('confirm')",
        " 3. run_fertility_annual_soft_owner_entry_menu_screen('confirm')",
        "Expected outputs:",
        " - notes/build/fertility_annual_finance_micro_screen.md",
        " - notes/build/fertility_annual_finance_micro_screen_candidates.csv",
        " - notes/build/fertility_annual_joint_reanchor_screen.md",
        " - notes/build/fertility_annual_joint_reanchor_screen_candidates.csv",
        " - notes/build/fertility_annual_soft_owner_entry_menu_screen.md",
        " - notes/build/fertility_annual_soft_owner_entry_menu_screen_candidates.csv",
        "Stopping rule: stop after the confirm chain finishes once, or after the first logged blocker/timeout."
    ) | Set-Content -Path $manifestPath

    $steps = @(
        @{ Index = 1; Name = "01_finance_micro_confirm"; Command = "run_fertility_annual_finance_micro_screen('confirm')"; TimeoutHours = $Step1TimeoutHours },
        @{ Index = 2; Name = "02_joint_reanchor_confirm"; Command = "run_fertility_annual_joint_reanchor_screen('confirm')"; TimeoutHours = $Step2TimeoutHours },
        @{ Index = 3; Name = "03_soft_owner_entry_confirm"; Command = "run_fertility_annual_soft_owner_entry_menu_screen('confirm')"; TimeoutHours = $Step3TimeoutHours }
    )

    foreach ($step in $steps) {
        if ($step.Index -lt $StartAtStep -or $step.Index -gt $EndAtStep) {
            Write-Status ("SKIP {0}" -f $step.Name)
            continue
        }

        Invoke-MatlabBatchStep -StepName $step.Name -BatchCommand $step.Command -TimeoutHours $step.TimeoutHours
    }

    @(
        "Annual owner-finance overnight workflow completed successfully.",
        "Run directory: $runDir",
        "Latest pointer: $latestPointer",
        "Outputs refreshed: finance micro, joint re-anchor, and soft owner-entry confirm notes/csvs."
    ) | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("ERROR {0}" -f $message)
    @(
        "Annual owner-finance overnight workflow stopped with an error.",
        "Run directory: $runDir",
        "Error: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "error"
    throw
}
