param(
    [ValidateSet('bounded_re','retryaware_edge','warm_start_k4','restart_checks_k4','full_horizon_live')]
    [string]$Mode = 'bounded_re',
    [string]$PackName = 'transition_re_t4_fixed_terminal',
    [string]$OutputDir = '',
    [ValidateSet('0.15','0.20')]
    [string]$Alpha = '0.15',
    [double]$Hours = 12,
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

switch ($Mode) {
    'bounded_re' {
        & (Join-Path $scriptDir 'run_transition_re_cli.ps1') `
            -PackName $PackName `
            -OutputDir $OutputDir `
            -SkipBuild:$SkipBuild
    }
    'retryaware_edge' {
        $effectivePack = if ($PackName -eq 'transition_re_t4_fixed_terminal') {
            'transition_re_k4_frontier_alpha_0_190899658203125_input_only'
        } else {
            $PackName
        }
        & (Join-Path $scriptDir 'run_transition_re_retryaware.ps1') `
            -PackName $effectivePack `
            -OutputDir $OutputDir `
            -SkipBuild:$SkipBuild
    }
    'warm_start_k4' {
        & (Join-Path $scriptDir 'run_transition_re_policy_bridge_k4_warm_start_sidecar.ps1') `
            -OutputDir $OutputDir `
            -SkipBuild:$SkipBuild
    }
    'restart_checks_k4' {
        & (Join-Path $scriptDir 'run_transition_re_policy_bridge_k4_restart_checks_sidecar.ps1') `
            -Alpha $Alpha `
            -OutputDir $OutputDir `
            -SkipBuild:$SkipBuild
    }
    'full_horizon_live' {
        & (Join-Path $scriptDir 'run_transition_re_full_horizon_away_workflow.ps1') `
            -SessionName 'tr_full_horizon_away_live' `
            -Hours $Hours
    }
    default {
        throw "Unsupported Mode: $Mode"
    }
}
