param(
    [string]$StatePath = "",
    [int]$PollSeconds = 300,
    [int]$MaxMinutes = 720,
    [switch]$AutoSubmitT20
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$watcher = Join-Path $scriptDir "watch_annual_full_re_price_path_hamilton.ps1"
if (-not (Test-Path -LiteralPath $watcher)) {
    throw "Watcher not found: $watcher"
}

$argsList = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $watcher,
    "-PollSeconds", [string]$PollSeconds,
    "-MaxMinutes", [string]$MaxMinutes
)
if (-not [string]::IsNullOrWhiteSpace($StatePath)) {
    $argsList += @("-StatePath", $StatePath)
}
if ($AutoSubmitT20.IsPresent) {
    $argsList += "-AutoSubmitT20"
}

$proc = Start-Process -FilePath "powershell" -ArgumentList $argsList -WindowStyle Hidden -PassThru
[pscustomobject]@{
    ProcessId = $proc.Id
    Watcher = $watcher
    AutoSubmitT20 = $AutoSubmitT20.IsPresent
    PollSeconds = $PollSeconds
    MaxMinutes = $MaxMinutes
} | Format-List
