# memory.md — Necessity Entrepreneurs

Most recent session first.

---

### Session: 2026-02-19 (repo reorganisation)
- Repository restructured: `PaperProjects/` renamed to `projects/`; `skills/` moved to `_shared/skills/`
- This file and `README.md` created as part of the new workspace standard
- No changes made to paper content in this session

### Session: 2026-02-18 (math audit + code crosswalk)
- Math audit run on full LyX file; 30 issues found
- Referee response drafted and compiled: `Referee/RESPONSE_TO_REFEREE.tex/.pdf`
- Code–paper crosswalk of `cfv_red_final.cpp` completed
- 10 discrepancies found (D1–D10); D1 fixed; D2–D10 require decisions

---

## Key files

| Role | Path |
|---|---|
| Paper source (TeX) | `projects/01_Necessity_Entrepreneurs/Chivers et al. (2025) Necessity Entrepreneurship.tex` |
| C++ calibration code | `projects/01_Necessity_Entrepreneurs/Calibration/cfv_red_final.cpp` |
| Referee response (TeX) | `projects/01_Necessity_Entrepreneurs/Referee/RESPONSE_TO_REFEREE.tex` |
| Math audit report | `projects/01_Necessity_Entrepreneurs/Referee/CodeAudit_2026-02-18/CODE_REFEREE_REPORT.md` |
| Figure scripts | `projects/01_Necessity_Entrepreneurs/Figures/generate_enter_employed.py` |

## Open decisions (as of 2026-02-18)

| ID | Question | Owner |
|----|----------|-------|
| D2 | Entrepreneur continuation: stay entrepreneur or re-enter as unemployed? | Bo / Dave |
| D3 | $\bar{m}$: paper says 0.8, code uses 0.9. Which is correct? | Dave |
| D4 | $b$: paper says 0.40w, code uses 0.30w/0.25w. Which? | Dave |
| D5 | $\tau_y$: paper says 0.151, code uses 0.037. Same object? | Dave + Bo |
| D6 | HSV progressive tax: is it in the model or aspirational? | Dave |
| D7 | $\alpha, \gamma$: paper shows averages, code uses education-varying. Clarify in paper? | Dave |
| D8 | Government budget: code doesn't balance. Note in paper or fix in code? | Dave |
| D9 | $p(\theta)$ vs $q(\theta)$ in vacancy cost: verify with Bo | Bo |

## Case-to-experiment mapping

| Case # | Experiment |
|---|---|
| 220 | Low unemployment insurance |
| 221 | High unemployment insurance |
| 222 | **Baseline** |
| 225 | No unemployment (frictionless market) |
| 226 | Unknown — ask Dave |

## Key conventions

- TeX file is ~54k tokens; read in 400–500 line chunks.
- $i_w$ coding: paper uses 0=unemployed, 1=employed, 2=entrepreneur; code uses reverse (0=entrepreneur).
- Build LaTeX in the `Referee/` folder: `pdflatex RESPONSE_TO_REFEREE.tex`.
- Do NOT commit `.aux`, `.log`, `.out` build artifacts.
