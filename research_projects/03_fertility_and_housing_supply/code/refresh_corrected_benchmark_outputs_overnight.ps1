param(
    [switch]$SkipPdf
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $projectRoot "notes/build"
$logsRoot = Join-Path $buildDir "logs"

if (-not (Test-Path $logsRoot)) {
    New-Item -ItemType Directory -Path $logsRoot | Out-Null
}

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir = Join-Path $logsRoot "overnight_benchmark_refresh_$runStamp"
New-Item -ItemType Directory -Path $runDir | Out-Null

$latestPointer = Join-Path $logsRoot "latest_overnight_benchmark_refresh.txt"
$statusPath = Join-Path $runDir "status.txt"
$manifestPath = Join-Path $runDir "manifest.txt"
$summaryPath = Join-Path $runDir "summary.txt"

function Write-Status {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamped = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $statusPath -Value $timestamped
    Set-Content -Path $latestPointer -Value $runDir
}

function Convert-ToMatlabPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathValue
    )

    return ($PathValue -replace "\\", "/")
}

function Invoke-LoggedProcess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList
    )

    $stdoutPath = Join-Path $runDir ("{0}_stdout.log" -f $StepName)
    $stderrPath = Join-Path $runDir ("{0}_stderr.log" -f $StepName)

    Write-Status ("START {0}" -f $StepName)
    & $FilePath @ArgumentList 1> $stdoutPath 2> $stderrPath
    if ($LASTEXITCODE -ne 0) {
        Write-Status ("FAIL {0} exit={1}" -f $StepName, $LASTEXITCODE)
        throw "Step failed: $StepName"
    }

    Write-Status ("DONE {0}" -f $StepName)
}

function Invoke-MatlabBatchStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [string]$BatchCommand
    )

    $matlabCodeDir = Convert-ToMatlabPath -PathValue $PSScriptRoot
    $batch = "cd('$matlabCodeDir'); $BatchCommand;"
    Invoke-LoggedProcess -StepName $StepName -FilePath "matlab" -ArgumentList @("-batch", $batch)
}

function Invoke-PythonStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StepName,
        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    $scriptPath = Join-Path $PSScriptRoot $ScriptName
    Invoke-LoggedProcess -StepName $StepName -FilePath "python" -ArgumentList @($scriptPath)
}

try {
    Set-Content -Path $statusPath -Value ""
    Write-Status "RUN_DIR $runDir"

    @(
        "Expected refreshed outputs:",
        " - notes/build/fertility_run_ge_report.md",
        " - notes/build/fertility_local_benchmark_search.csv",
        " - notes/build/fertility_vs_nimby_benchmark_summary.csv",
        " - notes/build/fertility_vs_nimby_common_price_grid.csv",
        " - notes/build/fertility_vs_nimby_benchmark_report.md",
        " - notes/build/fertility_vs_nimby_benchmark_panels.png",
        " - notes/build/fertility_vs_nimby_benchmark_panels.pdf"
    ) | Set-Content -Path $manifestPath

    Invoke-MatlabBatchStep -StepName "01_run_ge_fertility" -BatchCommand "run_ge_fertility_main"
    Invoke-MatlabBatchStep -StepName "02_write_benchmark_note" -BatchCommand "write_fertility_vs_nimby_benchmark_main"
    Invoke-PythonStep -StepName "03_plot_benchmark_panels" -ScriptName "plot_fertility_vs_nimby_benchmark.py"

    if (-not $SkipPdf) {
        $pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
        if ($null -ne $pandoc) {
            $reportMd = Join-Path $buildDir "fertility_vs_nimby_benchmark_report.md"
            $reportPdf = Join-Path $buildDir "fertility_vs_nimby_benchmark_report.pdf"
            if (Test-Path $reportMd) {
                Invoke-LoggedProcess -StepName "04_pandoc_benchmark_pdf" -FilePath $pandoc.Source -ArgumentList @(
                    $reportMd,
                    "--from", "markdown",
                    "--to", "pdf",
                    "--pdf-engine=xelatex",
                    "--resource-path=$buildDir",
                    "-o", $reportPdf
                )
            }
            else {
                Write-Status "SKIP 04_pandoc_benchmark_pdf report markdown missing"
            }
        }
        else {
            Write-Status "SKIP 04_pandoc_benchmark_pdf pandoc not found"
        }
    }
    else {
        Write-Status "SKIP 04_pandoc_benchmark_pdf requested"
    }

    @(
        "Run completed successfully.",
        "Run directory: $runDir",
        "Latest pointer: $latestPointer"
    ) | Set-Content -Path $summaryPath
    Write-Status "SUCCESS"
}
catch {
    Write-Status ("ERROR {0}" -f $_.Exception.Message)
    throw
}
