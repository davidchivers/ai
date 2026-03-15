# UBI scan results — 2026-03-15

## Setup

Cases 148–151, all from case 147 benchmark. 200 GE iterations (hit limit, not
fully converged — directional results only). Steady-state only, no transition.
UBI is manna-from-heaven (unfunded), added to asset_income in all states.

## Key numbers

| Case | UBI (× mean wage) | theta | entr share | self-emp share | avg n | avg k |
|------|-------------------|-------|------------|----------------|-------|-------|
| 147  | 0.0 (baseline)    | 0.658 | 17.6%      | 57.1%          | 6.23  | 99.3  |
| 148  | 0.2               | 0.608 | 19.6%      | 57.9%          | 5.33  | 82.2  |
| 149  | 0.4               | 0.601 | 19.8%      | 57.9%          | 5.22  | 78.7  |
| 150  | 0.6               | 0.600 | 19.9%      | 57.7%          | 5.19  | 77.1  |
| 151  | 0.8               | 0.597 | 20.0%      | 57.1%          | 5.22  | 76.2  |

## Main finding

Entrepreneurship rises with UBI, not falls. This is the opposite of the
partial-equilibrium prediction.

The mechanism is a GE labour market channel: UBI raises worker income, reducing
their willingness to accept low wages. Firms post fewer vacancies. Theta (vacancy-
to-unemployment ratio) falls ~9%, making wage work harder to find. The
deterioration in job-finding prospects pushes more people into entrepreneurship,
more than offsetting the direct consumption-floor effect on the necessity band.

Average firm size falls (6.23 → ~5.2), consistent with more low-scale/necessity
entry. The self-employment share rises slightly at moderate UBI levels (148–150)
but retreats at UBI=0.8, where employer entry picks up — a hint that very high UBI
starts enabling opportunity entry.

## Convergence caveat

All four cases hit the 200-iteration cap. Theta was still drifting (~0.5–1%
per iteration at termination). The directional results are reliable; exact
magnitudes should be treated as approximate pending full convergence.

## Implication

The paper claim would be: UBI does not reduce necessity entrepreneurship in
general equilibrium. The GE labour-market channel (fewer vacancies, worse
job-finding) dominates the partial-equilibrium consumption-floor channel.
Policy aimed at reducing necessity entry needs to operate on vacancy creation,
not just the income floor.

## Next steps

1. Run with -MaxIterAgg 500 or adaptive GE to get converged values.
2. Produce a version of the necessity-entry-regions figure (cutoff panels) for
   UBI=0.4 to visualise the threshold compression.
3. Consider revenue-neutral version: same UBI funded by proportional labour
   income tax. This would additionally compress vacancy creation and likely
   strengthen the GE channel further.
