# Learning by Viewing  Kickoff Pack

## 1. Project overview

Core question: does scalable video demonstration (for example YouTube tutorials) causally raise skill acquisition relative to learning by doing alone, text/diagram instruction, or in-person help, and for whom?

Primary research questions:
1. Does greater access to instructional video increase the probability and speed of mastering procedural skills?
2. Are gains larger for tacit/visual tasks (motor sequence, timing, technique) than for declarative tasks?
3. Does video access reduce or increase skill inequality across income, baseline education, age, and geography?
4. Do platform dynamics (ranking, creator competition, recommendation systems) accelerate diffusion of best practice?
5. Are there welfare offsets (injury risk, low-quality misinformation, overconfidence)?

Scope and positioning:
- Main paper should be empirical microeconomics with transparent quasi-experimental identification.
- Theory should be lightweight and prediction-generating, not heavy structural at kickoff stage.
- Extension: interactive human/AI guidance as an additional treatment arm after core video result is established.

High-level empirical strategy shortlist:
- Access shocks: broadband rollout/quality jumps, mobile data price shocks, platform outages/blocks.
- Content-supply shocks: exogenous changes in tutorial availability by language/topic.
- Differential exposure designs: task-level heterogeneity (visual vs non-visual skills) in DiD/event-study frameworks.
- Instrumental variables: predicted exposure from pre-period local internet quality x global tutorial growth.
- Panel individual/course/workplace data where skill outcomes are observed repeatedly.

Expected contribution:
- A causal estimate of learning-by-viewing effectiveness.
- Mechanism decomposition: information quality, search/match, repetition, and motivation/accountability channels.
- Distributional and welfare accounting, including externalities from platform-mediated skill diffusion.

## 2. Mechanisms and testable hypotheses

Main hypotheses:
1. H1 (effectiveness): Access to high-quality instructional video raises skill acquisition rates and lowers time-to-mastery.
2. H2 (task heterogeneity): Effects are stronger for procedural/tacit/kinesthetic tasks than for text-dominant conceptual tasks.
3. H3 (distribution): Video access weakly equalizes skill acquisition for liquidity-constrained learners but may widen gaps if algorithmic curation favors high-skill users.
4. H4 (quality dispersion): Gains are increasing in instructor clarity and production quality; noisy content can attenuate or reverse effects.
5. H5 (complementarity): Video and doing are complements; the largest gains occur when video is paired with immediate practice.

Key mechanisms/channels (testable):
1. Demonstration fidelity channel: moving visuals encode timing, posture, grip, sequencing, and error correction better than static text.
2. Search and match channel: platform scale lets learners match to preferred teaching style, language, and difficulty.
3. Repetition and pacing channel: pause/rewind/slow-motion reduces cognitive load and enables personalized pacing.
4. Quality competition channel: creators compete for engagement; good pedagogical formats diffuse quickly.
5. Social proof/motivation channel: comments, communities, and visible progress increase persistence.
6. Risk channel: low-quality or overconfident learning may raise failed attempts, material waste, or injuries.

Welfare implications (expected):
- Likely winners: remote learners, low-income households, self-directed learners, workers reskilling outside formal institutions.
- Potential losers: incumbents relying on information scarcity rents, local low-quality training providers.
- Ambiguous groups: novices in high-risk physical tasks (possible productivity gain but injury risk).
- Aggregate effects: faster diffusion of productive techniques, potential increase in small-scale entrepreneurship, uncertain impact on wage dispersion.

Empirical predictions linked to mechanisms:
- Larger effects where tasks are highly visual and sequence-dependent.
- Larger effects where video quality and language match improve.
- Diminishing marginal returns to additional viewing minutes after threshold mastery.
- Stronger long-run persistence when viewing is combined with repeated practice episodes.

## 3. Modeling menu (34 options)

1. Static choice model (mode selection)
- Agents/choices/timing/state: learner chooses text vs video vs in-person in one period; state is baseline ability.
- Viewing does: raises success probability for visual tasks.
- Comp statics/predictions: higher video quality shifts demand from text/in-person; biggest shift for low baseline ability.
- Data mapping: modality usage logs, completion outcomes, pre-tests.

