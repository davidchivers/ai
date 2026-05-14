# 2026-05-11 Perfect-Foresight Bridge/Polish Probes

Purpose: use the already-cleared T20/T40 continuation rows to push the staged
perfect-foresight ladder toward T60 and T80 without submitting another broad
model grid.

## Logic

- Rows 1-3 target T60. This is the highest-value near-term paper result because
  T60 is just above the usable threshold and T20/T40 are already usable.
- Rows 4-5 are T80 bridge probes seeded from the best T60/T40 rows. These test
  whether a staged seed improves the hard T80 object.
- Row 6 is a conservative polish of the current best T80 grid row. This is less
  likely than the T60 rows, but cheap to test in parallel.

## Verdict Rules

- `paper_safe`: `max_abs_path_gap <= 0.0002`.
- `usable`: `max_abs_path_gap <= 0.001`.
- `survivor`: `0.001 < max_abs_path_gap <= 0.003`.
- `dead`: missing, failed, or best gap above `0.003`.

Do not submit another chained wave automatically. If T60 clears, treat that as a
paper-relevant staged-RE result and checkpoint before deciding whether to push a
T60-to-T80 extension.
