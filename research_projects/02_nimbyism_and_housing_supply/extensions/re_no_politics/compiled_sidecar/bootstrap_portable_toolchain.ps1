param(
    [string]$ToolRoot = 'D:\codex_tools',
    [string]$TempRoot = 'D:\codex_temp\nimby_compiled_sidecar_setup'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

New-Item -ItemType Directory -Force -Path $ToolRoot, $TempRoot | Out-Null

$downloads = @(
    @{
        Name = 'cmake'
        Url = 'https://github.com/Kitware/CMake/releases/download/v4.3.1/cmake-4.3.1-windows-x86_64.zip'
        ZipPath = Join-Path $TempRoot 'cmake.zip'
        DestRoot = $ToolRoot
        FinalPath = Join-Path $ToolRoot 'cmake-4.3.1-windows-x86_64'
    },
    @{
        Name = 'llvm-mingw'
        Url = 'https://github.com/mstorsjo/llvm-mingw/releases/download/20260407/llvm-mingw-20260407-ucrt-x86_64.zip'
        ZipPath = Join-Path $TempRoot 'llvm-mingw.zip'
        DestRoot = $ToolRoot
        FinalPath = Join-Path $ToolRoot 'llvm-mingw-20260407-ucrt-x86_64'
    },
    @{
        Name = 'ninja'
        Url = 'https://github.com/ninja-build/ninja/releases/download/v1.13.2/ninja-win.zip'
        ZipPath = Join-Path $TempRoot 'ninja.zip'
        DestRoot = Join-Path $ToolRoot 'ninja-1.13.2'
        FinalPath = Join-Path $ToolRoot 'ninja-1.13.2\ninja.exe'
    }
)

foreach ($pkg in $downloads) {
    if (Test-Path $pkg.FinalPath) {
        Write-Output "Already present: $($pkg.Name)"
        continue
    }

    Write-Output "Downloading: $($pkg.Name)"
    Invoke-WebRequest $pkg.Url -OutFile $pkg.ZipPath

    Write-Output "Extracting: $($pkg.Name)"
    if ($pkg.Name -eq 'ninja') {
        New-Item -ItemType Directory -Force -Path $pkg.DestRoot | Out-Null
        Expand-Archive -Path $pkg.ZipPath -DestinationPath $pkg.DestRoot -Force
    } else {
        Expand-Archive -Path $pkg.ZipPath -DestinationPath $pkg.DestRoot -Force
    }
}

Write-Output 'Portable toolchain ready.'
Write-Output "Tool root: $ToolRoot"
Write-Output "Temp root: $TempRoot"
