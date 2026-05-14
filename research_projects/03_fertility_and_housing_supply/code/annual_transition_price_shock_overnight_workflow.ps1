param(
    [string]$RunLabel = "annual_transition_price_shock_overnight",
    [double]$TimeoutHours = 2
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

try {
    Set-Content -Path $statusPath -Value ""
    Set-Content -Path $summaryPath -Value ""
    Set-ActivePointer -Phase "starting"

    @(
        "Objective: run one bounded annual transition price-shock packet.",
        "Run label: $RunLabel",
        "Scope lock:",
        " - annual transition-path branch only",
        " - one exogenous price path only",
        " - no endogenous voting feedback",
        " - no steady-state reruns",
        " - no Hamilton work",
        "Expected outputs:",
        " - notes/build/annual_transition_path_price_shock.md",
        " - notes/build/annual_transition_path_price_shock.csv",
        " - notes/build/annual_transition_path_price_shock_summary.csv",
        " - notes/build/annual_transition_path_price_shock_initial_mass.csv",
        "Stopping rule: stop after one clean bounded price-shock run, or after the first timeout/error."
    ) | Set-Content -Path $manifestPath

    $stdoutPath = Join-Path $runDir "01_price_shock_stdout.log"
    $stderrPath = Join-Path $runDir "01_price_shock_stderr.log"
    Write-Status "RUN_DIR $runDir"
    Write-Status "START 01_price_shock"

    $scriptPath = Join-Path $PSScriptRoot "build_annual_transition_path_price_shock.py"
    $job = Start-Job -ScriptBlock {
        param($InnerScriptPath, $InnerStdoutPath, $InnerStderrPath)
        & python $InnerScriptPath 1> $InnerStdoutPath 2> $InnerStderrPath
        return $LASTEXITCODE
    } -ArgumentList $scriptPath, $stdoutPath, $stderrPath

    Set-ActivePointer -Phase "01_price_shock" -ProcessIds $job.Id -StdoutPath $stdoutPath -StderrPath $stderrPath

    $deadline = (Get-Date).AddHours($TimeoutHours)
    while ($true) {
        $jobState = $job.State
        if ($jobState -eq "Completed" -or $jobState -eq "Failed" -or $jobState -eq "Stopped") {
            break
        }
        if ((Get-Date) -gt $deadline) {
            Stop-Job -Job $job | Out-Null
            Wait-Job -Job $job -Timeout 30 | Out-Null
            Remove-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
            Write-Status "TIMEOUT 01_price_shock"
            throw "Timeout waiting for 01_price_shock"
        }
        Start-Sleep -Seconds 30
    }

    $exitCode = Receive-Job -Job $job -Keep | Select-Object -Last 1
    Remove-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
    if ($null -eq $exitCode) {
        $exitCode = 1
    }
    if ([int]$exitCode -ne 0) {
        Write-Status ("FAIL 01_price_shock exit={0}" -f $exitCode)
        throw "Step failed: 01_price_shock"
    }

    Write-Status "DONE 01_price_shock"
    @(
        "Annual transition price-shock overnight workflow completed successfully.",
        "Run directory: $runDir",
        "Latest pointer: $latestPointer",
        "Outputs refreshed: annual transition bounded price-shock files."
    ) | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("ERROR {0}" -f $message)
    @(
        "Annual transition price-shock overnight workflow stopped with an error.",
        "Run directory: $runDir",
        "Error: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "error"
    throw
}
