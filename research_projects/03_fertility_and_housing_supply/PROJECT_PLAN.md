# Project Plan: Fertility, Housing Constraints, and the Political Economy of Housing Supply

## Overview

This project extends an existing theoretical model of NIMBYism and housing supply by incorporating household fertility decisions and life-cycle dynamics. The core political mechanism governing housing supply â€” inherited from `../02_nimbyism_and_housing_supply` â€” is held fixed. The extension studies how housing supply restrictions, housing costs, and access to adequately sized housing interact with fertility timing and completed fertility over the household life cycle.

**Current phase:** Brainstorming and model design. Formal implementation will follow once the theoretical structure is settled.

**Toolchain:** LyX (paper), MATLAB (model solution), Stata (data pipeline). Conventions inherited from project 02.

---

## Core Research Questions

1. Do housing supply constraints and high housing costs delay the timing of first birth?
2. Does delayed access to adequately sized housing reduce completed fertility, given finite biological and life-cycle horizons?
3. Can political mechanisms that restrict housing supply â€” by raising prices or limiting housing size â€” indirectly depress fertility rates?
4. How does the trade-off between housing utility and child utility shape household sorting across housing markets?

---

## Key Mechanisms

These are the causal channels the model is designed to capture:

- **Overcrowding disutility:** Household utility from housing is decreasing in the ratio of household size to housing size. Fertility increases effective household size, making small housing more costly.
- **Fertility timing:** Households may defer childbearing until they have transitioned to sufficiently large housing (owned or rented). Delays are costly because of finite fertility horizons.
- **Quantityâ€“quality trade-off:** Higher housing costs may induce substitution away from children in favour of higher per-child expenditure or housing quality (a Becker-style channel).
- **Political economy spillover:** If the political equilibrium restricts housing supply and raises prices, the fertility responses above aggregate into a demographic effect â€” connecting the NIMBY mechanism to fertility outcomes.

---

## Modelling Framework

### 1. Political Economy of Housing Supply

Inherited from `../02_nimbyism_and_housing_supply`. Housing supply is determined endogenously by a political mechanism (e.g. median voter or political redistribution). This block is not modified.

### 2. Household Utility

Households derive utility from:
- Housing (size or quality),
- Children (number and/or quality).

Housing utility is mediated by household size: larger households experience disutility from small housing (overcrowding). The precise functional form (e.g. per-capita housing services, ratio-based) will be chosen to balance tractability with empirical plausibility.

Working baseline after initial literature scan:
- Keep a CRRA/Cobb-Douglas core inherited from project 02 and map fertility into effective housing services via a crowding term.
- Candidate form (to be finalized):
  `u_t = ((c_t^(1-zeta) * h_eff_t^zeta)^(1-gamma))/(1-gamma)`, with `h_eff_t = h_t / (1 + lambda * n_t)^psi`.
- Alternative extensions to test later:
  - add a direct child utility term (quantity channel),
  - add tenure-specific utility wedges (owner vs renter) if needed empirically.

See: `notes/02_literature_and_synthesis.md`.

### 3. Fertility and Timing Decisions

- Fertility is a choice variable, chosen over the life cycle.
- Households may defer childbearing contingent on:
  - securing housing of sufficient size, and/or
  - transitioning from renting to homeownership.
- Finite fertility horizons mean that deferral is costly: delayed access to adequate housing translates into reduced completed fertility.

### 4. Life-Cycle Structure

Stylised household life cycle:

| Stage | Description |
|---|---|
| Formation | Household forms as a couple (initially modelled as a single unit). |
| Renting and saving | Household rents, accumulates savings, and makes fertility decisions. |
| Homeownership | Household transitions to ownership upon reaching a down payment threshold. |
| Childrearing | Children are present for a finite period (approximately 18â€“25 years). |
| Post-children | Household size declines; housing demand adjusts. |

Partner formation and marriage timing are acknowledged as potentially important but are treated as second-order extensions for now.

---

## Literature Agenda

### A. Fertility in Life-Cycle and Household Utility Models

- Fertility as a discrete or continuous choice variable in OLG and life-cycle models.
- Desired versus realised fertility: mechanisms through which constraints bind.
- Quantityâ€“quality trade-offs (Becker and Lewis 1973 [UNVERIFIED]; Becker, Murphy, and Tamura 1990 [UNVERIFIED]).
- Drivers of declining fertility: income effects, opportunity cost of children, housing costs.

### B. Housing Constraints and Family Formation

- Housing adequacy and overcrowding: definitions, measurement, and welfare effects.
- Housing affordability and the timing of family formation and first birth.
- Homeownership as a precondition for childbearing: cultural and economic dimensions.
- Empirical links between housing supply restrictions, house prices, and fertility rates.

### C. Political Economy and Demographics

- Connections between median-voter housing models and demographic outcomes.
- Fiscal externalities of fertility (e.g. public schooling, social security) and their interaction with local zoning.

---

## Empirical Motivation and Data (Future Phase)

Empirical work will be structured to motivate and discipline the theoretical model, rather than to test it directly.

**Potential outcome variables:**
- Total fertility rate (TFR) and completed cohort fertility.
- Timing of first birth (median maternal age at first birth).

**Potential explanatory variables:**
- Housing supply: building permits, housing unit growth, Wharton Residential Land Use Regulation Index (WRLURI), Saiz (2010) supply elasticities.
- Housing costs: real house prices, price-to-income ratios, rental market tightness.
- Housing size and adequacy: overcrowding rates, average dwelling size.

**Initial geographic focus:** United States (MSA-level or county-level panel), with potential cross-country extension depending on data availability.

**Potential identification strategies:** Shift-share instruments for housing supply; geographic constraints on land availability (Saiz 2010); policy variation in zoning.

---

## Workflow

| Step | Task | Status |
|---|---|---|
| 1 | Formalise the extended theoretical model (utility, constraints, equilibrium). | In progress |
| 2 | Conduct targeted literature review (strands Aâ€“C above). | In progress |
| 3 | Map reusable model blocks from `../02_nimbyism_and_housing_supply`. | Not started |
| 4 | Define empirical variables and identify candidate datasets. | Not started |
| 5 | Implement the model in MATLAB. | Not started |
| 6 | Calibrate or empirically illustrate the model. | Not started |

---

## Notes and Conventions

- All upstream model changes from project 02 should be evaluated for portability and logged in `UPSTREAM_SYNC_LOG.md`.
- AI tools (Claude Code, etc.) are used as research and workflow assistants. Conceptual clarity takes precedence over code output at this stage.
- Do not commit `.mat` or `.dta` files.


