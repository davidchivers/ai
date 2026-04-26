param(
    [double]$MaxHours = 24,
    [string]$MatlabExe = "matlab"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ensureScript = Join-Path $scriptDir "ensure_original_5yr_transition_local_smoothed_strategy_boss.ps1"

$taskName = "Codex_NIMBY_SmoothedLocalBoss_Watchdog"
$userId = $env:USERDOMAIN + "\" + $env:USERNAME

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ensureScript`" -MaxHours $([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:R}', $MaxHours)) -MatlabExe `"$MatlabExe`""

$triggerRecurring = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 15) `
    -RepetitionDuration (New-TimeSpan -Days 3650)

$triggerLogon = New-ScheduledTaskTrigger -AtLogOn -User $userId
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger @($triggerRecurring, $triggerLogon) `
    -Principal $principal `
    -Settings $settings `
    -Description "Keeps the NIMBY local smoothed-politics strategy boss alive." `
    -Force | Out-Null

[ordered]@{
    task_name = $taskName
    user_id = $userId
    ensure_script = $ensureScript
    installed_at = (Get-Date).ToString("s")
} | ConvertTo-Json -Depth 4
