# External arrival first pass

Last updated: 2026-05-13

Status: first operational pass plus executed own-band-excluded final audit on experienced outside-musician arrivals

## Question

Can the member-edge data support a causal follow-on design where outside human capital enters a
local scene?

The key measurement distinction is:

- not observed: a musician literally moves residence
- observed: a musician first appears in a local `city x genre` band roster after earlier band
  experience in another city or country

So the treatment language should be `experienced outside-musician arrival`, not migration.

## Workflow added

Two scripts now define the first pass:

- `code/83_build_external_arrival_event_study.py`
- `code/84_build_external_arrival_matched_control.py`
- `code/85_build_external_arrival_final_audit.py`

The first script builds four first-arrival definitions:

- `cross_city_any`: prior membership in a different city, any metal genre
- `cross_city_same_genre`: prior membership in a different city and the same genre family
- `cross_country_any`: prior membership in a different country, any metal genre
- `cross_country_same_genre`: prior membership in a different country and the same genre family

The second script focuses on the strictest definition, `cross_country_same_genre`, and matches
treated cells to same-country, same-genre control cells in the same calendar year.

The third script is the intended final robustness audit. It requires a freshly rebuilt event file
with full `arriving_band_ids`, rebuilds band-level local starts, excludes the arriving musician's
own band from treated outcomes, and computes a matched event-study with `t-1` as the baseline.

## Output files

- `data/processed/scene_networks/external_arrival_events.csv`
- `data/processed/scene_networks/external_arrival_event_windows.csv`
- `data/processed/scene_networks/external_arrival_relative_year_summary.csv`
- `data/processed/scene_networks/external_arrival_event_study_summary.md`
- `data/processed/scene_networks/external_arrival_matched_controls.csv`
- `data/processed/scene_networks/external_arrival_matched_event_comparison.csv`
- `data/processed/scene_networks/external_arrival_matched_control_summary.md`
- `data/processed/scene_networks/external_arrival_final_audit_event_windows.csv`
- `data/processed/scene_networks/external_arrival_final_audit_event_study.csv`
- `data/processed/scene_networks/external_arrival_final_audit_summary.md`

## Final-audit attempt

On `2026-05-13`, a last pass was attempted on the arrival branch. The first script was patched so
future event files preserve full pipe-delimited `arriving_band_ids`, because the existing event
file schema did not contain enough information to remove the arrival-associated band from the
outcome count. A new final-audit script, `code/85_build_external_arrival_final_audit.py`, now
implements the own-band-excluded matched event-study.

The missing raw downloads were then found in local Downloads/Outlook attachment cache, moved to the
D-drive raw-data target, and removed from the known C-drive download/cache locations. The member
dump was reingested and the arrival workflow was rerun from the restored D-backed data.

The final audit now produces:

- `data/processed/scene_networks/external_arrival_final_audit_event_windows.csv`
- `data/processed/scene_networks/external_arrival_final_audit_event_study.csv`
- `data/processed/scene_networks/external_arrival_final_audit_summary.md`

## Event-count read

The first script recovers `55,183` cell-level first-arrival events across all definitions.

| Definition | First arrival events | Analysis sample |
|---|---:|---:|
| `cross_city_any` | 29,625 | 2,269 |
| `cross_city_same_genre` | 16,024 | 1,383 |
| `cross_country_any` | 6,300 | 456 |
| `cross_country_same_genre` | 3,234 | 212 |

The analysis sample keeps events from `1988` to `2017` where the local `city x genre` cell has
`1-4` prior cumulative bands and has not yet crossed the operational emergence threshold.

This is a strong feasibility result. Even the strict cross-country same-genre definition has `212`
analysis-sample events, compared with only `9` usable post windows in the verified-death branch.

## Raw event-window read

The raw event windows show a visible rise in later same-genre band starts, but the event-year spike
is mechanically risky because the arrival is usually attached to a local band roster.

The cleaner descriptive margin is the average number of same-genre band starts in years `+1` to
`+3`, compared with years `-3` to `-1`.

