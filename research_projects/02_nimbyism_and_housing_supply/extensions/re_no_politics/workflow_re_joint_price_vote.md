# Bounded joint price and vote workflow

This is the next bounded step after the first political-path packet.

## Goal

Take the `T = 4` political-path diagnostic and add a simple feedback rule from political pressure
into the price path.

The workflow is still heuristic. It is not a solved political RE fixed point.

## Update rule

For each bounded outer step:

1. run the current transition solver with political-path diagnostics on
2. keep the housing-side updated price path from that solve
3. adjust log prices by a small multiple of coalition-weighted vote share

Schematically:

$$
\log p^{new}_t = \log p^{housing}_t + \omega_{vote} \cdot \text{weighted vote share}_t
$$

with a small default `vote_weight = 0.001`.

## Why this is useful

This packet answers a very practical question:

- do the housing-clearing and political forces push prices in the same direction or in opposite
  directions?

If they point in opposite directions, then a full political RE solver will be meaningfully harder
than the house-price-only object.

## Packet

- horizon: first 4 periods
- housing solve per joint step: 1 bounded `full_backward` run
- joint iterations: 2
- vote weight: 0.001

## Outputs

- `transition_re_joint_price_vote_summary.csv`
- `transition_re_joint_price_vote_periods.csv`
- `transition_re_joint_price_vote_results.mat`
- `transition_re_joint_price_vote_report.md`

## Stopping rule

Stop after the bounded packet.

Do not escalate to the full 2010-2018 political RE object until this bounded interaction between
housing pressure and political pressure is understood.
