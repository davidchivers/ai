param(
    [string]$RemoteAlias = "hamilton8",
    [string]$RemoteProject = "",
    [string]$Partition = "shared",
    [string]$WallTime = "12:00:00",
    [int]$MemoryGb = 10,
    [int]$CpusPerTask = 1,
    [string]$MatlabModule = "matlab/R2021a",
    [string]$SeedPricePathCsv = "",
    [string]$PacketProfile = "baseline"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$submitScript = Join-Path $scriptDir "submit_original_5yr_hamilton_reduced_path_packet.ps1"

$argsList = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $submitScript,
    "-RemoteAlias", $RemoteAlias,
    "-Partition", $Partition,
    "-WallTime", $WallTime,
    "-MemoryGb", [string]$MemoryGb,
    "-CpusPerTask", [string]$CpusPerTask,
    "-MatlabModule", $MatlabModule,
    "-PacketProfile", $PacketProfile,
    "-DemographicSourceMode", "historical_1950_two_group"
)
if (-not [string]::IsNullOrWhiteSpace($RemoteProject)) {
    $argsList += @("-RemoteProject", $RemoteProject)
}
if (-not [string]::IsNullOrWhiteSpace($SeedPricePathCsv)) {
    $argsList += @("-SeedPricePathCsv", $SeedPricePathCsv)
}

& powershell @argsList
