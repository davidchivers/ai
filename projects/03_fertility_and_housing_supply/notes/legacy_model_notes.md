# Model Notes - 03_Fertility_and_Housing_Supply

Date: 2026-02-25

## Model objective
Embed fertility choices into the existing NIMBY housing political-economy framework without breaking the core housing-voting structure.

## Core extension blocks
1. Utility with children-at-home and crowding
```math
u_t = \frac{(c_t^{1-\zeta} h_{t,eff}^{\zeta})^{1-\gamma}}{1-\gamma} + \chi\frac{n_{t,home}^{1-\eta}}{1-\eta},
\quad
h_{t,eff}=\frac{h_t}{(1+\lambda n_{t,home})^{\psi}}
```

2. Fertility as an endogenous choice in the household DP
```math
V_t(s_t)=\max_{c_t,a_{t+1},h_{t+1},b_t}\{u_t+\beta E_t[V_{t+1}(s_{t+1})]\}
```

3. Children-leaving-home dynamics (deterministic baseline)
```math
N_{0,t+1}=b_t,
\quad
N_{a+1,t+1}=N_{a,t},
\quad
n_{t,home}=\sum_{a=0}^{A_{leave}-1}N_{a,t}
```

4. Endogenous demographic transition
```math
M_{j+1,t+1}=\ell_j M_{j,t},
\quad
M_{1,t+1}=\sum_{j\in\mathcal F} f_j M_{j,t}
```

## Equilibrium implication
The model becomes a joint price-demography fixed point:
```math
\{p_t, r_t, policy_t, M_t\}_{t\ge 0}
```
instead of a price path with exogenous demographics.

## Numerical lessons from prototype experiment
- Undamped updates generate unstable oscillatory dynamics.
- Damping and bounded transforms are required for robust convergence.
- Family-sized supply shifts raise fertility in the stabilized toy run.

## Implementation sequence
1. Household DP with fertility control (`children-at-home` state).
2. Demographic update block from policy-implied births.
3. Outer loop on prices and cohort shares with damping.
4. Convergence checks on prices, cohort shares, and births simultaneously.

## Current practical defaults
- Keep partner formation exogenous in baseline (avoid extra state explosion).
- Start with deterministic leave-home age; test stochastic leaving in robustness.
- Normalize by population shares in outer-loop convergence checks.

## Legacy detail
Full derivations and prototype-report documents are archived in:
- `_playground/backups/2026-02-25_notes_flattening/03_fertility_and_housing_supply/Notes_old`


