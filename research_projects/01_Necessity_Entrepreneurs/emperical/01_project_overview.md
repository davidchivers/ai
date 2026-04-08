# Project overview

## Core question

Can we do a cleaner empirical job of identifying necessity entrepreneurship in a way
that matches the paper's formal object, rather than leaning on motives, observed
status at entry, or broad self-employment measures alone?

## The paper's formal object

The paper defines necessity entrepreneurship as a counterfactual occupational-choice
object. Let `h` denote entrepreneurial human capital, and let the entrepreneurship
threshold when unmatched be lower than the threshold when employed:

`h_hat_unmatched < h_hat_employed`

A necessity entrepreneur satisfies:

`h_hat_unmatched < h < h_hat_employed`

This person chooses entrepreneurship only because the wage-work outside option is
weak. By contrast, an opportunity entrepreneur satisfies:

`h >= h_hat_employed`

and would choose entrepreneurship even if a viable job were available.

The paper also splits entrepreneurship internally. When hired labor is zero,
`n_h = 0`, the business is nonemployer self-employment. When `n_h > 0`, it is
employer entrepreneurship. That second margin matters because the model's main
quantitative claim is not just about more entry, but about more low-scale entry.

## What the current paper already does well

The live draft and the recent data sidecar already make one important move correctly:
they treat necessity entrepreneurship as latent rather than directly observed. The
paper is explicit that GEM motive data are informative but overlapping, that prior
labor-market status is useful but imperfect, and that recession evidence should be
used for motivation rather than as a definition.

The current empirical pair also points in the right direction. The business-size
figure shows that downturns shift activity toward zero-employee establishments, while
the business-applications series shows that the employer-oriented margin weakens.
That is not a direct measure of necessity entrepreneurship, but it is consistent with
the model's composition logic.

## Why clean measurement is hard

The core difficulty is that the formal definition is counterfactual. In data, we do
not observe whether the same person would still have chosen entrepreneurship if they
had kept or found a good job. That means a literal classification is unavailable
without strong structural assumptions.

The project materials already highlight four separate measurement problems.

- Motive overlap: GEM shows that "jobs are scarce" and "high income or wealth" can
  both be true for the same early-stage entrepreneur.
- Status endogeneity: entry from nonemployment is informative, but nonemployment is
  not randomly assigned and may proxy for many things besides a weak outside option.
- Unit mismatch: CPS self-employment is person based, while nonemployer and employer
  establishment counts are business based.
- Margin mismatch: stocks, flows, self-employment, employer entry, and startup scale
  are related but not interchangeable.

There is a fifth issue that matters for this paper in particular. Even within the
entrepreneur category, own-account entry and employer entry are different objects. A
design that treats them as one outcome loses the main compositional content of the
model.

There is also a sixth issue. Small entry is not the same thing as necessity entry.
Even opportunity entrepreneurs often start small, and some opportunity entrepreneurs
may rationally choose self-employment without ever becoming employers. Initial scale,
capital, and payroll therefore belong on the outcome side of the design, not as a
standalone definition of entrepreneurial type.

## What a cleaner design needs

A better empirical design should do five things.

- Shift the wage-work outside option for reasons that are as exogenous as possible.
- Keep own-account or nonemployer entry separate from employer entry.
- Work with person-to-business transitions, not only aggregate counts.
- Measure post-entry scale, payroll start, and survival, not just an entry dummy.
- Treat entry size and capital as secondary markers of type, not as the type definition.
- Accept that the cleanest estimand may be a local causal margin rather than a full
  person-by-person classification.

## Working conclusion

Inference: the cleanest empirical analogue to the paper's formal object is not a
survey label and not a single observed status variable. It is the margin of business
entry induced by an exogenous deterioration in the wage-work outside option, measured
separately for nonemployer and employer entry.
