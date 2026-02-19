# DAAF Tutorial for Economists & Data Scientists
## A Beginner's Guide to AI-Assisted Research with Claude Code

---

## Part 1: What Is This Thing?

### The One-Sentence Version
DAAF (Data Analyst Augmentation Framework) is a set of instructions and tools that turn Claude Code into a **research assistant that can find data, clean it, analyze it, and write reports** — all while keeping a paper trail you can audit.

### Why Should an Economist Care?
Imagine you want to answer: *"Do more selective colleges have higher graduation rates?"*

Normally you would:
1. Find the right dataset (IPEDS? Scorecard?)
2. Download it
3. Clean it (missing values, recoding, merging)
4. Run regressions / make charts
5. Write up findings

DAAF does all of this **programmatically**, with Claude Code acting as your research assistant. Every step is saved as a Python script. Every script gets a quality-assurance review. You end up with a full audit trail — not just results, but *how* you got them.

### The Key Idea: You Stay in Control
DAAF is **not** a black box. It:
- Asks you to confirm its plan before executing
- Saves every script it writes (you can read and edit them)
- Runs quality checks after every transformation
- Produces a final report you review

Think of it as a very organized RA who documents everything.

---

## Part 2: How the Folder Is Organized

Here's the `daaf/` folder you just cloned, explained in plain English:

```
daaf/
│
├── CLAUDE.md              ← The "brain": master instructions that tell
│                            Claude how to behave as a research assistant
│
├── agents/                ← 14 specialist "roles" Claude can play
│   ├── research-executor  ← Runs your data scripts
│   ├── code-reviewer      ← Checks scripts for errors
│   ├── data-planner       ← Writes your research plan
│   ├── report-writer      ← Writes your final report
│   └── ...more            ← (debugger, verifier, etc.)
│
├── .claude/skills/        ← 26 "knowledge packs" Claude can reference
│   ├── data-scientist/    ← How to do stats properly
│   ├── education-data-*/  ← Knowledge about 15+ education datasets
│   ├── polars/            ← How to use the Polars data library
│   ├── plotnine/          ← How to make ggplot-style charts in Python
│   └── ...more
│
├── agent_reference/       ← Internal protocols (the "employee handbook")
│   ├── 01_PROTOCOLS.md
│   ├── PLAN_TEMPLATE.md
│   ├── REPORT_TEMPLATE.md
│   └── ...more
│
├── user_reference/        ← YOUR guides (start here!)
│   ├── 01_installation_and_quickstart.md
│   ├── 02_understanding_daaf.md
│   ├── 03_best_practices.md
│   └── ...more
│
├── research/              ← Example completed project
│   └── 2026-02-15 College Graduation Rate.../
│       ├── Plan.md        ← The research plan
│       ├── Report.md      ← Final written report
│       ├── scripts/       ← All Python scripts (fetch, clean, analyze)
│       ├── data/          ← Raw + processed data files
│       └── output/        ← Charts and statistical results
│
├── scripts/               ← Utility scripts
├── Dockerfile             ← Sets up the Python environment
└── docker-compose.yml     ← Runs everything in a container
```

### Analogy for Economists
| DAAF Component | Academic Equivalent |
|---|---|
| `CLAUDE.md` | Your lab's standard operating procedures |
| `agents/` | Specialist roles (RA, reviewer, editor) |
| `.claude/skills/` | Your RA's training materials & codebooks |
| `agent_reference/` | Internal process documentation |
| `user_reference/` | The manual you actually read |
| `research/` | A completed replication package |

---

## Part 3: The Workflow (How Research Happens)

DAAF follows a **5-phase, 12-stage pipeline**. Here's the economist-friendly version:

### Phase 1: Discovery & Scoping (Stages 1-3)
**What happens:** You ask a research question. DAAF explores what data exists.

```
You: "I want to study the relationship between college selectivity
      and graduation rates"

DAAF: Explores available datasets → Finds IPEDS has admission rates,
      graduation rates, institutional characteristics → Reports back
      what's available and feasible
```

### Phase 2: Planning (Stage 4)
**What happens:** DAAF writes a research plan (like a pre-analysis plan).

The plan includes:
- Research question & observable hypotheses
- Data sources and variables
- Exact transformation sequence (merge this, filter that)
- Statistical methods
- Potential limitations

**You review and approve the plan before anything runs.**

### Phase 3: Data Acquisition & Preparation (Stages 5-6)
**What happens:** DAAF writes Python scripts to fetch and clean data.

- **Stage 5 (Fetch):** Downloads data from APIs
- **Stage 6 (Clean):** Recodes variables, handles missing data, merges files

Each script gets a separate QA review. If something fails, it gets fixed before moving on.

### Phase 4: Analysis (Stages 7-10)
**What happens:** DAAF runs your analysis.

