param(
    [string]$LyxPath = "lyx",
    [string]$SourceLyx = "$PSScriptRoot/../drafts/necessity_entrepreneurship.lyx",
    [string]$OutTex = "$PSScriptRoot/../drafts/old_drafts/source_tex/necessity_entrepreneurship.tex"
)

if (-not (Test-Path -LiteralPath $SourceLyx)) {
    throw "Source LyX file not found: $SourceLyx"
}

$outDir = Split-Path -Parent $OutTex
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

& $LyxPath -batch -f all -E latex $OutTex $SourceLyx
if ($LASTEXITCODE -ne 0) {
    throw "LyX export failed with exit code $LASTEXITCODE"
}

Write-Host "Exported TeX companion to $OutTex"
