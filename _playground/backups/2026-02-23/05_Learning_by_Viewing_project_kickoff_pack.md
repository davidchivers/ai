# Learning by Viewing  Kickoff Pack
## 1. Project overview
Core question: does scalable access to high-quality video demonstration (for example, YouTube) causally increase skill acquisition relative to text, diagrams, and trial-and-error learning alone?

Primary research questions:
1. How much does video access change the probability, speed, and quality of mastering practical skills?
2. Which skills benefit most from viewing (procedural, motor, tacit, sequence-heavy) versus reading/diagrams?
3. Does video learning reduce or widen skill inequality across income, education, age, and geography?
4. What is the welfare impact when video substitutes for paid instruction, apprenticeships, or formal training?
5. Do platform dynamics (creator competition, recommendation systems, feedback loops) improve teaching quality over time?

Scope and framing:
- Main paper should be empirical economics first, with reduced-form and quasi-experimental evidence.
- Theory/modeling should discipline mechanism interpretation and generate heterogeneity predictions.
- Minor extension: interactive human/AI help as a complement to passive viewing.

Candidate outcomes:
- Individual: task completion, error rate, time-to-completion, certification/passing, wages in skill-linked occupations.
- Household: DIY spending efficiency, contractor substitution, repair quality/safety incidents.
- Market: service prices, demand for professional instruction, entry into skilled occupations/hobbies.
- Distributional: gains by baseline skill and digital access.

Expected contribution:
- Introduce and measure "learning by viewing" as distinct from learning by doing and learning by reading.
- Provide causal evidence on when demonstration-rich media improves human capital formation.
- Quantify welfare and distributional implications in a platform-mediated learning environment.

## 2. Mechanisms and testable hypotheses
Main hypotheses:
1. Video access raises skill acquisition rates more for procedural/motor tasks than for conceptual tasks.
2. Effects are larger when learners can sort across many instructors and formats (choice set mechanism).
3. Video narrows geographic inequality in skill access but can widen digital-access inequality.
4. Platform learning effects grow over time as instructional best practices diffuse among creators.
5. Video + minimal interactivity (comments, Q&A, AI tutor) outperforms video-only for troubleshooting-heavy tasks.

Key mechanisms/channels:
1. Demonstration fidelity: moving visual sequences transmit tacit steps that text/diagrams miss.
2. Lower search/matching costs: users find instructor style/pace that fits prior knowledge.
3. Repetition and pacing control: pause/rewind/slow-motion increases effective practice intensity.
4. Quality competition/network effects: creators optimize pedagogy under feedback and engagement.
5. Scale and long tail supply: niche skills receive tutorials unavailable in local markets.
6. Social proof and motivation: visible success examples increase effort and persistence.
7. Complementarity with doing: viewing reduces early mistakes, making practice more productive.

Testable predictions:
1. Treatment effects should be strongest for tasks requiring ordered hand movements and error-sensitive sequencing.
2. Effects should increase with broadband quality/video load speed and decrease with outages.
3. Gains should be larger where local in-person instruction is scarce/high-cost.
4. As platform maturity rises, average tutorial quality metrics should improve and learning effects should strengthen.
5. Video-heavy learners should show fewer "first-try" errors and shorter completion times.

Expected welfare implications:
- Likely winners: remote/rural learners, low-income self-learners, career-switchers, small creators of instructional content, consumers via cheaper services.
- Potential losers: incumbent local instructors with low differentiation, low-digital-access groups, workers in tasks where amateur substitution reduces paid demand.
- Inequality possibilities:
- Democratization channel: low-cost access broadens skill acquisition.
- Divergence channel: those with devices, bandwidth, and digital literacy capture larger gains.
- Net welfare sign likely positive if quality/safety externalities are managed and access gaps are addressed.

