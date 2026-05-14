$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$codeDir = $PSScriptRoot
$draftsDir = Join-Path $projectRoot "drafts"
$logsRoot = Join-Path $projectRoot "notes/build/logs"

if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $logsRoot "referee_revision_away_$runStamp"
New-Item -ItemType Directory -Path $runDir | Out-Null

$activePointer = Join-Path $logsRoot "active_referee_revision_away.txt"
$latestPointer = Join-Path $logsRoot "latest_referee_revision_away.txt"
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

function Convert-ToMatlabPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue
    )

    return ($PathValue -replace "\\", "/")
}

function Get-MatlabExecutable {
    $cmd = Get-Command matlab -ErrorAction SilentlyContinue
    if ($null -ne $cmd) {
        return $cmd.Source
    }

    return "C:\Program Files\MATLAB\R2025b\bin\matlab.exe"
}

function Get-ProjectMatlabProcesses {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Marker
    )

    return Get-CimInstance Win32_Process | Where-Object {
        ($_.Name -ieq "matlab.exe" -or $_.Name -ieq "MATLAB.exe") -and
        $_.CommandLine -and
        $_.CommandLine.Contains($Marker)
    } | Sort-Object CreationDate
}

function Get-LatestLogPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )

    $item = Get-ChildItem $logsRoot -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like $Pattern } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -eq $item) {
        return ""
    }

    return $item.FullName
}

