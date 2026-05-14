function Set-NimbySidecarPortableToolchain {
    param(
        [string]$ToolRoot = 'D:\codex_tools',
        [string]$TempRoot = 'D:\codex_temp\nimby_compiled_sidecar'
    )

    $cmakeExe = Join-Path $ToolRoot 'cmake-4.3.1-windows-x86_64\bin\cmake.exe'
    $ninjaExe = Join-Path $ToolRoot 'ninja-1.13.2\ninja.exe'
    $compilerRoot = Join-Path $ToolRoot 'llvm-mingw-20260407-ucrt-x86_64\bin'
    $cxxExe = Join-Path $compilerRoot 'g++.exe'
    $ccExe = Join-Path $compilerRoot 'gcc.exe'

    foreach ($path in @($cmakeExe, $ninjaExe, $cxxExe, $ccExe)) {
        if (-not (Test-Path $path)) {
            throw "Portable toolchain component missing: $path"
        }
    }

    New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null

    $env:TEMP = $TempRoot
    $env:TMP = $TempRoot
    $env:CC = $ccExe
    $env:CXX = $cxxExe
    $env:CMAKE_GENERATOR = 'Ninja'
    $env:CMAKE_MAKE_PROGRAM = $ninjaExe
    $env:PATH = ($compilerRoot, (Split-Path $cmakeExe), (Split-Path $ninjaExe), $env:PATH) -join ';'

    return [pscustomobject]@{
        ToolRoot = $ToolRoot
        TempRoot = $TempRoot
        CMake = $cmakeExe
        Ninja = $ninjaExe
        CC = $ccExe
        CXX = $cxxExe
    }
}