## 3. Modeling menu (34 options)
1. Binary mastery choice model.
- Agents/choices/timing/state: individual chooses learning mode (view/read/do) before attempting task; state is baseline ability.
- What viewing does: increases success probability and lowers time cost.
- Comparative statics/predictions: larger viewing premium for low baseline ability in procedural tasks.
- Data mapping: completion rates, attempt durations, modality exposure logs.

2. Sequential learning-with-errors model.
- Agents choose modality each period; state is accumulated mistakes.
- Viewing reduces transition probability into high-error states.
- Predicts fewer catastrophic failures early in learning.
- Map with repeated attempt data and error-type classifications.

3. Bayesian signal precision model.
- Learner updates belief about correct method from noisy signals.
- Viewing provides higher-precision signal than text.
- Predicts larger gains when prior uncertainty is high.
- Use pre/post confidence and objective test scores.

4. Search and matching over instructors.
- Learner samples creators with heterogeneous teaching fit.
- Viewing expands choice set and lowers sampling cost.
- Predicts gains from larger platform penetration and recommendation quality.
- Map using clickstream diversity, watch histories, completion outcomes.

5. Dynamic discrete choice of effort.
- Each period learner allocates time across viewing/practice/reading.
- Viewing raises marginal return to practice.
- Predicts complementarity: viewing and doing increase together.
- Use time-use + progression outcomes.

6. Human capital production with media inputs.
- Skill stock evolves with inputs: practice, text, video.
- Video has task-specific productivity parameter.
- Predicts modality elasticities vary by task type.
- Estimate with panel on practice intensity and outcomes.

7. Hazard model of time-to-mastery.
- State is not-yet-mastered; exit hazard depends on modality exposure.
- Viewing shifts hazard upward.
- Predicts shorter median time-to-mastery with video access.
- Map with cohort onboarding and milestone timestamps.

8. Multi-task allocation model.
- Learner chooses which skills to attempt under budget.
- Viewing lowers fixed learning cost for some tasks.
- Predicts broader skill portfolio and niche-skill entry.
- Measure number/type of new skills adopted.

9. Peer diffusion model.
- Individuals observe peers' success and adopt modalities.
- Viewing adoption diffuses through networks.
- Predicts local peer exposure amplifies individual treatment effects.
- Use social graph/proxy and staggered adoption.

10. Two-sided platform quality model.
- Creators choose instructional quality; learners choose watch time.
- Better pedagogy attracts demand; feedback improves quality.
- Predicts rising average instructional quality over platform maturity.
- Data: video metadata, retention, outcome-linked surveys.

11. Tournament among creators.
- Creator payoff depends on ranking/engagement.
- Viewing ecosystem induces innovation in teaching format.
- Predicts format convergence toward high-effectiveness designs.
- Use content feature trends and performance metrics.

12. Attention constraint model.
- Learner has finite cognitive bandwidth.
- Viewing can reduce extraneous cognitive load for some tasks.
- Predicts non-monotonic effects for overly edited/fast videos.
- Map with pace/length features and outcomes.

13. Information overload/search friction model.
- Large content supply creates selection frictions.
- Viewing benefit depends on recommendation/filter quality.
- Predicts stronger effects where curation improves.
- Use algorithm changes or playlist tools as shocks.

14. Mistake-cost minimization model.
- Learner chooses modality to minimize expected mistake damage.
- Viewing most valuable when mistakes are costly.
- Predicts strongest demand in high-penalty tasks (electrical, medical prep).
- Map with task risk ratings and modality usage.

15. Local instruction substitution model.
- Household chooses between paid instructor and self-learning via video.
- Viewing lowers demand for paid instruction.
- Predicts price/demand effects in local lesson markets.
- Use service market prices and platform penetration.

16. Complementarity with formal education model.
- Student chooses extra video supplement to classroom learning.
- Viewing boosts returns to formal training.
- Predicts bigger gains in under-resourced institutions.
- Map with school-level resources and online exposure.

