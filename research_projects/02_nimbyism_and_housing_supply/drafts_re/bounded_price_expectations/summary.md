# Bounded price-expectations artifact

## Status

Built a first bounded price-expectations comparison for `bound40_baby_rss_l4`.
This is a finite-horizon price-belief prototype, not a full T80 rational-
expectations result and not the final Moll-aligned route.

## Model object

- Expectations label: bounded price expectations.
- Run tag: `bound40_baby_rss_l4`.
- Report horizon: 40 years.
- Internal horizon: 80 years.
- Tail rule: 40-year return-to-steady-state tail.
- Terminal anchor: `terminal_fixed_point`.
- Political pass-through: `0.006`.
- Vote timing: four-year block vote with four-year lagged pass-through proxy.
- Update method: `basis_broyden`.
- Best outer iteration: `7`.

## Validation

- Ranked report-horizon path gap: `0.000990326504390953`.
- Recomputed report-horizon path gap: `0.000990326504390731`.
- Usable gate: `0.001`.
- Paper-safe gate: `0.0002`.
- Verdict: usable, not paper-safe.

## Comparison to no-RE

Comparator: `nore80bv4_006`, plotted over the same 40 reported years.

- Bounded price-expectations trough: `-0.109076964063` percent.
- No-RE comparator trough: `-0.21341944853` percent.
- Difference in troughs, bounded minus no-RE: `0.104342484467` percentage points.

## Files

- Figure: `figure/bounded_price_expectations_vs_nore_0513.svg`.
- Plotted data: `figure/bounded_price_expectations_vs_nore_0513.csv`.
- Validation table: `figure/bounded_price_expectations_validation_0513.csv`.
- Source copies: `source/`.

## Paper label

Use "bounded price expectations" or "finite-horizon price beliefs." Do not call
this full RE.

## Moll alignment

This object is only partially aligned with Moll's challenge. It is tractable and
uses direct price expectations, but the 40-year horizon and return-to-steady-
state tail are not yet empirically disciplined, and beliefs do not update from
actual model outcomes. The actual Moll-aligned route is now
`../moll_direct_price_beliefs/criteria_audit.md`.
