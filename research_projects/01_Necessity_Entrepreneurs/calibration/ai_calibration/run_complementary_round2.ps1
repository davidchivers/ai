<#
.SYNOPSIS
    Complementary experiment batch — Round 2 (2026-03-01).

.DESCRIPTION
    Round 1 revealed:
      - UI=0.40 unfixed m40: tol_ge=0.109 (slowly improving, other LLM)
      - UI=0.40 fixed-match m20: tol_ge=0.0702 (better — matching helps)
      - UI=0.30 unfixed m5:  tol_ge=2.48  (EXPLODES — cliff between 0.30 and 0.40)
      - UI=0.20 unfixed: theta hits boundary by iter 12 (blowing up)

    Round 2 strategy — locate the cliff and test the matching-fix across it:
      F: UI=0.35 unfixed m20       — bisect the cliff (stable or not?)
      G: UI=0.30 fixed-match m20   — KEY: does matching stabilize the cliff?
      H: UI=0.20 fixed-match m20   — same test below the cliff
      I: UI=0.35 fixed-match m20   — matching test at the midpoint
      J: UI=0.30 step=0.80 m20     — damping variant at cliff (more aggressive damp)
#>

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$runner = Join-Path $root 'run_ai_calibration.ps1'

$TimeoutSeconds = 1200
$Seed = 12345
$MaxIter = 20

Write-Host "=== Complementary batch Round 2 (2026-03-01) ===" -ForegroundColor Cyan
Write-Host "Experiments: 5 | Timeout/run: ${TimeoutSeconds}s | Iterations: ${MaxIter}" -ForegroundColor Cyan
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

# EXP-F: UI=0.35 unfixed m20 — bisect the cliff
# Round 1 cliff: UI=0.40 ok, UI=0.30 explodes. Is 0.35 stable?
Run-Experiment -Label "F: ui035 unfixed m20" -Params @{
    Scenario       = 'baseline'
    UiOverride     = '0.35'
    MaxIterAgg     = $MaxIter
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = $TimeoutSeconds
    SkipCompile    = $true
    RunTag         = 'comp_F_ui035_unfixed_m20'
}

# EXP-G: UI=0.30 fixed-match m20 — KEY experiment
# Does pinning theta/rho overcome the UI=0.30 explosion?
# If tol_ge drops vs the unfixed 2.48, matching is the instability source.
Run-Experiment -Label "G: ui030 fixed-match m20" -Params @{
    Scenario       = 'baseline'
    UiOverride     = '0.30'
    FixedTheta     = '0.25'
    FixedRho       = '0.03'
    MaxIterAgg     = $MaxIter
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = $TimeoutSeconds
    SkipCompile    = $true
    RunTag         = 'comp_G_ui030_fixmatch_m20'
}

# EXP-H: UI=0.20 fixed-match m20 — extend matching fix further down
# Round 1: UI=0.20 unfixed blew up at iter 12.
# If fixed-match stabilizes this, matching is the key lever.
Run-Experiment -Label "H: ui020 fixed-match m20" -Params @{
    Scenario       = 'ui_020'
    FixedTheta     = '0.25'
    FixedRho       = '0.03'
    MaxIterAgg     = $MaxIter
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = $TimeoutSeconds
    SkipCompile    = $true
    RunTag         = 'comp_H_ui020_fixmatch_m20'
}

# EXP-I: UI=0.35 fixed-match m20 — matching test at midpoint
# Paired with EXP-F (unfixed). Shows whether matching fix changes the midpoint.
Run-Experiment -Label "I: ui035 fixed-match m20" -Params @{
    Scenario       = 'baseline'
    UiOverride     = '0.35'
    FixedTheta     = '0.25'
    FixedRho       = '0.03'
    MaxIterAgg     = $MaxIter
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = $TimeoutSeconds
    SkipCompile    = $true
    RunTag         = 'comp_I_ui035_fixmatch_m20'
}

# EXP-J: UI=0.30 step=0.80 (more aggressive damping) m20
# Round 1 baseline damping=0.95. Testing 0.80 at the cliff.
# Prior result: step=0.90 worse than 0.95 for ui_000. Does UI=0.30 differ?
Run-Experiment -Label "J: ui030 step=0.80 m20" -Params @{
    Scenario       = 'baseline'
    UiOverride     = '0.30'
    UpdateStep1    = '0.80'
    MaxIterAgg     = $MaxIter
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = $TimeoutSeconds
    SkipCompile    = $true
    RunTag         = 'comp_J_ui030_step080_m20'
}

Write-Host "=== Round 2 complete ===" -ForegroundColor Cyan
Write-Host ("Logs in: " + (Join-Path $root 'runtime/data/output/case_1/')) -ForegroundColor Cyan
