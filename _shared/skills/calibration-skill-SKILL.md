---
name: calibration-skill
description: Run theory-first benchmark calibration searches with broad-to-local continuation, survivor triage, and cluster auto-upload. Use for Hamilton or other HPC benchmark searches where exact early target fit is a mistake and comparative statics should guide each new box.
workflow_stage: calibration
compatibility:
  - claude-code
  - codex
  - cursor
  - gemini-cli
author: Dave AI workspace
version: 1.1.0
user_invocable: true
tags:
  - calibration
  - benchmark
  - cluster
  - hpc
  - comparative-statics
  - automation
---

# Calibration Skill

## Purpose

This skill is for computational economics benchmark searches that run on a cluster and can easily get stuck if the search is too local or the targets are treated too strictly too early.

The core rule is:

**Do not auto-upload a new calibration batch until you have done a theory checkpoint on what the previous batch implies.**

And:

**If a batch times out in a promising economic region, treat that as a solver/refinement problem, not as a dead region.**

This skill exists to stop the common failure mode:
- tiny local tweaks around the old benchmark
- strict early rejection on noisy targets
- repeated uploads with no economic diagnosis of what the model is actually doing


## When to Use

- Recalibrating a quantitative macro / search / entrepreneurship model on Hamilton or another cluster
- Replacing an old benchmark after changing empirical inputs
- Running a benchmark search where some moments are noisy, definition-sensitive, or model-specific
- Continuing a search after failed batches and needing a more disciplined controller than `submit -> wait -> rerun`


## Non-Negotiable Operating Rules

### 1. Separate target types before searching

Every object must be classified as one of:

- **Anchor target**
  Used early. Central to the benchmark identity.
- **Loose target**
  Informative, but noisy or definition-sensitive. Used as a broad band, not an exact fit.
- **Plausibility diagnostic**
  Important for economic sanity, but too downstream to kill first-pass candidates.

Default benchmark-search architecture:

- first-pass anchors: core composition margins like entrepreneur share and self-employment share
- first-pass loose targets: scale objects that are partly model constructs, like `avg_n`
- first-pass plausibility diagnostics: output, taxes, welfare objects, downstream equilibrium aggregates

If the search is failing, do **not** automatically make every target looser. First decide whether the model is in the wrong economic region.


### 2. Do a comparative-statics checkpoint before every new upload

Before submitting a new box, write down:

1. What changed in the environment?
2. Which margins should move in theory?
3. Which parameters should offset that movement?
4. Which directions would count as obviously wrong?

The point is not to prove the full model analytically. The point is to force an explicit directional argument.

Example pattern:

- If updated education shares and wage premia make wage work more attractive, then entrepreneurship may need:
  - materially higher entrepreneurial productivity / selection terms
  - lower outside-option strength
  - lower hiring or operating costs
- Therefore a new search should try:
  - higher `x_shift`
  - lower `bar_m`
  - lower `f_hire`
  - lower `kappa` if active

Do **not** expect `0.002`-type local perturbations to reveal the right region if theory says the environment shifted materially.


### 3. Use three cycle verdicts, not two

Every finished cycle must be classified as:

- **dead**
  True collapse, nonsense equilibrium, or obviously wrong region
- **survivor**
  Not a benchmark yet, but economically sane enough to refine locally
- **usable**
  Broad candidate worth stopping on and inspecting closely

Bad workflow:
- `usable` vs `fail`

Good workflow:
- `dead`
- `survivor`
- `usable`


### 4. Only hard-reject collapse regions

A row should be `dead` only when it is genuinely collapse-like or implausible.

Typical dead signals:
- entrepreneurship share near zero
- output collapse
- terminal residual still very large
- bizarre tax or scale objects

Typical survivor signals:
- moments are still off, but not collapsed
- residual is still moderate, not explosive
- the candidate suggests a direction for local tinkering

If a row is merely “not good enough yet,” it is a survivor, not a failure.


### 5. Broad first, local second

The search pattern should be:

1. Theory-first broad preset box
2. Finished-cycle assessment
3. Local refinement around survivors
4. Tightened screening only after sane regions exist

