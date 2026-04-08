# UI explanation

Date: 2026-03-06

## purpose

This note isolates the explanation for the zero-UI result in the Necessity Entrepreneurship model. It is intended to answer a narrow question clearly:

- why the old zero-UI result should not be used;
- why the corrected zero-UI case now converges;
- what the no-UI experiment is economically doing;
- how much of the result is fiscal closure versus a pure insurance effect.

## 1. The old `101A` archive is not valid zero-UI evidence

The March 4 archive tagged as `ui000_101A` should not be treated as a true no-UI run.

Evidence:

- it records `ui_override=0.00`;
- but its terminal moments are the same as the baseline case-101 run;
- in particular it reproduces baseline entrepreneurship, baseline mean entrepreneur labor demand, baseline `theta`, and the baseline tax rate.

Interpretation:

- the old archive was still running through the pre-fix UI path;
- so the `UI=0.00` label was misleading.

Conclusion:

- the old `101A` archive is best read as a mislabeled baseline-equivalent run, not as a valid sanity check for zero UI.

## 2. What changed before the corrected zero-UI result

The corrected no-UI result only appears after the March 5 fix pass.

The important changes were:

- the UI override path was fixed so case 101 actually runs at the requested `lowerincome_b`;
- interpolation/indexing problems were fixed, which had previously created explosive policy extrapolation;
- numerical guards were added to the aggregate fixed-point loop.

This matters because before those fixes, the solver was often being destabilized by artificial policy spikes rather than by the underlying economics of the no-UI case.

So part of the explanation is purely numerical:

- the fixed-point algorithm can now settle;
- earlier it was often being knocked off course by interpolation and mapping failures.

## 3. What the corrected zero-UI result is

The current credible no-UI logs are:

- endogenous-tax case 101:
  - `calibration/ai_calibration/runtime/data/output/case_1/run_ui_000_endog101_ui000_m40_uioverridefix_20260305_20260305_145727.log`
- fixed-tax case 113:
  - `calibration/ai_calibration/runtime/data/output/case_1/run_baseline_fixedtax113_ui000_m40_homotopyfix_20260306_091442.log`

Terminal outcomes:

- case 101, endogenous tax:
  - `best_tol = 0.00556019`
  - `entr_share = 0.08466`
  - `theta_new = 0.61191`
- case 113, fixed tax:
  - `best_tol = 0.00286268`
  - `entr_share = 0.08262`
  - `theta_new = 0.615773`

Conclusion:

- the corrected model now reaches a zero-UI steady state under both closures;
- so the new convergence is not just a label artifact and not just a single-run coincidence.

## 4. Why the corrected no-UI case converges now

There are two separate questions here:

1. Why does the solver converge at all now?
2. Why is the no-UI equilibrium not especially hard to support once the code is corrected?

### 4.1 Numerical answer

The solver converges now because the main numerical obstacles were removed.

In particular:

- policy interpolation is now consistent with array indexing;
- off-grid interpolation queries are clamped;
- the UI override actually changes the case-101 budget environment;
- invalid or extreme aggregate updates are guarded.

Without those fixes, the code could produce artificial explosions in entrepreneur labor demand and then fail to settle.

### 4.2 Economic answer

Once the numerical problems are removed, the no-UI equilibrium is not a pathological corner.

Setting UI to zero changes the model through two channels:

#### A. Direct insurance channel

- the unemployed state becomes much less attractive;
- non-employment is more painful;
- this shifts households toward work or entrepreneurship.

#### B. Fiscal closure channel

- when UI is removed, transfer spending collapses;
- under endogenous-tax closure, the equilibrium tax rate falls sharply;
- this raises after-tax returns to work and entrepreneurship relative to the baseline.

These two channels move in the same direction:

- both reduce the relative attractiveness of unemployment;
- both push the equilibrium away from the insured non-employment margin.

That is why the corrected no-UI equilibrium is not hard to sustain once the code is behaving properly.

## 5. Why this is not just a tax artifact

The strongest concern is that the no-UI run might converge only because the tax rate falls almost to zero.

That concern is partly right but not fully right.

It is true that in the endogenous-tax case:

- `tau_y` falls from `0.01812` to about `0.00066`;
- UI outlays fall from `8994.34` to `0`.

So the fiscal channel is quantitatively important.

But it is not the whole explanation, because the zero-UI result also converges under fixed tax.

In the fixed-tax case:

- the baseline tax rate is held fixed;
- UI is still removed;
- the model still converges cleanly.

That means:

- tax collapse is not the fundamental reason the solve succeeds;
- it is an amplifying channel, not the whole story.

## 6. What the corrected UI ladder actually shows

Corrected endogenous-tax case-101 ladder:

- `UI=0.40`: entrepreneurship `0.07884`
- `UI=0.05`: entrepreneurship `0.07944`
- `UI=0.00`: entrepreneurship `0.08466`

Tax and transfer movements:

- `tau_y`: `0.01812 -> 0.00277 -> 0.00066`
- `total_lower_out`: `8994.34 -> 1092.55 -> 0`

This pattern is informative.

From `UI=0.40` to `UI=0.05`, the entrepreneurship response is modest:

- `0.07884 -> 0.07944`

From `UI=0.05` to `UI=0.00`, the response becomes materially larger:

- `0.07944 -> 0.08466`

Interpretation:

- small UI cuts do not overturn the occupational structure by much;
- the large movement happens when the unemployed branch effectively loses its insurance value altogether;
- at the same time, transfer financing disappears and the tax rate nearly vanishes.

So the no-UI case should not be described as a pure “risk only” experiment.
It is a joint insurance-removal and fiscal-closure experiment in the endogenous-tax environment.

## 7. What happens to firm size

The corrected no-UI result does not look like a broad expansion of high-scale entrepreneurship.

Mean entrepreneur labor demand by education:

- low education:
  - `8.9299 -> 5.6389`
- medium education:
  - `12.0528 -> 10.8825`
- high education:
  - `21.5651 -> 21.6084`

Interpretation:

- the main response is not more large employer expansion;
- the response is concentrated among low- and medium-education entrepreneurs;
- this looks more like increased lower-scale necessity entry than a general entrepreneurial boom.

## 8. What does not drive the current result

Matching tightness stays broadly similar between baseline and no UI:

- baseline `theta_new = 0.611106`
- no UI `theta_new = 0.611910`

So under the current vacancy-floor environment, the no-UI result is not being driven by a dramatic change in matching tightness.

The active channels are instead:

- lower value of unemployment;
- lower tax financing need;
- composition shifting toward smaller-scale entrepreneurship.

## 9. Clean coauthor version

The shortest accurate summary is:

```text
The older March 4 `101A` archive was not a true zero-UI run, because the UI override was not yet propagating through the standard case-101 path and the terminal moments still matched the baseline. After fixing that path and the earlier interpolation/indexing problems, the model now converges cleanly at zero UI in case 101. This happens for two reasons. First, the numerical failure points that previously destabilized the fixed-point iteration have been removed. Second, zero UI is not a degenerate environment in the corrected model: it lowers the value of unemployment directly and, under endogenous tax closure, also removes the taxes needed to finance UI. The fiscal channel matters quantitatively, but it is not the whole story, because the model also converges at zero UI when the tax rate is held fixed. Quantitatively, the corrected no-UI result raises entrepreneurship mainly through a lower-scale margin concentrated in low- and medium-education groups, rather than through broad expansion of high-scale firms.
```