17. Option value model for experimentation.
- Viewing lowers uncertainty before starting skill.
- More people attempt skills with positive option value.
- Predicts increased trial of previously intimidating tasks.
- Use new-channel/topic entry and novice participation metrics.

18. Quality threshold model.
- Skill mastery requires crossing an instruction-quality threshold.
- Viewing increases chance of encountering above-threshold instruction.
- Predicts discrete jump in mastery for users exposed to top-tail videos.
- Map with creator quality rankings and learner outcomes.

19. Heterogeneous learning-style model.
- Learners differ in visual/verbal preference parameter.
- Viewing effects heterogeneous by preference/cognitive traits.
- Predicts sorting and differential gains.
- Use baseline assessments + modality interactions.

20. Learning depreciation/refresh model.
- Skill decays without reinforcement.
- Viewing enables low-cost refresher episodes.
- Predicts slower skill decay and better retention.
- Map with follow-up tests and refresh watch behavior.

21. Credential production model.
- Workers choose learning paths to pass skill exams.
- Viewing raises pass probability at low cost.
- Predicts exam attempt and pass-rate increases after access shocks.
- Use certification data by region/time.

22. Spatial access model.
- Remote regions face high cost of in-person training.
- Viewing compresses distance penalty.
- Predicts larger treatment effects in low-density areas.
- Map with rural broadband rollout and local training supply.

23. Household bargaining model.
- Household allocates time/resources to member upskilling.
- Viewing lowers monetary cost and schedule coordination burden.
- Predicts stronger gains where time constraints bind (parents/caregivers).
- Use household composition interactions.

24. Firm training adoption model.
- Firms choose between in-house trainer and video modules.
- Viewing lowers training cost per worker.
- Predicts SME adoption and productivity gains in routine technical tasks.
- Map with firm surveys and output/productivity measures.

25. Apprenticeship queue model.
- Limited apprentice slots constrain doing-based learning.
- Viewing partially substitutes for queue-constrained slots.
- Predicts higher entry into constrained trades.
- Use waitlist data and training enrollments.

26. Safety externality model.
- Learners choose risky DIY with/without video preparation.
- Viewing may reduce per-attempt risk but increase attempts.
- Predicts ambiguous net accident levels; clearer effect on severity.
- Map with injury rates, severity, and DIY activity proxies.

27. Quality-adjusted output model.
- Task output has quality index, not just completion.
- Viewing increases precision and finish quality.
- Predicts quality gains even when completion rates unchanged.
- Use expert ratings, returns/complaints, rework rates.

28. Multi-stage production task model.
- Task has stages; failure at early stage cascades.
- Viewing especially improves stage transitions.
- Predicts largest gains on bottleneck stages.
- Map with step-level telemetry or process audits.

29. Algorithmic exposure model.
- Platform recommender determines instructional exposure quality.
- Viewing effect mediated by recommendation policy.
- Predicts discontinuities around algorithm updates.
- Use policy change/event study with creator-learner panels.

30. Creator entry model.
- Potential instructors decide whether to produce tutorials.
- Lower production tools + demand induce entry.
- Predicts more supply in underserved skills and faster pedagogic innovation.
- Map with category-level creator entry and learner outcomes.

31. Language accessibility model.
- Multilingual/subtitled videos reduce language barriers.
- Viewing lowers comprehension cost for migrants/non-native speakers.
- Predicts larger gains in language-mismatched populations.
- Use subtitle availability and migrant outcomes.

32. Social reputation model.
- Learners post outcomes publicly; reputation rewards mastery.
- Viewing strengthens norm of self-teaching and sharing.
- Predicts peer-driven adoption cycles and persistence.
- Map with social posting data and subsequent learning behavior.

33. Income-constrained investment model.
- Learning investment constrained by cash and liquidity.
- Viewing is low-cost capital-light learning input.
- Predicts larger effects among credit-constrained groups.
- Use income/credit proxies and heterogeneity.

