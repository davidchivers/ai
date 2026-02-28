# Math + Code Referee Report
**Date:** 2026-02-19
**Project:** 02_Nimbyism_and_Housing_Supply
**Paper source of truth:** `Gross and Chivers (2025) NIMBYism and the Housing Supply.lyx`
**Code audited:** `code/steadystate/` (MATLAB), `code/data/` (Stata)
**Auditor:** Claude Code (automated static audit — no compile/run tests executed)

---

## Scope

This is a static code audit comparing the MATLAB steady-state solvers and Stata data pipeline against the paper's stated model, equations, and calibration table. Seven MATLAB files and six Stata do-files were read in full.

The paper's numerical solution section (Section [solution algorithm]) and calibration table are used as the reference standard. Where a parameter or equation appears in both, both are quoted.

**Not in scope (this round):**
- `code/codes_abb/` (quantitative results / impulse responses) — flagged for a separate audit
- Runtime behaviour (no MATLAB/Stata execution environment available)
- The `.lyx` file references in Section numbers below are approximate — verify exact locations in the source before citing to the referee

---

## High-Level Math Audit (Paper First)

This section checks internal model logic and equation coherence in the paper before code crosswalk.
Source checked: `projects/02_nimbyism_and_housing_supply/Gross and Chivers (2025) NIMBYism and the Housing Supply.lyx`.

### Summary by severity

| ID | Severity | Description |
|---|---|---|
| HLM1 | **High** | Median-voter equilibrium conditions are not fully justified given acknowledged non-monotonic preferences |
| HLM2 | **Medium** | Mixed local-derivative vs finite-difference voting objects (`\partial V/\partial p` vs `V(p+\epsilon)-V(p)`) |
| HLM3 | **Medium** | Time/notation switching for prices and assets (`p_t` vs `p_t^h`; borrowing constraint timing) |
| HLM4 | **Medium** | Calibration sentence does not match listed parameter vector interpretation |
| HLM5 | **Low** | Mathematical exposition/notation typos (e.g., “Medan Voter Theorem”) |

### HLM1 — HIGH: Median-voter regularity conditions are not established

**Evidence:** The paper applies a median-voter condition  
`∫ g(s; p_t^h) Θ(s; p^h) ds = 0.5`  
while also noting (footnote in the same section) that preferences over house prices are not monotonic for some households.

**Inference:** Non-monotonic or non-single-peaked preferences can break the standard existence/uniqueness logic behind a one-dimensional median-voter equilibrium. The current text states the equilibrium condition but does not provide a sufficient condition under which it is valid in this model.

**Requested clarification:** Add a short proposition/assumption stating when the voting aggregator is monotone in price (or explain that equilibrium is computed numerically as a root without uniqueness claim).

### HLM2 — MEDIUM: Mixed marginal and discrete voting objects

**Evidence:** The narrative describes voting in marginal terms (`∂V/∂p`), while the formal voting rule uses a finite perturbation:
`V_j(s; p^h + ε^p) - V_j(s; p^h) + σ ≥ 0`.

**Inference:** These are equivalent only in a local limit (`ε^p → 0`) or under smoothness assumptions. That bridge is not currently spelled out.

**Requested clarification:** State explicitly whether `ε^p` is an infinitesimal local perturbation used for numerical derivative approximation, or a finite policy step.

### HLM3 — MEDIUM: Time/notation consistency can be tightened

**Evidence:** The paper alternates between `p_t` and `p_t^h` for house price, and presents borrowing/asset constraints in both static and recursive forms (`a_t` and `a_{t+1}` contexts).

**Inference:** This is likely not a model error, but it increases risk of misreading the state-control timing in the Bellman problem.

**Requested clarification:** Add one compact timing convention paragraph (start-of-period states, within-period controls, end-of-period transitions), and normalize house-price notation.

### HLM4 — MEDIUM: Calibration prose does not align with parameter-vector labeling

**Evidence:** The calibration sentence labels a subset as “discount rate, rental discount, utility housing weight and real estate markup” but the listed calibrated vector includes `β, σ, ζ, w̄, ψ, φ^rent`.

**Inference:** The list includes additional parameters (non-financial preference and bequest terms) beyond the prose description.

**Requested clarification:** Rewrite the sentence to explicitly classify all calibrated parameters by block (preferences, bequests, rental sector, voting wedge).

### HLM5 — LOW: Minor mathematical exposition typos

