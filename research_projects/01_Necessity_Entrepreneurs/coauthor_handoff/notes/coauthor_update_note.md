# coauthor update note

Date: 2026-03-06

## purpose

This note summarizes where the Necessity Entrepreneurship project stands after the recent code audit, corrected UI experiments, and the new self-employment extension. The emphasis is on transparency: which results are currently credible, what was changed in the code, and which parts are still work in progress.

## 1. What happened with the old zero-UI result

The older March 4 `101A` archive should not be treated as a valid zero-UI result.

Evidence:

- The archived run tagged as `ui000_101A` ends at the same terminal moments as the baseline case-101 run.
- In particular, it reproduces the baseline entrepreneurship share, mean entrepreneur labor demand, matching tightness, and baseline tax rate.

Interpretation:

- The old `101A` archive was still running through the pre-fix UI path, so the `UI=0.00` label was misleading.
- It is better interpreted as a mislabeled baseline-equivalent run, not as evidence that the model had already been shown to converge at zero UI.

## 2. Why the corrected zero-UI result now converges

After the March 5 corrections, the model does converge at zero UI in the canonical case-101 environment.

There are three distinct parts to this explanation, and it is important not to mix them up.

First, the old apparent zero-UI result was not a true zero-UI solve at all.
That was a labeling/path issue, not an economic finding.

Second, the model now converges because the main numerical failure points were removed.
The important technical changes were:

- fixing the UI override path so case 101 actually runs at the requested UI level;
- fixing interpolation/indexing problems that previously generated explosive policy extrapolation;
- adding numerical guards to the aggregate fixed-point loop.

Before those fixes, the solver was often being pushed off course by bad interpolation and inconsistent policy mapping.
So one part of the story is purely numerical: the fixed-point iteration can now settle instead of being repeatedly destabilized by artificial spikes in entrepreneur labor demand.

The current credible no-UI evidence is:

- endogenous-tax case 101, `UI=0.00`:
  - `best_tol = 0.00556`
  - `entr_share = 0.08466`
  - `theta_new = 0.61191`
- fixed-tax case 113, homotopy to `UI=0.00`:
  - `best_tol = 0.00286`
  - `entr_share = 0.08262`
  - `theta_new = 0.61577`

Third, there is a genuine economic reason why the corrected zero-UI case is not especially hard to solve once the numerical problems are fixed.

Setting UI to zero changes the model through two channels:

1. The direct insurance channel.
   - The unemployed state becomes much less attractive.
   - This shifts occupational choices away from unemployment and toward work or entrepreneurship.
   - In that sense, zero UI increases the penalty from labor-market non-employment.

2. The fiscal closure channel.
   - When UI is removed, transfer spending collapses.
   - Under endogenous tax closure, this allows the equilibrium tax rate to fall sharply.
   - That raises after-tax returns to work and entrepreneurship relative to the baseline.

These two channels move in the same direction.
They both make the non-unemployed branches relatively more attractive than in the baseline.
That is why the zero-UI case is not a pathological corner in the corrected model.

What is important here is what does **not** happen:

- matching tightness does not collapse toward zero;
- labor demand and labor supply remain close at the terminal iteration;
- entrepreneur policy tails remain bounded rather than exploding.

So the corrected zero-UI result is an interior equilibrium, not a trivial degenerate one.

Interpretation:

- the corrected model now finds a zero-UI steady state under both endogenous-tax and fixed-tax closure;
- this means convergence is not just an artifact of letting the equilibrium tax rate fall toward zero;
- but the endogenous fiscal channel still matters quantitatively, because zero UI removes both insurance and the taxes needed to finance it.

So the right statement is:

- convergence now occurs because the numerical obstacles were fixed;
- the zero-UI equilibrium itself is economically easier to support because both the outside-option channel and the fiscal channel push away from unemployment;
- the fixed-tax result shows that the fiscal channel is not the only reason the solve works.

## 3. What the corrected UI experiments show

In the corrected endogenous-tax case-101 ladder:

- entrepreneurship rises from `0.07884` at `UI=0.40` to `0.08466` at `UI=0.00`;
- the equilibrium income tax falls from `0.01812` to about `0.00066`;
- UI outlays go from `8994.34` to `0`.

The most informative way to read these numbers is as a decomposition of what the model is doing.

From `UI=0.40` to `UI=0.05`, the entrepreneurship response is modest:

- `0.07884 -> 0.07944`

This says that small UI cuts do not overturn the occupational structure very much on their own.

From `UI=0.05` to `UI=0.00`, the response becomes noticeably larger:

- `0.07944 -> 0.08466`

