<#
.SYNOPSIS
    Complementary experiment batch — Round 4 (2026-03-01).

.DESCRIPTION
    Round 3 KEY finding (Exp K):
      UI=0.30 fixed-match m80: best_check_tol=0.030 (!!) but tol_ge=0.258 (oscillating).
      The system CAN reach tol_ge~0.03 with matching fixed, but overshoots.
      Root cause: r/w step=0.95 is too loose — oscillates around equilibrium.

    Round 4 strategy — damp the r/w oscillation:
      P: UI=0.30 fixed-match + step=0.60 m80   — lower r/w damping, long run
      Q: UI=0.30 fixed-match + step=0.50 m80   — aggressive r/w damping, long run
      R: UI=0.30 fixed-match + step=0.30 m80   — very aggressive r/w damping
      S: UI=0.20 fixed-match + step=0.60 m40   — test at lower UI with damping fix
      T: UI=0.40 unfixed     + step=0.60 m40   — does lower r/w step help at UI=0.40?
#>

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$runner = Join-Path $root 'run_ai_calibration.ps1'
$Seed = 12345

Write-Host "=== Complementary batch Round 4 (2026-03-01) ===" -ForegroundColor Cyan
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

# EXP-P: UI=0.30 fixed-match step=0.60 m80 (3600s)
# K hit best=0.030 but oscillated with step=0.95. step=0.60 reduces overshoot.
Run-Experiment -Label "P: ui030 fixed-match step=0.60 m80" -Params @{
    Scenario       = 'baseline'
    UiOverride     = '0.30'
    FixedTheta     = '0.25'
    FixedRho       = '0.03'
    UpdateStep1    = '0.60'
    MaxIterAgg     = 80
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = 3600
    SkipCompile    = $true
    RunTag         = 'comp_P_ui030_fixmatch_s060_m80'
}

# EXP-Q: UI=0.30 fixed-match step=0.50 m80 (3600s)
# More aggressive damping than P.
Run-Experiment -Label "Q: ui030 fixed-match step=0.50 m80" -Params @{
    Scenario       = 'baseline'
    UiOverride     = '0.30'
    FixedTheta     = '0.25'
    FixedRho       = '0.03'
    UpdateStep1    = '0.50'
    MaxIterAgg     = 80
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = 3600
    SkipCompile    = $true
    RunTag         = 'comp_Q_ui030_fixmatch_s050_m80'
}

# EXP-R: UI=0.30 fixed-match step=0.30 m80 (3600s)
# Very aggressive damping. If P and Q still oscillate, this should stop it.
Run-Experiment -Label "R: ui030 fixed-match step=0.30 m80" -Params @{
    Scenario       = 'baseline'
    UiOverride     = '0.30'
    FixedTheta     = '0.25'
    FixedRho       = '0.03'
    UpdateStep1    = '0.30'
    MaxIterAgg     = 80
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = 3600
    SkipCompile    = $true
    RunTag         = 'comp_R_ui030_fixmatch_s030_m80'
}

# EXP-S: UI=0.20 fixed-match step=0.60 m40 (2400s)
# Apply the r/w damping fix to a lower UI level.
Run-Experiment -Label "S: ui020 fixed-match step=0.60 m40" -Params @{
    Scenario       = 'ui_020'
    FixedTheta     = '0.25'
    FixedRho       = '0.03'
    UpdateStep1    = '0.60'
    MaxIterAgg     = 40
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = 2400
    SkipCompile    = $true
    RunTag         = 'comp_S_ui020_fixmatch_s060_m40'
}

# EXP-T: UI=0.40 unfixed step=0.60 m40 (2400s)
# Baseline sensitivity: does lower r/w step help the unfixed UI=0.40 run?
# Current best (Codex): best_check_tol=0.054 at step=0.95 m40.
Run-Experiment -Label "T: ui040 unfixed step=0.60 m40" -Params @{
    Scenario       = 'baseline'
    UiOverride     = '0.40'
    UpdateStep1    = '0.60'
    MaxIterAgg     = 40
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = 2400
    SkipCompile    = $true
    RunTag         = 'comp_T_ui040_unfixed_s060_m40'
}

Write-Host "=== Round 4 complete ===" -ForegroundColor Cyan