2. Two-period human capital model
- Agents/choices/timing/state: period 1 choose learning mode and effort; period 2 productivity realized.
- Viewing does: lowers learning cost and increases skill stock.
- Comp statics/predictions: video access raises investment especially for time-constrained workers.
- Data mapping: time-use, earnings/productivity outcomes, platform usage.

3. Bayesian signal extraction
- Agents/choices/timing/state: learner receives noisy signals about correct technique.
- Viewing does: improves signal precision.
- Comp statics/predictions: higher precision reduces trial-error variance; faster convergence.
- Data mapping: repeated attempts, error rates over time, content quality proxies.

4. Learning curve with mode-specific slope
- Agents/choices/timing/state: cumulative practice determines skill via learning curve.
- Viewing does: steepens slope early by improving initial technique.
- Comp statics/predictions: largest gains at low experience; convergence later.
- Data mapping: panel performance trajectories, watch-time before practice.

5. Dynamic discrete choice (continue/quit)
- Agents/choices/timing/state: each period learner decides continue practicing or quit.
- Viewing does: increases expected reward via higher success odds.
- Comp statics/predictions: lower dropout under video access.
- Data mapping: course/tutorial sequence completion and abandonment.

6. Search-and-match between learner and instructor
- Agents/choices/timing/state: learner searches among instructors; match quality state evolves.
- Viewing does: enlarges market and improves match probability.
- Comp statics/predictions: gains highest where local offline options are poor.
- Data mapping: recommendation click paths, language/accent match, outcomes.

7. Queue model for in-person tutoring substitute
- Agents/choices/timing/state: learners choose waiting for tutor vs immediate video.
- Viewing does: near-zero wait time.
- Comp statics/predictions: bigger effects when tutor scarcity is high.
- Data mapping: tutoring waitlists, office-hour congestion, platform usage.

8. Time allocation model
- Agents/choices/timing/state: fixed time budget across work, leisure, learning.
- Viewing does: reduces setup/search time per learning unit.
- Comp statics/predictions: total learning rises more for high-opportunity-cost individuals.
- Data mapping: time diaries, viewing sessions, practice minutes.

9. Household production model (DIY)
- Agents/choices/timing/state: household chooses outsource vs DIY production.
- Viewing does: raises DIY productivity.
- Comp statics/predictions: outsource demand falls after video access shock.
- Data mapping: spending substitution patterns, DIY purchases, service usage.

10. Multi-task portfolio model
- Agents/choices/timing/state: learner chooses which skills to attempt.
- Viewing does: lowers fixed cost of entering new skill domains.
- Comp statics/predictions: broader skill portfolios, more experimentation.
- Data mapping: category-level tutorial consumption and multi-skill outcomes.

11. Threshold mastery model
- Agents/choices/timing/state: skill requires crossing threshold competence.
- Viewing does: shifts ability distribution right.
- Comp statics/predictions: mass at pass threshold increases.
- Data mapping: pass/fail exams, certification cutoffs.

12. Production-function augmentation
- Agents/choices/timing/state: output depends on labor quality and tool use.
- Viewing does: augments effective human capital parameter.
- Comp statics/predictions: marginal product gains larger with complementary capital.
- Data mapping: worker output, tool adoption, viewing intensity.

13. Directed technical change in pedagogy
- Agents/choices/timing/state: creators choose pedagogy format given audience demand.
- Viewing does: enables scalable pedagogical innovation.
- Comp statics/predictions: high-demand topics improve teaching quality faster.
- Data mapping: tutorial format trends, engagement metrics, learning outcomes.

14. Social learning network model
- Agents/choices/timing/state: peers share successful content links.
- Viewing does: lowers transmission cost of know-how.
- Comp statics/predictions: network centrality amplifies treatment.
- Data mapping: referral links, social graph proxies, outcomes.

15. Epidemic diffusion model of techniques
- Agents/choices/timing/state: practices spread with contact and adoption rates.
- Viewing does: increases contact rate globally.
- Comp statics/predictions: faster diffusion and shorter half-life of inferior techniques.
- Data mapping: adoption timing across regions, trend-break tests.

