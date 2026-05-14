# Full T80 RE Completion Audit

Objective: find a defensible full-T80 rational-expectations fixed-point price path for the published baby-boom model and produce a paper-quality RE versus no-RE figure.

Concrete deliverables:

1. A headline-eligible full-T80 RE row for the published baby-boom experiment.
2. A verified usable fixed point with `max_abs_path_gap <= 0.001`; paper-safe only if `<= 0.0002`.
3. A paper figure comparing that RE path to the fixed no-RE comparator.
4. A validation table documenting the selected RE row, comparator, normalization, source paths, plotted columns, plotted periods, and numerical gates.
5. A closeout memo if no usable full-T80 row exists.

Completion criteria and evidence:

| Requirement | Evidence needed | Current evidence |
|---|---|---|
| Full T80 RE row, not bounded horizon or diagnostic | Ranked row has `family=re`, `horizon_t=80`, target baby-boom route, and is not local-linear, partial-equilibrium, or bounded-horizon | Pending `17145335` safeguarded packet |
| Usable fixed point | `max_abs_path_gap <= 0.001` in `truth/re_safeguard_0513/re_wide_ranked_0512.csv` | Missing; no first summary output yet |
| Paper-safe fixed point, if achieved | `max_abs_path_gap <= 0.0002` | Missing |
| Same no-RE comparator | No-RE path from `truth/annual_political_transition_fail_safe/nore80bv4_006/paths_T80.csv` | Located and used by `build_re_vs_nore_figure_0513.py` |
| Same normalization | RE and no-RE plotted as percent deviation from each series' period-1 price | Implemented in `build_re_vs_nore_figure_0513.py` |
| Validation table | `truth/re_safeguard_0513/figure/full_t80_re_validation_0513.csv` with chosen RE row metadata, source paths, source run/outer, terminal settings, update method, vote timing, usable/paper-safe gates, plotted columns, plotted periods, and normalization | Builder staged; not run until usable RE exists |
| Ranked metadata preservation | `rank_re_wide_0512.py` preserves model-design columns needed by the validation table, including pass-through, vote timing, source row, path-update method, terminal settings, and basis/focus settings | Implemented in the ranked CSV field list |
| Paper figure | `truth/re_safeguard_0513/figure/full_t80_re_vs_nore_0513.svg`; `.png` and `.pdf` if matplotlib is available | Builder staged; SVG fallback verified on diagnostic survivor because Hamilton lacks matplotlib |
| No relabeling of non-full RE | Figure builder refuses non-usable requested rows unless `--allow-survivor` is explicitly passed for diagnostics | Implemented |
| Bounded-horizon rows not relabeled | `rank_re_wide_0512.py` assigns bounded-specific verdicts such as `bounded_usable` rather than plain `usable`, even if the numeric gap clears | Implemented after negative smoke caught ambiguous `usable` label |
| Search/diagnostic rows not relabeled | `rank_re_wide_0512.py`, `build_re_vs_nore_figure_0513.py`, and `closeout_re_safeguard_0513.py` treat `homotopy_diagnostic`, `lag_sweep`, `seed_diagnostic`, and `blind_restart` as non-headline routes unless explicitly reviewed and reclassified | Implemented |
| Report wording avoids diagnostic success language | `rank_re_wide_0512.py` writes "Best headline-clearing row" only for plain `usable` or `paper_safe`; diagnostic and bounded rows remain "Best visible row" if they are the best finite row | Implemented |
| No accidental diagnostic headline | Builder and closeout helper exclude bounded-horizon, partial-equilibrium, local-linear, and diagnostic routes from headline eligibility | Implemented in `build_re_vs_nore_figure_0513.py` and `closeout_re_safeguard_0513.py` |
| Correct RE iteration plotted | Figure uses the selected row's ranked `best_outer`; matching is numeric rather than string-exact to avoid silently dropping paths if CSV formats `4` versus `4.0` differently | Implemented in `build_re_vs_nore_figure_0513.py` |
| Correct RE iteration ranked | Ranker path statistics use numeric outer-iteration matching, so `4` and `4.0` refer to the same selected iterate | Implemented in `rank_re_wide_0512.py` |
| Mechanical closeout | `closeout_re_safeguard_0513.py` ranks the safeguarded packet; return code `0` means usable row and figure/table built, `3` means pending rows remain, `2` means final failure memo written | Non-final test returned `3` while all `sg80_*` rows were still missing |
| CSV encoding robustness | Ranker, builder, and closeout helper read CSVs with `utf-8-sig` so BOM-marked files do not hide key columns such as `period` | Implemented after synthetic closeout smoke caught the issue |
| Synthetic success-path smoke | Tiny D:-drive fixture with a usable full-T80 RE row, BOM-marked CSVs, and no-RE comparator runs `closeout_re_safeguard_0513.py --annual-dir .` end-to-end | Passed: ranked synthetic row, built figure CSV/validation table/plot, preserved `re_pass_through=0.006`, `re_vote_block_length=4`, `re_source_run_tag=w80_b60hold_bl70`, `re_path_update_method=trust_region_relaxation`, `usable=True`, `paper_safe=False`, `plotted_periods=80` |
| Diagnostic pipeline check | Diagnostic survivor figure path can be built only with `--allow-survivor` and goes to a diagnostic folder, not the headline folder | Verified with `w80_b60hold_bl70`; SVG/CSV/validation were written under `truth/re_wide_0512/diagnostic_survivor_figure` |

