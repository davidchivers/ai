# Necessity Entrepreneurs — Project Plan

**Paper**: Chivers, Feng, Keller & Li (2025) "Necessity Entrepreneurship"
**Status**: Half-complete draft in LyX format
**Last updated**: 2026-02-18

---

## Paper Structure (current sections in LyX)

1. Introduction (draft, needs polish + lit review completion)
2. The Model: Economic Environment (has subsections: preferences, endowments, production, factor remuneration, government, firm's problem)
3. Optimal Behavior and Equilibrium (firm manager, capital, entrepreneurs, employed, unemployed, government, household problem, equilibrium)
4. Calibration (has parameter table, needs results filled in)
5. Baseline Results (empty)
6. Quantitative Analysis — experiments:
   - No Unemployment
   - Increasing Unemployment Insurance (holding taxes constant / adjusting taxes)
   - Consumption Floor (lump-sum transfer / non-pecuniary penalty)
   - Consumption floor with no unemployment or taxes
   - Credit Friction Wedge
   - Job Market Experiment
7. Conclusion (empty)
8. Appendix: Computation
9. Appendix: Search and Matching

---

## Workstreams

### WS1: Literature Review
- **Status**: Incomplete. Paper says "This paper is related to the following" then stops.
- **Difficulty**: Medium-High (risk of hallucinated citations)
- **Approach**: Use only verified papers from Literature/ folder + papers Claude can confidently identify. Dave verifies any additions.
- **Literature folder contains**: Fairlie & Fossen (2020), Elsby & Michaels (2013), Pellegrini (2025), Garicano & Rossi-Hansberg (2006), Block Fisch van Praag (2017), Bilal (2022), Sedlacek & Sterk (2017), Donovan Lu Schoellman (2023), Engbom et al (2025), Elsby et al (2022), Herreno & Ocampo (2023)
- **Candidate for**: Codex batch task (read each PDF, summarize relevance, draft lit review paragraphs)

### WS2: Math Checking
- **Status**: IN PROGRESS (background agent running 2026-02-18)
- **Difficulty**: Medium
- **Approach**: Full read of LyX, check all equations, FOCs, Bellman equations, equilibrium definition
- **Output**: Will be saved to this folder when complete

### WS3: Experiments Write-Up
- **Status**: Sections exist but results are incomplete/placeholder
- **Difficulty**: Medium (requires Dave's input on case mapping)
- **Key question**: Which case numbers map to which experiments?
- **Case PNGs available**: 220, 221, 222, 225, 226 (3x1 and 4x1 variants)
- **Sub-task 3.1**: Assess whether existing figures explain results well; possibly redo as TikZ/Python

#### Case-to-Experiment Mapping (TO BE FILLED BY DAVE)
| Case # | Experiment | Notes |
|--------|-----------|-------|
| 220    | Decreased UI benefit | Compared vs baseline (222) in slides |
| 221    | Increased UI benefit | Compared vs baseline (222) in slides |
| 222    | **Baseline** | Main calibration case |
| 225    | No unemployment | Perfect market, compared vs baseline (222) |
| 226    | Unknown | Has cutoff PNGs, not in slides — ask Dave |

Source: Slides_v3.lyx frame titles map cases to experiments.

### WS4: Calibration & Convergence
- **Status**: Ongoing issue. Model may not be converging correctly.
- **Difficulty**: Very High
- **Code**: cfv_red_final.cpp (C++ with VFI + GE loop + simulation)
- **Results**: Multiple xlsx files across old/ and results_2025/
- **Key concerns from to_do.txt**:
  1. Plot difference between cutoff level of employed vs unemployed at different education levels
  2. Run no-friction experiment (rho=0, p(theta)=1, bar_m=1, mu=1)
  3. Compare cutoff values under no friction vs with friction
  4. Understand non-monotonicity of cutoff line for mid/high-education in case 220
- **Approach**: Read C++ code, review convergence logs, run experiments

---

## Day-by-Day Schedule

### Day 1 (2026-02-18) — Planning + Math ✓ COMPLETE
- [x] Create project plan
- [x] Launch math checking (background agent, Opus)
- [x] Math check complete — 30 issues found, referee report written
- [x] Compiled paper PDF (20 pages)
- [x] Referee report saved as PDF + MD + TEX in Referee/ folder
- [x] Case mapping extracted from Slides_v3.lyx (222=baseline, 225=no unemp, 221=high UI, 220=low UI)
- [x] Copied Slides_v3.lyx and Slides_Feng_v3.lyx/pdf to working folder
- [ ] Still unknown: what is case 226?

### Day 2 — Math Fixes + Experiments Write-Up
- [ ] **FIRST**: Compare C++ code (cfv_red_final.cpp) with paper equations to determine which is correct (Issues 1-4, 14)
- [ ] Fix critical math issues in LyX (FOCs, profit function, budget constraint sign, r/r̃)
- [ ] Fix high-priority issues (i_w coding, state space, equilibrium definition)
- [ ] Draft experiment results sections
- [ ] Assess case PNG figures — do they explain the results well?

### Day 3 — Calibration + Literature
- [ ] Deep-read C++ code
- [ ] Run calibration, investigate convergence
- [ ] (Codex or Claude) Draft literature review using papers in Literature/ folder

### Day 4 — Slides + Polish
- [ ] Build slides from paper content
- [ ] Final consistency pass

---

## Tools & Resources
- **Stata**: StataNow 19 SE at C:/Program Files/StataNow19/StataSE-64.exe
- **C++ code**: NecessityEntrepreneurs/Calibration/cfv_red_final.cpp
- **Python figure scripts**: NecessityEntrepreneurs/Figures/generate_enter_*.py
- **Codex**: Available for self-contained batch tasks

---

## Notes for Future Claude Sessions
- Read this file first to understand project state
- Check the case-to-experiment mapping table above
- Math check results saved in this folder
- The LyX file is ~54k tokens — read in 500-line chunks