**Evidence:** Typographic/label errors in math-adjacent text (example: “Medan Voter Theorem”).

**Inference:** Low technical risk, but these reduce referee confidence in formal sections.

**Requested clarification:** Clean math-section proofreading pass before submission.

### High-Level Math Verdict

No clear algebraic sign error was found in the core household Bellman setup, tenure-choice decomposition, or rental zero-profit equation in this high-level pass. The main outstanding math risk is the equilibrium-voting regularity argument (HLM1), followed by notation/timing clarity (HLM2-HLM4).

---

## Findings: MATLAB (SteadyState)

### Summary by severity

| ID | Severity | Description |
|---|---|---|
| M1 | **Critical** | Housing weight ζ: paper = 0.75, code = 0.50 |
| M2 | **Critical** | Discount factor β: paper = 0.978, multiple code files use 0.80 |
| M3 | **Critical** | Non-financial preference σ = −2.4 not found in any code file |
| M4 | **Critical** | Rental price hardcoded; zero-profit equation not implemented |
| M5 | **High** | Retirement age: paper = 65, `SolveSS.m` uses 60 |
| M6 | **High** | Risk-free savings rate: paper = 2%, `SolveSS.m` uses 3% |
| M7 | **High** | Bequest parameters: paper ψ = 10, w̄ = 150; code bequestweight = 0.72 |
| M8 | **High** | Transaction cost ka inconsistent across files (0.06, 0.07, 0.09) |
| M9 | **High** | Rental discount θ^rent inconsistent across files (0.85 vs 0.90) |
| M10 | **High** | Utility form switches between CRRA and log across solver files |
| M11 | **Medium** | Housing grid size J inconsistent across files (10, 20, 40) |
| M12 | **Medium** | Age range: `SolveSS_function.m` extends agemax to 90; paper says 80 |
| M13 | **Medium** | Notation reversal: paper ζ = housing weight; code ω = consumption weight |
| M14 | **Low** | `IncomeProcess.m` is an incomplete fragment (ends at line 104) |
| M15 | **Low** | `sigma` declared in `SolveSS.m` line 18 but never used |

---

### M1 — CRITICAL: Housing weight in utility function

**Paper (Eq. 2):**
```
u(c_t, h_t) = [(c_t^(1−ζ) · h_t^ζ)^(1−γ)] / (1−γ)     ζ = 0.75
```
Housing receives weight ζ = 0.75; consumption receives weight 1−ζ = 0.25.

**Code (`SolveSS.m` line 15; `SolveSS_iter.m` line 14):**
```matlab
omega = 0.5
value_plane = (C^omega * (H + theta_r*R)^(1-omega))^(1-eta) / (1-eta)
```
Here `omega` is the *consumption* weight, so the housing weight is `1-omega = 0.50`.

**Discrepancy:** Housing weight is 0.75 in the paper but 0.50 in these files (a difference of 25 percentage points). Additionally, the notation is reversed: the paper's ζ is the housing weight, while the code's `omega` is the consumption weight. The correct mapping would be `omega = 1 - ζ = 0.25`, not 0.50.

**Impact:** This affects the optimal housing-to-consumption ratio across the entire life cycle, ownership rates, and housing price calibration. All calibrated moments are sensitive to this parameter.

**Decision needed:** Confirm the calibrated value of ζ. If ζ = 0.75 is correct, the code should use `omega = 0.25` (or equivalently rewrite as `h^0.75 * c^0.25`).

---

### M2 — CRITICAL: Discount factor β

**Paper (calibration table):** β = 0.978.

**Code:**

| File | Line | Value |
|---|---|---|
| `SolveSS.m` | 17 | `beta = 0.80` |
| `SolveSS_function.m` | 16 | `beta = 0.98` |
| `SolveSS_iter.m` | 16 | `beta = 0.80` |
| `SolveSS_Loop.m` | 20 | `beta = 0.80` |

`SolveSS_function.m` (the optimisation wrapper) uses 0.98 ≈ 0.978, which matches the paper. However `SolveSS.m`, `SolveSS_iter.m`, and `SolveSS_Loop.m` all use β = 0.80, which is far below the calibrated value and implies implausibly low patience.

**Impact:** β = 0.80 vs 0.978 is a large difference. It dramatically compresses life-cycle saving and housing accumulation. Any quantitative results generated from `SolveSS.m` directly (the baseline standalone script) would not correspond to the calibrated model.

