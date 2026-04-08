---
title: "Fertility benchmark versus NIMBY benchmark"
date: "2026-03-20"
fontsize: 11pt
geometry: margin=1in
header-includes:
  - \usepackage{graphicx}
  - \usepackage{microtype}
  - \usepackage{xurl}
  - \setlength{\emergencystretch}{3em}
---

# Fertility benchmark versus NIMBY benchmark

## Purpose

This note compares the current corrected-code household fertility benchmark in project 03 to the upstream project-02 NIMBY benchmark. The comparison uses the same steady-state voting convention in both models:

- fix `rbPos = 0.03`
- trace `totalvote` over the house-price grid
- locate the sign change in that vote object

So this is a benchmark-to-benchmark model comparison, not a full two-dimensional market-clearing exercise over both `a_price` and `rbPos`, and not an empirical claim.

## Executive summary

Three facts matter.

1. The project-03 solver is a true extension of the NIMBY benchmark. When fertility and crowding are shut off, it reproduces the upstream steady-state object exactly.
2. Under the active corrected calibration, the fertility extension shifts the vote schedule toward lower house prices relative to upstream NIMBY.
3. The raw vote totals and the normalized vote-per-mass object point in the same direction once the forward-pass mass bug is removed. The level comparison should therefore be read with both metrics in view.

## Exact nesting result

With `C = 1` and the fertility/crowding terms shut off, the project-03 solver reproduces the upstream project-02 benchmark exactly at the same `(a_price, rbPos)`.

| Check | Gap |
|---|---:|
| Distance gap | 0 |
| Vote gap | 0 |
| Debt gap | 0 |

This is the key technical result behind the comparison: project 03 nests project 02 exactly.

## What changes relative to NIMBY

### Intuition first

The upstream NIMBY benchmark is a life-cycle housing-and-voting model. The fertility benchmark keeps that structure and adds a family formation margin.

The important modeling change is that project 03 separates:

- `p_t`: children ever born, a permanent parity state
- `h_t`: children currently at home, a temporary crowding state

A birth raises both states today. Later, children can leave home, so `h_t` falls while `p_t` stays fixed.

### Side-by-side structure

| Object | NIMBY benchmark | Fertility benchmark |
|---|---|---|
| Household state | assets, housing, income, age | assets, housing, income, age, parity, children at home |
| Flow utility | consumption, housing, bequest | consumption, housing, bequest, child utility, crowding |
| Birth choice | absent | parity-specific birth branch |
| Child dynamics | absent | leave-home transition lowers children-at-home only |
| Political block | price perturbation vote | same vote logic retained |
| Upstream nesting | baseline object | exact when fertility is shut off |

In equation form, the NIMBY benchmark values housing services directly. The fertility benchmark instead values effective housing

$$
H^{eff}_t = \frac{H_t}{(1 + \lambda_c h_t)^{\psi_c}},
$$

and then adds a birth branch with parity-specific birth utility and housing-price-sensitive birth cost.

In plain language, project 03 does not just add a fertility coefficient. It changes the household problem so that families care about housing costs for two separate reasons:

1. housing itself is expensive
2. children at home make crowding more expensive

That is the main mechanism behind the benchmark comparison below.

## Side-by-side benchmark comparison

### Benchmark convention

- Upstream NIMBY is evaluated on its native household grid `I = 50`, `J = 10`.
- The fertility benchmark is evaluated on `I = 60`, `J = 14`.

The finer project-03 grid matters. In the fertility extension, the coarser `50 x 10` grid created spurious extra sign changes in the vote schedule. The `60 x 14` benchmark removed that numerical wiggle and is now the active corrected-code benchmark resolution.

### Crossing comparison

| Metric | NIMBY benchmark | Fertility benchmark |
|---|---:|---:|
| Vote sign-change bracket | `[2.25, 2.50]` | `[1.75, 2.00]` |
| Lower-bracket vote | `1.4834` | `0.0084` |
| Upper-bracket vote | `-3.3779` | `-0.3332` |
| Linear-refined `a_price` | `2.326287` | `1.751853` |
| Vote at refined price | `0.228450` | `0.016237` |
| Vote per unit mass at refined price | `0.035764` | `0.002634` |
| Total household mass at refined price | `6.387684` | `6.163346` |
| Debt stock at refined price | `0.668415` | `44.351720` |

The main benchmark comparison is therefore simple: under the corrected calibration, the fertility extension lowers the steady-state crossing price relative to upstream NIMBY.

The natural interpretation is that family-forming households place more value on lower housing costs once crowding enters the household problem. That statement is an inference from the benchmark comparison, not a separate identified result.

Raw vote totals are not the right cross-model scale comparison by themselves because the two models aggregate over different stationary mass objects. The cleaner cross-model comparison is the sign pattern, the crossing price, and the normalized vote-per-mass schedule.

### Common price-grid comparison

The common-price table isolates how the vote object shifts at the same house prices. It reports both raw vote and vote per unit mass.

