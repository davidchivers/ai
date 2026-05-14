param(
    [string]$RunLabel = "annual_full_re_12_hour_workflow",
    [double]$TimeoutHours = 12
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

function Invoke-ExternalStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,
        [Parameter(Mandatory = $true)]
        [datetime]$Deadline
    )

    $stdoutPath = Join-Path $runDir ("{0}_stdout.log" -f $StepName)
    $stderrPath = Join-Path $runDir ("{0}_stderr.log" -f $StepName)

    Write-Status ("START {0}" -f $StepName)
    $job = Start-Job -ScriptBlock {
        param($InnerFilePath, $ArgList, $InnerWorkingDirectory, $InnerStdoutPath, $InnerStderrPath)
        Push-Location $InnerWorkingDirectory
        try {
            & $InnerFilePath @ArgList 1> $InnerStdoutPath 2> $InnerStderrPath
            return $LASTEXITCODE
        }
        finally {
            Pop-Location
        }
    } -ArgumentList $FilePath, ([object[]]$Arguments), $WorkingDirectory, $stdoutPath, $stderrPath

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
        "Objective: rerun the calibrated annual construction-flow RE hierarchy and build one clean packet note.",
        "Run label: $RunLabel",
        "Scope lock:",
        " - calibrated construction-flow annual block only",
        " - rerun anchor + k=3 + k=5 + k=20",
        " - build one consolidated packet note/table",
        " - no new RE law, no horizon widening, no draft edits",
        "Expected outputs:",
        " - notes/build/annual_snapshot_state_transition_permits_starts_stock_calibrated.md",
        " - notes/build/annual_3_step_re_permits_starts_stock_calibrated.md",
        " - notes/build/annual_5_step_re_permits_starts_stock_calibrated.md",
        " - notes/build/annual_20_step_re_permits_starts_stock_calibrated.md",
        " - notes/build/annual_permits_starts_stock_re_packet.md",
        " - notes/build/annual_permits_starts_stock_re_packet.png",
        " - drafts/fertility_and_housing_supply_annualised.pdf",
        "Stopping rule: stop after the packet note exists, or at the first timeout/error."
    ) | Set-Content -Path $manifestPath

    Write-Status ("RUN_DIR {0}" -f $runDir)
    $deadline = (Get-Date).AddHours($TimeoutHours)

    Invoke-PythonStep -StepName "01_calibrated_construction_block" `
        -Arguments @(
            (Join-Path $PSScriptRoot "build_annual_snapshot_state_transition_permits_starts_stock_calibrated.py")
        ) `
        -Deadline $deadline

    Invoke-PythonStep -StepName "02_re_k3" `
        -Arguments @(
            (Join-Path $PSScriptRoot "build_annual_k_step_re_permits_starts_stock_calibrated.py"),
            "--k",
            "3"
        ) `
        -Deadline $deadline

    Invoke-PythonStep -StepName "03_re_k5" `
        -Arguments @(
            (Join-Path $PSScriptRoot "build_annual_k_step_re_permits_starts_stock_calibrated.py"),
            "--k",
            "5"
        ) `
        -Deadline $deadline

    Invoke-PythonStep -StepName "04_re_k20" `
        -Arguments @(
            (Join-Path $PSScriptRoot "build_annual_k_step_re_permits_starts_stock_calibrated.py"),
            "--k",
            "20"
        ) `
        -Deadline $deadline

    Invoke-PythonStep -StepName "05_packet_note" `
        -Arguments @(
            (Join-Path $PSScriptRoot "build_annual_permits_starts_stock_re_packet.py")
        ) `
        -Deadline $deadline

    Invoke-PythonStep -StepName "06_packet_figure" `
        -Arguments @(
            (Join-Path $PSScriptRoot "plot_annual_permits_starts_stock_re_packet.py")
        ) `
        -Deadline $deadline

    Invoke-ExternalStep -StepName "07_compile_annualised_pdf" `
        -FilePath "latexmk" `
        -Arguments @(
            "-pdf",
            "-interaction=nonstopmode",
            "-halt-on-error",
            "fertility_and_housing_supply_annualised.tex"
        ) `
        -WorkingDirectory (Join-Path $projectRoot "drafts") `
        -Deadline $deadline

    @(
        "Annual full-RE 12-hour workflow completed successfully.",
        "Run directory: $runDir",
        "Latest pointer: $latestPointer",
        "Outputs refreshed: calibrated construction-flow anchor, k=3/5/20 RE notes, consolidated packet note, packet figure, annualised PDF."
    ) | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("ERROR {0}" -f $message)
    @(
        "Annual full-RE 12-hour workflow stopped with an error.",
        "Run directory: $runDir",
        "Error: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "error"
    throw
}
