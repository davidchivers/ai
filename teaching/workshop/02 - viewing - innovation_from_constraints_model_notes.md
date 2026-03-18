# 03 Model notes

Last updated: 2026-03-16

---

# Model 1: Known problem space with salience-weighted inventive search

**Model type:** Static problem-allocation model with heterogeneous firm search capability.

**Literature.**
Rosenberg (1976, 1982) is the conceptual anchor because he treats technical change as being
focused by concrete bottlenecks and technical imbalances. Acemoglu (2002), Popp (2002), and
Acemoglu et al. (2012) provide the benchmark economics of directed innovation, where prices
or policy redirect inventive effort across technology lines. Griliches (1990) matters here
because the empirical payoff of the model will often be patenting in problem-linked classes.
The departure from those papers is that the primitive object is not only the return to a
technology line. It is the set of problems that have become worth solving.

**How this applies to the question.**
At date $t$, the economy contains an observed set of problems $J_t$. For each problem $j$,
$s_{jt}$ is salience, $b_{jt}$ is the loss from leaving the problem unsolved, and $d_{jt}$
is difficulty. Firm $i$ has search capability $a_i$ and allocates inventive effort $x_{ijt}$
across problems, facing convex cost parameter $\kappa$. A constraint shock changes either the
problem set $J_t$ itself or the weights $(s_{jt}, b_{jt})$ on existing problems. In the
simple interior case, optimal effort on problem $j$ is:

$$x_{ijt}^* = \frac{a_i s_{jt} b_{jt}}{\kappa d_{jt}}$$

This is the core payoff equation for the paper. It predicts that constraint shocks should
reallocate inventive effort toward problem classes where salience and bottleneck losses rise
most sharply, with stronger responses among firms that already have relevant search
capability. The empirical counterpart is a shift in patenting or other innovation output
toward the classes most tightly linked to the new problem cluster.

**References.**
Acemoglu, D. (2002). "Directed Technical Change." *Review of Economic Studies*.
Acemoglu, D., P. Aghion, L. Bursztyn, and D. Hemous (2012). "The Environment and Directed Technical Change." *American Economic Review*.
Griliches, Z. (1990). "Patent Statistics as Economic Indicators: A Survey." *Journal of Economic Literature*.
Popp, D. (2002). "Induced Innovation and Energy Prices." *American Economic Review*.
Rosenberg, N. (1976). "The Direction of Technological Change: Inducement Mechanisms and Focusing Devices." In *Perspectives on Technology*.
Rosenberg, N. (1982). *Inside the Black Box: Technology and Economics*.

---

# Model 2: Latent problems and discovery after a constraint shock

**Model type:** Dynamic search model with exploratory effort and shock-driven problem revelation.

**Literature.**
Rosenberg (1982) is again the right conceptual starting point because it emphasizes
uncertainty and sequential problem-solving rather than one-shot research choice. Porter and
van der Linde (1995) are useful here not for the paper's main framing, but because they point
to the idea that constraints can uncover inefficiencies and previously neglected margins.
Gregoire-Zawilski and Popp (2024) provide a modern empirical example in which standards and
coordination requirements focus innovation in a narrow technological domain. Together, these
papers support an extension where some relevant problems are not fully visible until the shock
arrives.

**How this applies to the question.**
Now let some relevant problems be latent before the shock. Firm $i$ first chooses exploratory
effort $e_{it}$ to learn which latent problems matter, then allocates solution effort across
the problems it has discovered. Let $r_{jt}(C_t)$ measure how strongly constraint shock
$C_t$ reveals latent problem $j$, and let $\phi_i$ denote the firm's discovery productivity.
The probability that problem $j$ enters the firm's observed problem set at $t+1$ is:

$$\Pr\!\left(j \in J^{obs}_{i,t+1}\right) = 1 - \exp\!\left[-\phi_i e_{it} r_{jt}(C_t)\right]$$

This extension matters when a regulation or standard first exposes broad downstream issues
and only later reveals narrower design, testing, interoperability, or usability subproblems.
Its empirical payoff is a lag structure: enabling or compliance patents should move first,
with more specialized subproblem patenting following later as firms learn what the new
constraint actually requires.

**References.**
Gregoire-Zawilski, A., and D. Popp (2024). "Do Technology Standards Induce Innovation in Environmental Technologies When Coordination is Important?" *Research Policy*.
Porter, M.E., and C. van der Linde (1995). "Toward a New Conception of the Environment-Competitiveness Relationship."
Rosenberg, N. (1982). *Inside the Black Box: Technology and Economics*.
