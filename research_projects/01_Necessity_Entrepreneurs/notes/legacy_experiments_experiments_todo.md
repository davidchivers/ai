# Experiments To-Do (2026-02-20)

Status note (2026-02-23): Active project tracking has moved to `projects/01_necessity_entrepreneurs/STATUS.md`. Keep this file as supporting detail for experiment-specific implementation notes.

## 1) Slides-Paper Alignment (must stay in sync)

- Counterfactual 1 in slides (`No Unemployment Risk`) -> paper section `No Unemployment` and Table `tab:cf1_no_unemployment`.
- Counterfactual 2 in slides (`UI Level Changes`) -> paper section `Unemployment Insurance` and Table `tab:cf2_ui_levels`.
- Counterfactual 3 in slides (`Consumption Floor`) -> paper section `Consumption floor` and Table `tab:cf3_consumption_floor_ui04`.
- Slides "Next Steps" (`Credit Friction`, `Job Market`) -> paper placeholder sections `Credit friction wedge`, `Job market experiment`.

## 2) Immediate Fill Tasks (high priority)

- Fill `tab:cf_consumption_floor_ui00_pending` using UI=0.0 baseline plus lump-sum and penalty runs.
- Fill `tab:cf_consumption_floor_ui00_lowmatch_pending` using UI=0.0 + lower matching-efficiency counterfactual runs.
- Add one sentence after each pending table interpreting sign and magnitude of changes.
- Confirm whether the UI experiment in the paper is explicitly `constant-tax` only, or if a `revenue-neutral` block is now available.

## 3) Baseline Explanation Block (ready to use)

- Keep these baseline interpretation points explicit in text/slides:
- Necessity margin share: `Unemp-Ent / entrepreneurship = 0.00204 / 0.145 = 1.41%`.
- Education-sorting gradient: high-education firm size is `33.417 / 9.682 = 3.45x` low-education.
- No-unemployment comparison: entrepreneurship rises by ~`35.9%`, average firm size rises by ~`10.3%`.

## 4) Experiments Cleanup Pass (before coauthor circulation)

- Standardize all experiment tables to the same row order:
- `entrepreneur-avg`, `entrepreneur-low`, `entrepreneur-mid`, `entrepreneur-high`, `firm size-avg`, `firm size-low`, `firm size-mid`, `firm size-high`, `Unemp-Ent`.
- Add a `notes` sentence under each table defining what changes across columns (UI level, matching efficiency, tax rule).
- Ensure column names always include benchmark value (e.g., `Baseline (UI=0.4)`).
- Add one summary table at the end with only three outcomes: `entrepreneur-avg`, `firm size-avg`, `Unemp-Ent` for all completed counterfactuals.

## 5) Convergence Debug Package Needed (blocking item)

The repository currently has no calibration source code for this project (no `cfv_red_final.cpp` or equivalent) and no convergence logs/results in `calibration/results_2025/`.

To debug the low-UI (`b -> 0`) non-convergence, provide:

- The exact source file used for runs (`.cpp`/`.m`) and commit/date stamp.
- One convergent run log (e.g., UI=0.4) and one non-convergent run log (UI=0.0).
- Parameter blocks for both runs (especially: `b`, borrowing limit, taxes, matching efficiency, damping, tolerances, max iterations).
- The reported failure mode:
- value function oscillation,
- policy oscillation,
- negative consumption/infeasible states,
- GE outer loop divergence,
- NaN/Inf generation.

Once these files are in place, debug in this order:

1. Reproduce failure with deterministic seed and full iteration logs.
2. Check feasibility guards (`c > 0`, finite utility, borrowing constraints).
3. Isolate whether failure is inner VFI or outer GE fixed point.
4. Apply damping/line-search in outer price/tax updates.
5. Apply policy iteration or Howard improvement in inner loop.
6. Test homotopy in UI (`0.4 -> 0.3 -> 0.2 -> 0.1 -> 0.0`) using previous solution as initial guess.
