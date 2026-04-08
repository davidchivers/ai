# Failure timing, capital loss, and legal form

## Why this note exists

The self-employment branch raises three linked questions:

1. What does the entrepreneur actually receive in the current period: profit, a wage, or some mixed object?
2. What is lost when the business fails?
3. Do we need to distinguish incorporated and unincorporated firms immediately?

This note records the current answer, the sources behind it, and the first-pass coding choice.

## What the literature suggests

### 1. For self-employment, current income is not a clean wage-profit split

The national accounts treatment is helpful here. The OECD glossary defines `mixed income` as the balancing item for unincorporated enterprises owned by households, and notes that it contains both the remuneration for work done by the owner and the return to the entrepreneur that cannot be separately identified as labor or capital income.

Source:
- OECD glossary, `mixed income`: https://stats.oecd.org/glossary/detail.asp?ID=1638

Implication for the model:
- For the nonemployer self-employed margin, it is defensible to interpret current entrepreneurial flow income as `owner mixed income`, rather than forcing an explicit owner wage plus residual profit split in the first pass.

### 2. Entrepreneurial capital is illiquid, so failure should destroy some business value

Wang, Wang, and Yang (2012) model entrepreneurship with incomplete markets, borrowing constraints, and capital illiquidity. Their core point is that capital illiquidity is central for entry, exit, and risk management, and that the exit option matters because entrepreneurial capital is not frictionlessly reversible.

Sources:
- NBER working paper version: https://www.nber.org/papers/w16843
- Journal of Financial Economics version: https://doi.org/10.1016/j.jfineco.2012.05.002

Chen, Miao, and Wang (2010) also emphasize nondiversifiable entrepreneurial risk and exit decisions in entrepreneurial finance.

Source:
- Review of Financial Studies: https://academic.oup.com/rfs/article/23/12/4348/1601374

Implication for the model:
- Failure should not be modeled as a purely cosmetic occupational relabeling.
- But it also need not wipe out all household wealth.
- A reasonable first step is partial loss of installed business capital on failure.

### 3. Incorporated and unincorporated activity are meaningfully different, but that is a second-pass extension

Levine and Rubinstein show that incorporated and unincorporated self-employment differ in economically important ways, including selection and earnings patterns. That makes legal form a real issue, not a semantic one.

Sources:
- NBER working paper: https://www.nber.org/papers/w19276
- Journal version (`Selection into Entrepreneurship and Self-Employment`): https://doi.org/10.1093/restud/rdx010

Implication for the model:
- A richer version should likely distinguish:
  - unincorporated nonemployer self-employment
  - employer entrepreneurship / incorporated-type firms
- But this should not be the first pass. It would multiply both state-space and interpretation questions too early.

## Current modeling conclusion

The first-pass interpretation should be:

- Current-period self-employment income is `mixed income`.
- Business failure happens at the end of the period, after current operating income is realized.
- Failure destroys the business continuation value and pushes the household into the non-UI unemployment state next period.
- Failure also destroys some installed business capital.
- Failure does **not** wipe out all household assets in the first pass.

This avoids two bad extremes:

- Too weak: failure only changes next period's label.
- Too strong: failure eliminates all current entrepreneurial income and/or wipes out household wealth.

## First experiment now coded

I coded a new self-employment experiment case:

- `case 145`: harsh stress test
  - closure risk on entrepreneurs
  - no regular UI after closure
  - closure removes current entrepreneurial income
  - result: too harsh; entrepreneurship collapses to zero in baseline

- `case 146`: first-pass capital-loss experiment
  - closure risk on entrepreneurs
  - no regular UI after closure
  - current-period entrepreneurial income is preserved
  - failure reduces next-period assets by a fraction of installed capital

The current first-pass law of motion after closure is:

```text
a'_closure = max(a_l, a' - delta_k * k')
```

with:

```text
delta_k = 0.25
```

Interpretation:
- the entrepreneur loses `25%` of installed business capital on failure
- `75%` is effectively recoverable in the first experiment

## Where the `25%` comes from

This is **not** a directly estimated model parameter. It is an initial experimental choice.

The exact provenance is:

- source idea: entrepreneurial capital is illiquid and exit destroys some business value
  - Wang, Wang, and Yang (2012)
  - Chen, Miao, and Wang (2010)
- transformation: translate that qualitative mechanism into a simple reduced-form capital-loss share on failure
- status: initial experimental choice, not yet a calibrated estimate

Why `0.25` in the first experiment:
- it is meant to be a mild first pass rather than an aggressive liquidation-loss assumption
- it is large enough to make failure economically meaningful
- it avoids the stronger and legally messier assumption that household wealth is broadly destroyed

So the correct paper language is:

- `delta_k = 0.25` is a first-pass experimental assumption motivated by the literature on entrepreneurial capital illiquidity and exit, not a directly estimated empirical parameter.

## What is not in the first pass

Not yet included:

- separate incorporated versus unincorporated firm types
- different failure technologies by legal form
- explicit owner wages for employer entrepreneurs
- bankruptcy law or limited liability structure

## Recommended next step

Use `case 146` as the main diagnostic run, not `case 145`.

If `case 146` still produces implausible baseline moments, the next extension should be:

1. higher closure risk for nonemployers than employers, or
2. different capital-loss rates for nonemployers versus employers

Only after that should the model split incorporated and unincorporated firms explicitly.
