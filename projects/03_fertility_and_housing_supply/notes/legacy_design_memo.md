# Design Memo - 03_Fertility_and_Housing_Supply

Date: 2026-02-25

## Core empirical question
Do housing-supply restrictions and housing affordability pressures causally reduce fertility (timing and completed outcomes)?

## Ranked design portfolio
1. Middle-housing legalization event-study (baseline)
2. NIMBY political turnover close-election design (high-upside extension)

## Baseline design: middle-housing legalizations
Unit:
- Region-by-year panel (county/local authority style, final geography pending data lock).

Treatment:
- Post-reform exposure to middle-housing legalizations.
- Optional intensity term based on ex-ante housing composition or reform bite.

Outcomes:
- Age-specific birth rates
- First-birth timing
- Completed-fertility proxies where feasible

Main specification:
```math
BirthRate_{it} = \sum_{k \neq -1} \beta_k 1\{EventTime_{it}=k\} + \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}
```

Intensity extension:
```math
BirthRate_{it} = \beta (Post_{it} \times Exposure_i) + \alpha_i + \delta_t + X_{it}'\Gamma + \varepsilon_{it}
```

## NIMBY political-economy extension
First stage:
```math
Supply_{it} = \pi\,ProHousingWin_{it} + f(Margin_{it}) + \eta_i + \tau_t + u_{it}
```

Second stage:
```math
BirthRate_{it} = \beta\,\widehat{Supply}_{it} + f(Margin_{it}) + \eta_i + \tau_t + e_{it}
```

## Identification risks and mitigation
- Differential demand trends / sorting:
  - Pre-trend event-study diagnostics
  - Migration and labor-market controls
- Concurrent policy bundles:
  - Policy-timing controls and sensitivity windows
- Weak first-stage quantity response:
  - Explicit permit/unit-mix first-stage reporting

## Immediate execution checklist
- [ ] Finalize treatment source and treatment timing definition
- [ ] Finalize main outcome family for baseline table 1
- [ ] Assemble baseline panel with harmonized geography
- [ ] Run first pass pre-trend and placebo checks

## Legacy detail
Full pre-consolidation empirical note files are archived in:
- `_playground/backups/2026-02-25_notes_flattening/03_fertility_and_housing_supply/Notes_old`


