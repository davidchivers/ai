# Model Sketch (v0, simple OLG incidence framework)

## 1. Agents and types
- Overlapping generations with periods: young (education decision period) and working life (repayment/tax period), then retirement (optional terminal period with no education payments).
- Individual type `i` includes:
  - Education status `e_i in {G, N}` (graduate/non-graduate), exogenous in v0.
  - Family wealth type `a_i in {H, L}` (high/low parental resources).
  - Earnings path `y_{i,t}` over working years.

## 2. Timing
1. At youth, tuition cost `F` is due for those with `e_i = G`.
2. Financing regime determines whether tuition is loan-financed, tax-financed, or paid upfront.
3. During working years, individuals make repayments/tax contributions according to regime rules.
4. Government budget closes each period/cohort via taxes or subsidy accounting.

## 3. Common accounting object
For each type `i` and regime `r`, define PDV net burden:

`B_i^r = sum_t beta^t * (Payment_{i,t}^r - Transfer_{i,t}^r)`

Compare `B_i^r` across regimes to identify winners/losers.

## 4. Regime-specific rules

### A. Current UK-style tuition loan regime (post-2012 stylised)
- Graduates can borrow tuition `F` (and optionally maintenance in extensions).
- Repayments are income-contingent:
  - `R_{i,t} = phi * max(y_{i,t} - y_bar, 0)`
- Loan balance evolves with interest rate `r_L` and is written off after horizon `T_w`.
- Government subsidy for borrower `i` is the shortfall between loan outlay (plus financing cost) and realised repayments.

Upfront-fee option (wealthy families):
- If allowed, type `a_i = H` may pay `F` at youth and avoid loan participation.
- This can change pool composition and therefore average subsidy of remaining loan borrowers.

### B. Graduate tax regime
- No individual tuition debt.
- Graduates pay surcharge `tau_G * y_{i,t}` (or above threshold variant) for `T_G` years or lifetime.
- Non-graduates do not pay the graduate surcharge.
- Government uses graduate-tax revenue to finance higher-education spending.

### C. General taxation regime
- No tuition debt and no graduate-specific surcharge.
- Tuition financed from broad tax base (e.g., proportional tax `tau_all * y_{i,t}` on all workers).
- Incidence includes non-graduates by construction.

## 5. Budget constraints (minimal form)
- Individual working-period budget:
  - `c_{i,t} + savings_{i,t+1} = (1 - tax_{i,t}^r)*y_{i,t} - repayment_{i,t}^r + (1+r)savings_{i,t}`
- In v0 incidence accounting, we can suppress savings choice and evaluate PDV burdens directly from exogenous earnings profiles.

## 6. Welfare/incidence comparisons
- Primary metric: `Delta B_i^{r,s} = B_i^r - B_i^s`.
- Report by cells:
  - Graduate status (`G/N`).
  - Family wealth type (`H/L`).
  - Earnings quantile/profile.

Interpretation:
- `Delta B_i^{r,s} < 0`: type `i` prefers regime `r` over `s` (lower PDV burden).

## 7. Policy mechanisms to highlight
- Income contingency and write-off create insurance and redistribution in loan regime.
- Upfront payment by wealthy households can alter cross-subsidisation in the loan book.
- Timing matters: identical undiscounted totals can imply different PDV incidence.

## 8. Deliberate simplifications (v0)
- Education choice fixed (no extensive-margin schooling response).
- No equilibrium wage feedback.
- No detailed borrowing constraints beyond wealth-type financing margin.
- Calibration is illustrative, not structural estimation.