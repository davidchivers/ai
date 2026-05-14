param(
    [string]$LiveRoot = ""
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($LiveRoot)) {
    $LiveRoot = Join-Path $scriptDir "truth\original_5yr_political_re_live"
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

Write-Log "Reporter started."

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
                "# Original 5-Year Political RE Reporter",
                "",
                "- State: $($status.state)",
                "- Current step: $($status.current_step)",
                "- Updated: $($status.updated_at)"
            )
            if ($payload.classification) {
                $lines += "- Classification: $($payload.classification)"
            }
            if ($payload.recommended_target_price) {
                $lines += "- Recommended target price: $($payload.recommended_target_price)"
            }
            if ($payload.best_vote_abs) {
                $lines += "- Best |vote| on tested tree: $($payload.best_vote_abs)"
            }
            if ($payload.best_run_name) {
                $lines += "- Best run branch: $($payload.best_run_name)"
            }
            if ($payload.coarse) {
                $lines += "- Coarse best |vote| price: $($payload.coarse.best_vote_abs_price)"
                $lines += "- Coarse sign pattern: $($payload.coarse.sign_pattern)"
                $lines += "- Coarse bracket found: $($payload.coarse.has_vote_bracket)"
            }
            if ($payload.lower_expand) {
                $lines += "- Lower expansion best |vote| price: $($payload.lower_expand.best_vote_abs_price)"
                $lines += "- Lower expansion sign pattern: $($payload.lower_expand.sign_pattern)"
            }
            if ($payload.upper_expand) {
                $lines += "- Upper expansion best |vote| price: $($payload.upper_expand.best_vote_abs_price)"
                $lines += "- Upper expansion sign pattern: $($payload.upper_expand.sign_pattern)"
            }
            if ($payload.broad_full) {
                $lines += "- Broad sweep best |vote| price: $($payload.broad_full.best_vote_abs_price)"
                $lines += "- Broad sweep sign pattern: $($payload.broad_full.sign_pattern)"
            }
            if ($payload.rb_sensitivity) {
                $rbRuns = @($payload.rb_sensitivity)
                if ($rbRuns.Count -gt 0) {
                    $lines += "- RB sensitivity runs completed: $($rbRuns.Count)"
                    foreach ($rbRun in $rbRuns) {
                        $lines += "  rb branch $($rbRun.name): best |vote| = $($rbRun.best_vote_abs), bracket = $($rbRun.has_vote_bracket)"
                    }
                }
            }
            if ($payload.refined) {
                $lines += "- Refined best |vote| price: $($payload.refined.best_vote_abs_price)"
                $lines += "- Refined bracket found: $($payload.refined.has_vote_bracket)"
            }
            if ($payload.dense) {
                $lines += "- Dense best |vote| price: $($payload.dense.best_vote_abs_price)"
                $lines += "- Dense bracket found: $($payload.dense.has_vote_bracket)"
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
