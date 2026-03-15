# UBI and Necessity Entrepreneurship — Write-up

**Date:** 2026-03-15
**Status:** Scan complete (200 iter, directional). Not fully converged.
**Branch:** fertility-first-birth-empirical-bridge

---

## 1. The question

Does a Universal Basic Income reduce necessity entrepreneurship?

The intuition from the model's partial equilibrium is yes: UBI raises the value
of the unmatched state, compressing the necessity band
`h_hat_unmatched < h < h_hat_employed`. Fewer people get pushed into
entrepreneurship because being jobless is less costly.

The scan tests this intuition in general equilibrium.

---

## 2. What we did

Added a universal lump-sum transfer (`ubi_transfer_level * w0_tmp`) to
`asset_income` in all occupational states — employed, unemployed (UI and
no-UI), and entrepreneur. This is manna-from-heaven UBI: unfunded, isolating
the outside-option channel only.

Four steady-state cases against the case 147 benchmark:

| Case | UBI (fraction of mean wage) |
|------|-----------------------------|
| 148  | 0.20                        |
| 149  | 0.40 (equal to current UI rate) |
| 150  | 0.60                        |
| 151  | 0.80                        |

All other parameters identical to case 147. Steady-state only (no transition).
200 GE iterations (hit cap — not fully converged, but direction stable).

---

## 3. Results

| | Baseline (147) | UBI=0.2 (148) | UBI=0.4 (149) | UBI=0.6 (150) | UBI=0.8 (151) |
|---|---|---|---|---|---|
| **theta** | 0.658 | 0.608 | 0.601 | 0.600 | 0.597 |
| **entr share** | 17.6% | 19.6% | 19.8% | 19.9% | 20.0% |
| **self-emp share** | 57.1% | 57.9% | 57.9% | 57.7% | 57.1% |
| **employer share** | 42.9% | 42.1% | 42.1% | 42.3% | 42.9% |
| **avg firm size (n)** | 6.23 | 5.33 | 5.22 | 5.19 | 5.22 |
| **avg capital (k)** | 99.3 | 82.2 | 78.7 | 77.1 | 76.2 |

---

## 4. What happened and why

**The prediction was wrong. Entrepreneurship rose, not fell.**

The general equilibrium mechanism that dominates is a vacancy-creation channel:

1. UBI raises income for all households, including workers.
2. Workers become more selective — they demand better matches and are less
   desperate to accept any available job.
3. Firms respond by posting fewer vacancies. Labour market tightness (theta)
   falls by roughly 9%, from 0.658 to ~0.60.
4. With fewer vacancies relative to unemployed workers, the job-finding rate
   falls. Being unmatched becomes a worse state in terms of search prospects,
   even if the consumption floor is higher.
5. The deterioration in job-finding pushes more workers into entrepreneurship.
   The GE outside-option effect works in the opposite direction to the
   partial-equilibrium consumption-floor effect, and it dominates.

This is a clean example of a standard GE reversal: the partial-equilibrium
prediction (better floor → fewer necessity entrants) is overturned by the
general-equilibrium response of the labour market.

**Secondary patterns:**

- Average firm size falls (6.23 → ~5.2), consistent with the new entrants
  being low-scale necessity types. The composition of entrepreneurship
  deteriorates even as its level rises.
- Self-employed share rises moderately at UBI = 0.2–0.4 and then retreats
  at UBI = 0.8, where employer entry ticks back up. At high UBI levels,
  some opportunity entrepreneurs may be entering — the income floor enables
  riskier projects even as labour market tightness further worsens.
- Capital per entrepreneur falls monotonically (99.3 → 76.2), consistent
  with a compositional shift toward lower-productivity entrants.

---

## 5. Key caveat

The GE iteration did not converge. All four cases hit the 200-iteration cap
with theta still drifting ~0.5–1% per iteration. The oscillation is caused
by the large magnitude of the UBI shock — the equilibrium is far from the
baseline and the simple fixed-point iteration is slow to damp.

