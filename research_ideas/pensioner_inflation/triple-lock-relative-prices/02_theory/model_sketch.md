# model sketch

## intuition first
We want a minimal model where a policy-driven increase in pension income raises demand for pensioner-intensive non-tradables. If local non-tradable supply is inelastic, equilibrium non-tradable prices rise relative to tradables. Financing can either be pure redistribution or include a cost-push term through payroll taxes.

## setup
- Groups: workers `W` and pensioners `P`.
- Sectors: tradables `T` and non-tradables `N`.
- Prices: `P_T` (numeraire candidate) and `P_N`.
- Population masses: `n_W`, `n_P`.

### preferences
For each group `g in {W, P}`:
`U_g = alpha_g * ln(C_{gN}) + (1 - alpha_g) * ln(C_{gT})`
with `alpha_P > alpha_W` (pensioners are more N-intensive).

### income and budgets
- Worker disposable income: `Y_W = wL - Tau`.
- Pensioner income: `Y_P = B`.
- Budget constraints:
  - `P_N C_{WN} + P_T C_{WT} = Y_W`
  - `P_N C_{PN} + P_T C_{PT} = Y_P`

`B` is the state pension transfer determined by uprating rule.

### demand system
Log utility implies:
- `C_{gN} = alpha_g Y_g / P_N`
- `C_{gT} = (1 - alpha_g) Y_g / P_T`

Aggregate N demand:
`D_N = n_W alpha_W Y_W / P_N + n_P alpha_P Y_P / P_N`

## supply side
- Tradables: perfectly elastic at world/national price (normalise `P_T = 1`).
- Non-tradables: upward sloping local supply `S_N(P_N)` with elasticity `eta_N` finite.

Equilibrium in N:
`S_N(P_N) = D_N(P_N; B, Tau)`

## comparative statics with pension shock
Differentiate equilibrium implicitly for a marginal increase in `B`:
- Direct effect: raises `Y_P`, increasing `D_N` proportionally to `alpha_P`.
- If financing does not fully neutralise demand and `S_N` is not perfectly elastic, then
`dP_N/dB > 0`.

### case 1: lump-sum tax on workers
Government budget: `n_P dB = n_W dTau`.
Net N-demand effect per unit `dB`:
`(n_P alpha_P - n_W alpha_W dTau/dB)` scaled by incomes/MPC assumptions.
With equal MPCs and `alpha_P > alpha_W`, relative demand for N still tends to rise.

### case 2: labour income tax
Higher labour tax may reduce labour supply/wage income, partly offsetting demand.
Price effect remains positive if pensioner N-demand shift dominates labour-income contraction.

### case 3: employer payroll tax (NIC-like)
Let non-tradables be labour-intensive with unit cost `mc_N = w(1+tau_pay)/A_N`.
Then `dtau_pay > 0` can raise `P_N` directly (cost-push), independent of demand shift.
This creates a second channel to test empirically.

### case 4: debt financing
Short-run demand effect larger (less immediate offset on workers), implying stronger short-run `dP_N/dB` under inelastic `S_N`.
Intertemporal tax effects are deferred.

## propositions (minimal, testable)
### proposition 1
If `alpha_P > alpha_W` and N supply is upward sloping, a pension transfer increase raises the relative price `P_N/P_T`.

Intuition: income is reallocated toward the group with stronger N demand, pushing against limited local capacity.

### proposition 2
The price response is increasing in retiree exposure and decreasing in local N-supply elasticity.

Intuition: larger pensioner mass and tighter local capacity amplify demand pressure on N prices.

### proposition 3
Under payroll-tax financing, N-price inflation includes both demand-composition and marginal-cost components; under lump-sum financing, the marginal-cost component is absent.

Intuition: financing instrument choice changes incidence and observable inflation signatures.

## what would kill the mechanism?
1. Perfectly elastic supply in N (`eta_N -> infinity`): quantity adjusts without price effects.
2. No expenditure-share gap (`alpha_P <= alpha_W`): no systematic shift toward N.
3. Financing fully offsets demand with equal MPCs and identical baskets: little or no net demand-composition effect.
4. Sector fully tradable with national pricing: local retiree exposure should not predict relative local inflation.

## empirical mapping
- `B` maps to pension uprating shocks.
- `alpha` differences map to LCF age-specific expenditure weights.
- `eta_N` proxies map to local labour tightness/business capacity measures.
