# Easy Summary: What Could Have Messed Results Up
Date: 2026-02-18

This is a plain-language summary for coauthors.

## Three biggest risks
1. Entrepreneur output appears to be coded as zero in key simulation lines.
2. Education index is used before assignment in some loops.
3. Hiring/search cost uses a matching object that may not match the equation in the paper (`p` vs `q`).

If (1) and (2) are present in production runs, they can materially change output, welfare, and entrepreneurship moments.

## What seems okay
- Worker budget equations in the code line up with the current `.lyx` formulation.
- The firm FOC section in `.lyx` looks corrected relative to older drafts.

## Recommendation
Treat items (1) and (2) as immediate hotfixes, then settle the `p(theta)` vs `q(theta)` mapping before new calibration runs.