16. Rational inattention model
- Agents/choices/timing/state: attention budget allocated across content.
- Viewing does: richer cues reduce attention needed for comprehension.
- Comp statics/predictions: higher returns for low-attention-constrained users.
- Data mapping: watch completion, playback speed, quiz scores.

17. Cognitive load model
- Agents/choices/timing/state: working-memory constraints during learning.
- Viewing does: chunked demonstrations lower intrinsic load for procedural tasks.
- Comp statics/predictions: stronger effect on complex multi-step tasks.
- Data mapping: task complexity indices, error decomposition.

18. Trial-and-error hazard model
- Agents/choices/timing/state: hazard of successful completion per attempt.
- Viewing does: increases baseline hazard.
- Comp statics/predictions: fewer failed attempts before success.
- Data mapping: attempt logs, completion timestamps.

19. Injury-risk tradeoff model
- Agents/choices/timing/state: learner chooses effort/attempt intensity under accident risk.
- Viewing does: can reduce risk via safer technique or raise risk via overconfidence.
- Comp statics/predictions: sign depends on content quality and task hazard.
- Data mapping: injury claims/ER records, tutorial quality proxies.

20. Principal-agent workplace training model
- Agents/choices/timing/state: firm chooses training modality for workers.
- Viewing does: lowers per-worker training cost.
- Comp statics/predictions: greater training scale in SMEs.
- Data mapping: firm training spend, productivity, platform subscriptions.

21. Education production model
- Agents/choices/timing/state: school combines teacher time and digital materials.
- Viewing does: substitutes for lecture repetition, complements coaching.
- Comp statics/predictions: teacher time reallocated to high-value feedback.
- Data mapping: classroom outcomes, LMS video logs, teacher time-use.

22. Experience-good quality model
- Agents/choices/timing/state: learner uncertain about tutorial quality pre-click.
- Viewing does: platform ratings reduce uncertainty.
- Comp statics/predictions: better ranking increases average learning gain.
- Data mapping: rating/ranking data and downstream performance.

23. Vertical differentiation model (free vs premium courses)
- Agents/choices/timing/state: learners choose quality tier under budget constraints.
- Viewing does: free high-quality video compresses quality-price gradient.
- Comp statics/predictions: consumer surplus gains strongest for low-income learners.
- Data mapping: course pricing, uptake by income bins, outcomes.

24. Local public good model of knowledge externalities
- Agents/choices/timing/state: one learner’s skill creates spillovers (helping peers).
- Viewing does: increases initial learners and spillover stock.
- Comp statics/predictions: multiplier effects in dense communities.
- Data mapping: neighborhood adoption clusters and peer outcomes.

25. Sequential task model
- Agents/choices/timing/state: tasks require ordered subtasks.
- Viewing does: improves sequencing accuracy.
- Comp statics/predictions: largest effects in tasks with high penalty for wrong order.
- Data mapping: step-level process data, rework frequency.

26. Option value model of experimentation
- Agents/choices/timing/state: learner can sample tutorial before committing resources.
- Viewing does: lowers experimentation cost.
- Comp statics/predictions: more entry into uncertain high-return skills.
- Data mapping: trial views, subsequent enrollment/purchases.

27. Career switching model
- Agents/choices/timing/state: worker chooses stay/switch occupation with retraining.
- Viewing does: lowers retraining fixed costs.
- Comp statics/predictions: increased mobility into skill-intensive occupations.
- Data mapping: occupational transitions, pre-switch viewing behavior.

28. Attention competition platform model
- Agents/choices/timing/state: platform allocates impressions across entertainment and tutorials.
- Viewing does: exposure depends on recommender objective.
- Comp statics/predictions: tutorial outcomes improve when educational content ranking weight rises.
- Data mapping: policy changes in recommendation systems and learning outcomes.

29. Geographic disparity model
- Agents/choices/timing/state: remote vs urban learners with different offline access.
- Viewing does: compresses geographic learning gaps.
- Comp statics/predictions: larger treatment in rural/low-service areas.
- Data mapping: region-level outcomes by broadband and local training density.

30. Language-friction model
- Agents/choices/timing/state: learners differ by language proficiency.
- Viewing does: subtitles/visual demonstration reduce language barrier.
- Comp statics/predictions: stronger gains for non-native readers in visual tasks.
- Data mapping: subtitle availability, language metadata, outcomes.

