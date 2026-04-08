# entrepreneur closure risk by education

## purpose

This note documents where the proposed entrepreneur closure-risk parameter comes from, how it is mapped into the model, and which parts are evidence versus calibration choice. The goal is transparency: the paper should not report a new transition-risk parameter without a clear provenance chain.

## object in the model

In the self-employment extension, let `rho_e(h)` denote the probability that an entrepreneur of education group `h` is forced to close the business and move out of entrepreneurship in the next period.

This is not the same object as worker separation `rho(h)`. It is an entrepreneurial closure or forced-exit risk, intended to capture business fragility on top of the existing `x` shock.

## source chain

### 1. average closure level

I am treating the average entrepreneur closure rate as an initial calibration choice rather than a directly observed model moment.

The anchor is U.S. business-survival evidence from official sources:

- [BLS survival rates, 2013 cohort](https://www.bls.gov/bdm/us_age_naics_00_table7.txt): one-year survival is `79.6%`, so first-year exit is `20.4%`.
- [BLS entrepreneurship and survival](https://www.bls.gov/opub/ted/2016/entrepreneurship-and-the-age-of-startups.htm): the 1998 cohort has a four-year survival rate of `44.0%`.
- [Census working paper, Headd (2001)](https://www.census.gov/library/working-papers/2001/adrm/ces-wp-01-01.html): about half of new employer firms survive at least four years, and about one-third of nonemployer firms survive that long.

These official numbers imply that startup closure is substantial. I therefore set the initial average entrepreneur closure rate to:

```text
rho_e_bar = 0.15
```

This is intentionally below the startup first-year exit rate from BLS because the model's entrepreneur pool includes incumbent businesses, not only new startups.

### 2. education gradient

Direct U.S. estimates of entrepreneur closure risk by education are limited, and the literature is not fully one-sided. The most usable U.S. evidence I found for a relative education gradient is:

- [Grashuis (2021), PLOS One](https://pmc.ncbi.nlm.nih.gov/articles/PMC8670589/): CPS competing-risk estimates for self-employment transitions during 2020. In Table 4, the sub-hazard ratio for transition from self-employment to unemployment is lower for more educated individuals. Using high school as the omitted category, the reported sub-hazard ratios are:
  - associate degree: `0.891`
  - bachelor's degree: `0.873`
  - graduate degree: `0.837`

I map these into the model's three education groups as:

- low education: `1.000`
- medium education: `0.891`
- high education: `0.855`

where the high-education value is the simple average of bachelor's and graduate relative hazards:

```text
(0.873 + 0.837) / 2 = 0.855
```

This produces a conservative gradient, which is deliberate. The broader literature suggests education helps survival, but the causal strength is not completely settled:

- [Headd (2001)](https://ideas.repec.org/p/cen/wpaper/01-01.html): good education is listed among the major factors associated with remaining open.
- [Asoni and Sanandaji (2017)](https://ideas.repec.org/a/kap/jecstr/v6y2017i4d10.1007_s40843-017-0061-9.html): after correcting for selection, college education does not appear to improve business survival much.

So the model should use a modest monotone education gradient, not a dramatic one.

## mapping into the model

Let the model education shares be:

```text
pi_h = {0.109, 0.581, 0.310}
```

and let the relative education multipliers be:

```text
m_h = {1.000, 0.891, 0.855}
```

Then I set:

```text
rho_e(h) = rho_e_bar * m_h / sum_j pi_j * m_j
```

with:

```text
rho_e_bar = 0.15
```

The weighted average relative hazard is:

```text
sum_j pi_j * m_j = 0.891721
```

So the initial education-specific entrepreneur closure rates are:

```text
rho_e(h) = {0.168214, 0.149879, 0.143823}
```

Rounded for the paper table:

```text
rho_e(h) = {0.168, 0.150, 0.144}
```

## interpretation

This parameter is:

- partly evidence-based, because the education gradient comes from U.S. CPS estimates and the level is anchored to official U.S. business survival facts;
- partly a calibration choice, because the exact average closure rate `0.15` is imposed as a conservative intermediate value rather than directly estimated from a single matching dataset.

So in the paper this should be described as an initial calibration rule, not as a directly observed statistic.

## UI treatment after closure

An important institutional point is that entrepreneur closure should not automatically imply regular unemployment insurance receipt.

Official U.S. guidance points that way:

- [U.S. Department of Labor, general UI eligibility](https://www.dol.gov/general/topic/unemployment-insurance): regular UI is tied to work and wage requirements in a base period.
- [IRS, employment taxes](https://www.irs.gov/businesses/small-businesses-self-employed/employment-taxes): self-employment tax covers Social Security and Medicare, not regular unemployment insurance.
- [IRS, unemployment compensation](https://www.irs.gov/individuals/employees/unemployment-compensation): unemployment compensation is distinct from self-employment tax treatment.
- [DOL PUA guidance](https://www.dol.gov/node/160837): self-employed workers were explicitly brought into a special temporary pandemic program because they were outside regular UI coverage.

So the benchmark interpretation for the model should be:

- entrepreneur closure means forced exit from business;
- closure moves the household into unemployment or non-employment;
- but closure does not automatically create regular UI eligibility.

If later we want entrepreneurs with recent wage history to retain UI eligibility after closure, that requires an additional eligibility state. The current model does not track that yet.

## recommended paper wording

Use language like:

```text
Entrepreneur closure risk by education is calibrated in two steps. We set an average annual closure rate of 0.15, guided by U.S. business-survival evidence from BLS and Census, and impose a modest education gradient using relative self-employment-to-unemployment hazards from Grashuis (2021). Normalizing these relative hazards to the model's education shares yields rho_e(h) = {0.168, 0.150, 0.144}.
```

## status

- This provenance rule is now also recorded in `_shared/memory/RESEARCH_STYLE.md`.
- The self-employed paper should include both the table row and a short calibration paragraph, not only the row.
- The self-employed paper should also state that entrepreneur closure does not automatically confer regular UI eligibility in the benchmark.
- The code does not use `rho_e(h)` yet. This note is documenting the proposed calibration before implementation.
