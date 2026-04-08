# 07 Self-employment static tests

## Purpose

This note records the first static-discipline experiments for the self-employment version
of the model. The goal was to see whether the excessive entrepreneurial mass in the
baseline comes mainly from self-employment being too attractive in a static sense, before
adding entrepreneur closure risk.

## Cases run

Using `main_2025_v1_case113_self_employment.cpp` in the isolated self-employment runtime:

- `141`: self-employment root baseline, `self_employment_x_scale = 1.00`
- `142`: attenuated self-employment productivity, `self_employment_x_scale = 0.50`
- `143`: stronger attenuation, `self_employment_x_scale = 0.25`
- `144`: attenuation plus fixed hiring cost,
  `self_employment_x_scale = 0.50`, `self_employment_hiring_fixed_cost = 1.0`

Common settings:

- `UI = 0.40`
- `MaxIterAgg = 40`
- `RngSeed = 12345`

## Main results

### Case 141: raw self-employment baseline

- entrepreneur share: `0.38345`
- self-employed share among entrepreneurs: `0.61307`
- employer share among entrepreneurs: `0.38693`
- mean entrepreneur labor demand: `2.03`

Implied shares in the full population:

- self-employed: `0.2351`
- employers: `0.1484`

Interpretation:

- the self-employment margin is active
- but baseline entry is far too high

### Case 142: attenuation only (`x_scale = 0.50`)

- entrepreneur share: `0.38216`
- self-employed share among entrepreneurs: `0.00000`
- employer share among entrepreneurs: `1.00000`
- mean entrepreneur labor demand: `2.03`

### Case 143: stronger attenuation only (`x_scale = 0.25`)

- entrepreneur share: `0.38101`
- self-employed share among entrepreneurs: `0.00000`
- employer share among entrepreneurs: `1.00000`
- mean entrepreneur labor demand: `2.05`

Interpretation:

- attenuation by itself does not solve the over-entry problem
- more importantly, it destroys the self-employed corner

What happens is not that agents stop entering. Instead, they choose extremely small
positive hired labor and thereby classify as employers. In the logs:

- final realized `n_raw min` is around `0.000625`
- this is above the `self_employment_n_threshold = 1e-4`

So agents use an epsilon-hire employer corner to avoid the self-employment productivity
penalty.

### Case 144: attenuation plus fixed hiring cost

- entrepreneur share: `0.16868`
- self-employed share among entrepreneurs: `0.00000`
- employer share among entrepreneurs: `1.00000`
- mean entrepreneur labor demand: `6.20`

Interpretation:

- adding a fixed hiring cost does cut overall entry substantially
- but once self-employment is penalized enough, entrepreneurs still prefer the employer
  margin
- the model continues to collapse the self-employed corner

So the fixed hiring cost closes the epsilon-hire loophole as a pure numerical dodge, but
it does not change the deeper economics created by `x_scale = 0.50`: self-employment has
become too unattractive relative to employer status.

## Main lesson

The attenuation parameter `lambda_se` is not the right first lever if the aim is to:

1. reduce total entrepreneurial entry
2. preserve a substantial self-employed margin
3. move employer share among entrepreneurs toward the data target

In this model, attenuation does not act like a clean "discipline on self-employment."
Instead, it pushes agents away from the self-employed corner and into employer choices.

That is the opposite of what is needed for the employer/nonemployer composition target.

## Implication for next step

The next extension should not be "more attenuation."

More promising directions are:

1. entrepreneur closure risk `rho_e(h)`

- this reduces durability of entrepreneurship without mechanically favoring employer status
- it fits the substantive idea that low-education necessity self-employment is fragile

2. a separate employer-side fixed cost

- if the aim is to increase the no-employee share among entrepreneurs

3. a common entrepreneurial operating cost, used carefully

- this may reduce total entry, but it risks cutting self-employment more than employer
  entrepreneurship if used alone

## Current conclusion

The static tests support the view that entrepreneur risk/durability is likely fundamental.

The raw self-employment baseline creates too much entrepreneurship. But reducing own-account
productivity directly does not produce a disciplined self-employment margin. It instead
eliminates the self-employed corner. That pushes the next modeling step toward
entrepreneur closure risk `rho_e(h)` rather than more static attenuation.
