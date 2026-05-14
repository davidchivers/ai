# Bounded joint price and vote weight sweep

This workflow tests whether the bounded conflict between the housing-clearing update and the
political update is robust to the vote-feedback weight.

## Goal

Hold the bounded `T = 4` housing solve fixed and vary the political update weight:

$$
\log p^{new}_t = \log p^{housing}_t + \omega_{vote} \cdot \text{weighted vote share}_t
$$

The question is not whether the packet converges. The question is whether the sign conflict survives
across reasonable values of \(\omega_{vote}\).

## Default grid

- `0.0`
- `0.0005`
- `0.0010`
- `0.0020`
- `0.0050`

## Outputs

- `transition_re_joint_price_vote_weight_sweep_summary.csv`
- `transition_re_joint_price_vote_weight_sweep_periods.csv`
- `transition_re_joint_price_vote_weight_sweep_results.mat`
- `transition_re_joint_price_vote_weight_sweep_report.md`

## Interpretation

If the housing candidate still wants higher prices in periods `2` to `4`, while weighted vote
share stays negative in those same periods for every tested weight, then the main message is
robust:

- the political force pushes down
- the housing-clearing force pushes up
- the full political RE problem is structurally antagonistic on the bounded path

That is the main thing this workflow is meant to establish.
