# annotated code diff: benchmark vs self-employment source

Date: 2026-03-06

## purpose

This note documents the code differences between the current benchmark source and the separate self-employment source. It is meant for coauthor review, not as a replication patch file.

Compared files:

- benchmark:
  - `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113.cpp`
- self-employment branch:
  - `calibration/canonical_dropbox/2026-02-28_main_2025_v1_case113/main_2025_v1_case113_self_employment.cpp`

Headline diff summary from `git diff --no-index --stat`:

```text
1 file changed, 482 insertions(+), 103 deletions(-)
```

So this is not a tiny parameter tweak. It is a separate model branch layered on top of the benchmark code.

## 1. New global controls added for self-employment

The benchmark file has no self-employment-specific controls at the top of the source.

The self-employment source adds:

- `use_self_employment_root`
- `self_employment_owner_labor`
- `self_employment_hired_scale`
- `self_employment_n_threshold`
- `self_employment_x_scale`
- `self_employment_hiring_fixed_cost`
- `chi_self_emp`
- `chi_employer`

Code location:

- self-employment file:
  - around lines `110-117`

Interpretation:

- these are the switches and parameters that turn the employer-only benchmark into a model where zero-hire entrepreneurship is feasible;
- they also add two optional utility shifters and a fixed hiring cost.

What changed economically:

- in the benchmark, entrepreneurship is effectively tied to hiring labor;
- in the self-employment branch, entrepreneurship can begin with zero hired workers.

## 2. The static entrepreneurial technology was rewritten

This is the core model change.

In the benchmark source, firm output and profits are computed using the old employer-only logic. The key code path is still the old analytic structure:

- benchmark:
  - `solve_opt()` begins around line `589`
  - benchmark precomputed firm-policy block around lines `3632-3742`

The self-employment source adds a new static block:

- `entrepreneur_effective_hired_labor(...)`
- `entrepreneur_total_labor_input(...)`
- `entrepreneur_effective_x(...)`
- `entrepreneur_output_static(...)`
- `entrepreneur_hiring_cost(...)`
- `entrepreneur_capital_cost(...)`
- `entrepreneur_profit_given_choices(...)`
- `entrepreneur_best_k_for_n(...)`
- `entrepreneur_profit_best_k(...)`
- `solve_self_employment_static_problem(...)`

Code location:

- self-employment file:
  - roughly lines `601-785`

Interpretation:

- the benchmark relies on the old span-of-control closed-form logic for firm scale;
- the self-employment source replaces that with a numerical static entrepreneur problem that explicitly allows the zero-hire corner.

What changed economically:

- owner labor now enters production directly;
- the no-hire corner can generate positive output;
- the distinction between self-employed and employer firms is implemented through `n_h <= self_employment_n_threshold` versus `n_h > self_employment_n_threshold`.

Why this matters:

- this is the change that makes one-person firms possible in the model at all.

## 3. Entrepreneur utility can now differ by self-employed vs employer status

The benchmark source does not add a separate utility shifter once the agent chooses entrepreneurship.

The self-employment source adds:

- `chi_self_emp` when `n_opt <= self_employment_n_threshold`
- `chi_employer` when `n_opt > self_employment_n_threshold`

Code location:

- self-employment file:
  - `solve_opt()` around lines `948-955`

Interpretation:

- the current calibration sets both of these to zero in the tested cases;
- but the branch is now coded so that autonomy or employer-status utility can be introduced later without rewriting the Bellman problem again.

What changed behaviorally:

- nothing in the current baseline runs, because both shifters are zero;
- but this is a new margin in the code and should be treated as part of the model branch.

## 4. Simulated entrepreneurial output is no longer the old benchmark formula

In the benchmark simulation, entrepreneurial output is still:

```text
y = x * k^alpha * n^gamma
```

Code location:

- benchmark:
  - `simulation()` around lines `972+`
  - benchmark output line near `1293`

In the self-employment source, simulation switches to:

- if `use_self_employment_root == true`, use `entrepreneur_output_static(...)`
- otherwise fall back to the old benchmark formula

Code location:

- self-employment file:
  - `simulation()` around lines `1500-1504`

Interpretation:

- this is important because even if the policy functions changed, the simulated moments would still have been wrong if output were left on the old formula;
- the self-employment branch correctly updates simulation output to match the new production logic.

## 5. New simulation diagnostics distinguish self-employed and employers

