# Notes phase standard

This standard governs brainstorming and pre-paper planning when active work is in a research project's or research idea's `notes/` folder.

## Scope

- Applies to pre-paper work only.
- Does not govern paper-phase structure; use `paper_project_structure_standard.md` for that.

## Required `notes/` layout

Use a flat Markdown layout in `notes/` for active documents. Generated outputs may live in `notes/build/`, and superseded material may live in `notes/old/`; the organizer must not flatten either folder.

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
- Use the shared note templates in `_shared/templates/notes/` when creating a new notes file from scratch.

## Recommended section order by file

The exact prose should vary by project, but the house style should be recognizable across idea
notes.

For research ideas intended as economics projects, `01_project_overview.md` should include a blunt
`## Journal fit and ambition` section. The point is not to pretend we know the final outlet. The
point is to force an honest current-tier read such as:

- `top 5: no / maybe / plausible only with major redesign`
- `top general-interest field: no / maybe`
- `strong field journal: yes / maybe`
- `best interdisciplinary fit`

That section should distinguish between:

- the current read for the idea as it stands now
- what would have to improve to move the idea up a tier

### `01_project_overview.md`

Use this order unless the user requests something different:

- `Last updated`
- `Status`
- `## Project intention`
- `## Motivating intuition`
- `## Central research question`
- `## What the project is really about`
- `## Journal fit and ambition`
- `## Scope`
- `## Working hypotheses`
- `## Contribution framing`
- `## Main risks`
- `## Design lock questions`
- `## Near-term roadmap`

### `02_literature_and_synthesis.md`

Use this order unless the user requests something different:

- `Last updated`
- `## Current rule`
- `## Benchmark strand ...`
- `## What remains missing`
- `## Working synthesis`
- `## Verified anchor references`
- `## Open verification tasks`

### `03_model_notes.md`

Use the shared model block template. Each model should be a separate top-level heading:

- `# Model N: [name]`
- `**Model type:**`
- `**Literature.**`
- `**How this applies to the question.**`
- `**References.**`

### `04_empirical_notes.md`

Use the shared empirical strategy block template. Each strategy should be a separate top-level
heading:

- `# Strategy N: [name]`
- `**Strategy type:**`
- `**Literature.**`
- `**How this applies to the question.**`
- `**References.**`

### `05_research_plan.md`

Use this order unless the user requests something different:

- `Last updated`
- `Status`
- `## Chosen question and estimand`
- `## Chosen models`
- `## Chosen empirical strategies`
- `## Data access and fallback`
- `## Decision log`
- `## Design lock criteria`
- `## Next 3 tasks`

Each task in `## Next 3 tasks` should name an owner and a concrete deliverable.

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

After reviewing the audit, apply the migration to named projects rather than the entire repository:

```powershell
&_shared/scripts/organize_notes.ps1 -ProjectPaths research_ideas/learning_by_viewing,research_ideas/accents_and_dialects -Apply
```

Strict read-only enforcement mode (fails when violations remain):

```powershell
&_shared/scripts/organize_notes.ps1 -AllProjects -FailOnViolations
```
