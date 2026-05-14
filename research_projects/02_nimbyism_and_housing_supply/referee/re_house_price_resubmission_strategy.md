# RE and house-price resubmission strategy

## Working assumption

- The relevant IER rejection packet is now identified as:
  - `IER MS31540-1 Decision letter.pdf`
  - `IER MS31540-1 R1's report.pdf`
  - `IER MS31540-1 R2's report.pdf`
- These files live in the project root rather than in `referee/`.
- The immediate goal is not to draft a full referee response to a live revise-and-resubmit.
  The goal is to decide how to reopen the RE extension in a way that improves the paper for
  resubmission.
- User clarification from 2026-04-13:
  the target is RE over house prices only, not a full political RE transition.

## What the reports are actually asking for

The three reports do not read like a demand for a fully solved political RE transition before the
paper can move again.

The dominant themes are:

1. clearer model exposition
2. clearer equilibrium definition and timing
3. clearer explanation of what is abstracted from and why
4. one serious expectations question around whether future house prices are being handled in a way
   that could matter for the transition results

That last point is the one worth taking most seriously. It is also the point that connects best to
the work already done in `extensions/re_no_politics/`.

## Recommended framing

The right response is not:

- "we solved full political rational expectations"
- "the benchmark was fully correct already so nothing changes"
- "the computational problem is hard, so we leave it there"

The better response is:

- the key concern is whether the benchmark transition relies too heavily on the random-walk
  shortcut for future house prices
- we therefore add a bounded RE exercise focused on future house prices
- that exercise is deliberately simplified, because full political RE is a high-dimensional fixed
  point over future prices, distributions, and endogenous voting outcomes
- the simplified exercise does not reveal a sharply different house-price branch
- so the main qualitative mechanism does not appear to be an artifact of the benchmark
  expectations shortcut

This keeps the response tied to the referee concern and to the actual house-price object, rather
than turning the revision into an open-ended numerical project.

## Why house prices should be the priority object

If we reopen the RE work, the central question should be:

$$
\text{Does imposing model-consistent expectations over future house prices materially change the transition path?}
$$

That is narrower and more useful than asking for "full RE" in the abstract.

It also fits the current evidence:

- the no-coalition RE diagnostic already exists
- the continuation results are already computed
- the current notes already support a cautious statement that RE shifts are localized rather than
  transformative
- the existing computational explanation is strongest when it is tied to the future house-price
  path, not to generic solver difficulty

## Current evidence we can already use

The strongest existing materials are:

- `extensions/re_no_politics/transition_re_intuition_note.md`
- `extensions/re_no_politics/rational_expectations_appendix_note.md`
- `extensions/re_no_politics/re_extension_section/figures/re_lambda_continuation.pdf`
- `extensions/re_no_politics/re_extension_section/figures/re_vs_paper_benchmark.pdf`

Current read from those files:

- the stripped-down RE path remains close to the benchmark-style transition
- continuation in the demographic shock is smooth rather than revealing a new regime
- the hardest numerical tension is localized early in the transition
- the real hard object is the household-policy feedback block, especially once expectations feed
  back into future political support and supply

That is already enough for a defensible resubmission position.

## Recommended paper changes

### Main text

1. State the benchmark expectations shortcut more clearly.
   Explain in plain language that the benchmark transition does not solve a full political RE path.

2. Add one short paragraph explaining why full political RE is hard here.
   Keep the explanation structural:
   future price path, backward household problem, forward distribution dynamics, and feedback into
   future voting and supply.

3. Tighten the transition equilibrium description.
   Reviewer 2 explicitly seems to want a clearer definition of equilibrium and a clearer account of
   what happens when the demographic shock arrives.

4. Reduce unnecessary symbolic exposition in the model-description sections.
   Reviewer 3 appears to be asking for a cleaner intuition-first presentation, not more notation.

### Appendix or long footnote

1. Add the existing rational-expectations appendix note in a paper-safe form.
2. Include one figure at most.
   The safest candidate is `re_lambda_continuation.pdf`.
3. If the benchmark overlay figure is used, label it carefully as a heuristic timing comparison,
   not as a clean apples-to-apples political-versus-no-politics welfare comparison.

## What not to promise

Do not promise a full political RE transition for the next version unless that becomes a deliberate
project in its own right.

Do not let the revision stance become:

- "we only need more compute"
- "one more frontier sweep will settle the economics"
- "the paper stands or falls on solving the entire political RE object"

The existing extension evidence does not support that framing, and the reports do not require it.

## If one more RE exercise is run

Keep it tightly bounded and explicitly house-price centered. Good candidates are:

1. a short-horizon RE exercise for the early periods where the price-path bottleneck is strongest
2. a reduced-form-first or policy-bridge house-price check that asks whether the path moves in a
   materially different direction under RE
3. a compact continuation refresh if we need one cleaner figure for the revised paper

The bad version would be reopening a broad full-path frontier campaign without a direct resubmission
payoff.

## Suggested response language

Short version:

> We agree that expectations over future house prices are a natural concern for the transition
> analysis. In the revised paper we make the benchmark forecasting shortcut explicit and clarify why
> a full political rational-expectations transition is computationally demanding in this
> environment. To address the concern directly, we add a stripped-down rational-expectations
> diagnostic focused on future house prices in a no-coalition version of the model. The resulting
> transition path remains close to the benchmark-style path, and a continuation exercise does not
> reveal a sharply different equilibrium branch. We therefore interpret the benchmark results as
> unlikely to be driven mainly by the random-walk expectations shortcut, while treating a fully
> solved political RE transition as an important topic for future work.

Longer version for internal use:

- We should answer the reports by making the RE objection narrower and more concrete.
- The question is whether the transition path for house prices changes materially once households
  form model-consistent expectations.
- The strongest response is not a promise of full political RE. It is a bounded house-price RE
  robustness argument backed by the no-politics diagnostic, the continuation evidence, and a clear
  explanation of why the full political fixed point is hard.

## Bottom line

For resubmission, the RE extension should be repositioned as a house-price expectations check, not
as a standalone race to solve the full political transition under rational expectations.
