param(
    [string]$RunLabel = "annual_smoothed_political_path_trial_workflow",
    [double]$TimeoutHours = 2,
    [double]$SmoothRho = 0.65,
    [double]$BoomAmp = 0.10
)

$ErrorActionPreference = "Stop"

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

function Invoke-PythonStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [datetime]$Deadline
    )

    $stdoutPath = Join-Path $runDir ("{0}_stdout.log" -f $StepName)
    $stderrPath = Join-Path $runDir ("{0}_stderr.log" -f $StepName)

    Write-Status ("START {0}" -f $StepName)
    $job = Start-Job -ScriptBlock {
        param($ArgList, $InnerStdoutPath, $InnerStderrPath)
        & python @ArgList 1> $InnerStdoutPath 2> $InnerStderrPath
        return $LASTEXITCODE
    } -ArgumentList ([object[]]$Arguments), $stdoutPath, $stderrPath

    Set-ActivePointer -Phase $StepName -ProcessIds $job.Id -StdoutPath $stdoutPath -StderrPath $stderrPath

    while ($true) {
        $jobState = $job.State
        if ($jobState -eq "Completed" -or $jobState -eq "Failed" -or $jobState -eq "Stopped") {
            break
        }
        if ((Get-Date) -gt $Deadline) {
            Stop-Job -Job $job | Out-Null
            Wait-Job -Job $job -Timeout 30 | Out-Null
            Remove-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
            Write-Status ("TIMEOUT {0}" -f $StepName)
            throw "Timeout waiting for $StepName"
        }
        Start-Sleep -Seconds 30
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

try {
    Set-Content -Path $statusPath -Value ""
    Set-Content -Path $summaryPath -Value ""
    Set-ActivePointer -Phase "starting"

    @(
        "Objective: run one dormant bridge-level smoothed-political-path trial for the fertility project.",
        "Run label: $RunLabel",
        "Scope lock:",
        " - bridge diagnostic only",
        " - do not touch the compiled Bellman RE ladder",
        " - do not touch Hamilton",
        " - do not rerun the annual full-RE hierarchy",
        " - only write the trial note/csv/paths/figure bundle",
        "Expected outputs:",
        " - notes/build/nimby_vs_fertility_smoothed_political_path_trial.md",
        " - notes/build/nimby_vs_fertility_smoothed_political_path_trial.csv",
        " - notes/build/nimby_vs_fertility_smoothed_political_path_trial_paths.csv",
        " - notes/build/nimby_vs_fertility_smoothed_political_path_trial.png",
        " - notes/build/nimby_vs_fertility_smoothed_political_path_trial.pdf",
        "Stopping rule: stop after the trial bundle exists, or at the first timeout/error."
    ) | Set-Content -Path $manifestPath

    Write-Status ("RUN_DIR {0}" -f $runDir)
    $deadline = (Get-Date).AddHours($TimeoutHours)

    Invoke-PythonStep -StepName "01_smoothed_political_path_trial" `
        -Arguments @(
            (Join-Path $PSScriptRoot "build_nimby_vs_fertility_smoothed_political_path_trial.py"),
            "--smooth-rho",
            $SmoothRho.ToString([System.Globalization.CultureInfo]::InvariantCulture),
            "--boom-amp",
            $BoomAmp.ToString([System.Globalization.CultureInfo]::InvariantCulture)
        ) `
        -Deadline $deadline

    @(
        "Annual smoothed-political-path trial workflow completed successfully.",
        "Run directory: $runDir",
        "Latest pointer: $latestPointer",
        "Outputs refreshed: dormant bridge-level smoothed-political-path trial bundle."
    ) | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("ERROR {0}" -f $message)
    @(
        "Annual smoothed-political-path trial workflow stopped with an error.",
        "Run directory: $runDir",
        "Error: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "error"
    throw
}
