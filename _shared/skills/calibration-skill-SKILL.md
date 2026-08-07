---
name: calibration-skill
description: Run theory-first quantitative-model calibration searches with broad-to-local continuation, survivor triage, and controlled cluster submission. Use for Hamilton or other HPC searches where strict early target fit, tiny local grids, or automatic resubmission could hide the economically relevant parameter region.
---

# Calibration Skill

Use theory to choose search regions and use computation to learn whether those regions are viable. Do not upload or auto-continue a batch until the previous evidence has an explicit economic diagnosis.

## Establish authority and limits

Read the live `STATUS.md` first for a tracked project, then the stable `README.md`; read `memory.md` only for durable paths, conventions, or past decisions that are relevant. Inspect the current calibration code, target definitions, controller, recent cycle outputs, and cluster instructions before planning another run.

Before remote submission, confirm:

| Control | Required decision |
|---|---|
| Authorization | Whether submission and automatic continuation are in scope |
| Compute ceiling | Maximum jobs, cores, walltime, cycles, and concurrent batches |
| Storage ceiling | Scratch and retained-output limits plus cleanup behavior |
| Stop time | User deadline or monitoring horizon |
| Failure boundary | Conditions that stop continuation and require review |
| Live target | Cluster, account, partition, project path, and active branch or commit |

Do not infer permission to submit, cancel, delete, or auto-continue from permission to edit code. Keep a dry-run or local planning path available when remote authority is absent.

## Classify calibration objects

Separate objects before searching:

- **Anchor target:** central to the calibrated model and sufficiently well measured to guide early search.
- **Loose target:** informative but noisy, definition-sensitive, or partly model-constructed; use a defensible band rather than fake precision.
- **Plausibility diagnostic:** important for economic sanity but too downstream to reject first-pass candidates by itself.

Record a target map:

| Object | Type | Empirical definition and source | Model counterpart | Tolerance or role | Caveat |
|---|---|---|---|---|---|

Do not silently loosen all targets when a search fails. First determine whether the model is in the wrong economic region, the target mapping is wrong, or the solver is failing.

## Write the theory checkpoint

Before every new box, record:

| Changed object | Predicted effect on key margins | Parameters that can offset or reinforce it | Ambiguity | Wrong-region signal |
|---|---|---|---|---|

Translate comparative statics into economically material parameter directions. Use the live model equations and implementation hooks; do not borrow project-specific signs or parameter roles from another model. If theory is ambiguous, design the box to distinguish mechanisms rather than pretending to know the sign.

## Search broad, then local

1. Construct a small number of economically distinct broad regions from the theory checkpoint.
2. Avoid excessive decimal precision and tiny perturbations around an inherited calibration when the environment changed materially.
3. Screen first on anchors and collapse diagnostics; retain loose targets and plausibility objects in the cycle report.
4. Refine locally only around candidates that are economically sane.
5. Tighten tolerances only after the search has found viable regions.

Keep parameter transformations, bounds, seeds, grids or sampling rules, solver settings, and code commit reproducible.

## Classify each cycle

Use three verdicts:

- **dead:** true collapse, invalid equilibrium, explosive residuals, or an economically incoherent region;
- **survivor:** not yet an acceptable calibration but sufficiently sane to teach the next local search;
- **usable:** broad candidate worth stopping on for close verification.

A target miss is not automatically dead. A timed-out row is not automatically incomplete: if it reached a non-collapse region with useful diagnostics, classify it as a survivor with a solver bottleneck. Conversely, a solver convergence flag does not make an economically nonsensical row viable.

## Diagnose the bottleneck

For every completed or timed-out batch, distinguish:

- wrong economic region;
- target-definition or model-mapping problem;
- numerical convergence or conditioning problem;
- insufficient iteration budget or walltime;
- controller, upload, or output-collection failure.

Use residual paths, terminal diagnostics, resource use, and moment movements to support the diagnosis. When a promising region times out, combine economic refinement with justified solver or resource changes; do not discard it solely because of the timeout.

## Gate continuation

Continue only when authorization and resource ceilings remain valid:

- if a usable candidate exists, stop automatic submission and inspect it;
- if survivors exist, refine around the best economically distinct survivors;
- if the region is dead, move to the next theory-backed broad region;
- if the diagnosis is unclear, pause rather than generating another box mechanically;
- if any stop condition or ceiling is reached, stop and report it.

Every submitted cycle must carry a short continuation note stating what changed, which margins improved or overshot, what moves next and why, and whether the current bottleneck is economic, numerical, or operational.

## Produce a cycle report

Record at least:

| Field | Content |
|---|---|
| Run identity | Timestamp, code commit, controller version, cluster job IDs |
| Search definition | Parameter bounds or draws, targets, tolerances, seeds, and solver limits |
| Resource use | Jobs, walltime, failures, timeouts, and retained output size |
| Best evidence | Best rows, full target and diagnostic values, and residuals |
| Verdict | Dead, survivor, or usable with reasons |
| Diagnosis | Economic, mapping, solver, resource, or operational bottleneck |
| Next action | Stop, inspect, refine locally, broaden, or repair |

Update `STATUS.md` with the live state, blockers, decisions, and next tasks. Update `memory.md` only when a durable path, convention, or author decision changed; do not turn it into a session log.

## Verification and handoff

For a usable candidate, rerun or otherwise verify reproducibility, check all equilibrium residuals and constraints, compare code and paper definitions, inspect unsupported or contradictory moments, and preserve the exact configuration needed to reproduce it.

Leave behind the controller or submission script, theory checkpoint, target map, cycle report, canonical result pointers, resource usage, and a clear statement of what remains unproven. Never invent moment values, empirical targets, parameter directions, job status, or convergence evidence.
