# 01 Project overview

Last updated: 2026-02-25
Status: living document (update in place)

## Project intention
The project studies whether scalable learning-by-viewing technologies (video-first instruction, recorded demonstrations, and hybrid guided media) causally raise skill acquisition, reduce learning costs, and change distributional outcomes across learners and task types.

## Why this project matters
- Instructional technology diffusion has outpaced evidence on which tasks benefit most.
- Average treatment effects hide meaningful heterogeneity by task procedural intensity, safety risk, and prerequisite structure.
- Policy and institutional decisions (content investment, broadband, tutoring complements, platform standards) need causal and mechanism evidence.

## Aims
1. Estimate causal impacts of video-based instructional access on measurable skill outcomes.
2. Identify mechanism channels: procedural transfer, precision gains, reduced error variance, and complementarity with practice.
3. Build a tractable theory stack linking task attributes, modality choice, and dynamic skill accumulation.
4. Provide decision-useful empirical guidance for institutions, platforms, and policy.

## Scope
### In scope
- Training/education settings with repeated learner-task outcomes.
- Explicit task decomposition (procedural vs conceptual; low-risk vs high-risk).
- Causal and quasi-experimental designs with transparent assumptions.
- Structural or semi-structural extensions only after baseline reduced-form credibility is established.

### Out of scope (phase 1)
- Full general-equilibrium welfare claims without validated first-stage evidence.
- Claims based solely on engagement metrics without skill outcomes.
- Domains where treatment timing/exposure cannot be credibly measured.

## Core research questions
1. Does video access improve outcomes on procedural tasks more than conceptual tasks?
2. Are gains concentrated among lower-baseline learners, or do they reinforce existing skill gaps?
3. Is learning-by-viewing a substitute or complement for tutoring and supervised practice?
4. Do effects operate through mean improvement, variance compression, or both?
5. How persistent are gains under depreciation and task switching?

## Working hypotheses
- H1: Video access yields larger gains for high-procedural tasks than low-procedural tasks.
- H2: Gains increase with demonstrability and prerequisite clarity.
- H3: Effects are larger when practice opportunities are immediate.
- H4: Video and tutoring are complements for high-risk tasks, substitutes for low-risk repetitive tasks.
- H5: Quality heterogeneity in content explains a large share of between-context variation.

## Key definitions
- Learning by viewing: skill accumulation from visual demonstration channels, distinct from text-only or lecture-only modes.
- Procedural task: a task where sequence execution and motor/cognitive workflow dominate conceptual exposition.
- Demonstrability: the extent to which a task can be faithfully conveyed through video representation.
- Effective exposure: treatment-relevant access weighted by bandwidth, completion, and content quality.

## Planned outputs
### Output A: Baseline empirical paper
- Main DDD design around video-access shock x task procedurality.
- Event-study and falsification suite.
- Transparent reporting of effect heterogeneity and robustness.

### Output B: Theory note
- Task-modality assignment and dynamic learning framework.
- Model variants mapped to empirical moments.

### Output C: Data and measurement appendix
- Source catalog, access route, variable construction, and audit checks.

### Output D: Replication-ready workflow
- Reproducible data prep and estimation scripts.
- Assumption checklist and diagnostics log.

## Design lock decisions (must resolve soon)
1. Primary domain (institutional training vs certification vs platform-native modules).
2. Geographic scope and period.
3. Public-data-only baseline vs partner-data baseline.
4. Minimum acceptable outcome set (score, pass, retention, error-based metrics).

## Risks and mitigation
- Risk: Treatment is confounded with curriculum reform.
  - Mitigation: policy/event controls, unit-specific trends, placebo cohorts.
- Risk: Exposure is noisy.
  - Mitigation: multiple treatment definitions; first-stage validation.
- Risk: Domain choice creates limited external validity.
  - Mitigation: explicit scope statement and parallel backup design.

## Current working roadmap
### Near-term (2-4 weeks)
- Lock primary and backup empirical designs.
- Finalize data inventory with feasibility tags.
- Produce baseline power and identification memo.

### Mid-term (1-2 months)
- Execute baseline estimates and heterogeneity map.
- Build mechanism tests (variance compression, precision channels).
- Draft theory-to-evidence alignment section.

### Later
- Expand into structural calibration/estimation if reduced-form evidence is stable.

## TODO
- Finalize domain ranking with hard feasibility criteria.
- Define treatment intensity metric and robustness alternatives.
- Lock minimal outcome dashboard for baseline results table.

## Open questions
- Which context offers the cleanest treatment timing with scalable external relevance?
- Should the first paper prioritize internal validity over cross-domain portability?
- What quality metric is feasible at scale for content heterogeneity?
