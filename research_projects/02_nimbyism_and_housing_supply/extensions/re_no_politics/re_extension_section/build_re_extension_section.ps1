$ErrorActionPreference = 'Stop'

$thisDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$matlab = 'C:\Program Files\MATLAB\R2025b\bin\matlab.exe'
$texFile = Join-Path $thisDir 're_extension_section.tex'
$pdfFile = Join-Path $thisDir 're_extension_section.pdf'

Push-Location $thisDir
try {
    $batch = "cd('$($thisDir -replace '\\','/')'); make_re_extension_figures"
    $matlabArgs = "-batch `"$batch`""

    Write-Host '=== build_re_extension_figures ==='
    $proc = Start-Process -FilePath $matlab -ArgumentList $matlabArgs -WorkingDirectory $thisDir `
        -NoNewWindow -PassThru -Wait
    if ($proc.ExitCode -ne 0) {
        throw "Figure generation failed with exit code $($proc.ExitCode)."
    }

    Write-Host '=== compile_re_extension_pdf ==='
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
