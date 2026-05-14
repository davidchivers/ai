param(
    [double]$TimeoutHours = 4
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$logsRoot = Join-Path $projectRoot "notes/build/logs"
if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $logsRoot "annual_owner_mortgage_state_confirm_$runStamp"
New-Item -ItemType Directory -Path $runDir | Out-Null

$activePointer = Join-Path $logsRoot "active_annual_owner_mortgage_state_confirm.txt"
$latestPointer = Join-Path $logsRoot "latest_annual_owner_mortgage_state_confirm.txt"
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
    $nextPing = (Get-Date).AddMinutes(10)
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
            $nextPing = (Get-Date).AddMinutes(10)
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

    @(
        "Objective: finish the recentered annual owner-mortgage-state confirm screen.",
        "Scope lock:",
        " - rerun run_fertility_annual_owner_mortgage_state_screen('confirm')",
        " - do not broaden into the transition-path branch inside this workflow",
        "Expected outputs:",
        " - notes/build/fertility_annual_owner_mortgage_state_screen.md",
        " - notes/build/fertility_annual_owner_mortgage_state_screen_candidates.csv",
        "Stopping rule: stop after the confirm run finishes once, or at the first logged timeout/error."
    ) | Set-Content -Path $manifestPath

    Invoke-MatlabBatchStep -StepName "01_owner_mortgage_state_confirm" -BatchCommand "run_fertility_annual_owner_mortgage_state_screen('confirm')" -TimeoutHours $TimeoutHours

    @(
        "Annual owner-mortgage-state confirm workflow completed successfully.",
        "Run directory: $runDir",
        "Latest pointer: $latestPointer",
        "Outputs refreshed: owner-mortgage-state note and candidate csv."
    ) | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("ERROR {0}" -f $message)
    @(
        "Annual owner-mortgage-state confirm workflow stopped with an error.",
        "Run directory: $runDir",
        "Error: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "error"
    throw
}