31. Algorithmic sorting model
- Agents/choices/timing/state: recommender sorts learners into content tracks by observed behavior.
- Viewing does: personalization can raise or lock in trajectory quality.
- Comp statics/predictions: early random exposure has persistent effects.
- Data mapping: first-video exposure variation and long-run performance.

32. Credibility and misinformation model
- Agents/choices/timing/state: learner chooses whether to trust tutorial signal.
- Viewing does: can raise persuasion independent of correctness.
- Comp statics/predictions: certification badges reduce harmful learning.
- Data mapping: misinformation flags, correction videos, safety outcomes.

33. Human + AI tutoring complement model
- Agents/choices/timing/state: learner chooses video only vs video + interactive help.
- Viewing does: baseline demonstration; AI/human resolves idiosyncratic questions.
- Comp statics/predictions: complementarity strongest for intermediate learners.
- Data mapping: chat/help usage layered on tutorial consumption.

34. General equilibrium skill supply model (reduced form)
- Agents/choices/timing/state: workers choose training; firms demand skills.
- Viewing does: shifts skill supply curve outward.
- Comp statics/predictions: wage premia for formerly scarce procedural skills compress over time.
- Data mapping: occupation-level wages, certification counts, platform penetration.

## 4. Literature map (what to search + why)

Bucket A. Economics of learning / skill acquisition / human capital
- Subtopics:
  - learning-by-doing and experience curves
  - observational learning/social learning
  - human capital investment under credit/time constraints
  - task-specific vs general skill formation
- Keywords to search:
  - "learning by doing economics", "observational learning productivity", "social learning skill acquisition", "experience curve worker performance", "procedural skill training economics"
- What we need:
  - canonical mechanisms for accumulation, heterogeneity, and dynamic returns
  - benchmark predictions to contrast with video-mediated learning
  - measurement conventions for skill outcomes and persistence

Bucket B. Economics of online platforms / information / media / edtech
- Subtopics:
  - platform content quality, ranking, and creator incentives
  - online education and digital training effectiveness
  - video vs text pedagogy in applied settings
  - digital divide and unequal returns to internet access
- Keywords to search:
  - "YouTube educational content economics", "online learning platform causal", "video instruction effectiveness", "edtech randomized trial economics", "platform recommendation educational outcomes"
- What we need:
  - evidence on content-supply and demand channels
  - design patterns for measuring exposure and quality
  - guidance on platform-mediated confounds (algorithm changes, selection)

Bucket C. Identification strategies used in related work
- Subtopics:
  - broadband rollout and speed shocks
  - internet outages/service disruptions
  - policy/platform access bans or unblocking events
  - staggered technology diffusion and event studies
- Keywords to search:
  - "broadband rollout difference-in-differences", "internet outage natural experiment education", "platform ban causal impact", "staggered adoption event study internet", "digital access instrument"
- What we need:
  - credible exogenous variation templates transferable to YouTube learning
  - threat diagnostics: pre-trends, spillovers, treatment mismeasurement
  - best-practice estimators for staggered treatment timing and heterogeneous effects

Note on references:
- This map is intentionally citation-light to avoid unverified citations at kickoff.
- Next step is to populate with verified papers only (DOI/journal working-paper links confirmed).

## 5. Empirical design brainstorm (10+)

1. Broadband speed threshold DiD
- Outcomes: certification pass rates, task completion, earnings in relevant occupations.
- Treatment/proxy: jump from low to high streaming-feasible speeds.
- ID: staggered DiD around infrastructure upgrades.
- Threats/mitigation: correlated local growth; include area trends, placebo outcomes, pre-trend tests.
- Feasibility: high if telecom/coverage data can be matched geographically.

2. Mobile data price shock IV
- Outcomes: tutorial watch-time, skill test scores.
- Treatment/proxy: effective price of streaming data.
- ID: IV using telecom tariff reforms.
- Threats/mitigation: concurrent telecom changes; control bundle features, provider fixed effects.
- Feasibility: medium.

