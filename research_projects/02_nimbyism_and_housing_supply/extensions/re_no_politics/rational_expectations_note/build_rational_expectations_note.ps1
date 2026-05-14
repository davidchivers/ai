$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$texFile = Join-Path $thisDir 'rational_expectations_note.tex'
$pdfFile = Join-Path $thisDir 'rational_expectations_note.pdf'

Push-Location $thisDir
try {
    Write-Host '=== compile_rational_expectations_note ==='
    & pdflatex -interaction=nonstopmode -halt-on-error $texFile | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "pdflatex failed on first pass with exit code $LASTEXITCODE."
    }
    & pdflatex -interaction=nonstopmode -halt-on-error $texFile | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "pdflatex failed on second pass with exit code $LASTEXITCODE."
    }

    $cleanup = @('aux', 'log', 'out', 'toc')
    foreach ($ext in $cleanup) {
        $candidate = [System.IO.Path]::ChangeExtension($texFile, $ext)
        if (Test-Path $candidate) {
            Remove-Item $candidate -Force
        }
    }

    Write-Host "Built $pdfFile"
}
finally {
    Pop-Location
}
