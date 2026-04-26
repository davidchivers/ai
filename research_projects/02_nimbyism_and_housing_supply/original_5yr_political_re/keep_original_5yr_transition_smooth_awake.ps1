param(
    [string]$LiveRoot = "",
    [double]$MaxHours = 24
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_local_smoothed_strategy_boss_live"
}
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$statePath = Join-Path $LiveRoot "keep_awake_state.json"
$logPath = Join-Path $LiveRoot "keep_awake_log.txt"
$stopPath = Join-Path $LiveRoot "keep_awake_stop.txt"
$endAt = (Get-Date).AddHours($MaxHours)

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class ExecutionStateHelper {
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern uint SetThreadExecutionState(uint esFlags);
}
"@

$ES_CONTINUOUS = [uint32]2147483648
$ES_SYSTEM_REQUIRED = [uint32]1
$ES_AWAYMODE_REQUIRED = [uint32]64

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

Write-Log "Smooth keep-awake helper started."
while ((Get-Date) -lt $endAt) {
    if (Test-Path $stopPath) {
        Write-Log "Stop file detected. Releasing execution state."
        break
    }

    [ExecutionStateHelper]::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_AWAYMODE_REQUIRED) | Out-Null
    [ordered]@{
        state = "running"
        updated_at = (Get-Date).ToString("s")
        end_at = $endAt.ToString("s")
    } | ConvertTo-Json | Set-Content -Path $statePath
    Start-Sleep -Seconds 60
}

[ExecutionStateHelper]::SetThreadExecutionState($ES_CONTINUOUS) | Out-Null
[ordered]@{
    state = "released"
    updated_at = (Get-Date).ToString("s")
    end_at = $endAt.ToString("s")
} | ConvertTo-Json | Set-Content -Path $statePath
Write-Log "Smooth keep-awake helper finished."