**Decision needed:** Confirm which file represents the calibrated model used for published results. Update `SolveSS.m` and `SolveSS_iter.m` to the calibrated β = 0.978.

---

### M3 — CRITICAL: Non-financial preference parameter σ not in code

**Paper:** σ = −2.4 is a key structural parameter (Eq. 13–15). It captures non-financial motives for voting (congestion, ideology). The paper states it is calibrated to ensure the voting equilibrium in 2000 matches data, and that it shifts approximately 15% of voters toward supply.

**Code:** No file in `code/steadystate/` contains any variable named `sigma`, `s_sigma`, or any other parameter with value −2.4. The voting implementation in `SolveSS.m` (lines 393–474) uses:
```matlab
vote = sign(valuefunction_dp - valuefunction) * population_density
```
This computes financial voting preferences only, with no additive non-financial term.

**Impact:** Without σ, the voting equilibrium is determined solely by financial incentives. This is a different model from what is described in the paper and will generate a different equilibrium price. The 15% voter shift attributed to σ is absent.

**Decision needed:** Was σ dropped from the code intentionally (e.g., absorbed into a price normalisation)? If not, it must be added as an additive term in the voting indicator before the median voter calculation.

---

### M4 — CRITICAL: Rental price hardcoded; zero-profit condition absent

**Paper (Eq. 12):** Rental price is determined endogenously:
```
p_t^rent = φ^rent + r_t^a · p_t^h − Δp_(t+1)^h
```
Real estate firms break even; rent covers operating cost plus borrowing cost minus expected capital gains.

**Code (`SolveSS.m` line 13):**
```matlab
r_price = 0.09
```
Rental price is a fixed constant (9%) not derived from the equilibrium condition. There is no code that computes `r_price` as a function of `a_price`, `rbPos`, or expected appreciation.

**Impact:** The rental price does not respond to changes in the house price or interest rate. This breaks the equilibrium link between the rental and ownership markets and means the model does not implement the zero-profit condition stated in the paper.

**Decision needed:** Either implement Eq. 12 explicitly, or document that 0.09 is a pre-computed equilibrium value at the baseline calibration (and explain why dynamic updating is not needed).

---

### M5 — HIGH: Retirement age

**Paper:** Working life J_ret = 41 periods, corresponding to age 65 (entry at 25, retire at 25+41−1 = 65).

**Code (`SolveSS.m` line 34):**
```matlab
agepension = 60
```
Retirement at age 60 implies J_ret = 35 periods, five years shorter than the paper.

**Impact:** Affects the lifecycle earnings profile, savings accumulation, and the age at which households transition from renters to owners. Pension income replaces 50% of final wage in the paper; a 5-year earlier retirement means 5 fewer high-income years, affecting calibration fit.

**Decision needed:** Confirm the intended retirement age. `SolveSS_Loop.m` does not set `agepension` explicitly — verify it inherits the same 60.

---

### M6 — HIGH: Risk-free savings rate

**Paper (calibration table):** r^a = 0.02 (2%).

**Code (`SolveSS.m` line 10):**
```matlab
rbPos = 0.03
```
Rate is 3%, one percentage point above the calibrated value.

`SolveSS_function.m` takes `rbPos = x(2)` as an optimised input, so the optimiser may converge to 0.02 — but `SolveSS.m` (standalone baseline) is hardcoded at 0.03.

**Impact:** Affects all saving decisions, the rental price via Eq. 12, and the mortgage spread. The paper's spread of 3pp implies r_mortgage = 0.05; with rbPos = 0.03, the mortgage rate would be 0.06 if the spread is maintained, or the spread must be adjusted.

---

### M7 — HIGH: Bequest parameters

**Paper (calibration table):** ψ = 10, w̄ = 150.

**Paper (Eq. 4):**
```
v(w) = ψ · [(w + w̄)^(1−γ)] / (1−γ)
```

**Code (`SolveSS.m` lines 23–24):**
```matlab
bequestweight1 = 0.72    % = 0.9 * 0.8 = beta * something
bequestweight2 = 0.72
```
The bequest term implemented is:
```matlab
bequestweight1 * (1 + Bequest/bequestweight2)^(1-eta)
```

The paper's ψ = 10 is nowhere near 0.72. The normalisation `(1 + Bequest/w̄)` could be algebraically equivalent to `(w̄ + Bequest)^(1−γ) / w̄^(1−γ)` (i.e., normalised by w̄^(1−γ)), but bequestweight2 = 0.72 ≠ 150 = w̄. Neither parameter value matches.

