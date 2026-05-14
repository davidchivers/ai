param(
    [string]$LiveRoot = ""
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_political_live"
}
New-Item -ItemType Directory -Force -Path $LiveRoot | Out-Null

$statusPath = Join-Path $LiveRoot "latest_status.json"
$reportPath = Join-Path $LiveRoot "latest_report.md"
$statePath = Join-Path $LiveRoot "reporter_state.json"
$logPath = Join-Path $LiveRoot "reporter_log.txt"
$stopPath = Join-Path $LiveRoot "reporter_stop.txt"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

Write-Log "Historical transition reporter started."

$lastUpdated = ""
while ($true) {
    if (Test-Path $stopPath) {
        Write-Log "Reporter stop file detected."
        break
    }

    if (Test-Path $statusPath) {
        $status = Get-Content -Raw -Path $statusPath | ConvertFrom-Json
        if ($status.updated_at -ne $lastUpdated) {
            $payload = $status.payload
            $lines = @(
                "# Original 5-Year Historical Transition Reporter",
                "",
                "- State: $($status.state)",
                "- Current step: $($status.current_step)",
                "- Updated: $($status.updated_at)",
                "- Run dir: $($status.run_dir)"
            )
            if ($payload.current_stage) {
                $lines += "- Current stage max_k: $($payload.current_stage.max_k)"
                $lines += "- Current stage max_iter: $($payload.current_stage.max_iter)"
                $lines += "- Current update rule: $($payload.current_stage.political_update_rule)"
                $lines += "- Current update weight: $($payload.current_stage.political_update_weight)"
            }
            if ($payload.stage_results) {
                $stageResults = @($payload.stage_results)
                $lines += "- Completed stages: $($stageResults.Count)"
                if ($stageResults.Count -gt 0) {
                    $lastStage = $stageResults[-1]
                    $lines += "- Last completed stage: $($lastStage.name)"
                    $lines += "- Last stage max |vote|: $($lastStage.max_abs_vote)"
                    $lines += "- Last stage max gap: $($lastStage.max_abs_gap)"
                }
            }
            if ($payload.classification) {
                $lines += "- Classification: $($payload.classification)"
            }
            if ($payload.demographic_source_mode) {
                $lines += "- Demographic source: $($payload.demographic_source_mode)"
            }
            if ($payload.selected_years) {
                $lines += "- Years: $([string]::Join(', ', @($payload.selected_years)))"
            }
            if ($payload.best_k2) {
                $lines += "- Best k2 branch: $($payload.best_k2.name)"
                $lines += "- Best k2 max |vote|: $($payload.best_k2.max_abs_vote)"
                $lines += "- Best k2 max gap: $($payload.best_k2.max_abs_gap)"
            }
            if ($payload.k1) {
                $lines += "- k1 smoke max |vote|: $($payload.k1.max_abs_vote)"
            }
            if ($payload.k2_baseline) {
                $lines += "- k2 baseline max |vote|: $($payload.k2_baseline.max_abs_vote)"
            }
            if ($payload.k2_fixed_fast) {
                $lines += "- k2 fixed-fast max |vote|: $($payload.k2_fixed_fast.max_abs_vote)"
            }
            if ($payload.k2_secant) {
                $lines += "- k2 secant max |vote|: $($payload.k2_secant.max_abs_vote)"
            }
            if ($payload.k3_smoke) {
                $lines += "- k3 smoke max |vote|: $($payload.k3_smoke.max_abs_vote)"
                $lines += "- k3 smoke max gap: $($payload.k3_smoke.max_abs_gap)"
            }
            if ($payload.k3_continue) {
                $lines += "- k3 continue max |vote|: $($payload.k3_continue.max_abs_vote)"
                $lines += "- k3 continue max gap: $($payload.k3_continue.max_abs_gap)"
            }
            if ($payload.k4_smoke) {
                $lines += "- k4 smoke max |vote|: $($payload.k4_smoke.max_abs_vote)"
                $lines += "- k4 smoke max gap: $($payload.k4_smoke.max_abs_gap)"
            }
            if ($payload.error) {
                $lines += "- Error: $($payload.error)"
            }
            Set-Content -Path $reportPath -Value ($lines -join [Environment]::NewLine)
            [ordered]@{
                updated_at = (Get-Date).ToString("s")
                source_updated_at = $status.updated_at
            } | ConvertTo-Json | Set-Content -Path $statePath
            $lastUpdated = $status.updated_at
            Write-Log "Reporter refreshed latest_report.md."
        }
    }
    Start-Sleep -Seconds 15
}
