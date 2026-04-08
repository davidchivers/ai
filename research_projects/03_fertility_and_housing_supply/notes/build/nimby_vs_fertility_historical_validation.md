# Historical baby-boom validation

This note compares the postwar aggregate fertility path in the legacy NIMBY data against
the current NIMBY and fertility-extension baby-boom transitions.

## Data and alignment

- Historical data source: `C:/Users/Dave_/Dropbox/Zac and David/Data/merged_birthrates_migrationweights.dta`
- Aggregate series used in the main figure: `metarea == 0`, `weightedbirthrate`, `1940-1995`
- Robustness series: state-average `birthrates_updated.dta`
- Normalization: divide by the mean pre-boom birth rate over `1940-1945`
- Post-boom alignment: compare data from `1956` onward to model periods `t >= 10`

## Main read

- Exact calendar alignment is imperfect because the historical baby boom is more persistent
  than the toy 10-year model shock.
- The informative comparison is therefore the post-boom decline rather than the raw peak.
- On that aligned post-boom path, the fertility extension fits modestly better than the
  NIMBY line at every horizon currently checked.

## RMSE by horizon

- `10` years: NIMBY `RMSE = 0.119`, fertility extension `RMSE = 0.104`
- `20` years: NIMBY `RMSE = 0.183`, fertility extension `RMSE = 0.177`
- `30` years: NIMBY `RMSE = 0.226`, fertility extension `RMSE = 0.218`
- `40` years: NIMBY `RMSE = 0.243`, fertility extension `RMSE = 0.233`

## Interpretation

- The original NIMBY transition returns immediately to baseline fertility after the
  imposed boom window.
- The fertility extension adds a later dip below baseline, which is closer to the shape
  of the historical post-boom decline.
- The improvement is modest rather than dramatic, so this should be read as a validation
  sign check, not a formal estimation result.
