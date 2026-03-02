# Markdown Viewer Stress Test

This document is designed to test reading comfort in **Markdown Preview Enhanced** with long-form academic text, equations, and mixed formatting.

## 1. Long-Form Prose

Economists often write in layers: first a conceptual argument, then a formal model, then empirical content. A good preview environment should let you move between those layers without friction. In practical terms, you want line breaks that are easy on the eyes, typography that supports scanning, and headings that make structure obvious. If a viewer handles these basics well, it reduces cognitive overhead and makes drafting substantially faster.

A second requirement is continuity across representation styles. In one paragraph you might describe intuition in plain language; in the next you might write a constrained optimization problem; two lines later you may insert a policy counterfactual in a block quote. If the viewer keeps these modes visually distinct while preserving a coherent style, it becomes a true writing workspace rather than just a rendering pane.

Third, tables and lists matter more than they seem. Research notes frequently include parameter values, assumptions, and decision logs. If these elements render cleanly and remain legible at a glance, markdown can replace many intermediate PDF cycles during drafting.

## 2. Emphasis And Inline Elements

You can mix *italics*, **bold**, and ***bold italics***. You can also use inline code like `argmax`, `beta`, `delta`, or command snippets such as `latexmk -pdf main.tex`.

A sentence with superscripts and subscripts via math: output gap $x_t$, inflation $\pi_t$, and policy rate $i_t$.

## 3. Lists

### Ordered

1. Define the environment.
2. Write down constraints.
3. State the objective.
4. Characterize equilibrium.
5. Discuss comparative statics.

### Unordered

- Assumption A: households are infinitely lived.
- Assumption B: technology follows AR(1).
- Assumption C: policy follows a feedback rule.

### Task List

- [x] Install preview extension
- [x] Enable dark theme
- [ ] Decide whether markdown replaces intermediate PDFs

## 4. Block Quote

> A preview tool is useful when it reduces latency between idea and readable output.
> 
> If a writer is waiting for tooling instead of thinking about content, the tooling is wrong.

## 5. Table

| Parameter | Meaning | Baseline |
|---|---|---:|
| $\beta$ | Discount factor | 0.99 |
| $\alpha$ | Capital share | 0.33 |
| $\delta$ | Depreciation rate | 0.025 |
| $\rho$ | Shock persistence | 0.90 |

## 6. Equations

Inline Euler equation: $u'(c_t)=\beta E_t\left[u'(c_{t+1})R_{t+1}\right]$.

Display math:

$$
\max_{\{c_t,k_{t+1}\}_{t=0}^{\infty}} \sum_{t=0}^{\infty} \beta^t u(c_t)
$$

subject to

$$
c_t + k_{t+1} = A_t k_t^{\alpha} + (1-\delta)k_t.
$$

And a compact matrix expression:

$$
A = \begin{bmatrix}
1 & 0 & 0 \\
\phi_\pi & \phi_x & 1 \\
0 & 1 & \rho
\end{bmatrix}.
$$

## 7. Code Blocks

```python
import numpy as np

beta = 0.99
alpha = 0.33
delta = 0.025

k = np.linspace(0.1, 10, 100)
y = k**alpha
print(y[:5])
```

```latex
\begin{align}
V(k,z) = \max_{c,k'}\; u(c) + \beta E[V(k',z')\mid z] \\
\text{s.t. } c + k' = z k^\alpha + (1-\delta)k
\end{align}
```

## 8. Footnotes

Markdown footnotes can be useful for side remarks.[^1]

[^1]: Footnotes are handy for caveats that would interrupt the main flow.

## 9. Horizontal Rule

---

## 10. Final Readability Check

If this page feels comfortable to read at length, markdown preview is a strong drafting interface. You can still export milestone snapshots to PDF when sharing with coauthors, referees, or for archival checkpoints.
