# 04 Empirical notes

Last updated: 2026-02-25

---

# Strategy 1: Calibration to UK graduate earnings profiles

**Strategy type:** Calibration exercise using administrative and survey earnings data to pin income-process parameters.

**Literature.**
The IFS graduate premium estimates (Britton et al., 2020) provide the most detailed UK
evidence on earnings differences by degree subject, institution, and background. The Student
Loans Company publishes aggregate repayment statistics that discipline the loan-balance
dynamics. HESA destination surveys and LEO (Longitudinal Education Outcomes) data provide
earnings trajectories by graduate type that can be used to build stylised profiles.

**How this applies to the question.**
The model requires exogenous earnings paths $\{y_{i,t}\}$ for each type cell (graduate
status, family wealth, earnings profile index). The calibration exercise:

1. Pins the earnings distribution for graduates and non-graduates from IFS/LEO data.
2. Sets institutional parameters ($F$, $\phi$, $\bar{y}$, $r_L$, $T_w$) from verified
   Student Loans Company and government documentation.
3. Calibrates $\tau_G$ and $\tau_{all}$ to close the budget constraint under Regimes B and C.
4. Computes PDV burdens $B_i^r$ across the type grid and produces the incidence table.

The main sensitivity checks vary the discount rate $\beta$, the earnings growth assumption,
and the write-off horizon $T_w$. Feasibility is high — all inputs are from public sources.
The calibration is illustrative rather than structurally estimated.

**References.**
Britton, J., L. Dearden, N. Shephard, and A. Vignoles (2020). "How English Domiciled Graduate Earnings Vary." *IFS WP*.

---

# Strategy 2: Policy-parameter verification from institutional sources

**Strategy type:** Systematic extraction of regime rules from UK policy documentation.

**Literature.**
UK student finance rules have changed repeatedly since 1998 (Barr, 2004; Bolton, 2024
House of Commons Library briefings). Accurate calibration requires verified parameters by
cohort — repayment thresholds, interest formulas, write-off horizons, maintenance provisions,
and upfront-payment rules. The graduate-tax counterfactual draws on policy design literature
(Chapman, 2006) and historical UK proposals.

**How this applies to the question.**
This strategy is not a regression but a data-assembly discipline. For each regime:

- **Regime A (loans):** verify $F$, $\phi$, $\bar{y}$, $r_L$, $T_w$ by entry cohort from
  SLC/BIS/DfE documentation. Flag where parameters changed and note which cohort the
  baseline calibration represents.
- **Regime B (graduate tax):** document the proposed $\tau_G$, threshold structure, and
  horizon $T_G$ from policy proposals and academic designs.
- **Regime C (general tax):** compute $\tau_{all}$ as the budget-balancing rate given
  aggregate earnings and graduate share.

The deliverable is a verified parameter table with source citations, ready to plug into the
model. All unverified placeholders must be flagged until confirmed.

**References.**
Barr, N. (2004). "Higher Education Funding." *Oxford Review of Economic Policy*.
Chapman, B. (2006). "Income Contingent Loans." *Handbook of the Economics of Education*.