34. Hybrid video + AI helper model (extension).
- Learner chooses passive video only or video plus interactive assistant.
- Interactivity lowers troubleshooting friction after failed attempts.
- Predicts gains concentrated in tasks with high idiosyncratic failure modes.
- Map with usage logs of Q&A/assistant tools and retry outcomes.

## 4. Literature map (what to search + why)
Bucket A. Economics of learning / skill acquisition / human capital
- Subtopics:
- Learning-by-doing and experience curves.
- Observational/social learning and peer effects.
- Skill formation and dynamic human capital accumulation.
- Tacit knowledge transfer and apprenticeship economics.
- Keywords:
- "learning by doing economics"
- "observational learning human capital"
- "social learning labor economics"
- "tacit knowledge transfer productivity"
- "experience curve worker performance"
- What we need from this bucket:
- Theoretical foundations for mechanisms.
- Established predictions on heterogeneity and dynamic gains.
- Benchmarks for comparing viewing to doing/reading.

Bucket B. Economics of online platforms / information / media / education technology
- Subtopics:
- Platform content quality competition.
- Returns to online education and digital learning tools.
- Attention markets and recommendation systems.
- Video-based instruction versus text-based instruction.
- Keywords:
- "online platform content quality economics"
- "video learning outcomes quasi experimental"
- "education technology causal effects"
- "YouTube education skill acquisition"
- "recommendation algorithm learning outcomes"
- What we need from this bucket:
- Evidence on platform-mediated information quality and access.
- Empirical designs that isolate platform exposure.
- Measurement conventions for digital learning behavior.

Bucket C. Identification strategies used in related work
- Subtopics:
- Broadband rollout and internet speed shocks.
- Platform outages/blocks and access interruptions.
- Device adoption shocks (smartphone penetration, data pricing).
- Differential timing of local digital infrastructure upgrades.
- Keywords:
- "broadband rollout difference in differences skills"
- "internet outage natural experiment education"
- "platform ban block causal effects"
- "fiber rollout event study labor outcomes"
- "data price shock digital learning"
- What we need from this bucket:
- Credible treatment variation sources.
- Threat-mitigation playbooks (pre-trends, migration, anticipation, compositional shifts).
- Templates for event-study and IV diagnostics.

## 5. Empirical design brainstorm (10+)
1. Broadband rollout x skill intensity DiD.
- Outcomes: certification rates, DIY service substitution, skill-related earnings.
- Treatment/proxy: local high-speed internet availability.
- ID: staggered DiD/event study across regions.
- Threats/fixes: endogenous rollout; use planned infrastructure timing controls and pre-trend checks.
- Feasibility: high (public infrastructure and labor data often available).

2. YouTube outage natural experiment.
- Outcomes: search-to-completion of tasks, course completion, repair outcomes.
- Treatment: temporary outages or throttling episodes.
- ID: event study around outage windows.
- Threats/fixes: concurrent shocks; use unaffected platforms/regions as controls.
- Feasibility: medium (needs granular outage and platform usage data).

3. Mobile data price shock IV.
- Outcomes: instructional video watch time, task success proxies.
- Treatment: effective video affordability.
- ID: IV using telecom tariff changes.
- Threats/fixes: pricing endogeneity; exploit regulatory or exogenous policy shifts.
- Feasibility: medium.

4. School/workplace video-access policy change.
- Outcomes: pass rates, productivity metrics.
- Treatment: introduction of allowed/blocked video learning tools.
- ID: DiD across institutions adopting at different times.
- Threats/fixes: policy chosen where problems biggest; include institution trends and matched controls.
- Feasibility: medium-high.

5. Recommendation algorithm change.
- Outcomes: learning completion, retention, follow-through behavior.
- Treatment: exogenous shifts in exposure to instructional content.
- ID: event study or diff-in-discontinuities using policy change date.
- Threats/fixes: simultaneous UI changes; isolate affected categories and placebo categories.
- Feasibility: medium.

