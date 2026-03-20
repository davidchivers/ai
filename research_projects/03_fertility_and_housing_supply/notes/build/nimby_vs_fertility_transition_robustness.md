# Baby-boom transition robustness

This note runs a bounded robustness sweep around the current project-03 transition bridge.
The direct upstream NIMBY IRF is available only for the benchmark `+10%` shock, so the
robustness pass uses the in-project NIMBY proxy and fertility extension under matched
parameter changes.

## Replication check

- Fertility bridge max absolute error against MATLAB benchmark policy run: `6.395e-14`
- NIMBY-proxy bridge max absolute error against MATLAB benchmark policy run: `5.684e-14`

## Main read

### Shock size

- Fertility-extension post-price response range: `0.051` to `0.125`
- NIMBY-proxy post-price response range: `0.031` to `0.058`
- Fertility-extension young-homeownership trough range: `-0.0248` to `-0.0107`

### Price-fertility sensitivity

- Fertility-extension post-price response range: `0.049` to `0.052`
- NIMBY-proxy post-price response range: `0.031` to `0.031`
- Fertility-extension young-homeownership trough range: `-0.0121` to `-0.0104`

### Family-demand strength

- Fertility-extension post-price response range: `0.045` to `0.058`
- NIMBY-proxy post-price response range: `0.031` to `0.031`
- Fertility-extension young-homeownership trough range: `-0.0128` to `-0.0095`
