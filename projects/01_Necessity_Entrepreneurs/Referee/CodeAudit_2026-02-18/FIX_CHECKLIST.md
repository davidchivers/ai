# Fix Checklist (Coding)

## Critical
- [ ] Fix entrepreneur output formula in simulation blocks (`cfv_red_final.cpp:972`, `cfv_red_final.cpp:2189`).
- [ ] Set `ppl_edu` before any interpolation calls in reporting loops (`cfv_red_final.cpp:1184`, `cfv_red_final.cpp:2341`).
- [ ] Recompute `ppl_edu` per agent before CEV interpolation (`cfv_red_final.cpp:1289`, `cfv_red_final.cpp:2439`).

## High
- [ ] Correct `check_agg()` theta criterion to use `> tol_agg` (`cfv_red_final.cpp:2964`).
- [ ] Resolve `q(theta)` vs `theta_ut` denominator in vacancy/search cost (`cfv_red_final.cpp:2785`, `cfv_red_final.cpp:2834`).
- [ ] Standardize and document state coding (`i_w`) across paper and code.

## Medium
- [ ] Decide whether separation in profit cost is average or education-specific (`cfv_red_final.cpp:2834`).
- [ ] Move `srand(...)` out of the period loop (`cfv_red_final.cpp:799`).
- [ ] Replace hardcoded path root with configurable relative path (`cfv_red_final.cpp:23`).

## Low
- [ ] Unify figure filename case conventions between scripts and paper includes.