6. Geographic instrument: terrain-driven broadband quality.
- Outcomes: skill uptake and quality.
- Treatment: realized streaming quality.
- ID: IV with topography/cable distance interactions.
- Threats/fixes: exclusion concerns; saturate with geographic controls and historical development trends.
- Feasibility: medium.

7. Platform entry of localized language subtitles.
- Outcomes: learning gains among non-native speakers.
- Treatment: subtitle availability by language/time.
- ID: DiD by language community exposure.
- Threats/fixes: concurrent migration trends; add demographic and area-year controls.
- Feasibility: medium-high.

8. Public library/community center Wi-Fi expansion.
- Outcomes: skill course completion, certification, employment transitions.
- Treatment: nearby free high-speed access.
- ID: DiD or synthetic control at municipality level.
- Threats/fixes: targeted rollout; propensity-score weighting and pre-trend balance.
- Feasibility: high.

9. Vocational exam reform requiring practical competencies.
- Outcomes: pass rates in practical components.
- Treatment: differential need for demonstration learning.
- ID: triple-difference (before/after x practical-heavy exams x high-video-access regions).
- Threats/fixes: other reform components; isolate practical-specific sections.
- Feasibility: medium.

10. Device shock: low-cost smartphone rollout.
- Outcomes: first-time engagement with skill learning and outcomes.
- Treatment: smartphone/video-capable access.
- ID: DiD with staggered retail rollout or subsidy eligibility thresholds.
- Threats/fixes: income trends confounding; include local labor and price controls.
- Feasibility: medium-high.

11. Category-specific creator supply shock.
- Outcomes: skill adoption in affected categories.
- Treatment: sudden increase in tutorial supply from creator entry wave.
- ID: Bartik-style exposure or event study.
- Threats/fixes: demand-driven entry; instrument using creator-side shocks (policy, monetization changes).
- Feasibility: medium.

12. Platform block/unblock across countries.
- Outcomes: skill market indicators, learning outcomes.
- Treatment: access ban/lift timing.
- ID: synthetic control + event study.
- Threats/fixes: macro-political confounds; narrow windows and multiple controls.
- Feasibility: medium-low (policy complexity).

13. Firm-level adoption of video SOPs.
- Outcomes: error rates, training duration, output quality.
- Treatment: rollout of video-based standard operating procedures.
- ID: staggered DiD within multi-site firms.
- Threats/fixes: contemporaneous process upgrades; collect implementation details and phased controls.
- Feasibility: high if partnership data obtained.

14. Weather-driven stay-at-home shocks interacting with video access.
- Outcomes: home task completion, online instructional consumption.
- Treatment: exogenous time at home x internet quality.
- ID: shift-share panel with fixed effects.
- Threats/fixes: weather affects many behaviors; isolate task categories plausibly linked to viewing.
- Feasibility: medium.

## 6. Deep-dive: DIY/COVID and safety/accidents angle
Causal story:
- During COVID-era stay-at-home periods, households shifted toward DIY tasks.
- Video tutorials reduced information frictions for attempting/performing tasks.
- Net accidents can rise or fall: more attempts raise exposure, better instruction lowers per-attempt risk.
- Therefore identify both extensive margin (attempts) and intensive margin (risk per attempt/severity).

Outcome measures (at least 3):
1. DIY project incidence/intensity: purchases of task-specific materials/tools.
2. Safety outcomes: emergency visits for DIY-related injuries, severity, admissions.
3. Quality outcomes: repeat purchases (rework), contractor call-backs after DIY attempts.
4. Labor market outcomes (optional): home-service demand shifts/prices.

YouTube learning exposure measures (at least 3):
1. Region-time watch intensity in DIY tutorial categories.
2. Search/query intensity for "how to" repair/build tasks.
3. Exogenous video access proxies: broadband speed, data affordability, platform uptime.
4. Creator supply in local language/region relevant DIY content.

