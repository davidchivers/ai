# Fertility leave-home calibration table

This table documents the current leave-home calibration used by the
steady-state fertility block and the intended U.S.-data replacement.

## Current implementation

| Component | Current value | Role in code | Status |
|---|---:|---|---|
| Fertility ages | `25, 30, 35, 40` | Ages when births can occur | Active |
| Model period length | `5` years | Converts child ages into model periods | Active |
| Leave-home bins | `leave by 20`, `leave by 25`, `leave by 30` | Candidate child leave-home bins | Active |
| Leave-home weights | `0.588, 0.147, 0.265` | Mixture over leave-home bins | Active, U.S.-targeted |
| Birth-age weights | `1/4, 1/4, 1/4, 1/4` | Mixture over fertility ages | Placeholder |

## Implied effective leave probabilities by parent age

These are the current implied one-period leave probabilities after mapping the
`20/25/30` child-age assumptions into the parent-age lifecycle grid.

| Parent age | Leave probability |
|---|---:|
| `25` | `0.0000` |
| `30` | `0.0000` |
| `35` | `0.0000` |
| `40` | `0.0833` |
| `45` | `0.1818` |
| `50` | `0.3333` |
| `55` | `0.5000` |
| `60` | `0.6667` |
| `65` | `1.0000` |
| `70` | `1.0000` |
| `75` | `1.0000` |
| `80` | `1.0000` |
| `85` | `1.0000` |
| `90` | `1.0000` |

## Calibration note

The `20/25/30` leave-home ages are the intended calibration structure.
The equal weights are only a temporary placeholder. They should be replaced
with weights disciplined by U.S. data on living with parents / leaving home.

## Interpretation note

This leave-home block is a reduced-form calibration device, not a fully
structural model of child departure from the parental home.

What is treated as exogenous here:
- the timing distribution of leaving home
- the mapping from child age to parental child-at-home state persistence

What is implicitly swept into this reduced-form block:
- endogenous expectations about when children will leave
- child income, schooling, and household formation decisions
- housing-market conditions that may affect co-residence directly
- parental resources and bargaining within the household

So this block should be described as a tractable stand-in for a richer
endogenous co-residence process, calibrated to broad U.S. moments rather
than derived from household microfoundations.

## Next replacement target

Replace:
- leave-home weights across `20/25/30`
- optionally birth-age weights across `25/30/35/40`

With:
- U.S.-data-based targets from Census / CPS / ACS or PSID moments.

## Official U.S. target moments

Recent official Census CPS ASEC releases report:

| Source year | Age group | Share living in parental home | Source |
|---|---|---:|---|
| `2025` | `18-24` | `0.58` | Census families and living arrangements release |
| `2025` | `25-34` | `0.16` | Census families and living arrangements release |
| `2023` | `18-24` | `0.56` | Census tip sheet |
| `2023` | `25-34` | `0.16` | Census tip sheet |

Source links:
- `2025`: <https://www.census.gov/newsroom/press-releases/2025/families-and-living-arrangements.html>
- `2023`: <https://www.census.gov/newsroom/press-releases/2023/children-families-living-arrangements.html>
- historical tables: <https://www.census.gov/data/tables/time-series/demo/families/adults.html>

## Leave-home weights implied by the official moments

If the model interprets the support points `20`, `25`, and `30` as
**leave-by bins** rather than exact leave ages, then matching the latest
official moments (`0.58` for ages `18-24`, `0.16` for ages `25-34`) implies
the current implemented weights:

| Leave-by bin | Illustrative weight |
|---|---:|
| `leave by 20` | `0.588` |
| `leave by 25` | `0.147` |
| `leave by 30` | `0.265` |

These are an inference from the Census target moments, not a direct Census
estimate, but they are now the active default in the code.

## Implementation caution

The current code now interprets `20/25/30` as leave-by bins rather than exact
child leave-home ages. This is still a reduced-form mapping from Census
coresidence moments into the model, not a structural estimate of child
departure hazards.
