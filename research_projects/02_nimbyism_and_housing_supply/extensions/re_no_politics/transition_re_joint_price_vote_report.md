# Joint price and vote experiment report

Generated: 2026-04-13 21:46:38

## Goal

- Take the bounded `T = 4` political-path packet one step further by feeding political pressure back into the price path.
- Keep the update heuristic and bounded: one housing solve per outer step, then a small log-price adjustment proportional to coalition-weighted vote share.

## Iteration summary

- joint iter 1: residual norm = 0.116671; max price gap = 0.167264; max abs weighted vote = 0.948715; adjusted price range = [1.998155, 1.999042]
- joint iter 2: residual norm = 0.116676; max price gap = 0.166960; max abs weighted vote = 0.948714; adjusted price range = [1.996312, 1.997632]

## Final joint iteration ($joint\_iter = 2)

- 2010: input = 1.998769; housing candidate = 1.999059; weighted vote share = -0.928211; politically adjusted = 1.997204; implied = 1.998769
- 2011: input = 1.998922; housing candidate = 1.999289; weighted vote share = -0.925081; politically adjusted = 1.997440; implied = 2.087920
- 2012: input = 1.999042; housing candidate = 1.999475; weighted vote share = -0.922332; politically adjusted = 1.997632; implied = 2.166436
- 2013: input = 1.998155; housing candidate = 1.998155; weighted vote share = -0.922941; politically adjusted = 1.996312; implied = 2.149048

## Read

- This is still not a solved political RE fixed point. It is a bounded joint-update experiment.
- The point is to see whether political pressure pushes in the same direction as the housing-clearing update or against it.
- If coalition-weighted vote share is negative while implied prices are above the current path, then the two forces are working against each other.
- That is the crucial bounded diagnostic before attempting a more serious joint solver.