3. YouTube outage event study
- Outcomes: short-run drops in learning activity/performance.
- Treatment/proxy: outage hours by region/time.
- ID: high-frequency event study.
- Threats/mitigation: outages not random; use surprise global outages with minute-level windows.
- Feasibility: medium-high for platform-level outcomes.

4. School/workplace firewall policy change
- Outcomes: course completion, practical assessment scores.
- Treatment/proxy: access blocked/unblocked to video platforms.
- ID: institutional DiD.
- Threats/mitigation: policy endogenous to performance; use sudden IT compliance rollouts.
- Feasibility: medium.

5. Content supply shock by language
- Outcomes: skill adoption among language groups.
- Treatment/proxy: rapid increase in tutorials for specific language-topic cells.
- ID: shift-share style exposure using pre-period language shares.
- Threats/mitigation: endogenous content growth; instrument with creator-side shocks.
- Feasibility: medium.

6. Recommender algorithm change
- Outcomes: educational watch share, downstream skill outcomes.
- Treatment/proxy: platform policy favoring/penalizing tutorial discoverability.
- ID: interrupted time series + differential exposure groups.
- Threats/mitigation: many simultaneous platform changes; narrow windows and unaffected control categories.
- Feasibility: low-medium due to data access.

7. Rural-first rollout synthetic control
- Outcomes: vocational enrollment, local entrepreneurship rates.
- Treatment/proxy: region-level video access expansion.
- ID: synthetic control for early-treated regions.
- Threats/mitigation: migration/compositional change; track population flows and robustness.
- Feasibility: medium.

8. Skill-task heterogeneity triple-difference
- Outcomes: performance in visual/procedural vs text-based modules.
- Treatment/proxy: same learners before/after video access change.
- ID: DDD across task types and time.
- Threats/mitigation: curriculum reform confounding; include module fixed effects.
- Feasibility: high with institutional data.

9. Randomized encouragement in MOOCs/training
- Outcomes: completion, assessment, retention.
- Treatment/proxy: nudges to watch demonstrations first.
- ID: RCT encouragement design.
- Threats/mitigation: noncompliance; estimate ITT and LATE.
- Feasibility: medium-high with platform partner.

10. Device capability RDD (video usability)
- Outcomes: adoption and mastery.
- Treatment/proxy: minimum hardware threshold for smooth playback.
- ID: RDD around device performance cutoff.
- Threats/mitigation: manipulation around cutoff; density tests and covariate balance.
- Feasibility: low-medium.

11. Historical internet backbone landing IV
- Outcomes: long-run skill supply and occupational shifts.
- Treatment/proxy: distance to backbone/cable nodes interacted with post period.
- ID: spatial IV.
- Threats/mitigation: urban confounding; granular controls and within-region comparisons.
- Feasibility: medium.

12. Cross-border platform ban/unban comparison
- Outcomes: skill-related search, course enrollments, practical outputs.
- Treatment/proxy: legal platform access status.
- ID: DiD/event study with neighboring-country controls.
- Threats/mitigation: policy endogeneity/political shocks; synthetic controls and placebo borders.
- Feasibility: medium.

13. Natural experiment from caption/subtitle auto-rollout
- Outcomes: learning outcomes among non-native language users.
- Treatment/proxy: subtitle availability change by language.
- ID: DiD by affected language groups.
- Threats/mitigation: simultaneous quality changes; include content fixed effects.
- Feasibility: medium.

14. Labor market validation design
- Outcomes: wages and job transitions in skills heavily taught via video.
- Treatment/proxy: local tutorial intensity x broadband access.
- ID: Bartik-style exposure with robustness battery.
- Threats/mitigation: weak instrument concerns; first-stage diagnostics and alternative shares.
- Feasibility: medium.

## 6. Deep-dive: DIY/COVID and safety/accidents angle

Causal story:
- Pandemic restrictions increased time at home and reduced access to in-person help.
- Households shifted toward DIY tasks and may have substituted into YouTube tutorials.
- Viewing could improve success and reduce errors, but higher attempt volume could increase total accidents even if per-attempt risk falls.

