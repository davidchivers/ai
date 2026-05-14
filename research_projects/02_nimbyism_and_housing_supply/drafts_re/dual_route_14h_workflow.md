# Dual-route 14-hour workflow

## Scope

Project: `research_projects/02_nimbyism_and_housing_supply`.

Start reference: 2026-05-13 20:02 BST.
Stop no later than: 2026-05-14 10:02 BST.

This workflow covers two routes only:

1. **Full T80 rational expectations:** finish the live safeguarded search and,
   only if it finally misses, optionally launch one prepared LM/Gauss-Newton
   fallback.
2. **Moll-aligned direct price beliefs:** build the restricted direct-price-
   belief route that follows Moll's criteria, not the bounded T40 prototype.

C: is below the 20 GB guard at workflow creation. Keep local writes small. Put
any bulky outputs on Hamilton or under the existing project subfolders only.

## Starting state

- Full RE live job: `17145335` (`bb80safe13`, array `1-5`).
- Current status at workflow creation: all five array tasks running, about
  8h50m into a 13-hour wall.
- Full RE current best provisional gap: above the usable gate, so no success
  yet.
- Prepared full-RE fallback, not submitted:
  `drafts_re/hamilton_jobs/run_re_lm_0513.m` and
  `drafts_re/hamilton_jobs/bb80relm_0513.slurm`.
- Moll route correction already written:
  `drafts_re/moll_direct_price_beliefs/criteria_audit.md`.
- Moll route menu:
  `drafts_re/moll_direct_price_beliefs/route_options.md`.
- Bounded T40 artifact exists but is diagnostic/prototype only:
  `drafts_re/bounded_price_expectations/`.

## Work plan

| # | Task | Time | Cost | Route |
|---:|---|---:|---|---|
| 1 | Check live full-RE job state and avoid duplicate polling while it is still running | 10 min | light | Full RE |
| 2 | Build the Moll direct-price-belief implementation spec from the criteria audit and route menu | 60-90 min | moderate | Moll |
| 3 | Prioritize Route B: adapt the existing `run_linear_age_price_rule.m` pattern into an annual political baby-boom least-squares-learning smoke design | 2-3 h | moderate | Moll |
| 4 | When job `17145335` finishes or reaches the wall, run guarded final closeout | 20-30 min | light | Full RE |
| 5 | If full RE clears, build the guarded RE-vs-no-RE figure and stop the full-RE route | 30-45 min | moderate | Full RE |
| 6 | If full RE misses and at least 6 hours remain, submit exactly one LM/Gauss-Newton fallback | 20 min setup, then scheduler time | light | Full RE |
| 7 | Run one small Moll-route smoke only if the driver is self-contained and time remains | up to 4 h | moderate | Moll |
| 8 | Final handoff: update `STATUS.md`, `memory.md`, and summarize both routes | 30-45 min | light | Both |

Total planned wall clock: up to 14 hours, with scheduler time overlapping the
Moll route where possible.

Overall cost: moderate, mostly remote execution plus small local workflow files.

## Full T80 RE route

### Allowed actions

- Continue the existing slow monitor for `17145335`.
- Run non-final closeout while the job is live only as a provisional readout.
- After all array rows finish, time out, or the deadline passes, run:

```bash
cd /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual
python3 closeout_re_safeguard_0513.py --annual-dir . --final
```

- If a headline-eligible full T80 row clears `max_abs_path_gap <= 0.001`, build
  the guarded figure/table and update project state.
- If no row clears and at least 6 hours remain, submit exactly one prepared
  fallback:

```bash
cd /nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/annual
sbatch bb80relm_0513.slurm
```

### Stop rules

- Do not submit the LM fallback while `17145335` is live.
- Do not launch another broad grid or blind packet.
- Do not count bounded, local-linear, partial-equilibrium, lag-sweep, seed-
  diagnostic, blind-restart, or homotopy-diagnostic rows as full RE.
- Do not call any result paper-safe unless `max_abs_path_gap <= 0.0002`.

## Moll direct-price-belief route

### Target object

Build a restricted direct-price-belief equilibrium:

1. Households forecast house prices directly.
2. They use a low-dimensional perceived law of motion, not the full age
   distribution.
3. The belief rule is disciplined by local house-price-expectations literature
   or by an explicit estimated perceived law of motion as a first step.
4. Model-implied realized prices feed back into the belief-rule coefficients.

### Working specification

Default implementation route: **least-squares learning over a direct price
law**. Start from:

```text
E_t[Delta log P_{t+s}] =
    lambda^(s-1) * (a + rho Delta log P_t + beta M_{t+s})
```

where `M` is a public demographic-pressure index. Candidate indices:

- baby-boom population pressure relative to 2001;
- homeowner-voter pressure relative to 2001;
- mean-age or age-share pressure, but only as a low-dimensional public signal.

Other legitimate Moll-adjacent routes are documented in
`drafts_re/moll_direct_price_beliefs/route_options.md`:

- temporary equilibrium with measured/calibrated price beliefs;
- restricted perceptions/simple heuristic forecasting;
- price-only aggregate-law route;
- reinforcement learning as future work, not a 14-hour target.

### Concrete coding target

Use `extensions/re_no_politics/run_linear_age_price_rule.m` as the coding
template, then create a political annual baby-boom smoke design that writes:

- belief-rule coefficients by iteration;
- believed versus realized price path;
- forecast-error RMSE;
- convergence status;
- criteria-audit row.

The first implementation should be a smoke, not a full production packet. It
should be allowed to fail cleanly and should not be presented as paper evidence
until its belief rule is disciplined.

### Stop rules

- Do not present the existing bounded T40 artifact as the Moll route.
- Do not use the full cross-sectional age distribution as the agent's forecast
  state.
- Do not download new literature or large datasets while C: is below the guard.
- Do not submit a long Hamilton job unless the driver is self-contained and the
  expected runtime fits inside the remaining 14-hour window.

## Deliverables

At the end of the workflow, deliver:

- full-RE closeout status, including whether `17145335` cleared, missed, or led
  to one LM fallback submission;
- any new full-RE figure/table only if the hard gates clear;
- Moll-route implementation spec and, if time permits, smoke-run outputs;
- updated `STATUS.md` and `memory.md`;
- a short final handoff with next three tasks.

## Will not touch

- No manuscript/LyX edits.
- No git branch switching, commits, pushes, or pull requests.
- No archive branch work.
- No broad literature search beyond the existing local house-price-expectations
  PDFs unless explicitly requested.
