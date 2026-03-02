<#
.SYNOPSIS
    Complementary experiment batch — 2026-02-28.

.DESCRIPTION
    Designed to run alongside (after) the other LLM's UI=0.40 ladder run.
    Five experiments covering:
      (a) fixed-matching ablation at UI=0.40 — isolates r/w from theta/rho
      (b) intermediate ladder mapping: UI=0.20, 0.10, 0.05 (unfixed, m20)
      (c) seed robustness at UI=0.00 with seed=42

    All runs use -SkipCompile (exe already built).
    Timeout per run: 1200s (20 min). Total wall time: ≤ 100 min.
#>

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$runner = Join-Path $root 'run_ai_calibration.ps1'
$outputDir = Join-Path $root 'runtime/data/output/complementary_2026-02-28'
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$TimeoutSeconds = 1200
$Seed = 12345
$MaxIter = 20

Write-Host "=== Complementary experiment batch 2026-02-28 ===" -ForegroundColor Cyan
Write-Host "Experiments: 5 | Timeout/run: ${TimeoutSeconds}s | Iterations: ${MaxIter}" -ForegroundColor Cyan
Write-Host ""

function Run-Experiment {
    param(
        [string]$Label,
        [hashtable]$Params
    )
    Write-Host ("--- Starting: {0} ---" -f $Label) -ForegroundColor Yellow
    try {
        & $runner @Params
        Write-Host ("    Done: {0}" -f $Label) -ForegroundColor Green
    } catch {
        Write-Host ("    Error: {0} -- {1}" -f $Label, $_.Exception.Message) -ForegroundColor Red
    }
    Write-Host ""
}

# EXP-A: Fixed matching at UI=0.40 (ablation complement to other LLM's free run)
# Rationale: other LLM ran unfixed at UI=0.40 (tol_ge=0.109 at m40).
# This pins theta/rho to isolate whether the residual is in r/w vs matching.
Run-Experiment -Label "A: ui040 fixed-matching m20" -Params @{
    Scenario       = 'baseline'
    UiOverride     = '0.40'
    FixedTheta     = '0.25'
    FixedRho       = '0.03'
    MaxIterAgg     = $MaxIter
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = $TimeoutSeconds
    SkipCompile    = $true
    RunTag         = 'comp_A_ui040_fixmatch_m20'
}

# EXP-B: UI=0.20, unfixed, m20
# Rationale: fills in the convergence ladder between baseline and ui=0.10.
# Neither LLM has run this level with m20 depth.
Run-Experiment -Label "B: ui020 unfixed m20" -Params @{
    Scenario       = 'ui_020'
    MaxIterAgg     = $MaxIter
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = $TimeoutSeconds
    SkipCompile    = $true
    RunTag         = 'comp_B_ui020_m20'
}

# EXP-C: UI=0.10, unfixed, m20
# Rationale: fills in the convergence ladder.
Run-Experiment -Label "C: ui010 unfixed m20" -Params @{
    Scenario       = 'ui_010'
    MaxIterAgg     = $MaxIter
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = $TimeoutSeconds
    SkipCompile    = $true
    RunTag         = 'comp_C_ui010_m20'
}

# EXP-D: UI=0.05, unfixed, m20
# Rationale: near-zero UI; quick probes before showed blow-up at m3.
# m20 gives a fuller picture of how fast divergence occurs.
Run-Experiment -Label "D: ui005 unfixed m20" -Params @{
    Scenario       = 'ui_005'
    MaxIterAgg     = $MaxIter
    RngSeed        = $Seed
    SkipTransition = $true
    TimeoutSeconds = $TimeoutSeconds
    SkipCompile    = $true
    RunTag         = 'comp_D_ui005_m20'
}

# EXP-E: UI=0.00, seed=42 (robustness check vs existing seed=12345 runs)
# Rationale: all prior runs used seed=12345. This tests whether convergence
# behavior at the hardest case (ui_000) is seed-dependent.
Run-Experiment -Label "E: ui000 seed=42 m20" -Params @{
    Scenario       = 'ui_000'
    MaxIterAgg     = $MaxIter
    RngSeed        = 42
    SkipTransition = $true
    TimeoutSeconds = $TimeoutSeconds
    SkipCompile    = $true
    RunTag         = 'comp_E_ui000_seed42_m20'
}

Write-Host "=== All complementary experiments complete ===" -ForegroundColor Cyan
Write-Host ("Logs in: " + (Join-Path $root 'runtime/data/output/case_1/')) -ForegroundColor Cyan
