# Annual political permit pass-through workflow

## Purpose

This lane re-anchors the political transition work on the annual steady-state code family
used by `LOOP.m`, where one model period is one year. The old 5-year political RE folder is
now treated as a diagnostic sandbox only.

The immediate question is not whether an 80-year rational-expectations solve can run. The
question is whether the annual political mapping has a plausible middle layer:

- demographics and household values create political pressure for higher or lower prices
- political pressure moves permits/supply only partially
- permits/supply then move prices with a finite pass-through

That is different from hard-clearing the political vote every year.

## Fertility-project lesson

Use the same discipline as the fertility annual walk-up:

- run map-level smokes first
- then run short-horizon annual tests
- only climb after the short mechanism is stable
- classify every cycle as `dead`, `survivor`, or `usable`
- do not treat a long timeout as useful unless it tells us which margin failed

The ladder is an information filter, not a race to a larger `k`.

## Active smoke

First smoke:

- source object: saved annual `Mod_IRF/loop101_output_extended.mat`
- no new household Bellman solves
- uses the saved annual price grid `PriceHouse`
- uses the saved annual vote grid `VoteBaseline`
- compares soft pass-through paths to the hard political-clearing price path

The soft rule in the smoke is:

```text
vote_residual_t = vote_share_t(price_t) - target_vote
pressure_t      = tanh(vote_residual_t / vote_scale)
restriction_t   = rho * restriction_{t-1} + phi * pressure_t
price_t         = reference_price * exp(gamma * restriction_t)
```

where:

- `phi` is political pass-through from pressure to permit/supply restriction
- `gamma` is the permit/supply-to-price pass-through
- `rho` is political/supply persistence
- `vote_scale` controls when political pressure saturates

This is only a reduced-form smoke. It does not replace the full market-clearing transition.

## Promotion rules

A row is `usable` only if:

- vote residual is materially smaller than the constant-price baseline
- prices do not hit the grid boundary
- the implied price movement is not extreme
- the rule works over the annual window, not just one year

A row is a `survivor` if:

- the sign and direction look right
- the residual improves but remains too large
- the implied price movement is economically plausible

A row is `dead` if:

- it worsens the vote residual
- it needs extreme price movement
- it hits the saved price-grid boundary often
- it only works by effectively recreating hard political clearing

## Ordered ladder

1. Map smoke on the saved annual grid.
2. If survivors exist, run a local annual `T = 4` transition smoke using the same phi/gamma/rho candidates.
3. If `T = 4` is stable, climb to `T = 8`.
4. If `T = 8` is stable, climb to `T = 12` or `T = 16`.
5. Only after that consider Hamilton for `T = 20+`.

Do not launch an 80-year run before the map and `T = 4/8` gates pass.

## Launch

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits\research_projects\02_nimbyism_and_housing_supply\original_annual_political_re\start_annual_political_permit_passthrough_map_smoke.ps1
```

## Outputs

- `truth/annual_political_permit_passthrough_map/latest_status.json`
- `truth/annual_political_permit_passthrough_map/<run_tag>/summary.csv`
- `truth/annual_political_permit_passthrough_map/<run_tag>/paths.csv`
- `truth/annual_political_permit_passthrough_map/<run_tag>/note.md`
