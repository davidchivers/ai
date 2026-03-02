# 02 Literature and synthesis

Last updated: 2026-02-25

---

## Purpose

Maintain one verified source base for UK policy parameters, graduate-tax design alternatives,
and incidence-accounting methods. This is an evidence-first working document, not a
literature survey.

---

## UK policy and institutional rules

The current England student finance system (post-2012, Plan 2; post-2023, Plan 5) sets:
- Fee cap: approximately GBP 9,535 (2025/26 benchmark).
- Repayment threshold: GBP 28,470 (Plan 2) / GBP 25,000 (Plan 5).
- Repayment rate above threshold: 9%.
- Interest: RPI-linked (Plan 2), with varying rates by income; zero real rate (Plan 5).
- Write-off: 30 years (Plan 2) / 40 years (Plan 5) after graduation.

These parameters define Regime A in the model. Verified documentation from the Student Loans
Company and Department for Education must pin each parameter by entry cohort. Unverified
placeholders must be flagged until confirmed.

---

## Graduate-tax design literature

Chapman (2006) provides the intellectual case for income-contingent financing and discusses
graduate-tax variants as an alternative to individual debt instruments. Barr (2004) surveys
efficiency, equity, and sustainability arguments across funding structures and distinguishes
insurance from redistribution components. The key design choices for Regime B are:
proportional vs thresholded surcharge, fixed horizon ($T_G$ years) vs lifetime, and whether
the tax applies to all graduates or only those above an income floor.

---

## Incidence-accounting methods

The standard public-finance approach defines a present-discounted-value burden for each type
and compares across regimes. The key conventions are: choice of discount rate (social vs
private), cohort vs lifecycle framing, and treatment of government subsidy as an implicit
transfer. Transparent reporting requires showing PDV burdens by type cell (not just
aggregate averages) so that distributional implications are visible.

---

## UK graduate earnings evidence

Britton, Dearden, Shephard, and Vignoles (2020) provide detailed IFS estimates of how
English-domiciled graduate earnings vary by subject, institution, and background. The LEO
(Longitudinal Education Outcomes) dataset links HMRC tax records to HESA records, providing
the most granular official earnings trajectories. These data discipline the exogenous
earnings profiles $\{y_{i,t}\}$ in the calibration.

---

## References

Barr, N. (2004). "Higher Education Funding." *Oxford Review of Economic Policy*.

Britton, J., L. Dearden, N. Shephard, and A. Vignoles (2020). "How English Domiciled
Graduate Earnings Vary with Gender, Institution Attended, Subject and Socio-economic
Background." *IFS Working Paper*.

Chapman, B. (2006). "Income Contingent Loans for Higher Education: International Reforms."
*Handbook of the Economics of Education*.
