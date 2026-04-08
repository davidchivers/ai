# Notes phase standard

This standard governs brainstorming and pre-paper planning when active work is in `research_projects/<name>/notes/` or `research_ideas/<name>/notes/`.

## Scope

- Applies to pre-paper work only.
- Applies to both paper-track projects and early-stage research ideas.
- Does not govern `Paper/` writing-phase structure.

## Required `notes/` layout

Use a flat Markdown layout in `notes/` (no subfolders for active docs):

- `notes/01_project_overview.md`
- `notes/02_literature_and_synthesis.md`
- `notes/03_model_notes.md`
- `notes/04_empirical_notes.md`
- `notes/05_research_plan.md`
- `notes/README.md`

## Phase workflow (mandatory)

1. Brainstorming phase (discovery): work in `01` to `04` only.
2. Planning phase (commitment): synthesize into `05_research_plan.md`.
3. Execution phase: update `STATUS.md` with the selected plan and next 3 tasks.

## Sub-agent orchestration (recommended)

Use staged orchestration for notes-phase work. The default pattern is parallel within stages, sequential across stages.

1. Scope lock: one lead agent defines the question, mechanism, geography, and constraints in `01_project_overview.md`.
2. Parallel scouting: bounded sidecar agents may run in parallel for literature search, related-mechanism scan, and data inventory.
3. Verification gate: verify shortlisted papers and core claims before using them for novelty claims or detailed design generation.
4. Design stage: once the literature gate passes, model and empirical design work may proceed in parallel in `03_model_notes.md` and `04_empirical_notes.md`.
5. Synthesis gate: one lead agent writes `05_research_plan.md`, updates `STATUS.md`, and records the next 3 tasks.

Typical agent mapping:

- `literature-scout.md`: stage 2 literature search, ranking, and checklist population.
- `evidence-checker.md`: stage 3 verification of papers and claims.
- `lit-review-drafter.md`: optional writing pass after the checklist gate clears.
- `empirical-idea-generator.md`: stage 4 empirical design generation from verified inputs.
- `notes-organizer.md`: end-of-session cleanup and link validation.

Rules:

- At most one agent edits a canonical file at a time.
- `05_research_plan.md`, `STATUS.md`, `README.md`, and `memory.md` are single-owner files.
- Sidecar agents should usually return structured memos, tables, or patch suggestions rather than editing canonical planning files directly.
- Novelty and feasibility claims must rely on verified literature or be marked `[INFERRED -- verify]`.
- For literature work, prefer a single Excel-editable checklist at `literature/checklist/reference_checklist.csv`.
- Treat `confirm_yn = Y` or `Yes` as the gate for citation-ready papers; blank or `N` means still open.

## Brainstorming formatting rules

- Use clear area headings with larger section structure (for example `## Causal evidence`, `## Model family: ...`).
- Prefer fewer, deeper options over long option lists.
- Use paragraph-first writing; keep bullets for short checklists only.
- In literature notes, use real and searchable references only.
- Mark novelty or feasibility claims that are not yet verified as `[INFERRED -- verify]`.
- In model notes, map each model to estimable objects.
- In empirical notes, include dataset/provider, identification design, baseline equation, key threats, and feasibility.

## Model notes format (required)

Each model in `notes/03_model_notes.md` uses this structure — one `#` heading per model, then three blocks:

```
# Model N: [Descriptive name]

**Model type:** [One sentence: e.g. "OLG lifecycle model", "task-based production model", "dynamic coordination game"]

**Literature.**
[Paragraph: which papers this builds on and what each contributes.]

**How this applies to the question.**
[Paragraph: how the model connects to the research question, what estimand or prediction it generates, one regression or key equation at the end as payoff.]

**References.**
[Citations]
```

Rules:
- Maximum 5 models per file unless explicitly requested.
- Number models sequentially: `# Model 1:`, `# Model 2:`, etc.
- Do not present context-free equations; the regression or key equation appears only as payoff of the prose argument.
- No numbered sub-sections or numbered bullet lists inside a model block.

## Empirical notes format (required)

Each strategy in `notes/04_empirical_notes.md` uses this structure:

```
# Strategy N: [Descriptive name]

**Strategy type:** [One sentence: e.g. "Staggered DiD / event study", "RCT with heterogeneity extension", "IV using predetermined geography"]

**Literature.**
[Paragraph: key papers using this design and what they establish.]

**How this applies to the question.**
[Paragraph: data source, identification argument, baseline regression equation, key threats and mitigations, feasibility note.]

**References.**
[Citations]
```

Rules:
- Maximum 5 strategies per file unless explicitly requested.
- Number strategies sequentially: `# Strategy 1:`, `# Strategy 2:`, etc.
- Baseline regression equation appears inside the "How this applies" block, not as a standalone section.

## Planning handoff file (`05_research_plan.md`)

`05_research_plan.md` must contain:

- Chosen research question and estimand.
- Top 1-2 model choices with rationale.
- Top 1-2 empirical designs with rationale.
- Data access decision and fallback path.
- Short novelty assessment tied to verified literature, with any remaining verification gaps clearly flagged.
- Decision log (what was rejected and why).
- Next 3 concrete tasks with owner and deliverable.

## Naming and capitalization

- Keep active notes filenames lowercase snake_case with numeric prefixes.
- Use sentence case for headings.
- Avoid all-caps words except fixed acronyms.

## Reference hygiene

When reorganizing notes:

- Update links in `README.md`, `STATUS.md`, `memory.md`, and `notes/README.md`.
- Keep `STATUS.md` as the canonical "where are we" source.

## Automation

Use the shared organizer script:

```powershell
&_shared/scripts/organize_notes.ps1 -AllProjects
```

Strict enforcement mode (fails when violations remain):

```powershell
&_shared/scripts/organize_notes.ps1 -AllProjects -FailOnViolations
```

Or target specific projects:

```powershell
&_shared/scripts/organize_notes.ps1 -ProjectPaths research_ideas/learning_by_viewing,research_ideas/accents_and_dialects
```

