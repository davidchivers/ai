# Transition RE intuition note

## Why this note exists

The transition-path rational-expectations extension is now being treated as a supporting extension
to the published paper rather than as a standalone numerical project. The goal is therefore not a
tightly converged RE benchmark at any cost. The goal is a credible qualitative answer to:

- does imposing RE along the demographic transition materially change the story?
- if not, why is the fully solved RE transition computationally difficult in this model?

This note records the current answer from the runs already completed.

## What the completed runs show

Evidence from the current summaries:

- Canonical control `config11_global_control`:
  - residual norm `0.128123139190`
  - max gap `0.165893855901`
  - last nontrivial iteration `3`
- Best challenger `aggressive_p2_b8_hybrid_relaxed`:
  - residual norm `0.128074177550`
  - max gap `0.166384245139`
  - last nontrivial iteration `4`
- Best pure-focus row `config11_focus_relaxed`:
  - residual norm `0.128660740438`
  - max gap `0.165893855901`
  - last nontrivial iteration `2`
- Completed lambda continuation:
  - `lambda = 0`: residual norm `0.189800232028`, max gap `0.210720915080`, worst gap period `8`
  - `lambda = 0.25`: residual norm `0.164965629626`, max gap `0.178640011328`, worst gap period `8`
  - `lambda = 0.5`: residual norm `0.145972386289`, max gap `0.152174686037`, worst gap period `8`
  - `lambda = 0.75`: residual norm `0.133643529519`, max gap `0.159104190915`, worst gap period `3`
  - `lambda = 1`: residual norm `0.128180623096`, max gap `0.165930860077`, worst gap period `3`

Supporting evidence from the saved diagnostics:

- the worst gap keeps localizing at period `3`
- accepted block moves concentrate around the `4-6` region in the stronger runs
- the relaxed hybrid challenger pushes accepted updates later in the path (`6-8`, then `5-7`)
  rather than materially relieving the peak problem at period `3`
- the focus-objective branch did not improve the control's worst-gap benchmark; it only tied it or
  reproduced the old residual-versus-gap tradeoff
- the lambda continuation path is smooth rather than explosive: as the demographic transition is
  turned on, the solver moves gradually from an easier late-period bottleneck toward the known
  full-shock period-`3` bottleneck

## Working interpretation

Inference from the runs above:

- RE does not currently appear to overturn the baseline transition story in a large way.
- The lambda continuation evidence strengthens that reading: the full-shock row reconnects to the
  old control-like result rather than revealing a qualitatively different RE branch.
- The current RE adjustments are small and localized rather than a dramatic re-shaping of the whole
  price path.
- When the solver improves average residual fit, it mainly seems to redistribute error across
  periods rather than eliminate the main bottleneck.
- The main numerical and economic tension is concentrated near period `3`, with adjacent pressure in
  the `4-6` block region.

That is already enough for a cautious extension-level message:

- imposing RE on the transition path appears to matter at the margin
- but under the present calibration it does not yet generate a qualitatively different transition
  equilibrium relative to the controlled benchmark

## Why the full RE transition is computationally hard here

The difficulty is not just "the computer is slow." It comes from the structure of the problem.

1. The equilibrium object is a whole future price path, not a scalar.
   The solver is searching over a vector of prices across all transition periods, so the fixed point
   is high-dimensional from the start.

2. Each candidate path is expensive to evaluate.
   In `solve_transition_re_no_politics.m`, a single candidate requires:
   - solving the household problem backward over the full horizon
   - simulating the distribution forward over the full horizon
   - recovering the implied RE price path from housing demand and supply

3. The current search method multiplies those expensive evaluations.
   The solver does not test only one update per iteration. It evaluates a regularized full-path
   candidate plus many sequential local block candidates and line-search scales. That is why a
   single completed case can take on the order of roughly `40` to `160` minutes in the summary
   files.

4. The hard periods are exactly where the map is most sensitive.
   The demographic transition creates a concentrated bottleneck around period `3`. Small local price
   changes there can improve one criterion while worsening another, which is why the solver keeps
   trading residual norm against worst-gap performance.

5. The objective is not naturally one-dimensional.
   The runs make clear that "better average residual fit" and "smaller worst-period gap" are not the
   same thing. A candidate can win on one while losing on the other, so the solver has to navigate
   a real ranking problem rather than a simple monotone convergence path.

## What this means for the extension

The current evidence supports a pragmatic position:

- We should stop treating this as a precision-calibration race.
- We should use the existing RE runs to motivate a qualitative statement plus a computational
  caution.
- If one more numerical exercise is wanted, it should be a deliberately simplified RE check rather
  than another broad heavy sweep.

## Acceptable simplified RE exercises

If we want one more bounded exercise for intuition, the best options are:

- a very coarse continuation check, for example `lambda = 0`, `0.5`, `1.0`
- a shorter-horizon RE transition concentrated on the early problematic periods
- a restricted-update RE solve that only lets prices move in the `2-6` window
- a low-iteration sanity check that asks whether RE moves the path in the expected direction, not
  whether the solver fully converges

These would be acceptable because the extension only needs intuition about how RE matters, not a
new headline calibration target.

## Recommended stopping rule

Use the current outputs unless one of the simplified RE exercises produces a clearly different
qualitative message. If the simplified check tells the same story, stop there and write it up as:

- RE matters somewhat for the transition path
- the effect is localized and not obviously transformative in this calibration
- a fully solved transition-path RE benchmark is computationally difficult because it is a
  high-dimensional backward-forward fixed point with a sharp local bottleneck

## Future revisit note

This is a good extension to revisit later if a better numerical approach becomes available.

The reason to defer is not that the question is uninteresting. The reason is that, under the
current model and solver architecture, the computational difficulty is clear while the qualitative
economic message already looks fairly stable.

So the recommended file-level conclusion for future work is:

- leave a clear record that period `3` is the persistent bottleneck
- note that current RE runs mainly reveal localized path adjustments and objective tradeoffs
- revisit the extension when either:
  - a better transition-path RE solver is available, or
  - a simplified model variant makes the RE fixed point easier to characterize cleanly
