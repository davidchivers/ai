param(
    [string]$SourceInputDir
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$runtime = Join-Path $root 'runtime'
$inputDir = Join-Path $runtime 'data/input/CFV'
$outputDir = Join-Path $runtime 'data/output/case_1'

New-Item -ItemType Directory -Force -Path $inputDir | Out-Null
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$required = @(
    'policy_functions_v17_in.txt',
    'rnd_100k.txt',
    'x_shk_iid.txt',
    'input_pi_x_iid_1.txt',
    'input_pi_x.txt'
)

if ($SourceInputDir) {
    foreach ($name in $required) {
        $src = Join-Path $SourceInputDir $name
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination (Join-Path $inputDir $name) -Force
        }
    }
}

$missing = @()
foreach ($name in $required) {
    if (-not (Test-Path (Join-Path $inputDir $name))) {
        $missing += $name
    }
}

if ($missing.Count -gt 0) {
    Write-Host 'Runtime directories are ready, but input files are still missing:' -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    exit 1
}

Write-Host "AI calibration runtime is ready at: $runtime" -ForegroundColor Green
