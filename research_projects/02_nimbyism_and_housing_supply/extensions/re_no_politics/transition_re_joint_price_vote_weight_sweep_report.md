# Joint price and vote weight sweep report

Generated: 2026-04-13 21:50:14

## Goal

- Check whether the bounded conflict between housing pressure and political pressure is robust to the political update weight.
- Hold the underlying `T = 4` housing solve fixed and vary only the vote-update weight.

## Summary

- weight = 0.0000: adjusted range = [2.000000, 2.000887]; mean adjustment = 0.000000; max abs adjustment = 0.000000; conflict share = 0.750
- weight = 0.0005: adjusted range = [1.999077, 1.999965]; mean adjustment = -0.000925; max abs adjustment = 0.000928; conflict share = 0.750
- weight = 0.0010: adjusted range = [1.998155, 1.999042]; mean adjustment = -0.001849; max abs adjustment = 0.001856; conflict share = 0.750
- weight = 0.0020: adjusted range = [1.996312, 1.997199]; mean adjustment = -0.003696; max abs adjustment = 0.003711; conflict share = 0.750
- weight = 0.0050: adjusted range = [1.990792, 1.991681]; mean adjustment = -0.009228; max abs adjustment = 0.009264; conflict share = 0.750

## Highest tested weight ($\omega_{vote} = 0.005)

- 2010: housing candidate = 2.000625; vote share = -0.928212; adjusted price = 1.991361; conflict = 0
- 2011: housing candidate = 2.000772; vote share = -0.925081; adjusted price = 1.991539; conflict = 1
- 2012: housing candidate = 2.000887; vote share = -0.922332; adjusted price = 1.991681; conflict = 1
- 2013: housing candidate = 2.000000; vote share = -0.922941; adjusted price = 1.990792; conflict = 1

## Read

- The base bounded housing solve is unchanged across the sweep; only the political feedback weight moves.
- If conflict share stays high across the whole weight grid, then the sign opposition is structural under the current bounded packet, not a quirk of the original `0.001` choice.
- If larger weights only scale the downward adjustment while preserving the same sign pattern, then the main conclusion is robust: the political update pushes against the housing-clearing update.
