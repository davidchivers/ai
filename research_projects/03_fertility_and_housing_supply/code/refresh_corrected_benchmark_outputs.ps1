$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $projectRoot "notes/build"
$reportMd = Join-Path $buildDir "fertility_vs_nimby_benchmark_report.md"
$reportPdf = Join-Path $buildDir "fertility_vs_nimby_benchmark_report.pdf"

function Invoke-MatlabStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BatchCommand
    )

    & matlab -batch "cd('$PSScriptRoot'); $BatchCommand;"
    if ($LASTEXITCODE -ne 0) {
        throw "MATLAB step failed: $BatchCommand"
    }
}

function Invoke-PythonStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName
    )

    & python (Join-Path $PSScriptRoot $ScriptName)
    if ($LASTEXITCODE -ne 0) {
        throw "Python step failed: $ScriptName"
    }
}

Invoke-MatlabStep -BatchCommand "run_ge_fertility_main"
Invoke-MatlabStep -BatchCommand "write_fertility_vs_nimby_benchmark_main"
Invoke-PythonStep -ScriptName "plot_fertility_vs_nimby_benchmark.py"

$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
if ($null -ne $pandoc -and (Test-Path $reportMd)) {
    & $pandoc.Source $reportMd `
        --from markdown `
        --to pdf `
        --pdf-engine=xelatex `
        --resource-path=$buildDir `
        -o $reportPdf
    if ($LASTEXITCODE -ne 0) {
        throw "Pandoc PDF build failed."
    }
}
