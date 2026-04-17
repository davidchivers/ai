param(
    [string]$LiveRoot = ""
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_transition_solver_stabilization_live"
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

Write-Log "Solver-stabilization reporter started."

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
                "# Original 5-year solver stabilization reporter",
                "",
                "- State: $($status.state)",
                "- Current step: $($status.current_step)",
                "- Updated: $($status.updated_at)",
                "- Run dir: $($status.run_dir)"
            )
            if ($payload.current_stage) {
                $lines += "- Current stage name: $($payload.current_stage.name)"
                $lines += "- Current stage state: $($payload.current_stage.run_state)"
                $lines += "- Current stage max_k: $($payload.current_stage.max_k)"
                $lines += "- Current stage max_iter: $($payload.current_stage.max_iter)"
                $lines += "- Current update rule: $($payload.current_stage.political_update_rule)"
                $lines += "- Current update weight: $($payload.current_stage.political_update_weight)"
                $lines += "- Current pids: $([string]::Join(', ', @($payload.current_stage.current_pids)))"
            }
            if ($payload.stage_results) {
                $stageResults = @($payload.stage_results)
                $lines += "- Completed stages: $($stageResults.Count)"
                if ($stageResults.Count -gt 0) {
                    $lastStage = $stageResults[-1]
                    $lines += "- Last completed stage: $($lastStage.name)"
                    $lines += "- Last stage max |vote|: $($lastStage.max_abs_vote)"
                    $lines += "- Last stage max gap: $($lastStage.max_abs_gap)"
                    $lines += "- Last stage best iteration: $($lastStage.best_iteration)"
                    $lines += "- Last stage mask: $($lastStage.accepted_update_mask)"
                    $lines += "- Last stage improved: $($lastStage.line_search_improved)"
                    $lines += "- Last stage probe accepted: $($lastStage.probe_accepted)"
                }
            }
            if ($payload.classification) {
                $lines += "- Classification: $($payload.classification)"
            }
            if ($payload.reference_k6_smoke_vote) {
                $lines += "- Reference k6 smoke max |vote|: $($payload.reference_k6_smoke_vote)"
            }
            if ($payload.reference_k14_smoke_vote) {
                $lines += "- Reference k14 smoke max |vote|: $($payload.reference_k14_smoke_vote)"
            }
            if ($payload.best_k6) {
                $lines += "- Best k6 stage: $($payload.best_k6.name)"
                $lines += "- Best k6 max |vote|: $($payload.best_k6.max_abs_vote)"
                $lines += "- Best k6 iteration: $($payload.best_k6.best_iteration)"
                $lines += "- Best k6 mask: $($payload.best_k6.accepted_update_mask)"
                $lines += "- Best k6 probe accepted: $($payload.best_k6.probe_accepted)"
            }
            if ($payload.k14_targeted) {
                $lines += "- k14 targeted max |vote|: $($payload.k14_targeted.max_abs_vote)"
                $lines += "- k14 targeted improved: $($payload.k14_targeted.line_search_improved)"
                $lines += "- k14 targeted mask: $($payload.k14_targeted.accepted_update_mask)"
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
