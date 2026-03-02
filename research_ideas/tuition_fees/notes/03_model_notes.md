# 03 Model notes

Last updated: 2026-02-25

---

# Model 1: OLG lifecycle incidence of higher-education funding regimes

**Model type:** Overlapping-generations lifecycle model with income-contingent repayment, regime comparison, and exogenous education choice.

**Literature.**
Chapman (2006) provides the intellectual framework for income-contingent loan design and its
insurance properties relative to mortgage-style repayment. Barr (2004) surveys the economic
arguments for different higher-education funding structures, distinguishing efficiency,
equity, and fiscal sustainability channels. The OLG incidence-accounting approach follows
standard public finance methodology: define a present-discounted-value burden for each type
under each regime and compare.

**How this applies to the question.**
The model compares three UK funding regimes: (A) the current income-contingent loan system
(post-2012 stylised), (B) a graduate tax, and (C) general taxation finance. Individuals are
characterised by education status $e_i \in \{G, N\}$, family wealth $a_i \in \{H, L\}$, and
an exogenous earnings profile $\{y_{i,t}\}$. The key accounting object is PDV net burden:

$$B_i^r = \sum_{t=0}^{T} \beta^t \left(Payment_{i,t}^r - Transfer_{i,t}^r\right)$$

Under Regime A, repayments are $R_{i,t}^A = \phi \max(y_{i,t} - \bar{y}, 0)$ with write-off
at horizon $T_w$. Under Regime B, graduates pay $\tau_G y_{i,t}$. Under Regime C, all
workers pay $\tau_{all} y_{i,t}$. Policy parameters $\tau_G$ and $\tau_{all}$ are calibrated
to close the government budget. The pairwise comparison $\Delta B_i^{r,s} = B_i^r - B_i^s$
identifies winners and losers by type cell. Deliberate v0 simplifications: education choice
is exogenous, earnings are regime-invariant, and there are no GE wage effects.

**References.**
Barr, N. (2004). "Higher Education Funding." *Oxford Review of Economic Policy*.
Chapman, B. (2006). "Income Contingent Loans for Higher Education." *Handbook of the Economics of Education*.

---

# Model 2: Education-choice extension with regime-dependent participation

**Model type:** OLG with endogenous education decision responding to net returns under each regime.

**Literature.**
The education-choice extension follows the human-capital investment literature (Becker, 1964)
and the specific application to tuition fee responses. Dearden, Fitzsimons, and Wyness
(2014) provide UK evidence on how fee and loan design affects university participation, with
particular sensitivity among students from lower-income backgrounds. The key additional
mechanism is that different regimes change the net return to education, which affects the
extensive margin — who goes to university.

**How this applies to the question.**
The v0 model takes education status as given. This extension makes it a choice: each
individual compares expected lifetime utility as a graduate (with regime-specific repayment
burden) against the outside option. The participation margin is:

$$e_i^* = \mathbf{1}\left\{\mathbb{E}\left[\sum_t \beta^t u(c_{i,t}^G)\right] - B_i^r > \mathbb{E}\left[\sum_t \beta^t u(c_{i,t}^N)\right]\right\}$$

The graduate share $Pr[e_i = G]$ becomes regime-dependent. This matters because a graduate
tax with high $\tau_G$ may deter participation by high-ability individuals who expect to earn
above the threshold for a long time, while income-contingent loans with write-off may
encourage participation by lower-expected-earnings types who benefit from the insurance.
Regime comparison then requires joint evaluation of incidence *and* composition effects.
This is a v1 extension — it should only be built after the v0 incidence table is locked.

**References.**
Becker, G. (1964). *Human Capital*. University of Chicago Press.
Dearden, L., E. Fitzsimons, and G. Wyness (2014). "Money for Nothing." *Economics of Education Review*.