This is the point at which the unemployed branch has effectively lost its insurance value altogether.
At the same time, transfer spending goes to zero and the tax rate nearly disappears.
So the `UI=0.00` result should not be read as a pure “risk-only” experiment.
It is a joint insurance-removal and tax-relief experiment in the endogenous-closure version.

The firm-size response is concentrated in low- and medium-education entrepreneurs:

- low education mean entrepreneur labor demand:
  - `8.93 -> 5.64`
- medium education:
  - `12.05 -> 10.88`
- high education:
  - `21.57 -> 21.61`

That pattern matters for interpretation.
The model is not mainly generating a broad increase in high-scale entrepreneurship.
Instead, it is generating more entry at the bottom of the entrepreneurial distribution, with lower average scale among low- and medium-education entrepreneurs.

This is why the corrected no-UI result looks like a necessity-entry result rather than a general boom in employer expansion.

It is also important that `theta` stays roughly unchanged between baseline and no UI in these runs.
That means the current case-101 no-UI result is not operating through a dramatic change in matching tightness.
Given the vacancy-floor environment, the main active channels are instead:

- lower value of unemployment;
- lower tax financing requirement;
- compositional movement into smaller-scale entrepreneurship.

Interpretation:

- lower UI raises entrepreneurship in the corrected model, but mainly through a lower-scale margin;
- much of the quantitative effect is a joint insurance-plus-fiscal effect rather than a pure matching-tightness effect.
- the cleanest way to present the no-UI experiment is therefore as a combined necessity-entry and fiscal-closure result, not as a pure labor-market-risk comparative static.

## 4. Current code provenance

The current credible runs come from:

- source file:
  - `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113.cpp`
- runner:
  - `calibration/ai_calibration/run_ai_calibration.ps1`

The current code path is therefore no longer a black box:

- the wrapper records source, case, seed, UI override, and iteration cap in the log headers;
- the main diagnostics now print entrepreneur mass, scale, and aggregate update terms;
- the current March 5-6 logs are auditable in a way the older archive logs were not.

## 5. New self-employment extension

Separately, I have started a self-employment version of the model and a separate draft:

- draft:
  - `drafts/necessity_entrepreneurship_self_employed.lyx`
  - `drafts/necessity_entrepreneurship_self_employed.pdf`
- source:
  - `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113_self_employment.cpp`

The motivation is that the original model is effectively an employer-only entrepreneurship model. The self-employment version changes that by allowing entrepreneurship to start at zero hired labor, with employer status becoming an expansion margin.

The paper draft has now been updated so its production function, Bellman equations, and appendix coding strategy reflect the self-employment structure rather than the old employer-only one.

A separate line-by-line annotated code-difference note for this branch is in:

- `notes/10_annotated_code_diff_self_employment.md`

## 6. What the first self-employment baseline showed

The first raw self-employment baseline was informative but not yet calibrated:

- entrepreneur share jumped to about `0.383`;
- about `61%` of entrepreneurs were self-employed;
- mean entrepreneur labor demand fell sharply relative to the old baseline.

Interpretation:

- the self-employment margin matters a great deal;
- lower UI in this version appears to raise self-employment much more than employer entrepreneurship;
- but the first-pass baseline clearly generates too much entrepreneurship overall, so it cannot yet be treated as the paper baseline.

## 7. Entrepreneur closure risk

I have also added a transparent calibration note and Section 5 table entry for education-specific entrepreneur closure risk in the self-employment draft.

Important conceptual point:

- closure risk is now in the paper math;
- but it is not yet fully implemented in the C++ in a way that respects the institutional treatment of unemployment insurance.

The institutional issue is that business closure should not automatically imply eligibility for regular U.S. unemployment insurance. That means the model likely needs either:

- a separate post-closure nonemployment state, or
- a UI-eligibility flag.

So this part is conceptually specified in the draft, but not yet fully coded.

## 8. What is credible right now

Credible now:

- the corrected case-101 no-UI convergence result;
- the fixed-tax no-UI confirmation;
- the conclusion that the older `101A` archive should not be used as the zero-UI sanity check;
- the statement that the current code path is much more transparent and auditable than before.

Not yet complete:

- a fully calibrated self-employment baseline;
- implementation of entrepreneur closure risk with the correct post-closure UI treatment;
- updated quantitative tables from the self-employment model.

## 9. Bottom line

The main corrected result is real: the canonical model now converges at zero UI under both endogenous-tax and fixed-tax closures, and the older `101A` archive should not be used as the evidence for that claim.

At the same time, the project is now moving toward a more interesting self-employment version of the model. That extension looks promising, but it still needs calibration and a clean implementation of entrepreneur closure risk before it can replace the current benchmark quantitatively.