Identification strategies (at least 2):
1. Triple-difference:
- Pre/post COVID periods x high/low broadband regions x DIY-intensive categories versus placebo categories.
2. Instrumental variables:
- Use exogenous network-quality variation (infrastructure timing, topology) for DIY video consumption.
3. Outage/event design:
- Compare DIY outcomes around local platform disruptions.

Key confounds and mitigation:
1. Income shocks and unemployment changed DIY demand.
- Mitigate with local labor controls and category-placebo checks.
2. Supply chain disruptions altered project feasibility.
- Include product availability indices and SKU-level controls.
3. Healthcare utilization changed during COVID.
- Use injury severity and alternative care channels; compare against non-DIY injury controls.
4. Time-at-home and stress changed behavior broadly.
- Include mobility/time-use controls and category-specific falsification tests.

Feasibility:
- Medium-high. Data integration is nontrivial, but credible variation and measurable outcomes exist.
- Stronger if partnered data can measure attempts (denominator) to interpret accident rates correctly.

## 7. Deep-dive: Metal music technicality angle
Causal story:
- YouTube increases access to demonstrations of advanced techniques (sweep picking, polyrhythms, double-kick patterns).
- Musicians learn/practice higher-complexity techniques faster; stylistic best practices diffuse.
- Over time, compositions/performances may become more technically demanding.
- Risk: compositional trends also respond to taste, production tech, and selection into genres.

Outcome measures (at least 3):
1. Audio/MIDI complexity metrics: tempo-adjusted note density, rhythmic irregularity, technique markers.
2. Performance difficulty proxies: expert-rated difficulty, transcription complexity, playthrough error rates.
3. Supply outcomes: share of releases exhibiting high-technical features by cohort/region.
4. Labor outcomes: session-musician wages/premia for technical subgenres (if available).

YouTube exposure measures (at least 3):
1. Exposure to instructional metal guitar/drum channels by region/cohort.
2. Timing of broadband/video quality improvements for likely musician populations.
3. Tutorial supply shocks: entry/sudden growth of major technique-focused creators.
4. Platform recommendation shifts affecting instructional music visibility.

Identification strategies (at least 2):
1. Cohort-by-region DiD:
- Younger cohorts in high-video-access regions compared with older cohorts and low-access regions.
2. Creator supply shock event study:
- Track technicality trends before/after major tutorial-supply expansions.
3. IV with internet quality:
- Instrument instructional consumption using infrastructure quality shocks.

Confounds and mitigation:
1. Global genre trend cycles unrelated to YouTube.
- Include genre-time fixed effects and placebo genres with low tutorial intensity.
2. Recording software/instruments improved independently.
- Control for production technology adoption proxies.
3. Selection: high-ability musicians both consume tutorials and produce technical music.
- Use plausibly exogenous access shocks and pre-trend tests.

Feasibility assessment:
- Medium-low for clean causal inference at scale.
- Measurement is possible, but linking exposure to causal outcomes is data-intensive and identification is fragile.
- Better as a side project or mechanism illustration unless exceptional data partnership is available.

Better alternatives to metal technicality:
1. Broader instrument learning outcomes (exam passes, lesson progression, upload quality metrics).
2. Programming skills (course completion, coding test outcomes) with clearer labor-market links.
3. Home repair quality/safety where objective outcomes are easier to observe.