**Impact:** Bequest motive affects end-of-life housing decisions and the terminal condition of the value function. Misstated bequest parameters affect household wealth accumulation and the calibration match.

**Decision needed:** Reconcile the parameterisation. Either the code normalises differently from the paper (document the algebraic equivalence), or the values are wrong.

---

### M8 — HIGH: Transaction cost inconsistent across files

**Paper:** F^sell = 0.07 (7%).

| File | Line | Value |
|---|---|---|
| `SolveSS.m` | 22 | `ka = 0.07` ✓ |
| `SolveSS_function.m` | 18 | `ka = 0.06` ✗ |
| `SolveSS_Loop.m` | 22 | `ka = 0.09` ✗ |

Two of three function files use a different value from the paper. F^sell enters the budget constraint for adjusting owners (Eq. 7 and Eq. 10) and affects the decision margin between adjusting and non-adjusting.

**Decision needed:** Standardise all files to the calibrated value of 0.07, or document if specific files are used for sensitivity analysis.

---

### M9 — HIGH: Rental discount θ^rent inconsistent across files

**Paper (calibration table):** θ^rent = 0.90 (sourced from Mian et al., 2017).

| File | Line | Value |
|---|---|---|
| `SolveSS.m` | 16 | `theta_r = 0.90` ✓ |
| `SolveSS_function.m` | 15 | `theta_r = 0.85` ✗ |
| `SolveSS_Loop.m` | 19 | `theta_r = 0.85` ✗ |

θ^rent governs the utility discount for renting vs. owning and directly affects the rent vs. own margin. A value of 0.85 vs 0.90 shifts the ownership threshold.

---

### M10 — HIGH: Utility form inconsistent across solver files

| File | Utility form |
|---|---|
| `SolveSS.m` | CRRA: `(c^ω · h^(1−ω))^(1−η) / (1−η)` with η=2 |
| `SolveSS_iter.m` | CRRA: same form, η=2 |
| `SolveSS_function.m` | Log: `log(c) + s_h*log(h + θ_r*R)` |
| `SolveSS_Loop.m` | Log: same form |

The paper specifies a single CRRA utility function (Eq. 2) with γ=2. Log utility is the limiting case γ→1 and is a different model. If `SolveSS_Loop.m` is the production grid-search solver, and it uses log utility while the paper states CRRA γ=2, the equilibrium prices reported in the paper cannot have come from that file with those settings.

**Decision needed:** Identify which file was actually used to produce the published results. Document this in a README.

---

### M11 — MEDIUM: Housing grid inconsistent across files

| File | Housing grid J | housingmax |
|---|---|---|
| `SolveSS.m` | 40 | 14 |
| `SolveSS_function.m` | 10 | ~15 |
| `SolveSS_iter.m` | 20 | 25 |
| `SolveSS_Loop.m` | 20 | 30 |

The paper does not report the grid size used for published results. A grid of J=10 is very coarse and likely too sparse for accurate value function approximation. The grid maximum also varies from 14 to 30, changing which housing quantities are accessible to households.

**Decision needed:** Document which grid parameters were used for the final published results.

---

### M12 — MEDIUM: agemax = 90 in SolveSS_function.m

**Paper:** Agents live from age 25 to 80 (J = 56 periods).

**Code (`SolveSS_function.m` line 26):**
```matlab
agemax = 90
```
This extends the model life by 10 years beyond the paper. With `dage = 5` in that file (coarser age grid), the terminal condition and bequest calculation apply at a different age than stated.

---

### M13 — MEDIUM: Notation reversal between paper and code

The paper uses ζ as the **housing** weight (ζ = 0.75 → housing gets 75%).
The code uses `omega` as the **consumption** weight (`omega = 0.50` → consumption gets 50%).

The correct code translation of the paper's notation would be `omega = 1 - zeta = 0.25`. Instead, the code uses `omega = 0.5`, which represents a different model (see M1) and a different naming convention simultaneously. This creates a risk of silent errors when re-parameterising.

---

### M14 — LOW: IncomeProcess.m is an incomplete fragment

`IncomeProcess.m` ends at line 104, mid-construction of lower-diagonal arrays for an income transition matrix. There is no return statement, no assembled sparse matrix, and no output. The file cannot be called as a standalone function. It appears to be a copy-paste fragment that was never completed.

