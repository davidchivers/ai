# Rational Expectations Appendix Note

## Suggested title

Appendix X. Rational Expectations and Computational Scope

## Exact appendix text

One concern with the transition analysis is the assumption that households treat future house
prices as following a random walk rather than forming fully model-consistent rational
expectations. In principle, one would like to replace that shortcut with a transition-path
equilibrium in which the entire future price sequence is jointly determined with household behavior
and housing-market clearing. In the present environment, however, doing so is substantially more
computationally demanding than the benchmark transition exercise.

The difficulty is structural. Under rational expectations, the equilibrium object is an entire
future price path rather than a single current-period price. Evaluating any candidate path requires
solving household problems backward over the full horizon, simulating the cross-sectional
distribution forward, and recovering the implied sequence of market-clearing prices. Once political
support is kept endogenous, the same candidate path also affects future tenure and wealth
distributions, which feed back into future voting outcomes and housing supply. A full political
rational-expectations transition is therefore a high-dimensional fixed point over prices,
distributions, and endogenous political support.

To assess whether the benchmark results appear to depend critically on the random-walk shortcut, we
solved a deliberately stripped-down rational-expectations diagnostic in which households form
model-consistent expectations over future prices in a no-coalition version of the transition
problem. The resulting price paths remain close to the benchmark-style transition, and a coarse
continuation exercise that gradually scales up the demographic shock does not reveal a sharply
different equilibrium branch. Instead, the same localized numerical bottleneck reappears as the
full shock is restored, with the most difficult part of the problem concentrated early in the
transition.

We interpret this evidence conservatively. It does not provide a full rational-expectations version
of the political model, and it should not be read as a substitute for one. What it does suggest is
that the paper's main qualitative mechanism is unlikely to be an artifact of the random-walk
forecasting shortcut. For that reason, we retain the benchmark expectations structure in the main
text and view a fully solved political rational-expectations transition as a natural topic for
future work rather than a requirement for the present paper.

## Optional figure

If one appendix figure is included, use the continuation figure already generated in
`re_extension_section/figures/re_lambda_continuation.pdf`.

## Optional figure caption

Figure A.1. Rational-expectations continuation across demographic shock sizes. The figure plots the
implied transition path and solver diagnostics as the size of the demographic shock is scaled up
from zero to its full benchmark value. The key pattern is continuity rather than a regime break:
the hard part of the rational-expectations problem returns smoothly as the full shock is restored.
