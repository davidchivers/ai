<#
.SYNOPSIS
    Complementary experiment batch — Round 3 (2026-03-01).

.DESCRIPTION
    Round 2 KEY finding (Exp G):
      UI=0.30 fixed-match m20: tol_ge=0.127 vs unfixed tol_ge=2.46.
      Matching (theta/rho) is confirmed as the PRIMARY instability source at the cliff.
      Fixing matching restores near-UI=0.40 convergence behaviour even at UI=0.30.

    Round 3 strategy — exploit the matching insight:
      K: UI=0.30 fixed-match m80     — Longer run. Does fixed-match fully converge at UI=0.30?
      L: UI=0.10 fixed-match m20     — Extend matching-fix to deeper UI levels
      M: UI=0.00 fixed-match m20     — Matching-fix at the extreme
      N: UI=0.30 theta-damp=0.40 m20 — Dampen theta update heavily (not fully fixed) — practical path
      O: UI=0.30 theta-damp=0.10 m20 — Near-full theta damping (CFV_UPDATE_STEP1 is for r/w;
                                        theta damping is within the solver, not separately exposed)
                                        Instead: run UI=0.30 unfixed but with market_gap_clamp=0.2
                                        to limit r/w divergence
#>

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$runner = Join-Path $root 'run_ai_calibration.ps1'

$Seed = 12345

Write-Host "=== Complementary batch Round 3 (2026-03-01) ===" -ForegroundColor Cyan
Write-Host ""

function Run-Experiment {
    param([string]$Label, [hashtable]$Params)
    Write-Host ("--- Starting: {0} ---" -f $Label) -ForegroundColor Yellow
    try {
        & $runner @Params
        Write-Host ("    Done: {0}" -f $Label) -ForegroundColor Green
    } catch {
        Write-Host ("    Error: {0} -- {1}" -f $Label, $_.Exception.Message) -ForegroundColor Red
    }
    Write-Host ""
}

# EXP-K: UI=0.30 fixed-match m80 — longer run to test full convergence
# Round 2: fixed-match m20 timed out at 1200s with tol_ge=0.127 at iter=20.
# With more budget (m80, 3600s timeout), can the r/w loop converge to tol<0.01?
Run-Experiment -Label "K: ui030 fixed-match m80 (3600s)" -Params @{
    Scenario       = 'baseline'
    UiOverride     = '0.30'
    FixedTheta     = '0.25'
    FixedRho       = '0.03'
    MaxIterAgg     = 80
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = 3600
    SkipCompile    = $true
    RunTag         = 'comp_K_ui030_fixmatch_m80'
}

# EXP-L: UI=0.10 fixed-match m20
# Round 1: UI=0.10 unfixed had tol_ge=2.35 at m20 (exploding).
# Does fixing matching also stabilize UI=0.10 like it did UI=0.30?
Run-Experiment -Label "L: ui010 fixed-match m20" -Params @{
    Scenario       = 'ui_010'
    FixedTheta     = '0.25'
    FixedRho       = '0.03'
    MaxIterAgg     = 20
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = 1200
    SkipCompile    = $true
    RunTag         = 'comp_L_ui010_fixmatch_m20'
}

# EXP-M: UI=0.00 fixed-match m20
# The hardest case. Previous m40 unfixed: tol_ge~0.40 (convergence wall).
# Fixed-match at ui_000 was done in earlier quick probes (g02 in focused profile)
# but only 15 iters. Fresh m20 run to compare with the r/w-pinned result.
Run-Experiment -Label "M: ui000 fixed-match m20" -Params @{
    Scenario       = 'ui_000'
    FixedTheta     = '0.25'
    FixedRho       = '0.03'
    MaxIterAgg     = 20
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = 1800
    SkipCompile    = $true
    RunTag         = 'comp_M_ui000_fixmatch_m20'
}

# EXP-N: UI=0.30 unfixed, market_gap_clamp=0.20 m20
# Softer alternative to full matching fix: clamp r/w market gap updates.
# The 0.5 clamp in Round 1 (2026-02-27) reduced sign flips but didn't help much.
# 0.20 is tighter — tests if clamping alone can stabilize the cliff.
Run-Experiment -Label "N: ui030 unfixed gap_clamp=0.20 m20" -Params @{
    Scenario        = 'baseline'
    UiOverride      = '0.30'
    MarketGapClamp  = '0.20'
    MaxIterAgg      = 20
    RngSeed         = $Seed
    SkipTransition  = $true
    TimeoutSeconds  = 1200
    SkipCompile     = $true
    RunTag          = 'comp_N_ui030_clamp020_m20'
}

# EXP-O: UI=0.30 unfixed, lower update_step1=0.50 m20
# Aggressive damping on r/w (and theta) updates.
# Prior tests: step=0.90 and 0.98 both worse than 0.95 for ui_000.
# At the cliff (ui_030), the dynamics are different. Does step=0.50 help?
Run-Experiment -Label "O: ui030 unfixed step=0.50 m20" -Params @{
    Scenario       = 'baseline'
    UiOverride     = '0.30'
    UpdateStep1    = '0.50'
    MaxIterAgg     = 20
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = 1200
    SkipCompile    = $true
    RunTag         = 'comp_O_ui030_step050_m20'
}

Write-Host "=== Round 3 complete ===" -ForegroundColor Cyan
