# Ranked Shortlist: Models and Empirical Designs

Date: 2026-02-24
Project: Learning by Viewing

## Why this shortlist

This note ranks the strongest ideas from the kickoff pack using three criteria:
1. Identification credibility for an empirical economics paper.
2. Data feasibility in a first paper timeline.
3. Direct connection to the core mechanism: video demonstration improves procedural learning.

The goal is to reduce the menu into a practical first-paper stack: one lead empirical design, one backup empirical design, one primary model, and one mechanism-extension model.

## A. Ranked model ideas (top 5)

### 1) Learning curve with mode-specific slope (Rank 1)

This is the best baseline model because it is simple, intuitive, and directly maps to observed learning trajectories. In this setup, skill increases with cumulative practice, but the slope and/or intercept of the learning curve differs by modality (video vs text vs no instruction). The core claim is that viewing improves early-stage technique, so learners move onto a steeper part of the curve faster.

The model is strong because it produces exactly the testable patterns we care about: large treatment effects among novices, smaller marginal gains at higher experience, and stronger effects in highly procedural tasks. It also gives a clean way to test complementarity between viewing and doing: the treatment should be strongest when practice immediately follows viewing.

Empirically, this model maps well to panel outcomes with repeated attempts, module progression, pass probabilities over time, or error-rate declines. For a first paper, this should be the primary theory framework because it gives high-value predictions without heavy structural burden.

### 2) Bayesian signal extraction / precision model (Rank 2)

In this model, learners receive noisy signals about the correct way to perform a task. Video raises signal precision by showing timing, movement, and sequencing that text often cannot encode well. The learner updates beliefs and adjusts technique over attempts.

This model is attractive because it micro-founds why video works better for tacit skills: it reduces uncertainty about the correct action. It also naturally produces heterogeneity predictions. Learners with low prior knowledge should benefit more from precision gains, and tasks with high ambiguity should show larger effects.

Data mapping is straightforward if we can observe attempts and errors (for example in coding exercises, graded practical modules, or sequential task logs). We can operationalize precision improvements as lower variance in outcomes, faster convergence, and fewer repeated errors of the same type.

### 3) Search-and-match model (learner-instructor fit) (Rank 3)

This model captures platform scale as a mechanism: learners choose among many instructors and formats, and better matching improves outcomes. Unlike pure "more information" stories, this model emphasizes heterogeneity in pedagogy preferences, language, pace, and prior skill.

It is particularly useful for policy-relevant welfare questions because it predicts larger gains where local offline options are poor. That gives a strong distributional angle: remote areas and constrained learners should gain more when platform variety expands.

Empirically, the model requires exposure and matching proxies (language, content style, difficulty tier, instructor characteristics) plus outcomes. This is slightly harder than the top two models, so it is best as the first extension once baseline causal effects are established.

### 4) Dynamic continue/quit model (persistence margin) (Rank 4)

This model treats learning as a sequence of participation decisions under uncertainty: continue practicing or quit. Video raises expected return to continuing by improving early success probability and reducing discouragement from failed attempts.

Its major value is that it targets a margin many studies miss: persistence. Even if final mastery effects are delayed, reduced dropout is an immediate and policy-relevant channel. This is especially relevant in online and self-directed settings where attrition is high.

It maps directly to completion, retention, session continuation, and module dropout outcomes. This model works well paired with the learning-curve model: one captures skill progression conditional on continuing, the other captures selection into continued effort.

### 5) Injury-risk tradeoff model (for DIY/safety domain) (Rank 5)

This model is not ideal as the core framework for the whole paper, but it is very useful if DIY is the empirical domain. It formalizes the key ambiguity: video can reduce per-attempt risk via better technique while also increasing total attempts, which may raise aggregate accidents.

This framing prevents incorrect welfare interpretation from raw injury counts alone. It forces denominator logic: per-attempt risk, not just total incidents. That is essential for credible policy conclusions in a safety context.

This should be treated as a targeted extension model attached to a DIY empirical design, not the main baseline model for the overall project.

## B. Ranked empirical designs (top 5)

### 1) Skill-task heterogeneity triple-difference (DDD) in institutional data (Rank 1)

