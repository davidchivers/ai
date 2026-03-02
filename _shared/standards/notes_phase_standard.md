# Notes phase standard

This standard governs brainstorming and pre-paper planning when active work is in `research_projects/<name>/notes/`.

## Scope

- Applies to pre-paper work only.
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

## Brainstorming formatting rules

- Use clear area headings with larger section structure (for example `## Causal evidence`, `## Model family: ...`).
- Prefer fewer, deeper options over long option lists.
- Use paragraph-first writing; keep bullets for short checklists only.
- In literature notes, use real and searchable references only.
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