Prompt-to-artifact checklist:

| Prompt requirement | Required artifact or command evidence | Completion standard |
|---|---|---|
| "Full T80" | `truth/re_safeguard_0513/re_wide_ranked_0512.csv` or fallback ranked file has selected row with `horizon_t=80` | Must be the row used by the figure builder |
| "rational-expectations fixed-point price path" | Selected row has `family=re` and source paths under `truth/annual_political_full_re_price_path/<run_tag>/paths_all.csv` | Must use selected `best_outer` and `price_guess` versus generated residual gate |
| "defensible" | Selected row's route is not bounded-horizon, partial-equilibrium, local-linear, or diagnostic; failure memo records searched methods if no row clears | Must be accepted through `is_headline_full_re()` |
| "`max_abs_path_gap <= 0.001` usable" | Ranked selected row `best_gap <= 0.001` | Required for any headline figure |
| "`<= 0.0002` paper-safe" | Ranked selected row `best_gap <= 0.0002` | Record as paper-safe only if true; usable-but-not-paper-safe is not paper-safe |
| "same normalization" | `full_t80_re_validation_0513.csv` field `normalization` plus plot data in `full_t80_re_vs_nore_0513.csv` | Percent deviation from each series' period-1 price |
| "no-RE comparator" | Validation table `nore_run_tag=nore80bv4_006` and path source `truth/annual_political_transition_fail_safe/nore80bv4_006/paths_T80.csv` | No alternate comparator without explicit decision |
| "validation table" | `truth/re_safeguard_0513/figure/full_t80_re_validation_0513.csv` or fallback equivalent | Must exist and contain row metadata, sources, gates, columns, and plotted periods |
| "paper-quality figure" | `full_t80_re_vs_nore_0513.svg` at minimum; `.png`/`.pdf` if matplotlib is available | Built only after a usable headline-eligible row |
| "no relabeling" | Builder exits unless row passes `is_headline_full_re()` and gap gate; diagnostic survivor figures require `--allow-survivor` | Proxy rows cannot complete the goal |

Completion verdict: not achieved. The required ranked usable full-T80 RE row and corresponding headline figure/validation artifacts do not yet exist.

Current blockers:

- `17145335` has not yet produced rankable numeric output.
- The goal cannot be marked complete until the ranked file contains a usable full-T80 RE row and the figure/validation artifacts have been generated from that row.
