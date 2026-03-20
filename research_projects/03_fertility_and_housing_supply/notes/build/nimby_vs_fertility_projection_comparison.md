# Future demographic projection comparison

This note compares a NIMBY proxy and a fertility bridge built on the same projected age
weights. Both sides are bridge objects driven by the upstream forecast age shares. The
NIMBY side shuts off the fertility-demand channel, while the
fertility side keeps births and children-at-home in the demand block.

## Medium-immigration read

- NIMBY price index in 2050: `1.093`
- Fertility price index in 2050: `1.000`
- NIMBY price index in 2100: `1.067`
- Fertility price index in 2100: `0.976`
- Fertility-side young-homeownership proxy in 2100: `0.402`

## Scope note

- This is a projection bridge, not a unified forecast solver.
- It is still informative about whether the fertility channel amplifies or dampens the
  price effects of projected aging under the same demographic scenarios.