Outcome measures (at least 3):
1. DIY project completion proxies: home improvement purchase bundles consistent with finished projects.
2. Service substitution: decline in paid handyman/plumbing/electrical small-job demand.
3. Safety outcomes: emergency visits or injury claims coded to home repair/tool accidents.
4. Quality outcomes: return/refund rates for materials, repeat-purchase due to failed attempts.

YouTube exposure measures (at least 3):
1. Region-time tutorial view intensity for DIY categories.
2. Google Trends share for "how to" + specific home-repair terms.
3. Broadband-enabled streaming capacity interacted with pre-COVID DIY propensity.
4. Platform-side metadata: uploads/watch-time in relevant tutorial tags.

Identification strategies (at least 2):
1. DiD/event study around COVID lockdown timing x pre-existing broadband quality.
2. IV: predicted DIY-video exposure from pre-COVID internet speed x global growth in DIY tutorial supply.
3. Optional additional: discontinuities around reopening policies affecting opportunity cost of DIY.

Key confounds and mitigation:
- Confound: demand shock to home improvement from stay-at-home preferences.
  - Mitigation: compare highly visual DIY tasks vs non-visual home activities; include granular spending controls.
- Confound: supply-chain disruptions affecting materials and project mix.
  - Mitigation: product-category fixed effects, local stockout controls.
- Confound: stress/mental-health shocks affecting accidents.
  - Mitigation: control for general accident categories not tied to DIY.
- Confound: hospital avoidance during peak COVID affecting observed injuries.
  - Mitigation: use multiple safety datasets (ER, urgent care, insurance claims).

Feasibility verdict:
- Medium-high as a reduced-form design if data access exists for local injuries and spending.
- Strong caution: accident data is sign-ambiguous without denominator (attempt volume). Need per-attempt risk metrics where possible.

Better alternatives to strengthen this angle:
1. Focus on low-risk tasks (painting, furniture assembly) where completion quality can be observed.
2. Use retailer/app partner data with step-level project progression.
3. Embed household survey module asking first source of instruction (video/text/friend/professional).

## 7. Deep-dive: Metal music technicality angle

Causal story:
- YouTube diffuses advanced techniques (sweep picking, polyrhythms, production workflows) and allows repeated close observation.
- Global learners copy high-skill exemplars, potentially raising average technical complexity in metal output.
- Platform visibility may reward technically dense styles, reinforcing diffusion.

Outcome measures (at least 3):
1. Audio-derived technicality index: tempo variability, note density, rhythmic complexity, execution precision proxies.
2. Performance skill outcomes: audition success rates, conservatory/online exam outcomes for relevant techniques.
3. Production complexity: track layering, editing intensity, time signatures, solo complexity metadata.
4. Market response: listener retention or niche chart outcomes for high-technicality subgenres.

YouTube exposure measures (at least 3):
1. Region/cohort-level watch-time in metal tutorial categories.
2. Creator-side supply metrics for technique-specific tutorial uploads.
3. Search intensity for specific guitar/drum technique terms.
4. Platform recommendation exposure if obtainable (impressions to tutorial content).

Identification strategies (at least 2):
1. Shift-share: local pre-period metal interest interacted with global growth in metal tutorial supply.
2. Event study around exogenous access shocks (broadband upgrades/outages) in musician-heavy regions.
3. Instrument from language-specific tutorial expansion affecting non-English-speaking musician cohorts.

Key confounds and mitigation:
- Confound: independent evolution of genre taste toward complexity.
  - Mitigation: use comparison genres with similar demand trends but lower tutorial intensity.
- Confound: DAW/software improvements making complex production easier.
  - Mitigation: control for software diffusion and plugin release cycles.
- Confound: selection into music production by motivated high-ability users.
  - Mitigation: panel designs with pre-trends and individual fixed effects where possible.
- Confound: measurement error in technicality.
  - Mitigation: triangulate multiple indices plus expert-rated validation subsample.

Feasibility verdict:
- Low-medium for a flagship economics paper due to data construction burden and identification complexity.
- Valuable as a creative side project, not ideal as primary first paper design.

Better alternatives than metal (while preserving strong learning-by-viewing signal):
- Instrument learning broadly (guitar/piano/drums) with standardized graded exams.
- Coding/IT certification prep with objective pass rates.
- Home repair tasks with verified completion outcomes.

