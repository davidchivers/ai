# Shared skills

Skills in this folder are broader reusable workflows rather than repo-specific operating prompts.

Discovery rule: if the user asks whether a skill exists or should be used, check this repo-level
folder before relying on installed system skills or saying the skill is unavailable.

## Source and discovery layout

- Existing single-file skills may remain at `_shared/skills/<name>-SKILL.md`.
- Skills with optional resources use `_shared/skills/<name>/SKILL.md` and may add `agents/`, `references/`, `scripts/`, or `assets/`.
- Do not define the same skill in both layouts.
- `.agents/skills/` and `.claude/skills/` are generated discovery bridges; do not edit them directly.
- After adding, moving, or editing a skill or resource, run `&_shared/scripts/sync_skill_bridges.ps1 -Prune`. Run it once in each worktree after the governance changes reach that worktree.
- Re-run the bridge after an editor uses atomic save, because replacing a file can sever an individual hard link.
- `sync_awesome_econ_skills.ps1` is audit-only unless called with `-Apply`; review every conflict because these skills intentionally diverge from their upstream templates.

## Preferred first choice by task

- `BOOK` / `The Target Trap` / book-blog-article drafting and revision: `book-voice-SKILL.md`
- Away-from-keyboard work sessions: `away-workflow-SKILL.md`
- Repository/code second-model reviews: installed `oracle` skill
- Whole-paper drafting and structure: `academic-paper-writer-SKILL.md`
- Literature search, verification, and synthesis: use the verified agent pipeline in `_shared/agents/README.md`
- Research question generation: `research-ideation-SKILL.md`
- Model exposition in LaTeX: `latex-econ-model-SKILL.md`
- Paper PDF compiling, hidden links, footnotes, and figure placement: `latex-paper-compile-layout-SKILL.md`
- Table redesign and rebuilds: `latex-tables-SKILL.md`
- Quantitative macro calibration tables: `calibration-tables/SKILL.md`
- Theory-first cluster calibration searches: `calibration-skill-SKILL.md`
- Slides in Beamer: `beamer-presentation-SKILL.md`
- Data downloads from external APIs: `api-data-fetcher-SKILL.md`
- Stata cleaning pipelines: `stata-data-cleaning/SKILL.md`
- Stata estimation workflows: `stata-regression-SKILL.md`
- Python panel-data workflows: `python-panel-data-SKILL.md`
- R causal and econometric workflows: `r-econometrics-SKILL.md`
- Figures and charts: `econ-visualization-SKILL.md`
- Theory-heavy GE work in Julia: `general-equilibrium-model-builder-SKILL.md`

## Boundary with agents

- Prefer a skill when you need a general method or software workflow.
- Prefer an agent when the task is mainly about how this repository organizes and documents work.

## Overlap rule

Some overlap is intentional. Choose the narrowest item that matches the task instead of stacking multiple near-equivalent skills.

For literature work, start from `_shared/templates/reference_checklist_template.csv` and copy it into a project-local `literature/checklist/reference_checklist.csv`, edited in Excel and gated by `confirm_yn`.

## Retired overlaps

- `codex-review-SKILL.md` was retired because the installed `oracle` workflow supersedes it.
- `lit-review-assistant-SKILL.md` was retired because the source-verified local agent pipeline supersedes it.
- Git history retains both earlier files; do not create a duplicate live archive.
