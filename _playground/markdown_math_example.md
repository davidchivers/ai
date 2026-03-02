# Markdown + LaTeX Preview Test

This file is temporary and safe to delete.

Inline math: $u(c)=\log c$, $y = A k^{\alpha} n^{1-\alpha}$.

## Optimization

$$
\max_{\{c_t, k_{t+1}\}_{t=0}^{\infty}} \sum_{t=0}^{\infty} \beta^t \log(c_t)
$$

subject to

$$
c_t + k_{t+1} = A k_t^{\alpha} + (1-\delta)k_t.
$$

## Euler Equation

$$
\frac{1}{c_t} = \beta \, \mathbb{E}_t\left[\frac{1}{c_{t+1}}\left(\alpha A k_{t+1}^{\alpha-1} + 1 - \delta\right)\right].
$$

## Matrix Example

$$
X = \begin{bmatrix}
1 & 2 \\
3 & 4
\end{bmatrix},
\quad
\det(X)= -2.
$$