## 8. Alternative domains and best next steps

Thirty-five alternative skill domains likely more tractable than metal technicality, each with one empirical path:
1. Cooking basics: link local tutorial exposure to recipe success ratings/app repeat behavior.
2. Baking precision: use bakery-school exam scores by cohort vs regional video access.
3. Home painting: retailer sales bundles + complaint/return rates after access shocks.
4. Furniture assembly: platform video views vs customer support calls/returns by region.
5. Basic plumbing fixes: plumber callout rates for minor issues vs DIY tutorial intensity.
6. Electrical safety basics: incidence of minor electrical incidents vs certified tutorial penetration.
7. Bicycle repair: bike shop service demand for common fixes vs tutorial watch-time.
8. Car maintenance basics: oil-change service substitution in areas with improved streaming access.
9. Sewing/alterations: machine accessory sales and completed listing quality on resale platforms.
10. Knitting/crochet: pattern complexity growth on craft platforms vs tutorial supply.
11. Makeup application: certification practical scores vs tutorial consumption trends.
12. Hair styling: salon trainee assessments pre/post video curriculum adoption.
13. Fitness form training: gym injury reports and progression outcomes with video coaching uptake.
14. Yoga technique: pose accuracy scores in studio assessments vs at-home video use.
15. Dance choreography: competition scoring and routine complexity vs tutorial access.
16. Language pronunciation: oral test pronunciation subscores vs exposure to video pronunciation lessons.
17. Public speaking: judged speech clarity/confidence after video-based coaching pilots.
18. Excel/data skills: certification pass rates vs workplace video-learning subscription rollout.
19. Programming basics: coding assessment improvements after tutorial access changes.
20. Data analysis software (R/Stata/Python): assignment completion speed in universities adopting video libraries.
21. Graphic design tools: portfolio rubric scores after video tutorial platform integration.
22. Video editing skills: freelance job success and revision rates vs tutorial exposure.
23. CAD/3D modeling: vocational lab practical scores vs tutorial-based prep access.
24. Photography technique: image quality ratings on platforms after tutorial exposure shocks.
25. Woodworking basics: makerspace certification pass rates with video-first onboarding.
26. Welding basics: trade school practical completion and safety violations under video supplements.
27. First-aid procedure knowledge: scenario test accuracy after public video campaigns.
28. Sign language basics: standardized proficiency gains from video module availability.
29. Early-childhood teaching techniques: classroom observation scores after video coaching rollouts.
30. Nursing procedural skills: simulation lab performance with mandatory video prep.
31. Physical therapy home exercises: patient adherence and recovery metrics vs tutorial usage.
32. Agricultural techniques: crop practice adoption and yields after localized instructional video expansion.
33. Small business bookkeeping: error rates in filings after tutorial access improvements.
34. E-commerce skills: seller conversion metrics after platform-provided video training.
35. Interview skills/job readiness: mock interview scores and placement outcomes under video prep interventions.

Best next steps (priority order):
1. Select one flagship domain (recommended: coding/certification or DIY home repair with objective outcomes).
2. Build a data feasibility table with columns: outcome, exposure proxy, ID source, access risk, time-to-clean.
3. Pre-register two designs: primary and backup.
4. Draft minimal estimating equations and identification assumptions for both.
5. Start verified literature file (paper, DOI/link, mechanism/ID relevance, replication notes).

## 9. Assumptions and open questions

Assumptions used in this kickoff:
- YouTube/tutorial access materially affects learning inputs, not just entertainment time.
- At least one domain has measurable outcomes with sufficient frequency and spatial/temporal variation.
- Exogenous variation in access/exposure is available or constructible.
- Video quality heterogeneity can be proxied (engagement, creator reputation, pedagogy markers).

Open questions requiring your decision:
1. Preferred primary context: UK, US, or cross-country?
2. Preferred domain for first estimable paper: DIY, coding/certification, or another from Section 8?
3. Data access constraint: public-only vs willingness to pursue partner data?
4. Tolerance for short-run reduced form first vs larger structural extension later?
5. Whether to include minor interactive-AI extension in first draft or leave entirely for follow-up.
