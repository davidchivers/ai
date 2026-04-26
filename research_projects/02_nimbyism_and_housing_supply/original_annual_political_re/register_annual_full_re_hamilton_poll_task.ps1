[CmdletBinding()]
param(
    [string]$TaskName = "NimbyAnnualFullREPoll",
    [int]$IntervalMinutes = 15,
    [int]$MaxHours = 24
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PollScript = Join-Path $ScriptDir "poll_annual_full_re_hamilton_once.ps1"
if (-not (Test-Path $PollScript)) {
    throw "Poll script not found: $PollScript"
}

$Args = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-WindowStyle", "Hidden",
    "-File", "`"$PollScript`"",
    "-TaskName", "`"$TaskName`""
) -join " "

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument $Args `
    -WorkingDirectory $ScriptDir

$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
    -RepetitionDuration (New-TimeSpan -Hours $MaxHours)

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "Poll and fetch annual full-RE Hamilton summaries every $IntervalMinutes minutes, then self-stop when jobs finish." `
    -Force | Out-Null

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $PollScript -TaskName $TaskName

Write-Host "Registered scheduled task $TaskName. It will poll every $IntervalMinutes minutes for up to $MaxHours hours and self-stop when the Hamilton jobs are finished."
