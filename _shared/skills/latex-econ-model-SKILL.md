---
name: latex-econ-model
description: Write and revise economic models in LaTeX with consistent notation and readable mathematical exposition. Use for assumptions, timing, optimization problems, equilibrium definitions, propositions, proofs, Bellman equations, first-order conditions, and theory sections that must remain aligned with the authoritative manuscript and live implementation.
---

# LaTeX Economic Model

## Establish the source of truth

Identify the authoritative manuscript, its preamble and macros, the model's requested scope, and any live analytical or computational implementation. Read surrounding sections before editing so the model inherits established notation, timing, labels, and equilibrium language. Ask only when an unresolved modeling choice would change the formulation.

Do not start from a generic document class or canned model. Preserve existing commands and environments unless a change is necessary and scoped.

## Build a notation and timing ledger

Before drafting equations, record the symbols the section needs:

| Symbol | Meaning | Domain or units | Timing and indices | Source or status |
|---|---|---|---|---|
|  |  |  |  | existing, derived, calibrated, or new |

Resolve collisions with notation elsewhere in the paper. Define every symbol before use, distinguish stocks from flows and individual from aggregate objects, and state whether prices, expectations, and choices are dated before or after shocks.

## Write intuition, variables, then equations

1. State the economic environment and mechanism in plain language.
2. Define agents, states, controls, parameters, information, timing, and feasibility.
3. Write objectives and constraints with domains and boundary conditions.
4. Derive optimality conditions, envelope conditions, laws of motion, and transversality or complementary-slackness conditions as applicable. Do not assume an interior solution without justification.
5. Define the equilibrium or solution concept by listing individual optimality, consistency, feasibility, aggregation, market clearing, policy rules, and expectations needed for this model.
6. State propositions and proofs only when their assumptions and logical steps are established. Separate analytical results, numerical findings, and interpretation.

Use only the mathematical detail needed for precision. Move long derivations to an appendix when the main text needs the result rather than every algebraic step.

## Typeset within the manuscript's system

Use existing theorem environments, notation commands, equation-label conventions, punctuation, and cross-reference style. Use aligned environments for related expressions and `\text{}` for words inside mathematics. Add a macro only for repeated notation and only after checking that it does not conflict with the preamble.

Keep equation groups readable at the manuscript's actual width. Avoid manual spacing or boxing that substitutes decoration for logical hierarchy.

## Audit the model

- Check dimensions, units, domains, signs, derivatives, indices, timing, boundary conditions, and limiting cases.
- Substitute first-order conditions back into constraints where useful and check resource or market clearing and Walras-type redundancies when applicable.
- Cross-check equations, parameter transformations, and calibration values against the live implementation. Report discrepancies instead of silently reconciling paper and code.
- Check that prose claims follow from the equations and that comparative statics hold under the stated assumptions.
- Compile the canonical source and inspect equation breaks, numbering, references, overfull lines, and proof layout.

Return the integrated source or proposed patch, the notation or equation changes that matter, the checks performed, and unresolved modeling or code-paper discrepancies.