---

### M15 — LOW: Unused variable `sigma` in SolveSS.m

`SolveSS.m` line 18 declares:
```matlab
sigma = 1.5
```
This variable is never referenced again in the file. The name coincides with the paper's non-financial preference parameter σ = −2.4 (see M3), but the value differs and it is unused.

---

## Findings: Stata (Data Pipeline)

### Summary by severity

| ID | Severity | Description |
|---|---|---|
| S1 | **Critical** | All merges drop `_merge` without tabulation — unmatched rates unknown |
| S2 | **Critical** | Impossible logical condition in `2 citystateweights.do` |
| S3 | **High** | 600+ lines of manual `replace share = 0` — undocumented selection |
| S4 | **High** | Hardcoded machine-specific paths throughout; code not portable |
| S5 | **High** | IV regressions in `5 combinepermits.do` — no first-stage F-statistics reported |
| S6 | **Medium** | Lag construction duplicated between files 3 and 5 |
| S7 | **Medium** | `statefips / 100` conversion (file 3, line 21) — potential precision issue |
| S8 | **Medium** | `predict own_predicted` created but never used (file 5, line 99) |
| S9 | **Low** | Commented-out Wharton merge in `merge data.do` — abandoned analysis path |
| S10 | **Low** | Age bins have overlapping boundary at age 30 (may be intentional) |

---

### S1 — CRITICAL: All merges silently drop unmatched observations

Every merge in the pipeline immediately drops `_merge` without tabulating match rates:

```stata
merge m:1 statefips year using birthrates_updated    // file 3, line 25
drop _merge                                           // file 3, line 26

merge m:m metarea using weights, keepusing(sumcity)  // file 3, line 41
drop _merge                                           // file 3, line 42

merge m:1 metarea year using tenurerates             // file 3, line 47
drop _merge                                           // file 3, line 48
```

Same pattern in files 5 and 6. There is no `tab _merge`, `assert _merge == 3`, or any check for unmatched observations. Any silently dropped metropolitan areas or years will not appear in the data without re-running and inserting checks.

**Impact:** The final panel used in regressions may exclude metropolitan areas or years that failed to match, without any record of which ones or why. This is a replication risk.

**Fix:** Add `tab _merge` before every `drop _merge`. For key merges, add `assert _merge == 3` or document the expected match rate.

---

### S2 — CRITICAL: Impossible logical condition in file 2

`2 citystateweights.do` contains at least one impossible condition in the manual override block (around line 1234):
```stata
drop if metarea == 60 & bpl == 13 & bpl == 45
```
A variable cannot simultaneously equal 13 and 45. This condition evaluates to false for all observations and silently does nothing. It may indicate a missing `|` (OR) operator:
```stata
drop if metarea == 60 & (bpl == 13 | bpl == 45)
```

**Impact:** The intended observations are not dropped, potentially leaving outlier or erroneous weight cells in the instrument. This affects weighted birth rate construction and all downstream regressions.

**Fix:** Review the full manual override block (lines 615–1234) for similar errors. Replace `&` with `|` where bpl conditions are clearly alternatives.

---

### S3 — HIGH: 600+ lines of manual `replace share = 0` with no documentation

`2 citystateweights.do` lines 615–1234 contain over 600 lines of statements of the form:
```stata
replace share = 0 if metarea == [X] & bpl == [Y]
```
There is no comment explaining the selection criterion (small cell size? data error? boundary case?). The selection appears hand-coded rather than rule-based (e.g., `replace share = 0 if count < 5`).

**Impact:** The shift-share instrument is constructed from these weights. Undocumented exclusions affect instrument validity and cannot be assessed by a reader or replicator.

**Recommendation:** Replace the manual block with a programmatic rule (e.g., `replace share = 0 if count < threshold`) and document the threshold. If the manual overrides are genuinely case-specific, add a comment to each explaining why.

---

### S4 — HIGH: Hardcoded machine-specific file paths

Multiple files contain paths tied to specific machines and users:

| File | Line | Path |
|---|---|---|
| `1 tenurechoices.do` | 1 | `/Users/igro0002/Dropbox/Zac and David/data/usa_00009.dta` |
| `4 importexcel .do` | 2 | `/Users/igro0002/Dropbox/Zac and David/data/Buildings/...` |
| `4 importexcel .do` | 13 | `/Users/igro0002/Dropbox/Zac and David/data/buildingcrosswalk.dta` |
| `merge data.do` | 6–7 | `C:\Users\Dave_\Dropbox\Zac and David\Data` |