## 8. Alternative domains and best next steps
35 alternative skill domains more tractable than metal technicality, each with one empirical path:
1. Cooking techniques: use recipe-video exposure shocks and meal-prep quality proxies from grocery basket shifts.
2. Baking/pastry: link tutorial exposure to local bakery-entry/home-baking sales by region-time.
3. Home electrical basics: relate tutorial watch intensity to permit pass rates and electrical service demand.
4. Plumbing repair: examine changes in plumber call-outs after localized video-access improvements.
5. Carpentry/furniture build: combine hardware SKU purchases with project completion reviews.
6. Auto maintenance: track mechanic-service substitution and parts purchases after access shocks.
7. Bicycle repair: use bike shop service records and local tutorial exposure.
8. Sewing/alterations: analyze machine/thread sales and alterations-service demand displacement.
9. Knitting/crochet: measure pattern complexity in marketplace uploads against video exposure.
10. Makeup application: link tutorial trends to cosmetology enrollments and product basket complexity.
11. Hairstyling/barber techniques: outcomes from cosmetology practical pass rates by broadband rollout.
12. Nail art: complexity in posted designs and local training enrollment shifts.
13. Fitness form training: injury-adjusted gym outcomes with instructional-video engagement.
14. Yoga technique: posture quality scores from app/video-linked cohorts.
15. Dance choreography: skill progression in studio assessments after tutorial integration.
16. Language pronunciation: spoken assessment scores with subtitle-rich video access shocks.
17. Public speaking: improvement in judged speech metrics with instructional video assignment.
18. Coding/programming: coding test performance by cohort exposed to tutorial channels.
19. Excel/data analysis: certification pass rates versus local platform access.
20. CAD/3D modeling: software certification outcomes around tutorial-supply increases.
21. Graphic design tools: portfolio quality ratings linked to instructional content exposure.
22. Video editing: freelance project quality/speed after tutorial-platform adoption.
23. Photography lighting: contest outcomes vs exposure to tutorial creators.
24. Music production/mixing: track-level mix-quality metrics after educational-channel growth.
25. Piano skills: exam-level progression with broadband/video quality improvements.
26. Guitar skills (general): grade-exam and performance outcomes by tutorial exposure.
27. Drumming skills (general): tempo/precision improvements in standardized assessments.
28. Drawing/illustration: quality ratings in marketplace portfolios vs tutorial access.
29. 3D printing workflows: print failure rates in maker spaces after training video rollout.
30. Gardening/horticulture: yield/plant survival outcomes with seasonal tutorial engagement.
31. Wood finishing/painting: defect rates in DIY project forums after access shifts.
32. First-aid procedures: simulation performance after assigned video modules.
33. Childcare techniques: parent training outcomes linked to instructional-viewing interventions.
34. Elder-care home assistance: caregiver competency assessments with video-based microtraining.
35. Small-business digital marketing skills: ad campaign performance after tutorial exposure.

Best near-term paper path (recommended):
1. Primary empirical setting: DIY/home repair and safety-quality outcomes.
2. Secondary robustness setting: coding or certification-based technical skills.
3. Keep metal technicality as illustrative extension or appendix.

Immediate next steps:
1. Pick one main outcome family with clear denominator (attempts) and quality/safety decomposition.
2. Build a data inventory table: outcomes, treatment proxies, geography-time unit, likely source, access risk.
3. Pre-register 2-3 feasible ID designs before deep data collection.
4. Draft a minimal conceptual model from options 7, 14, and 26 (hazard + mistake cost + safety externality).

## 9. Assumptions and open questions
Assumptions used here:
1. Video access variation can be measured with enough granularity for credible quasi-experimental designs.
2. At least one domain will have both learning outcomes and attempt-denominator proxies.
3. Platform exposure is sufficiently distinct from generic internet use.

Open questions to resolve before committing to design:
1. Unit of analysis: individual, household, region, or firm?
2. Which domain has the cleanest measurable outcome and least selection bias?
3. What exposure measure is actually obtainable (watch logs, search trends, broadband proxies)?
4. Can we observe attempts vs success separately to avoid misinterpreting safety outcomes?
5. Is there a viable partner dataset (retail, platform, exam authority, insurer, hospital)?
6. How global vs country-specific should the first paper be?
7. Which heterogeneity dimensions are central (income, geography, age, baseline digital literacy)?