- **Stage 7:** Exploratory data analysis, variable construction
- **Stage 8:** Regressions, charts, statistical tests
- **Stage 9:** Compiles everything into a Marimo notebook (interactive Python notebook)
- **Stage 10:** Final quality aggregation

### Phase 5: Synthesis (Stages 11-12)
**What happens:** DAAF writes your report and does a final verification.

- **Stage 11:** Generates a stakeholder-ready report with findings
- **Stage 12:** Adversarial verification (tries to poke holes in its own work)

---

## Part 4: What You Need to Get Started

### Prerequisites
1. **Claude Code** — You already have this (you're using it now in VS Code)
2. **An Anthropic API key** — With credits for Claude usage
3. **Docker** (recommended) — To run the Python data science environment in a container
4. **Git** — Already installed (you cloned the repo)

### Option A: Run With Docker (Recommended)
Docker gives you a clean Python environment with all packages pre-installed.

```bash
# From your Economics folder
cd daaf

# Build the container (first time only, takes a few minutes)
docker compose build

# Start the container
docker compose run --rm daaf-docker bash

# Inside the container, launch Claude Code
claude
```

### Option B: Run Without Docker (Use Your Local Python)
If you prefer not to use Docker, install the required packages locally:

```bash
pip install numpy pandas polars scipy requests pyarrow \
            scikit-learn statsmodels pyfixest \
            matplotlib seaborn plotnine plotly marimo
```

Then open the `daaf/` folder in VS Code and use Claude Code from there.

---

## Part 5: Your First Research Project (Step by Step)

### Step 1: Open the DAAF folder
In VS Code, open the folder: `Desktop/Economics/daaf/`

This is important — Claude Code reads `CLAUDE.md` when it starts, which loads all the framework instructions.

### Step 2: Start Claude Code
Open the Claude Code panel in VS Code (or use the terminal).

### Step 3: Ask a Research Question
Type something like:

> "I want to analyze the relationship between institutional spending
> per student and 6-year graduation rates at public 4-year universities
> using IPEDS data from 2015-2020."

### Step 4: DAAF Classifies Your Request
It will respond with something like:
> "Classification: **Full Pipeline** — This requires data discovery,
> planning, execution, and reporting. Confirm?"

Say yes.

### Step 5: Discovery Phase
DAAF explores available data sources and reports back:
- What variables are available
- What years are covered
- What limitations exist
- Whether your question is feasible

### Step 6: Review the Plan
DAAF generates a `Plan.md` in a new research folder. Read it carefully:
- Are the right variables included?
- Is the methodology appropriate?
- Are there missing controls you want?

Tell DAAF what to change before approving.

### Step 7: Watch It Execute
Once you approve, DAAF:
1. Writes fetch scripts → runs them → QA reviews each one
2. Writes cleaning scripts → runs them → QA reviews each one
3. Writes analysis scripts → runs them → QA reviews each one
4. Compiles a notebook and report

### Step 8: Review Your Outputs
You'll find in your research folder:
- `Plan.md` — Your approved research plan
- `Report.md` — Written findings
- `scripts/` — Every Python script, numbered and documented
- `data/raw/` — Original downloaded data
- `data/processed/` — Cleaned data
- `output/figures/` — Charts and visualizations

---

## Part 6: Learning from the Example Project

The repo includes a completed example at:
```
research/2026-02-15 College Graduation Rate Selectivity Analysis/
```

This is a **full replication package** you can study. Here's what to look at:

### 1. Read the Plan
Open `Plan.md` to see how DAAF structured the research design.

### 2. Read the Report
Open `Report.md` to see the final output.

### 3. Examine the Scripts
Look in `scripts/` — they're numbered sequentially:
- `stage5_fetch/01_*.py` — Data download scripts
- `stage6_clean/01_*.py` — Data cleaning scripts
- `stage7_transform/01_*.py` — Variable construction
- `stage8_analysis/01_*.py` — Statistical analysis

### 4. Check the QA Reviews
In `scripts/cr/` you'll find the quality-assurance review scripts.
Every data script got reviewed separately.

### 5. Look at the Output
`output/figures/` contains the visualizations.
`output/analysis/` contains statistical results.

---

## Part 7: Key Concepts for Economists

### "Observable Truths"
DAAF's version of testable hypotheses. Every analysis must establish
measurable outcomes. Example:
> "OT-1: Admission rate is negatively correlated with 6-year graduation
> rate (p < 0.05)"

### "Inline Audit Trail" (IAT)
Every script includes detailed comments explaining:
- **INTENT:** What this code block does
- **REASONING:** Why this approach was chosen
- **ASSUMES:** What data assumptions are being made

This is like commenting your Stata do-file, but enforced systematically.

### "Validation Checkpoints"
At each stage, specific checks must pass:
- **CP1 (Fetch):** Did we get the right number of rows? Right columns?
- **CP2 (Clean):** How much data was lost? Are coded values handled?
- **CP3 (Transform):** Did merges preserve row counts?
- **CP4 (Analysis):** Do models converge? Do figures render?

### "File-First Principle"
Nothing happens in memory only. Every script is saved. Every output
is written to disk. Every log is captured. This means:
- Full reproducibility
- You can re-run any individual step
- Nothing is lost if a session crashes

---

## Part 8: Available Data Sources (Out of the Box)

DAAF comes pre-configured to work with **40+ education datasets**
via the Urban Institute Education Data Portal:

| Dataset | What It Contains |
|---|---|
| **IPEDS** | Institutional characteristics, enrollment, graduation rates, finance |
| **College Scorecard** | Earnings outcomes, costs, debt, completion rates |
| **CCD** | K-12 school directory, enrollment, demographics |
| **CRDC** | Civil rights data (discipline, AP access, staffing) |
| **EdFacts** | K-12 achievement and accountability |
| **EADA** | Equity in Athletics (Title IX compliance) |
| **FSA** | Federal Student Aid (Pell grants, loans) |
| **SAIPE** | Small Area Income & Poverty Estimates |
| **NHGIS** | Historical census/demographic data |
| **PSEO** | Post-Secondary Employment Outcomes |
| **MEPS** | Medical Expenditure Panel Survey |
| **NCCS** | Nonprofit organization data |
| **NACUBO** | University endowment data |
| **Campus Safety** | Crime and safety statistics |

### Want Other Data?
DAAF can be extended to work with any data source. See
`user_reference/04_extending_daaf.md` for how to add new datasets.

---

## Part 9: Tips for Economists

### Writing Good Prompts
**Bad:** "Analyze education data"
**Good:** "Using IPEDS data from 2015-2020, estimate the relationship
between instructional expenditure per FTE and 6-year graduation rates
at public 4-year institutions, controlling for admission rate,
enrollment size, and urbanicity."

### Be Specific About Methods
DAAF supports:
- OLS regression (statsmodels)
- Fixed effects / panel methods (pyfixest)
- Clustering
- Descriptive statistics
- Correlation analysis
- Visualization (plotnine for ggplot-style, plotly for interactive)

Mention what you want explicitly.

### Review at Every Checkpoint
Don't just let it run. The framework is designed for you to:
1. Review the plan (Phase 2)
2. Spot-check scripts as they execute (Phases 3-4)
3. Carefully read the final report (Phase 5)

### Iterate
After the first run, you can ask for:
- "Add state fixed effects to the regression"
- "Restrict the sample to institutions with >1000 FTE"
- "Create a robustness check using 4-year graduation rates instead"

DAAF handles revisions as a separate workflow mode.

---

## Part 10: Quick Reference

### Folder You Should Read First
```
user_reference/01_installation_and_quickstart.md  ← Setup guide
user_reference/02_understanding_daaf.md            ← How it works
user_reference/03_best_practices.md                ← Tips for quality
```

### Folder You Can Ignore (For Now)
```
agent_reference/    ← Internal protocols (for framework developers)
.claude/            ← Configuration (don't modify unless extending)
```

### Important Files
```
CLAUDE.md           ← The master instructions (read if curious)
agents/README.md    ← How the specialist agents work
research/           ← Example project to study
```

### Common Commands
```
# Start a new analysis
"Analyze [topic] using [dataset] from [years]"

# Explore what data exists
"What IPEDS variables are available for financial aid analysis?"

# Revise existing work
"Update the analysis to add controls for [variable]"

# Get help
"What datasets does DAAF have access to?"
```

---

## Glossary

| Term | Meaning |
|---|---|
| **Agent** | A specialist role Claude plays (executor, reviewer, planner, etc.) |
| **Skill** | A knowledge pack Claude references (dataset codebooks, library guides) |
| **Stage** | A numbered step in the workflow (1-12) |
| **Phase** | A group of related stages (5 phases total) |
| **Observable Truth** | A testable hypothesis the analysis must address |
| **IAT** | Inline Audit Trail — detailed code comments |
| **CP1-CP4** | Validation Checkpoints at each pipeline stage |
| **Marimo** | An interactive Python notebook format (like Jupyter but better for reproducibility) |
| **Polars** | A fast DataFrame library (like pandas but faster) |
| **plotnine** | Python's ggplot2 equivalent |
| **pyfixest** | Fixed effects estimation (Python equivalent of Stata's reghdfe) |
| **IPEDS** | Integrated Postsecondary Education Data System |

---

*Tutorial created for economists and data scientists new to DAAF and Claude Code.*
*To get started: open the `daaf/` folder in VS Code and ask your first research question.*