| `a_price` | NIMBY vote | Fertility vote | NIMBY vote / mass | Fertility vote / mass | Fertility avg. birth rate | Fertility parity at age 50 `[0,1,2,3+]` |
|---:|---:|---:|---:|---:|---:|---|
| 1.50 | `5.3425` | `0.2367` | `0.8364` | `0.0384` | `0.6555` | `[0.070, 0.166, 0.349, 0.415]` |
| 1.75 | `5.0145` | `0.0084` | `0.7850` | `0.0014` | `0.5977` | `[0.134, 0.218, 0.333, 0.315]` |
| 2.00 | `4.1475` | `-0.3332` | `0.6493` | `-0.0541` | `0.5290` | `[0.224, 0.256, 0.293, 0.228]` |
| 2.25 | `1.4834` | `-0.3452` | `0.2322` | `-0.0560` | `0.4506` | `[0.335, 0.271, 0.238, 0.155]` |
| 2.50 | `-3.3779` | `-0.4321` | `-0.5288` | `-0.0701` | `0.3647` | `[0.460, 0.264, 0.179, 0.097]` |
| 2.75 | `-1.2922` | `-0.3788` | `-0.2023` | `-0.0615` | `0.2772` | `[0.587, 0.237, 0.122, 0.053]` |
| 3.00 | `-1.2165` | `-0.3420` | `-0.1904` | `-0.0555` | `0.1977` | `[0.703, 0.196, 0.075, 0.026]` |
| 3.25 | `-1.2032` | `-0.3102` | `-0.1884` | `-0.0503` | `0.1344` | `[0.796, 0.151, 0.042, 0.011]` |
| 3.50 | `-1.1970` | `-0.3128` | `-0.1874` | `-0.0507` | `0.0890` | `[0.863, 0.110, 0.022, 0.004]` |

At the same `a_price = 2.00`, the contrast is especially sharp:

- NIMBY still has strongly positive vote support for higher prices
- the fertility benchmark is already slightly negative

That contrast survives normalization by stationary mass, so the leftward shift is not a reporting artefact.

Another way to say the same thing is:

- in upstream NIMBY, `a_price = 2.00` is still below the crossing price
- in the fertility benchmark, `a_price = 2.00` is already above the crossing price

So the vote schedule has shifted left.

The panel figure below summarizes the same comparison visually. The top row separates raw vote from vote per unit mass so the scale issue is transparent rather than buried. The lower panels then show debt and the new family-state objects that appear only in project 03.

\begin{figure}[htbp]
\centering
\includegraphics[width=\textwidth]{fertility_vs_nimby_benchmark_panels.png}
\end{figure}

## Fertility benchmark as a new benchmark object

Evaluating the project-03 benchmark at its refined crossing price `a_price = 1.751853` gives the following family-state diagnostics.

| Metric | Value |
|---|---:|
| Average birth rate | `0.5972` |
| Parity age 50: 0 children | `0.1341` |
| Parity age 50: 1 child | `0.2183` |
| Parity age 50: 2 children | `0.3330` |
| Parity age 50: 3+ children | `0.3146` |
| Any child at home, age 40 | `0.8119` |
| Any child at home, age 50 | `0.7945` |
| Mean children at home, age 40 | `1.2870` |
| Mean children at home, age 50 | `1.5324` |

These are exactly the new benchmark objects that do not exist in upstream NIMBY. They are why project 03 should not be read as just a price-shifted copy of the older model.

## Reading the comparison correctly

Five caveats matter.

1. This is a steady-state comparison at fixed `rbPos = 0.03`, not the full two-dimensional market-clearing problem.
2. The project-03 benchmark uses a finer `I = 60`, `J = 14` household grid because the coarser `50 x 10` grid produced numerical vote wiggles in the fertility extension.
3. The upstream NIMBY benchmark remains on its native household grid.
4. The refined prices are linear interpolations inside the sign-change bracket. They are the correct benchmark summary for the grid search, but rerunning the nonlinear solver exactly at those interpolated prices does not force vote to equal zero exactly.
5. The benchmark comparison is about the model object, not about empirical identification.

## Bottom line

Relative to the upstream NIMBY benchmark, the corrected-code fertility benchmark now does four clean things:

- it nests the old model exactly when fertility is shut off
- it gives children a real household-state interpretation instead of a proxy term
- it shifts the benchmark vote schedule toward lower house prices
- it produces new benchmark objects for completed fertility and children at home

That is the cleanest short description of where project 03 stands relative to the NIMBY benchmark.

## Files generated

- `notes/build/fertility_vs_nimby_reproduction_check.csv`
- `notes/build/nimby_market_clearing_grid.csv`
- `notes/build/fertility_vs_nimby_benchmark_summary.csv`
- `notes/build/fertility_vs_nimby_common_price_grid.csv`
- `notes/build/fertility_vs_nimby_benchmark_panels.png`
- `notes/build/fertility_vs_nimby_benchmark_panels.pdf`
- `notes/build/fertility_vs_nimby_benchmark_report.md`
- `notes/build/fertility_vs_nimby_benchmark_report.pdf`
