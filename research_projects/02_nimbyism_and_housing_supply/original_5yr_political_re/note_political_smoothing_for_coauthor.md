# Note on Political Smoothing

Date: April 22, 2026

## Bottom line

The political smoothing we are testing does **not** change the underlying economic object that drives politics. The underlying object is still a value-difference comparison,

\[
dV = V^{\text{counterfactual}} - V^{\text{baseline}}.
\]

What smoothing changes is the **mapping** from that value difference into political support / permit response.

In the hard version, the mapping is effectively:

\[
m(dV) = \operatorname{sign}(dV).
\]

In the smoothed version, we replace that knife-edge rule with a soft threshold:

\[
m(dV) = \tanh\!\left(\frac{dV}{2\tau}\right),
\]

or equivalently

\[
m(dV) = 2\Lambda\!\left(\frac{dV}{\tau}\right)-1,
\]

where \(\Lambda(\cdot)\) is the logistic CDF. The output still lives in `[-1,1]`, but now moves smoothly rather than flipping discontinuously.

## What the code is doing right now

### Transition code

In the live transition branch, the smoothed political response is currently implemented as:

\[
m(dV) = \tanh\!\left(\frac{dV}{2\sigma_{\text{resp}}}\right).
\]

Code fact:
- In [solve_transition_re_no_politics.m](C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits\research_projects\02_nimbyism_and_housing_supply\extensions\re_no_politics\solve_transition_re_no_politics.m), the response builder is
  `preference_response = tanh(preference_value_difference ./ (2 .* response_sigma));`
- The mode names in the code are `smooth_tanh`, `smoothed_tanh`, and `probabilistic_permits`.

Important naming note:
- In the **transition code**, the parameter currently called `political_response_sigma` is functioning like a **temperature / smoothness parameter**, not like the paper's additive political wedge.
- So, in economics notation, it is cleaner to think of the current live transition implementation as using a **tau-like** object, even though the variable name says `sigma`.

### Patched steady-state code

In the patched steady-state code, I separated the two roles explicitly:

\[
m(dV) = \tanh\!\left(\frac{dV + \sigma}{2\tau}\right).
\]

Here:
- `sigma` is an **additive political wedge / preference shifter**
- `tau` is the **smoothness / temperature parameter**

Code fact:
- In [SolveSS_iter.m](C:\Users\Dave_\AI\.claude\worktrees\nimby_smoothed_permits\research_projects\02_nimbyism_and_housing_supply\code\steadystate\SolveSS_iter.m), the vote rule is now configurable through:
  - `vote_params.mode`
  - `vote_params.sigma`
  - `vote_params.tau`
- The smooth rule there is
  `vote_support = tanh(shifted_gap./(2.*vote_tau));`
  with `shifted_gap = vote_value_gap_fd + vote_params.sigma`.

## Interpretation

The clean interpretation is:

- `dV` still captures the underlying economic incentives.
- `sigma` shifts the political cutoff left or right.
- `tau` controls how sharply politics reacts around the cutoff.

So:
- **preference / wedge parameters** determine where the support cutoff sits
- **smoothness** determines how abrupt the political response is near that cutoff

That is why smoothing is not the same as "changing preferences." It is changing the implementation rule, not the underlying value comparison.

## Why this is potentially defensible

The most defensible reading is not "we smoothed it because the hard model was inconvenient." The better reading is:

- local permitting is not literally a deterministic sign-flip of one median voter's welfare gap
- there is unobserved heterogeneity, turnout noise, council discretion, project-level variation, coalition uncertainty, and institutional randomness
- a smooth approval / permit-response function is a reduced-form way to capture those frictions

Under that interpretation:
- the hard sign rule is a limiting case as `tau -> 0`
- the smoothed rule is a regularized version of the same underlying political comparison

## What smoothing is doing numerically

Numerically, smoothing helps by making the outer political fixed point less kinked. Instead of a tiny perturbation causing a discrete jump in political support, the response changes continuously with `dV`.

That should, in principle:
- improve continuation in horizon `k`
- make finite-difference Jacobians more stable
- reduce spurious accept/reject discontinuities in the outer solve

## What it is not doing

It is **not**:
- changing the household problem
- changing how `dV` is computed
- directly setting prices
- eliminating the political mechanism

The political channel still runs through the same logic:

\[
\text{economics} \to dV \to \text{political response} \to \text{permits / supply conditions} \to \text{prices}.
\]

The change is only in the `dV -> political response` step.

## Practical status as of April 22, 2026

Evidence from the current smoothed runs:
- At `k=2`, the smoother branch with response parameter `0.20` performed better than `0.10`.
- In the local `k=4` run, we have seen intermediate candidate points around:
  - `max_abs_vote ~ 0.00543`
  - `max_abs_gap ~ 0.00480`
- These are encouraging intermediate results, but the `k=4` stage has **not yet finalized**, so they should be described as provisional rather than final outcomes.

## Suggested way to describe this to a referee or coauthor

A careful phrasing would be:

> We do not change the underlying political comparison; agents still compare welfare across alternative housing-supply outcomes. What we change is the implementation rule that maps this welfare gap into political support. Rather than a knife-edge deterministic threshold, we allow political support / permit approval to vary smoothly with the welfare gap. This can be interpreted as a reduced-form representation of unobserved heterogeneity, turnout noise, or institutional discretion in local land-use decisions. The hard threshold model is nested as the limiting case as the smoothing parameter tends to zero.

## One caution

At the moment, the **transition code** and the **patched steady-state code** use slightly different parameter naming conventions:

- transition runs: the parameter named `political_response_sigma` is really acting like a **temperature**
- patched steady state: `sigma` and `tau` are separated cleanly

So, for paper exposition, I would strongly recommend describing the model in the cleaner notation:

\[
m(dV) = \tanh\!\left(\frac{dV + \sigma}{2\tau}\right),
\]

even though the current transition code still uses the older name in places.
