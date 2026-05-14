# Original 5-Year Political RE Workflow

This lane is the main target for the project. It intentionally does **not**
build on the annual `2010-2018` extension.

## Immediate sequence

1. Run a coarse steady-state vote sweep on the original 5-year model in
   `code/steadystate/SolveSS_iter.m`.
2. If a sign-change bracket appears, keep running local bracket sweeps on that
   interval:
   `refined`, then `dense`, then `micro`, then `ultra`, stopping early if the
   bracket is already tight enough or the vote residual is already tiny.
3. If the coarse sweep has no bracket:
   - if all votes are negative, expand toward lower prices
   - if all votes are positive, expand toward higher prices
4. If the directional expansion still has no bracket, run a broad full-domain
   sweep.
5. If the broad full-domain sweep still has no bracket, run a small
   interest-rate (`rb`) sensitivity family on the broad price grid.
6. Write the best tested point, any discovered bracket history, and the classification
   into a machine-readable handoff file for the compiled C lane.
7. Use that sweep tree as the parity target for the compiled steady-state
   political prototype.
8. Once the compiled steady-state object matches MATLAB, wrap a root solve
   around the steady-state political residual.
9. Refactor the original 5-year Bellman block into a reusable dynamic kernel.
10. Start the dynamic political RE object on the smallest nontrivial truncated
    horizon and climb by `k`.

## Current first milestone

The first milestone is purely steady state:

- baseline Bellman solve at `a_price`
- perturbed Bellman solve at `a_price * d_a_price`
- `pref = sign(V^{dp} - V)`
- `totalvote = sum(dens4 .* pref4, 'all')`
- `distance = totalvote^2`

## Outputs

The MATLAB sweep writes run folders under:

- `original_5yr_political_re/truth/`

Each run folder contains:

- `steady_state_vote_sweep.csv`
- `steady_state_vote_sweep_summary.csv`
- `steady_state_vote_sweep_results.mat`
- `c_port_handoff.json`

## Live automation

The live workflow can be launched with:

- `start_original_5yr_political_re_supervisor.ps1`

The live reporter can be launched with:

- `start_original_5yr_political_re_reporter.ps1`

They write to:

- `original_5yr_political_re/truth/original_5yr_political_re_live/`
