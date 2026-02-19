# Folder Hygiene (NecessityEntrepreneurs)

## Rule
Keep the project root clean. Root should contain only core paper/slides files and key docs.

## Put files here
- Figures: `Figures/`
- Calibration outputs and charts: `Calibration/` (or `Calibration/outputs/`)
- Referee/audit outputs: `Referee/`
- Build artifacts (`.aux`, `.log`, `.nav`, `.snm`, `.toc`): `build/` or delete after compile

## Root-level allowed (examples)
- `Chivers et al. (2025) Necessity Entrepreneurship.lyx`
- `Chivers et al. (2025) Necessity Entrepreneurship.pdf`
- `slides.tex`
- `slides.pdf`

## Root-level disallowed
- Loose `.png`/`.eps` figures
- Temporary LaTeX outputs
- One-off generated files not part of final deliverables