This is the strongest first-paper design if we can access panel outcomes where the same learners face both procedural/visual and text-heavy tasks. The treatment variation comes from a video-access change (policy, platform rollout, curricular shift), and identification comes from differential response across task types over time.

Why this ranks first: it directly tests the central mechanism rather than only reduced-form internet effects. If video truly improves demonstration-based learning, effects should be stronger in procedural tasks than conceptual text-dominant tasks. That is a hard-to-fake signature and a strong internal validity advantage.

Main threat is simultaneous curriculum or grading changes. Mitigation is module fixed effects, event-study checks, and placebo task categories where video should matter less. Feasibility is high in education or training settings with detailed module-level outcomes.

### 2) Broadband speed threshold DiD (Rank 2)

This is the cleanest broad access-shock design for external validity. Treatment is crossing a streaming-feasible quality threshold due to staggered infrastructure upgrades. Outcomes can include certification, practical test performance, or labor-market skill proxies.

The core strength is scale and transparency: clear treatment timing, large sample, and strong geographic variation. It can produce persuasive average treatment effects with good policy relevance.

Main threat is confounding local economic change correlated with upgrades. Mitigation requires area trends, rich controls, placebo outcomes, and pre-trend diagnostics. This is a strong primary design if institutional microdata are unavailable.

### 3) Randomized encouragement design in MOOCs/training platforms (Rank 3)

This is the highest internal-validity design: randomly encourage learners to consume demonstration video first (or more intensively), then measure downstream learning outcomes. ITT is clean; LATE can be estimated with take-up.

Its weakness is external validity and partnership dependence, but for mechanism testing it is excellent. It can directly isolate sequencing effects (view then do vs do then view), which closely matches the theory predictions in the model shortlist.

This design is best as a second paper or companion design if a partner is available. It may not be the fastest first-paper path, but it is the strongest causal micro-foundation for the mechanism.

### 4) DIY/COVID with exposure intensity x broadband (Rank 4)

This design uses pandemic-era shifts in at-home activity as a context where demand for self-learning spiked. Treatment intensity is measured with DIY tutorial exposure proxies interacted with broadband capacity. Outcomes include completion proxies, service substitution, and safety events.

It ranks below the top three because identification is harder: COVID introduced many concurrent shocks. Still, it remains promising due to rich variation and high policy relevance, especially for welfare tradeoffs.

This design is viable if we explicitly separate attempt volume from per-attempt risk and include strong controls for lockdown intensity, supply-chain constraints, and healthcare-seeking changes. Without that, interpretation is fragile.

### 5) Content supply shock by language (shift-share style) (Rank 5)

This design exploits rapid changes in tutorial availability across language-topic cells, interacted with pre-period local language shares. It is attractive for mechanism identification because it captures "better matching" and accessibility, not just generic internet access.

Its benefit is conceptual fit with the search-and-match model and equity questions: language expansion should disproportionately benefit learners previously underserved by available content.

The main challenge is endogeneity of content supply growth. It needs a credible creator-side instrument or clear exogenous source-side event. This is a high-upside but medium-risk design, best as a strong robustness or extension.

## C. Recommended first-paper stack

Primary empirical design:
- Skill-task heterogeneity DDD (Rank 1 empirical)

Backup empirical design:
- Broadband threshold DiD (Rank 2 empirical)

Primary model:
- Learning curve with mode-specific slope (Rank 1 model)

Mechanism extension model:
- Bayesian precision model (Rank 2 model)

Domain recommendation:
- Coding/certification or structured training environments for first pass, because outcome measurement and denominator logic are cleaner than DIY safety data.

## D. Concrete next implementation steps

1. In `Notes/empirical/03_design_memo_v1.md`, rewrite the baseline design as the DDD framework, with explicit unit, treatment, and equation.
2. In `Notes/empirical/02_data_inventory.md`, add two data blocks only: one for DDD-ready institutional panel data and one for broadband DiD backup.
3. Build a one-page assumptions checklist for the DDD design:
   - no differential pre-trends by task type
   - stable module composition
   - no concurrent grading rule change that differentially affects procedural tasks
4. Keep DIY/COVID as a secondary application unless denominator-quality data are secured.
