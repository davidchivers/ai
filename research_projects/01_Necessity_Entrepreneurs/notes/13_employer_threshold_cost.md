# Employer-threshold cost in the self-employment model

## Why this note exists

The self-employment branch already has a proportional hiring/search cost through
`kappa`. That object is realistic for vacancy posting, recruiting, and replacement,
but it does not by itself create a sharp wedge between:

- self-employed nonemployers: `n_h = 0`
- employer entrepreneurs: `n_h > 0`

This note records the case for a separate employer-threshold cost `f_hire`, the
source chain behind it, and the first experimental result.

## Model object

In the self-employment branch, the entrepreneur's static profit problem is:

```text
pi = x k^alpha (l_e + xi z n_h)^gamma
     - w (1 + psi tau) z n_h
     - r k
     - kappa * rho z n_h / q(theta)
     - f_hire * 1{n_h > 0}
```

Interpretation:

- `kappa` is the smooth search-and-matching hiring cost.
- `f_hire` is a discrete employer-threshold cost paid when the entrepreneur crosses
  from no hired workers to positive hired labor.

So `f_hire` is not a replacement for search frictions. It is an additional wedge at
the first-worker margin.

## Source chain

### 1. Direct evidence on the first-worker margin

The closest paper to our object is:

- Cockx and Desiere (2024), *Labour costs and the decision to hire the first employee*:
  https://doi.org/10.1016/j.euroecorev.2024.104859
  RePEc summary: https://ideas.repec.org/a/eee/eecrev/v170y2024ics0014292124001880.html

Main result:

- a Belgian reform permanently reduced the labor cost of the first employee by `13%`
- the number of new first-time employers jumped by `31%`
- implied elasticity of hiring the first employee with respect to labor cost:
  about `-2.39`

Mapped empirical object:

- transition from nonemployer to employer

Why it matters here:

- it is direct evidence that the first-worker margin is highly sensitive to labor costs
- this supports treating the self-employed/employer boundary as distinct from smooth
  proportional hiring costs

### 2. U.S. evidence that even small new-employer labor costs matter

- Guo and Wallskog (2025), *New employer payroll taxes and entrepreneurship*:
  https://doi.org/10.1016/j.jpubeco.2025.105469
  Working paper version: https://research.upjohn.org/up_workingpapers/410/

Main result:

- new-employer payroll taxes are small in dollar terms, about `$350` per worker on
  average in the U.S. setting they study
- even these small costs reduce firms' decisions to hire their first workers
- estimated elasticity of the number of new employers to taxes: about `-0.1`

Mapped empirical object:

- first-worker hiring by young firms in the U.S.

Why it matters here:

- it shows that even modest employer-side labor costs affect the extensive margin
  of becoming an employer
- it gives a U.S. institutional reason to include an employer-threshold wedge in
  addition to the vacancy cost `kappa`

### 3. Compliance-cost evidence for entrepreneurs

- Harju, Matikka, and Rauhanen (2019), *Compliance costs vs. tax incentives: Why do entrepreneurs respond to size-based regulations?*:
  https://doi.org/10.1016/j.jpubeco.2019.02.003
  RePEc summary: https://ideas.repec.org/a/eee/pubeco/v173y2019icp139-164.html

Main result:

- entrepreneurs respond strongly to size-based regulation around a VAT threshold
- the evidence indicates the response is driven by compliance costs rather than the
  tax rate itself

Mapped empirical object:

- entrepreneur response to a discrete increase in compliance burden

Why it matters here:

- it supports the economic interpretation of `f_hire` as a compliance/administrative
  threshold cost of becoming an employer

### 4. Broader hiring-cost evidence and caution

- Blatter, Muehlemann, and Schenker (2012), *The costs of hiring skilled workers*:
  https://doi.org/10.1016/j.euroecorev.2011.08.001
  RePEc summary: https://ideas.repec.org/a/eee/eecrev/v56y2012i1p20-35.html

Main result:

- average hiring costs are large, around `10` to `17` weeks of wage payments
- marginal hiring costs are convex
- they find no fixed cost component in that Swiss skilled-worker setting

Mapped empirical object:

- average external hiring costs for skilled workers

Why it matters here:

- it confirms that hiring costs are economically important
- but it also warns that the literature does not cleanly pin down a universal fixed
  employer cost

## Transparency conclusion

The honest reading of the literature is:

- there is strong evidence that the first-worker margin matters and that discrete
  employer-side costs can have large effects
- there is also evidence that compliance costs matter for entrepreneurs
- but there is not a clean directly observed structural parameter that maps one-to-one
  into our `f_hire`

So `f_hire` should be described as:

- evidence-motivated
- not directly estimated
- disciplined as an initial calibration or sensitivity parameter

## First experiment now coded

I added:

- `case 147 = case 146 + f_hire`

with:

```text
f_hire = 0.25
```

Status of the number:

- source: not directly observed
- empirical object being mapped: a modest employer-threshold hurdle on top of the
  existing search cost `kappa`
- transformation: initial experimental value in model units
- status: disciplined experimental choice

## What case 147 does

Baseline comparison versus `case 146`:

- `case 146` baseline:
  - entrepreneur share `0.1787`
  - self-employed share among entrepreneurs `0.4387`
  - employer share among entrepreneurs `0.5613`

- `case 147` baseline:
  - entrepreneur share `0.1781`
  - self-employed share among entrepreneurs `0.5768`
  - employer share among entrepreneurs `0.4232`

Interpretation:

- total entrepreneurship barely changes
- the self-employed/employer composition moves strongly in the desired direction
- this is exactly what we would want from an employer-threshold cost: it targets the
  first-worker margin rather than shrinking entrepreneurship mechanically

## Provisional recommendation

For now:

1. keep `kappa` as the smooth hiring/search cost
2. keep `f_hire` conceptually distinct as the employer-threshold cost
3. present `f_hire` as a transparent experimental choice rather than a fully
   calibrated parameter
4. use `case 147` as a promising next benchmark candidate, subject to a short set
   of follow-up runs

The next clean checks are:

1. `case 147` with `UI = 0.00`
2. a nearby value such as `f_hire = 0.15` or `0.35`
3. optional size-dependent closure risk only after deciding whether `f_hire` is
   part of the benchmark
