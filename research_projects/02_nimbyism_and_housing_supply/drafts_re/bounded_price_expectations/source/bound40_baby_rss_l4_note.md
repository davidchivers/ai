# Annual full RE price-path run

This run solves households with perfect foresight over the house-price path.
Demographics are exogenous; the expected aggregate object is the future price path.

- Scenario: `published_baby_boom`
- T: `40`
- Tail years: `40`
- Internal T: `80`
- Post-report demographic mode: `return_to_steady_state`
- Terminal anchor: `terminal_fixed_point`
- Terminal iterations: `150`
- Outer iterations: `10`
- Path relaxation: `0.010000`
- Path update method: `basis_broyden`
- Anderson memory: `4`
- Anderson damping: `0.700000`
- Anderson ridge: `1e-08`
- Anderson coefficient cap: `10.000000`
- Broyden damping: `0.420000`
- Broyden step cap: `0.002500`
- Political pass-through: `-0.006000`
- Vote scale: `0.020000`
- Vote rule: `smooth_logit`
- Vote tau: `0.04932788318`
- Vote sigma: `0`
- Vote shift mode: `block_vote`
- Vote shift horizon: `4`
- Vote block length: `4`
- Lagged pass-through: `1`
- Pass-through lag years: `4`
- Reference year: `2000`
- Reference price: `8.981292`
- Target vote: `0.404763`
- Source: `/nobackup/hfnt93/nimby_annual_runs/reT80PB_04301346/SteadyState/Mod_IRF/old_paper_source_min.mat`

Terminal steady-state anchor diagnostic:

- Terminal price: `8.927576`
- Terminal generated price: `8.927576`
- Terminal price gap: `0.000000`
- Terminal vote residual: `0.092518`

Final verdict: `usable`.
Final max path gap over reported periods: `0.001031`.
Final max vote residual: `0.010228`.
