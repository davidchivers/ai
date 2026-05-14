# 2026-05-11 Eleven-Hour PF Failsafe

Purpose: run one bounded parallel packet while the existing model grid,
continuation, and bridge/polish jobs finish. This is a numerical/model-closure
failsafe, not an open-ended broad search.

## Routes

- Rows 1-4: T60 residual-targeted polishing. The live T60 row is just above the
  usable threshold, and its binding report-horizon residual is around period 21.
- Rows 5-6: T80 residual-targeted polishing from the current best T80 row,
  separately focusing the two binding report windows around periods 20 and 37.
- Rows 7-8: longer hidden tail (`120`) with the same residual focus windows.
- Rows 9-10: softer terminal-reference closure, testing whether the terminal
  fixed-point boundary is over-pulling the reported transition.
- Rows 11-12: focused staged bridges from the best T60/T40 continuation sources
  into T80.
- Rows 13-14: small-shock T80 diagnostics. These are not target paper rows, but
  identify whether pure perfect-foresight continuation has a clean lower-shock
  path that could be used for a later homotopy checkpoint.

## Stop Rules

- Notify immediately if any T60 row is usable (`gap <= 0.001`).
- Notify immediately if any T80 row is usable.
- Mark `paper_safe` only at `gap <= 0.0002`.
- Do not submit another chained wave automatically. After this packet, checkpoint
  with the user before adding compute.