function Start-MatlabBatchProcess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [string]$BatchCommand
    )

    $stdoutPath = Join-Path $runDir ("{0}_stdout.log" -f $StepName)
    $stderrPath = Join-Path $runDir ("{0}_stderr.log" -f $StepName)
    $runnerPath = Join-Path $runDir ("{0}_runner.ps1" -f $StepName)
    $matlabExe = (Get-MatlabExecutable).Replace("'", "''")
    $stdoutLiteral = $stdoutPath.Replace("'", "''")
    $stderrLiteral = $stderrPath.Replace("'", "''")
    @(
        '$ErrorActionPreference = ''Stop'''
        '$batchCommand = @'''
        $BatchCommand
        '''@'
        "& '$matlabExe' -batch `$batchCommand 1> '$stdoutLiteral' 2> '$stderrLiteral'"
        'exit $LASTEXITCODE'
    ) | Set-Content -Path $runnerPath

    $proc = Start-Process -FilePath "powershell.exe" `
        -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $runnerPath) `
        -PassThru `
        -WindowStyle Hidden

    Set-ActivePointer -Phase $StepName -ProcessIds $proc.Id -StdoutPath $stdoutPath -StderrPath $stderrPath
    Write-Status ("START {0} pid={1}" -f $StepName, $proc.Id)

    return @{
        Pid = $proc.Id
        StdoutPath = $stdoutPath
        StderrPath = $stderrPath
        StartedAt = Get-Date
    }
}

function Wait-ForMatlabMarker {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [string]$Marker,
        [Parameter(Mandatory = $true)]
        [double]$TimeoutHours,
        [Parameter(Mandatory = $true)]
        [datetime]$StartedAt,
        [string]$StdoutPath = "",
        [string]$StderrPath = ""
    )

    $deadline = $StartedAt.AddHours($TimeoutHours)
    $nextPing = (Get-Date).AddMinutes(15)

    while ($true) {
        $procs = Get-ProjectMatlabProcesses -Marker $Marker
        if ($null -eq $procs -or $procs.Count -eq 0) {
            Write-Status ("DONE {0}" -f $StepName)
            return
        }

        if ((Get-Date) -gt $deadline) {
            $ids = $procs | Select-Object -ExpandProperty ProcessId
            Stop-Process -Id $ids -Force -ErrorAction SilentlyContinue
            Write-Status ("TIMEOUT {0} killed_pids={1}" -f $StepName, (($ids | Sort-Object) -join ","))
            throw "Timeout waiting for $StepName"
        }

        if ((Get-Date) -ge $nextPing) {
            $ids = $procs | Select-Object -ExpandProperty ProcessId
            Write-Status ("WAIT {0} active_pids={1}" -f $StepName, (($ids | Sort-Object) -join ","))
            Set-ActivePointer -Phase $StepName -ProcessIds (($ids | Sort-Object) -join ",") -StdoutPath $StdoutPath -StderrPath $StderrPath
            $nextPing = (Get-Date).AddMinutes(15)
        }

        Start-Sleep -Seconds 60
    }
}

function Wait-ForProcessIds {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [int[]]$ProcessIds,
        [Parameter(Mandatory = $true)]
        [double]$TimeoutHours,
        [Parameter(Mandatory = $true)]
        [datetime]$StartedAt,
        [string]$StdoutPath = "",
        [string]$StderrPath = ""
    )

    $deadline = $StartedAt.AddHours($TimeoutHours)
    $nextPing = (Get-Date).AddMinutes(15)
    $ids = $ProcessIds | Sort-Object -Unique

    while ($true) {
        $running = @()
        foreach ($id in $ids) {
            $proc = Get-Process -Id $id -ErrorAction SilentlyContinue
            if ($null -ne $proc) {
                $running += $id
            }
        }

        if ($running.Count -eq 0) {
            Write-Status ("DONE {0}" -f $StepName)
            return
        }

        if ((Get-Date) -gt $deadline) {
            Stop-Process -Id $running -Force -ErrorAction SilentlyContinue
            Write-Status ("TIMEOUT {0} killed_pids={1}" -f $StepName, (($running | Sort-Object) -join ","))
            throw "Timeout waiting for $StepName"
        }

        if ((Get-Date) -ge $nextPing) {
            Write-Status ("WAIT {0} active_pids={1}" -f $StepName, (($running | Sort-Object) -join ","))
            Set-ActivePointer -Phase $StepName -ProcessIds (($running | Sort-Object) -join ",") -StdoutPath $StdoutPath -StderrPath $StderrPath
            $nextPing = (Get-Date).AddMinutes(15)
        }

        Start-Sleep -Seconds 60
    }
}

function Assert-FileFresh {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue,
        [Parameter(Mandatory = $true)]
        [datetime]$NotBefore,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (-not (Test-Path $PathValue)) {
        throw "Missing expected output: $Label"
    }

    $item = Get-Item $PathValue
    if ($item.LastWriteTime -lt $NotBefore) {
        throw "Stale expected output: $Label"
    }
}

function Test-FileFresh {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue,
        [Parameter(Mandatory = $true)]
        [datetime]$NotBefore
    )

    if (-not (Test-Path $PathValue)) {
        return $false
    }

    return (Get-Item $PathValue).LastWriteTime -ge $NotBefore
}

function Invoke-LoggedProcess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,
        [string]$WorkingDirectory = ""
    )

    $stdoutPath = Join-Path $runDir ("{0}_stdout.log" -f $StepName)
    $stderrPath = Join-Path $runDir ("{0}_stderr.log" -f $StepName)

    Write-Status ("START {0}" -f $StepName)
    Set-ActivePointer -Phase $StepName -StdoutPath $stdoutPath -StderrPath $stderrPath

    if ($WorkingDirectory) {
        Push-Location $WorkingDirectory
    }

    try {
        & $FilePath @ArgumentList 1> $stdoutPath 2> $stderrPath
        if ($LASTEXITCODE -ne 0) {
            Write-Status ("FAIL {0} exit={1}" -f $StepName, $LASTEXITCODE)
            throw "Step failed: $StepName"
        }
    }
    finally {
        if ($WorkingDirectory) {
            Pop-Location
        }
    }

    Write-Status ("DONE {0}" -f $StepName)
}

try {
    Set-Content -Path $statusPath -Value ""
    Set-Content -Path $summaryPath -Value ""
    Set-ActivePointer -Phase "starting"
    Write-Status "RUN_DIR $runDir"

    @(
        "Objective: finish the referee-sweep chain for project 03 in a bounded unattended workflow.",
        "Deliverables:",
        " - notes/build/childlessness_recalibration.csv",
        " - notes/build/sensitivity_mechanism_parameters.csv",
        " - drafts/fertility_and_housing_supply.tex (Appendix C updated)",
        " - drafts/sections/model.tex (childlessness discussion updated)",
        " - drafts/fertility_and_housing_supply.pdf",
        "Stopping rule: stop after one clean milestone or after a logged blocker."
    ) | Set-Content -Path $manifestPath

    $codeMatlabPath = Convert-ToMatlabPath -PathValue $codeDir
    $nimbyPath = "C:/Users/Dave_/AI/research_projects/02_nimbyism_and_housing_supply/code/steadystate"

    $childMarker = "run_childlessness_recalibration"
    $childStdout = Get-LatestLogPath -Pattern "childlessness_recalibration_full_*.blocking.log"
    $childStderr = ""
    $childStart = Get-Date
    $existingChild = Get-ProjectMatlabProcesses -Marker $childMarker
    if ($existingChild -and $existingChild.Count -gt 0) {
        $childStart = Get-Date
        Write-Status ("ADOPT 01_childlessness_full active_pids={0}" -f (($existingChild | Select-Object -ExpandProperty ProcessId | Sort-Object) -join ","))
        Set-ActivePointer -Phase "01_childlessness_full" -ProcessIds (($existingChild | Select-Object -ExpandProperty ProcessId | Sort-Object) -join ",") -StdoutPath $childStdout -StderrPath $childStderr
        Wait-ForMatlabMarker -StepName "01_childlessness_full" -Marker $childMarker -TimeoutHours 8 -StartedAt $childStart -StdoutPath $childStdout -StderrPath $childStderr
    }
    else {
        $childBatch = "addpath('$nimbyPath'); cd('$codeMatlabPath'); run_childlessness_recalibration"
        $childProcess = Start-MatlabBatchProcess -StepName "01_childlessness_full" -BatchCommand $childBatch
        $childStdout = $childProcess.StdoutPath
        $childStderr = $childProcess.StderrPath
        $childStart = $childProcess.StartedAt
        Wait-ForProcessIds -StepName "01_childlessness_full" -ProcessIds @([int]$childProcess.Pid) -TimeoutHours 8 -StartedAt $childStart -StdoutPath $childStdout -StderrPath $childStderr
    }

    $childCsv = Join-Path $projectRoot "notes/build/childlessness_recalibration.csv"
    $childMd = Join-Path $projectRoot "notes/build/childlessness_recalibration.md"
    $childFresh = (Test-FileFresh -PathValue $childCsv -NotBefore $childStart) -and (Test-FileFresh -PathValue $childMd -NotBefore $childStart)
    if (-not $childFresh) {
        Write-Status "RECOVERY 01_childlessness_full run ended without fresh outputs; starting clean rerun"
        $childStart = Get-Date
        $childBatch = "addpath('$nimbyPath'); cd('$codeMatlabPath'); run_childlessness_recalibration"
        $childProcess = Start-MatlabBatchProcess -StepName "01b_childlessness_rerun" -BatchCommand $childBatch
        $childStdout = $childProcess.StdoutPath
        $childStderr = $childProcess.StderrPath
        Wait-ForProcessIds -StepName "01b_childlessness_rerun" -ProcessIds @([int]$childProcess.Pid) -TimeoutHours 8 -StartedAt $childProcess.StartedAt -StdoutPath $childStdout -StderrPath $childStderr
        $childFresh = (Test-FileFresh -PathValue $childCsv -NotBefore $childStart) -and (Test-FileFresh -PathValue $childMd -NotBefore $childStart)
    }

    Assert-FileFresh -PathValue $childCsv -NotBefore $childStart -Label "childlessness_recalibration.csv"
    Assert-FileFresh -PathValue $childMd -NotBefore $childStart -Label "childlessness_recalibration.md"
    Write-Status "VALIDATED 01_childlessness_full"

    $sensStart = Get-Date
    $sensBatch = "addpath('$nimbyPath'); cd('$codeMatlabPath'); run_sensitivity_table"
    $sensProcess = Start-MatlabBatchProcess -StepName "02_sensitivity_full" -BatchCommand $sensBatch
    Wait-ForProcessIds -StepName "02_sensitivity_full" -ProcessIds @([int]$sensProcess.Pid) -TimeoutHours 12 -StartedAt $sensStart -StdoutPath $sensProcess.StdoutPath -StderrPath $sensProcess.StderrPath

    $sensCsv = Join-Path $projectRoot "notes/build/sensitivity_mechanism_parameters.csv"
    $sensMd = Join-Path $projectRoot "notes/build/sensitivity_mechanism_parameters.md"
    $sensFresh = (Test-FileFresh -PathValue $sensCsv -NotBefore $sensStart) -and (Test-FileFresh -PathValue $sensMd -NotBefore $sensStart)
    if (-not $sensFresh) {
        Write-Status "RECOVERY 02_sensitivity_full run ended without fresh outputs; starting clean rerun"
        $sensStart = Get-Date
        $sensProcess = Start-MatlabBatchProcess -StepName "02b_sensitivity_rerun" -BatchCommand $sensBatch
        Wait-ForProcessIds -StepName "02b_sensitivity_rerun" -ProcessIds @([int]$sensProcess.Pid) -TimeoutHours 12 -StartedAt $sensStart -StdoutPath $sensProcess.StdoutPath -StderrPath $sensProcess.StderrPath
        $sensFresh = (Test-FileFresh -PathValue $sensCsv -NotBefore $sensStart) -and (Test-FileFresh -PathValue $sensMd -NotBefore $sensStart)
    }

    Assert-FileFresh -PathValue $sensCsv -NotBefore $sensStart -Label "sensitivity_mechanism_parameters.csv"
    Assert-FileFresh -PathValue $sensMd -NotBefore $sensStart -Label "sensitivity_mechanism_parameters.md"
    Write-Status "VALIDATED 02_sensitivity_full"

    Invoke-LoggedProcess -StepName "03_apply_referee_results_patch" `
        -FilePath "python" `
        -ArgumentList @((Join-Path $codeDir "apply_referee_revision_results.py"), "--run-dir", $runDir)

    $pdflatex = Get-Command pdflatex -ErrorAction SilentlyContinue
    if ($null -eq $pdflatex) {
        throw "pdflatex not found"
    }

    Invoke-LoggedProcess -StepName "04_pdflatex_pass1" `
        -FilePath $pdflatex.Source `
        -ArgumentList @("-interaction=nonstopmode", "-halt-on-error", "fertility_and_housing_supply.tex") `
        -WorkingDirectory $draftsDir
    Invoke-LoggedProcess -StepName "05_pdflatex_pass2" `
        -FilePath $pdflatex.Source `
        -ArgumentList @("-interaction=nonstopmode", "-halt-on-error", "fertility_and_housing_supply.tex") `
        -WorkingDirectory $draftsDir

    Assert-FileFresh -PathValue (Join-Path $draftsDir "fertility_and_housing_supply.pdf") -NotBefore $sensStart -Label "fertility_and_housing_supply.pdf"

    Invoke-LoggedProcess -StepName "06_sync_trackers" `
        -FilePath "python" `
        -ArgumentList @((Join-Path $codeDir "apply_referee_revision_results.py"), "--run-dir", $runDir, "--sync-trackers")

    @(
        "Run completed successfully.",
        "Run directory: $runDir",
        "Latest pointer: $latestPointer",
        "Draft PDF: $(Join-Path $draftsDir 'fertility_and_housing_supply.pdf')"
    ) | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
    Set-ActivePointer -Phase "success"
}
catch {
    $message = $_.Exception.Message
    Write-Status ("ERROR {0}" -f $message)
    @(
        "Run stopped with an error.",
        "Run directory: $runDir",
        "Error: $message"
    ) | Set-Content -Path $summaryPath
    Set-ActivePointer -Phase "error"
    throw
}