Code cannot be run by any collaborator or replicator without modifying these lines. The mixture of macOS (`/Users/igro0002/`) and Windows (`C:\Users\Dave_\`) paths suggests the pipeline was developed across machines without standardisation.

**Fix:** Replace all hardcoded paths with a single global macro at the top of each file, e.g.:
```stata
global datadir "C:\Users\Dave_\Dropbox\Zac and David\Data"
use "$datadir/usa_00009.dta"
```

---

### S5 — HIGH: IV regressions with no instrument diagnostics

`5 combinepermits.do` (lines 103–118) runs 50 IV regression specifications in nested loops varying horizon, lead, and lag. No first-stage F-statistics are reported, no Kleibergen-Paap or Cragg-Donald statistics, and no overidentification tests. The outlier exclusion threshold `abs(totalunits[horizon]growth) < 2` (lines 107, 112, 116) is not documented.

**Impact:** Without instrument strength diagnostics, it is not possible to assess whether the 50 IV specifications are valid. Weak instruments would invalidate all estimates.

**Recommendation:** Add `estat firststage` (or equivalent) to each IV loop and export first-stage F-statistics alongside point estimates in `Regressions.csv`.

---

### S6 — MEDIUM: Lag construction duplicated between files 3 and 5

`3 birthrates.do` constructs lags `l1bw` through `l50bw` (lines 55–119).
`5 combinepermits.do` reconstructs lags `l1bw` through `l65bw` (lines 13–77).

If the panel changes between the two files (due to the merge with `buildingcrosswalk.dta` in file 5), the lags may be computed over a different `tsset` structure. This is not a logical error but creates a maintenance risk: any change to the lag range in file 3 must be replicated manually in file 5.

**Recommendation:** Either carry lags through from file 3 (and only extend in file 5), or move all lag construction to a single location.

---

### S7 — MEDIUM: statefips / 100 conversion

`3 birthrates.do` line 21:
```stata
replace statefips = statefips / 100
```
IPUMS birth-state codes are typically in the range 1–950, while standard FIPS codes are 1–56. Dividing by 100 converts IPUMS codes like 100 (Alabama) to 1.00. However, this integer division via floating point may introduce precision issues for states whose IPUMS codes are not round multiples of 100 (e.g., the District of Columbia at code 98 → 0.98, not a valid FIPS code).

**Recommendation:** Use an explicit crosswalk (IPUMS provides one) rather than arithmetic conversion. Verify that all resulting values correspond to valid FIPS codes before merging.

---

### S8 — MEDIUM: Predicted variable created but unused

`5 combinepermits.do` line 99:
```stata
predict own_predicted
```
This variable is created after a regression of home ownership on lagged birth rates and fixed effects, but `own_predicted` never appears in any subsequent command in the file. It is not saved to output.

---

### S9 — LOW: Commented-out Wharton data merge in merge data.do

Lines 28–32 of `merge data.do` contain a commented-out merge with a Wharton land use regulation dataset. No explanation is given for why it was removed. The Wharton WRLURI is listed in the paper as a potential instrument for housing supply. If the Wharton data was ultimately excluded, this should be documented.

---

### S10 — LOW: Age bin boundary overlap

`1 tenurechoices.do` creates:
```stata
age20_30 = 1 if age >= 20 & age <= 30     // lines 88–91
age30_40 = 1 if age >= 30 & age <= 40     // lines 93–96
```
Age 30 is included in both bins. This may be intentional (age 30 is a natural boundary year), but it can cause double-counting if the bins are used in regression or summary tables. Confirm and document.

---

## Confirmed Matches

The following items agree between paper and code (in at least the primary file `SolveSS.m`):

- **LTV ratio m:** Paper m = 0.90 → Code `CC = 0.90` (`SolveSS.m` line 26) ✓
- **Risk aversion γ:** Paper γ = 2 → Code `eta = 2` (`SolveSS.m`, `SolveSS_iter.m`) ✓
- **Transaction cost in primary file:** Paper F^sell = 0.07 → Code `ka = 0.07` (`SolveSS.m` line 22) ✓
- **Rental discount in primary file:** Paper θ^rent = 0.90 → Code `theta_r = 0.90` (`SolveSS.m` line 16) ✓
- **Life span:** Paper J = 56 (age 25–80) → Code `agemin=25, agemax=80, dage=1` (`SolveSS.m`) ✓
- **Borrowing constraint form:** Paper a_t ≥ −m·h·p_t^h → Code `-b > a*P_h*CC` (`SolveSS.m` line 144–147) ✓
- **Voting direction:** Paper: vote to restrict supply if value rises with price → Code: `sign(valuefunction_dp - valuefunction)` (`SolveSS.m` lines 393–474) ✓ (financial component only; see M3)
- **Backward induction structure:** Paper solution algorithm steps 1–6 → Code backward loop from `agemax` to `agemin` followed by forward distribution simulation ✓

---

## Main Model-Risk Issues (could materially alter results)

The following discrepancies are most likely to affect the quantitative results if unresolved:

1. **M1 (Critical):** Housing weight ζ = 0.75 in paper vs 0.50 in code — large effect on consumption-housing substitution and ownership rates.
2. **M2 (Critical):** β = 0.978 in paper vs 0.80 in primary solver — large effect on life-cycle savings and housing accumulation.
3. **M3 (Critical):** σ = −2.4 entirely absent from code — changes the voting equilibrium and the calibrated house price level.
4. **M4 (Critical):** Rental price hardcoded at 9% rather than derived from zero-profit condition — breaks the rental-ownership arbitrage.
5. **S1 (Critical):** Silent merge failures in Stata pipeline — may silently exclude cities or years from the regression sample.

---

## Referee Recommendation (Code and Replication)

**Recommendation:** Major code revision before treating the current repository as a replication-ready implementation of the published model.

This recommendation is based on observed implementation mismatches (M1-M4), parameter inconsistencies across solver files (M5-M10), and missing data-pipeline diagnostics (S1-S5). As an inference, if the published quantitative results were produced from a different private code branch, the immediate requirement is a documented production-file mapping and a clean reproducible pipeline in this repository.

Minimum acceptance checklist for a replication package:
- Identify and document the exact production solver file(s) and calibration used for published tables/figures.
- Reconcile utility, discounting, voting, and rental-price equations with the paper, or explicitly document approved deviations.
- Add merge diagnostics and path standardization to Stata scripts and re-run to regenerate key regression outputs.
- Publish a short `README_code.md` that maps each paper equation block to code locations.
- Run and archive one end-to-end reproducibility test from raw inputs to final outputs.

---

## Suggested Immediate Action Order

1. Identify which MATLAB file was actually used to generate the published results and parameter values. Create a `README_code.md` in `code/steadystate/` documenting this.
2. Reconcile β, ζ (ω), θ^rent, and ka in `SolveSS.m` and `SolveSS_iter.m` against the calibration table.
3. Add σ = −2.4 to the voting block in the primary solver file.
4. Implement the rental zero-profit equation (Eq. 12) or document why the hardcoded value is a valid pre-computed approximation.
5. In Stata: add `tab _merge` before every `drop _merge` and fix the impossible condition in `2 citystateweights.do`.
6. Document the 600-line manual weight override block in file 2.
7. Plan a separate audit of `code/codes_abb/` (the quantitative results code), which was not covered here.

---

## Outstanding Items

| # | Item | Owner | Action |
|---|---|---|---|
| O1 | `code/steadystate/` is the likely production codebase, but parameter values in `SolveSS.m` differ from the calibration table (M1–M9). Verify whether `SolveSS.m` is the production file or a development variant, and document this in a `README_code.md`. | Authors | Confirm + document |
| O2 | Is housing weight ζ = 0.75 or 0.50 in the calibrated model? | Authors | Confirm; reconcile code |
| O3 | Was σ intentionally dropped from the code? | Authors | Confirm; add if missing |
| O4 | Is r_price = 0.09 a pre-computed equilibrium value or an error? | Authors | Confirm + document |
| O5 | Retirement age 60 or 65? | Authors | Confirm; update code |
| O6 | Reconcile bequest parameters (ψ, w̄ vs bequestweight1/2) | Authors | Algebraic equivalence or correction |
| O7 | `Codes_ABB/` audit (quantitative results, IRFs, calibration) | Auditor | Schedule separate pass |
| O8 | Fix impossible bpl condition in `2 citystateweights.do` | Code author | Fix & rerun weights |
| O9 | Add merge diagnostics to all Stata merge commands | Code author | Add before next run |
| O10 | Document / replace manual share = 0 block (600+ lines) | Code author | Programmatic rule or comments |
