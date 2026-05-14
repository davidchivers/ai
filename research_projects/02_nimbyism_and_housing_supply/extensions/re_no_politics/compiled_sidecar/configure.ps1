Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptDir 'tools\portable_toolchain.ps1')

$toolchain = Set-NimbySidecarPortableToolchain
$buildDir = Join-Path $scriptDir 'build'

& $toolchain.CMake `
    -S $scriptDir `
    -B $buildDir `
    -G Ninja `
    -D CMAKE_BUILD_TYPE=Release `
    -D CMAKE_CXX_COMPILER="$($toolchain.CXX)"