Do **not** narrow around the old benchmark basin before the model has shown any sign of life in the new environment.


## Recommended Workflow

### Step 1: Read project context

Read:
- `STATUS.md`
- `README.md`
- `memory.md`

Identify:
- current active benchmark
- recent failed regions
- known parameter hooks
- previous false positives


### Step 2: Build the target map

Write a short target map with three buckets:

- anchor targets
- loose targets
- plausibility diagnostics

If a quantity is definition-sensitive or partly a model object, default it to **loose**, not anchor.


### Step 3: Write the theory note for the next box

For each changed environment object:
- state the expected sign on core margins
- note ambiguities explicitly
- translate the economics into search directions

Minimum output:
- `what changed`
- `expected sign`
- `offset parameters`
- `wrong-region signals`


### Step 4: Submit a broad preset box

Build the box from theory, not from convenience.

Good broad preset design:
- a few economically distinct regions
- material parameter movement
- no fake precision

Bad broad preset design:
- tiny nudges around an old seed
- many decimals with no economic meaning
- tight early output or tax gating


### Step 5: Assess the finished batch

For each cycle:
- sort rows by a broad objective
- classify rows as `dead`, `survivor`, or `usable`
- record the best row
- record the economic diagnosis of the region

The assessment must answer:
- was the whole region dead?
- were there survivors?
- if survivors exist, what parameter direction do they point toward?

Timed-out rows with meaningful diagnostics are not automatically `incomplete`.

- If the row timed out but clearly reached a non-collapse economic region, classify it as a **survivor with solver bottleneck**
- The next upload should then combine:
  - economic refinement of the box
  - gentler solver steps
  - more iteration budget / walltime


### Step 6: Auto-continue, but only with reasoning

Auto-upload is allowed only under these rules:

- If `usable` exists:
  - stop and inspect
- If survivors exist:
  - refine locally around the best survivor(s)
- If the whole region is dead:
  - move to the next broad preset

Every auto-upload should carry a short written note:

- what changed in the previous cycle
- which margins improved or overshot
- which parameters are being moved next and why
- whether the bottleneck is economics or solver budget

The auto-uploader should carry forward:
- the verdict
- the best row
- the diagnosis
- the next search logic

If the controller cannot explain *why* it is uploading the next box, it should not upload it.


### Step 7: Update project records

After any substantive cycle:
- update `STATUS.md`
- update `memory.md`
- record the live pointer or agent root
- record whether auto-continuation is active or intentionally paused


## Concrete Design Pattern

Use this as the default benchmark-search control logic:

1. **Broad preset cycle**
   theory-chosen box
2. **Assessment**
   dead / survivor / usable
3. **Refinement cycle**
   generated only if survivors exist
4. **Broader fallback**
   used only if the whole previous cycle was dead

The refinement cycle should inherit the economic diagnosis:

- low entrepreneurship:
  - raise entrepreneurial selection/productivity terms
  - lower outside-option strength
  - lower hiring costs
- too much entrepreneurship:
  - reverse those directions
- low scale:
  - keep the entrepreneurial margin attractive while easing firm expansion


## What This Skill Is Trying to Prevent

- endless local grids around the wrong basin
- strict early failure on noisy targets
- confusing output collapse with mere target miss
- repeated uploads without a comparative-statics explanation
- treating a cluster controller as if it were an economist


## Deliverables

A good use of this skill should leave behind:

- a reproducible controller or upload script
- a written theory note for the active box
- calibration notes recording why the next box is moving the way it is
- a cycle report with `dead / survivor / usable`
- updated `STATUS.md` and `memory.md`


## NEC Example

For the Necessity Entrepreneurs project, the relevant example is:

- updated education shares and wage premia may strengthen worker outside options
- therefore the first broad search after those updates should not stay too close to the old benchmark
- the first theory-guided directions to test are:
  - higher `x_shift`
  - lower `bar_m`
  - lower `f_hire`
  - lower `kappa`

In that project, early entrepreneur-share collapse is a wrong-region signal, not evidence that the target should be dropped immediately.
