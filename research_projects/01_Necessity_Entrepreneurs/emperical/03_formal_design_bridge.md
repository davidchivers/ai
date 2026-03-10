# Formal design bridge

## Why the paper's object is hard to estimate directly

The model asks a counterfactual question: would this same person still choose
entrepreneurship if they had a viable employment contract? Observed data almost never
show that person under both outside-option states at the same moment. A literal
individual-level necessity label is therefore not identified without additional model
structure.

That does not mean the empirical problem is hopeless. It means the empirical target
should be reframed.

## What can be identified more cleanly

The cleanest empirical analogue is local necessity entry: business entry induced by an
exogenous deterioration in the wage-work outside option. If a shock lowers job-finding
prospects or raises separation risk without directly improving entrepreneurial
productivity, the extra entry caused by that shock is the closest observable counterpart
to the model's necessity margin.

This implies a change in emphasis. Instead of asking, "Which observed entrepreneurs are
truly necessity entrepreneurs?" the cleaner empirical question is, "Which types of
entrepreneurial entry are induced when outside options worsen?"

## Core estimands

The first estimand should be the response of nonemployer entry to an outside-option
shock:

`beta_nonemployer`

The second should be the response of employer entry:

`beta_employer`

The most informative contrast is then:

`beta_nonemployer - beta_employer`

If the paper's mechanism is right, this difference should be positive. Weak outside
options should push more people into low-scale entry than into employer formation.

Conditioning on entry, the next outcomes should be initial payroll, initial employment,
and early survival. Those are the observable bridges from the model's extensive margin
to its scale and composition margins.

## Why entry size is not the definition

Initial scale, capital, and self-employment status are useful signals, but they are not
the definition of necessity versus opportunity. A growth-oriented founder can start with
zero employees and scale later. An opportunity entrepreneur can also choose permanent
self-employment because the project is attractive at small scale. For this reason, size
and capital should be treated as outcomes that help interpret the type of entry induced
by outside-option shocks, not as a clean classifier on their own.

## Generic regression template

For a worker-level or local-area design, the generic equation is:

`Y_it^k = alpha_i + gamma_t + beta_k * Shock_it + epsilon_it`

where `k` indexes outcomes such as nonemployer entry, employer entry, first payroll,
or early survival. The key requirement is that `Shock_it` moves the wage-work outside
option more than it moves entrepreneurial productivity directly.

## Observable predictions from the model

A design grounded in the paper should look for the following pattern.

- Outside-option deterioration raises entrepreneurial entry mainly through the
  nonemployer or very low-scale margin.
- Employer entry responds less, or even weakens, relative to nonemployer entry.
- Conditional on entry, average initial scale is smaller.
- Early transitions from own-account status to employer status are weaker.

These are empirical predictions about composition, not only about the total number of
entrepreneurs.

## What not to do

Three shortcuts would be too loose for this project.

- Do not treat self-employment, nonemployer establishments, and employer startups as
  interchangeable.
- Do not use observed unemployment at entry as if it were the structural object.
- Do not treat small entry or low capital as sufficient evidence of necessity.
- Do not force a binary necessity label if the design only cleanly identifies a local
  causal margin.

## Practical implication

Inference: the paper can make a cleaner contribution if it presents necessity
entrepreneurship empirically as a response-to-outside-option margin with clear
compositional outcomes, rather than as a survey-based or status-based taxonomy of all
entrepreneurs.
