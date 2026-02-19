# 01_Necessity_Entrepreneurs

**Paper**: Chivers, Feng, Keller & Li (2025) "Necessity Entrepreneurship"
**Status**: Half-complete draft — math audit done; revisions in progress
**Last updated**: 2026-02-19

---

## What this project is

Heterogeneous-agent model of entrepreneurship in which workers choose between employment, unemployment, and entrepreneurship. Emphasises "necessity entrepreneurship" (entering out of unemployment) vs "opportunity entrepreneurship." Model calibrated with C++ value function iteration.

## Current status

- [x] Math audit complete (30 issues found, February 2026)
- [x] Referee response drafted (`Referee/RESPONSE_TO_REFEREE.tex/.pdf`)
- [x] Code–paper crosswalk complete (10 discrepancies found)
- [ ] Critical math fixes applied to LyX paper
- [ ] Co-author decisions on D2 (entrepreneur continuation), D3–D5 (parameter values), D6 (HSV tax)
- [ ] Substantive sections: abstract, introduction, baseline results, conclusion

## Next 3 concrete tasks

1. **Apply math fixes** to `Chivers et al. (2025) Necessity Entrepreneurship.lyx` for Issues 1–10 from the referee report.
2. **Resolve co-author questions** D2, D5, D6 with Bo/co-authors before rerunning code.
3. **Draft baseline results section** once calibration parameters are confirmed.

---

## Folder structure

```
01_Necessity_Entrepreneurs/
  Chivers et al. (2025) Necessity Entrepreneurship.tex   ← authoritative paper source
  Slides_paper_v4.tex / .pdf                             ← latest slides
  Calibration/
    cfv_red_final.cpp                                    ← C++ calibration code (main)
    old/                                                 ← old calibration runs
    results_2025/                                        ← current output files
  Figures/                                               ← publication figures + Python scripts
  Literature/                                            ← reference PDFs
  Referee/
    RESPONSE_TO_REFEREE.tex / .pdf                       ← referee response (main output)
    CodeAudit_2026-02-18/                                ← code audit report
    Slides_MathAudit_2026-02-18/                         ← math audit slides
  docs/policy/
    PROJECT_HYGIENE.md
```
