# Persistent NIMBY shock and fertility

This note studies a simple supply-tightening counterfactual in the fertility model.
The shock is a permanent increase in baseline political tightness, implemented as
`theta0 + 0.05` from the first post-baseline period onward.

## Stylized transition read

- At horizon `t = 40`, the house-price index is `0.761` under the NIMBY shock versus `0.549` in baseline.
- At horizon `t = 40`, the fertility rate is `0.232` under the NIMBY shock versus `0.248` in baseline.
- At horizon `t = 79`, the house-price index is `1.192` under the NIMBY shock versus `0.747` in baseline.
- At horizon `t = 79`, the fertility rate is `0.212` under the NIMBY shock versus `0.233` in baseline.

## Medium-immigration projection read

- In `2050`, the projected house-price index is `1.163` under the NIMBY shock versus `1.066` in baseline.
- In `2050`, the projected fertility rate is `0.190` under the NIMBY shock versus `0.194` in baseline.
- In `2100`, the projected house-price index is `1.767` under the NIMBY shock versus `1.254` in baseline.
- In `2100`, the projected fertility rate is `0.175` under the NIMBY shock versus `0.188` in baseline.

## Interpretation

- A persistent NIMBY shift raises housing pressure and lowers fertility over time.
- Unlike the earlier aging bridge, this object directly answers the mechanism question:
  if housing remains too tight for a long time, realized fertility falls.
- The projection remains a bridge rather than a full forecast solver, but the shared-2020
  starting point makes it informative about the sign and magnitude of a persistent NIMBY shift.