| Definition | Starts pre `-3:-1` | Starts post `+1:+3` | Change | Emerges within 5y |
|---|---:|---:|---:|---:|
| `cross_city_any` | 0.253 | 0.398 | 0.145 | 0.513 |
| `cross_city_same_genre` | 0.269 | 0.431 | 0.161 | 0.542 |
| `cross_country_any` | 0.262 | 0.482 | 0.221 | 0.610 |
| `cross_country_same_genre` | 0.234 | 0.500 | 0.266 | 0.575 |

This is encouraging, but it is not causal. These cells are selected because they are already
subthreshold and active enough to receive an outside experienced musician.

## Matched-control read

The matched-control prototype focuses on `cross_country_same_genre`.

Matching rule:

- same country
- same genre family
- same calendar year
- `1-4` prior cumulative bands
- no nearby strict arrival event in the control cell
- nearest controls by prior cumulative bands and mean local starts over `t-3` to `t-1`

Matched output:

- treated events with at least one matched control: `184`
- matched control rows: `780`
- mean controls per treated event: `4.24`

Headline matched comparison:

- treated mean pre starts: `0.234`
- treated mean post `+1` to `+3` starts: `0.433`
- treated mean change: `0.199`
- control mean pre starts: `0.245`
- control mean post `+1` to `+3` starts: `0.344`
- control mean change: `0.100`
- mean DID-style change: `0.099`
- share of event-level DID changes above zero: `0.489`

## Own-band-excluded final audit

The final audit focuses on the strict `cross_country_same_genre` matched stack, rebuilds
band-level local starts, and removes the arriving musician's observed own band from treated
outcome counts when the band ID is available.

Final-audit output:

- matched treated stacks: `184`
- event-window rows: `10,604`
- arrival-associated bands removed at event year: `97`
- arrival-associated bands removed in years `+1` to `+3`: `0`

Matched event-study read:

| Relative year | Treated-control | Normalized DID | SE |
|---:|---:|---:|---:|
| -5 | -0.013 | 0.028 | 0.053 |
| -4 | 0.021 | 0.062 | 0.056 |
| -3 | -0.031 | 0.011 | 0.060 |
| -2 | -0.080 | -0.038 | 0.055 |
| -1 | -0.042 | 0.000 | 0.000 |
| 0 | -0.031 | 0.011 | 0.062 |
| 1 | -0.001 | 0.041 | 0.060 |
| 2 | 0.072 | 0.114 | 0.067 |
| 3 | 0.192 | 0.234 | 0.084 |

Compact read:

- mean normalized pre coefficient, `t=-5` to `t=-2`: `0.016`
- event-year normalized coefficient, `t=0`: `0.011`
- mean normalized post coefficient, `t=+1` to `t=+3`: `0.130`

## Interpretation

The channel is absolutely worth keeping alive as the best new causal follow-on candidate.

But the read is still not a knockout. The first matched comparison is positive on average but has
weak event-level sign consistency, and the own-band-excluded event study still needs concentration
checks. That means the channel currently looks feasible and suggestive, not yet paper-grade.

The strongest interpretation is:

- experienced outside arrivals are common enough to study
- strict cross-country same-genre arrivals are followed by more local same-genre entry on average
- similar subthreshold cells also grow, so the identifying variation needs tighter controls
- the own-band-excluded post path stays positive, but the branch still needs leave-country-out,
  leave-genre-out, and manual event audits

## Next robustness checks

The next pass should not broaden definitions. It should test whether the strict definition survives
basic robustness screens:

1. Add leave-country-out sensitivity.
2. Add leave-genre-out sensitivity.
3. Audit the top positive and negative events manually to see whether they are real local arrivals
   or database artifacts.

## Decision

Keep alive as a follow-on sidecar, not as part of the stabilized main paper yet.

This remains a better bet than more death searching or breakout recovery, but it has not cleared
the bar for inclusion in the stabilized main paper. The branch should remain outside the main draft
unless the own-band-excluded event-study survives basic country and genre concentration checks and
manual event inspection.