The direction is reliable. The precise magnitudes (e.g. theta = 0.60 vs
0.605) should be treated as approximate.

To get fully converged values, the right fix is adaptive GE dampening
(`-AdaptiveGE` flag in the run script), not simply more iterations.

---

## 6. What this means for the paper

### Option A — One paragraph + table row (low effort, recommended first)

Add a short policy counterfactual paragraph to the existing policy section.
Something like:

> "A natural policy question is whether a universal basic income (UBI) —
> a lump-sum transfer paid regardless of employment status — would reduce
> necessity entrepreneurship by raising the value of being unmatched. Our
> model suggests the opposite: in general equilibrium, a UBI of 20–80 percent
> of mean wages raises entrepreneurship by 2–3 percentage points relative
> to baseline. The mechanism is a vacancy-creation channel. UBI raises
> workers' outside option, reducing firms' incentive to post vacancies.
> Labour market tightness falls roughly 9 percent, worsening job-finding
> odds and pushing more workers into necessity entry. The average firm
> entering under UBI is smaller and less capital-intensive, consistent with
> the compositional deterioration the model predicts for weaker outside
> options. The policy implication is that income-floor transfers alone do
> not reduce necessity entrepreneurship if they simultaneously crowd out
> vacancy creation."

This needs only the scan results and a citation to the output files.
No additional computation required.

### Option B — Full policy section (medium effort)

Add a dedicated subsection comparing:
1. Lower UI (the paper's current counterfactual)
2. Universal UBI (the new result)
3. Revenue-neutral UBI (UBI funded by proportional labour income tax)

The revenue-neutral version would additionally compress vacancy creation
through the tax wedge, likely strengthening the GE channel. This would
require:
- A tax-funded UBI case (modify the model to levy a proportional income
  tax equal to the UBI outlay — approximately `ubi_level * entr_share`
  of total income)
- Convergence via adaptive GE
- Probably 2–4 additional model runs

This would make the policy section genuinely novel and more rigorous, but
adds scope at a time when the referee wants the paper narrower.

### Option C — Standalone policy note or working paper (high effort)

The GE reversal is interesting enough to write up separately as a short
policy note (10–15 pages). Would need:
- Full convergence
- Revenue-neutral version
- A comparison to the UI literature (Hombert et al., Hurst & Pugsley)
- Some empirical motivation (Alaska Permanent Fund, Finland pilot)
- Probably not worth the time until the main paper is through revision

---

## 7. Recommended path

**Now:** Write the paragraph (Option A). File the scan results. Do not run
more model cases.

**After R&R:** If a referee asks about policy implications or UBI
specifically, implement Option B with full convergence via adaptive GE.

**Later:** If the paper generates enough interest, Option C as a follow-on.

---

## 8. Technical notes for replication

**Source file:** `UBI_extension/source/main_2025_v1_ubi_extension.cpp`

Changes relative to canonical `main_2025_v1_case113_self_employment.cpp`:
- Line ~103: `double ubi_transfer_level = 0.0;` added as global
- Lines ~462–466: `CFV_UBI_TRANSFER` env var parsed at startup
- Line ~980: worker branch `asset_income` adds `ubi_transfer_level * w0_tmp`
- Line ~1062: entrepreneur branch `asset_income` adds `ubi_transfer_level * w0_tmp`
- Cases 148–151 added after case 147

**To rerun with adaptive GE (recommended for convergence):**
```powershell
powershell -ExecutionPolicy Bypass -File run_ubi_scan.ps1 `
  -SingleCase 149 -SkipTransition -AdaptiveGE -MaxIterAgg 500 `
  -RunTag "ubi040_adaptive"
```

**To rerun at finer grid around UBI=0.3 (between 148 and 149):**
Use `CFV_UBI_TRANSFER` env var override on case 147:
```powershell
powershell -ExecutionPolicy Bypass -File run_ubi_scan.ps1 `
  -SingleCase 147 -UBITransfer 0.3 -SkipTransition -AdaptiveGE `
  -RunTag "ubi030_adaptive"
```