The benchmark source reports entrepreneurship as a single group.

The self-employment source adds:

- `self_emp_count`
- `employer_count`
- counts by education for each group
- printed shares among entrepreneurs

Code location:

- self-employment file:
  - counting block around lines `1649-1667`
  - printed diagnostics around lines `1669-1677`

Interpretation:

- this is one of the most useful transparency additions in the self-employment branch;
- it allows direct checking of whether the model is generating one-person firms or only relabeling employers.

What it revealed in the first runs:

- the raw self-employment baseline generated a large mass of self-employed agents;
- some later static-discipline experiments collapsed the self-employed margin entirely and left only employers.

That finding comes directly from these added diagnostics.

## 6. The parameter/case block now includes separate self-employment experiments

The benchmark `assign_value()` defines the standard benchmark and policy experiments.

The self-employment file keeps those and adds new cases:

- case `141`: baseline with self-employment root
- case `142`: self-employment root with attenuated own-account productivity
- case `143`: stronger own-account attenuation
- case `144`: attenuation plus fixed hiring cost

Code location:

- benchmark `assign_value()` starts around line `1968`
- self-employment `assign_value()` starts around line `2208`
- self-employment cases `141-144` are around lines `2387-2557`

Interpretation:

- these are not just flags hidden in the runner;
- they are explicit case blocks with their own model settings.

What changed behaviorally:

- case `141` is the raw self-employment baseline;
- cases `142-144` were first-pass static-discipline tests to see whether self-employment could be reduced without adding new risk.

## 7. Precomputed firm policy objects are generated differently

The benchmark source computes `k_star`, `n_star`, and constrained firm policies using the old employer-only formulas.

Code location:

- benchmark:
  - precomputed static policy block around lines `3632-3742`

The self-employment source keeps the benchmark formulas as fallback, but conditionally replaces them with `solve_self_employment_static_problem(...)`:

- for unconstrained entrepreneur scale:
  - around lines `4028-4030`
- for constrained entrepreneur scale:
  - around lines `4099-4100`

Interpretation:

- this is where the new model is actually fed into the dynamic program;
- without this change, the self-employment branch would only affect diagnostics, not actual policy functions.

## 8. What did not yet change

This is as important as what did change.

The self-employment branch still keeps the same coarse occupation-state structure:

- `Ni = 3`
- state values still correspond to:
  - entrepreneur
  - employed
  - unemployed

Code location:

- both files around line `187`

Interpretation:

- the self-employment branch did **not** yet add a new post-closure state;
- it did **not** yet add entrepreneur closure risk to the Bellman or simulation code;
- it therefore still lacks the full institutional treatment discussed in the paper draft.

This is the main current gap between the self-employment paper math and the self-employment C++ branch.

## 9. Main open risks / problematic points

### A. Closure risk is in the paper math but not yet in this code branch

The self-employment paper now includes education-specific entrepreneur closure risk.
The current self-employment C++ file does not yet implement that structure.

Consequence:

- current self-employment runs are still a no-closure version;
- they should not be described as the full closure-risk model.

### B. The branch is economically separate enough that old benchmark comparisons need care

Because the branch changes:

- production,
- static firm optimization,
- simulation output,
- diagnostics,
- and experiment cases,

the self-employment file is not a “minor extension” of the benchmark in quantitative terms.

Consequence:

- any comparison between the benchmark and self-employment versions should be described as a model comparison, not as a robustness tweak.

### C. Static-discipline experiments changed composition in unstable ways

Cases `142-144` showed that some apparently natural static penalties:

- reduced total entrepreneurship,
  but
- collapsed the self-employed margin and pushed entrepreneurs into employer status.

Consequence:

- the branch still needs a cleaner durability/risk mechanism, not just more static penalties.

## 10. Bottom line

The annotated diff shows that the self-employment file differs from the benchmark in a substantive way, not a cosmetic one.

The key legitimate structural differences are:

- a new production logic with owner labor;
- a new numerical static entrepreneur problem;
- new case blocks for self-employment experiments;
- new simulation output and diagnostics that distinguish self-employed from employers.

The key unresolved issue is equally clear:

- the self-employment paper now has closure risk in the math,
  but the self-employment C++ branch does not yet implement the corresponding state-transition structure.

So the current self-employment source should be read as:

- a real and transparent code branch for the self-employment mechanism,
  but
- not yet the final closure-risk version described in the latest paper draft.
