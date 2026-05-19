# NIMBY May submission layout, figure, table, and reference QA

Audited 2026-05-19 from the Dropbox submission folder and the repo mirror. The Dropbox and repo TeX/PDF hashes match, so these findings apply to both copies. No manuscript, PDF, or figure asset was edited.

Canonical source/PDF:
- `C:\Users\Dave_\Dropbox\Zac and David\2026_May_Submission\Gross and Chivers (2025) NIMBYism and the Housing Supply.tex`
- `C:\Users\Dave_\Dropbox\Zac and David\2026_May_Submission\Gross and Chivers (2025) NIMBYism and the Housing Supply.pdf`

## Findings worth acting on before submission

1. **PDF page 20 has a visible footer/text collision.**
   - Evidence: PDF page 20 shows the page number `20` inserted into the bottom paragraph: "the boom enter the labour and housing market, 20 the effect...". The source has `\enlargethispage{4\baselineskip}` at `...Housing Supply.tex:1079`, immediately before Figure 6 (`...Housing Supply.tex:1080-1086`) and the Section 5.2 text (`...Housing Supply.tex:1089-1100`).
   - Proposed fix: remove or reduce `\enlargethispage{4\baselineskip}` and either let Section 5.2 start on page 21 or slightly shrink/reposition Figures 5-6. Rebuild and visually recheck pages 20-21.

2. **Figures 9 and 10 are still unverified robustness assets.**
   - Evidence: current TeX includes `Figures/figure9_python_nonfinancial_pref_robust.pdf` at `...Housing Supply.tex:1166` and `Figures/figure10_python_alternative_voting_weights.pdf` at `...Housing Supply.tex:1187`; they render on PDF page 23. The existing risk checklist says these assets should not be treated as verified because the earlier regenerated robustness outputs used the bad flat seed (`referee/MANUSCRIPT_RISK_CHECKLIST_MAY2026.md:8-9`). `STATUS.md:172-176` says the corrected old-paper-seeded Figure 9/10 jobs were cancelled before starting, and `STATUS.md:3157-3160` still lists verification of corrected old-paper-seeded robustness packets as a next task.
   - Proposed fix: replace Figures 9 and 10 with corrected old-paper-seeded outputs before submission. If those outputs are unavailable, remove or quarantine the Figure 9/10 blocks and verify any retained Table 3 values against the same corrected source.

3. **Figure 7 remains a provisional/temporary asset relative to project status.**
   - Evidence: current TeX includes `Figures/figure7_unified_temporary_babyboom_forecast_rules.pdf` at `...Housing Supply.tex:1120`, rendering on PDF page 21. `STATUS.md:3149-3151` still says to monitor the corrected Figure 7 long-run packet and redraw Figure 7 once rows finish or stop improving; recent status entries also describe that packet as not final.
   - Proposed fix: redraw/insert final Figure 7 from the corrected packet before submission. If the current forecast-rule figure is now the intended submission object, rename or document it as final and update the status file so the source, asset name, and project state agree.

4. **Figures 5 and 6 have a source-consistency mismatch.**
   - Evidence: current TeX includes `Figures/figure5_python_steady_state_house_price.pdf` at `...Housing Supply.tex:1064` and `Figures/figure6_python_steady_state_projection.pdf` at `...Housing Supply.tex:1082`, rendering on PDF page 20. `STATUS.md:230-236` says Figures 5 and 6 were restored to original EPS-vector-derived PDFs, while `referee/MANUSCRIPT_RISK_CHECKLIST_MAY2026.md:20-21` flags this exact mismatch. The Dropbox submission `Figures/` folder does not contain the `figure5_steady_state_house_price_original_vector.pdf` or `figure6_steady_state_projection_original_vector.pdf` files.
   - Proposed fix: choose one convention before submission. If the original-vector assets are intended, copy them into the Dropbox `Figures/` folder and update the TeX include paths. If the Python reconstructions are intended, update the status/checklist and consider renaming the assets to remove reconstruction ambiguity.

5. **Table 3 is displayed before its first explicit textual reference.**
   - Evidence: Table 3 begins at `...Housing Supply.tex:1193` and renders at the top of PDF page 24; the first explicit textual reference is after the table at `...Housing Supply.tex:1222`.
   - Proposed fix: move the lead sentence beginning "Table 3 summarises..." above the table, or add a one-sentence lead-in before `\begin{table}`.

## Checks with no action found

- All 10 `\includegraphics` paths referenced by the current TeX exist in the Dropbox submission `Figures/` folder.
- The current compile log has no missing-figure, undefined-reference, rerun-required, overfull-box, or fatal-error warnings.
- All LaTeX `\ref`, `\figlink`, `\figlinklower`, `\eqnlink`, and `\paperlink` targets resolve in the source.
- Figures are numbered sequentially 1-10 and tables are numbered sequentially 1-3.
- Figures are discussed before display in the source.
- `hyperref` is loaded with `hidelinks` at `...Housing Supply.tex:96`; rendered pages show no visible link boxes or coloured link styling.
- References begin on PDF page 25 and the appendix begins after them on PDF page 29.
- No visible `TODO`, `FIXME`, placeholder marker, unresolved `??`, or revision-process language was found in the rendered PDF.
