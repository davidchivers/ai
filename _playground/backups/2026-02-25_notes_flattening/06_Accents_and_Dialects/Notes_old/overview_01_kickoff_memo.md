# 2026-02-25 Amended Research Memo: Accents and Dialects in Long-Run Political Economy and Growth

This memo amends and extends the initial kickoff memo. It adds formal models of historical linguistic formation, a broader cross-field literature review, a UK-first data map, and a long-run political economy empirical portfolio.

## (1) Conceptual model

### Model A: Binary accent/phonetic variant with transmission, articulation cost, and prestige

#### Setup
- Regions: \(i \in \{1,\dots,N\}\).
- Time: discrete generations \(t=0,1,2,\dots\).
- Linguistic trait: share of innovative variant in region \(i\), \(x_{i,t} \in [0,1]\).
- Interpret "innovative" as a low-effort or prestige-associated pronunciation (example: glottal stop variant in specific contexts).

#### Structural components
- Intergenerational transmission: children hear local and migrant speech and update beliefs with noise.
- Articulation bias: innovative variant may have lower expected production effort.
- Coordination/network effect: communicative payoff rises when own variant matches local interaction partners.
- Prestige/state/media: standard language institutions and broadcast intensity shift payoffs.

#### Reduced-form transition equation
\[
\Delta U_{i,t} = \alpha_i + \phi_i + \kappa x_{i,t} + \mu \sum_j w_{ij,t} x_{j,t} + \psi P_t
\]
\[
x_{i,t+1} = \Lambda(\Delta U_{i,t}) = \frac{1}{1+e^{-\Delta U_{i,t}}}
\]
where:
- \(\alpha_i\): inherited local preference/identity for innovation (can be negative for conservative regions).
- \(\phi_i\): articulation advantage of innovation (positive if easier production).
- \(\kappa\): local coordination strength.
- \(w_{ij,t}\): migration/contact network weights.
- \(\mu\): impact of external contact.
- \(P_t\): prestige pressure from schooling/state/media (can favor either variant by coding sign).
- \(\psi\): pass-through of prestige to adoption.

Equivalent replicator form:
\[
x_{i,t+1}-x_{i,t} = \eta\, x_{i,t}(1-x_{i,t})\,\Delta U_{i,t}
\]

#### Equilibrium intuition
- If coordination is weak (small \(\kappa\)), long-run \(x_i^*\) varies smoothly with fundamentals.
- If coordination is strong, multiple stable steady states emerge (persistence of dialect regions).
- A gradual change in \(P_t\) or \(\mu\) can trigger a tipping point (rapid shift), matching observed phase transitions.
- Migration/urbanization raises \(\mu\) and tends to synchronize neighboring regions (convergence), unless identity term \(\alpha_i\) strengthens defensive local persistence.

#### Comparative statics
- \(\partial x_i^*/\partial \phi_i > 0\): lower articulation cost raises innovation share.
- \(\partial x_i^*/\partial P_t\) has sign of \(\psi\): stronger prestige pressure shifts the system.
- \(\partial x_i^*/\partial \mu > 0\) for high-contact innovative neighbors.
- Heterogeneous \(\alpha_i\) plus high \(\kappa\) generate persistent dialect boundaries.

### Model B: Continuous phonetic target with articulation anchor and chain-shift interaction

#### Setup
- Each vowel/phonetic category \(k\in\{1,\dots,K\}\) has regional target \(z_{i,k,t}\) in acoustic space (for example normalized F1/F2 dimension).
- Learners minimize mismatch with exemplars, articulation effort, social coordination, and prestige target.

#### Objective and law of motion
Learner in region \(i\) chooses \(z\) for category \(k\):
\[
\min_z \Big[(z-\tilde z_{i,k,t})^2 + \lambda_a (z-z_k^a)^2 + \lambda_n (z-\bar z_{N(i),k,t})^2 + \lambda_p (z-z_{k,t}^{std})^2 + \chi \sum_{\ell\neq k} e^{-\frac{(z-z_{i,\ell,t})^2}{\tau}}\Big]
\]

With quadratic approximation, dynamics become:
\[
z_{i,k,t+1}= a z_{i,k,t}+b\bar z_{N(i),k,t}+c z_{k,t}^{std} + d z_k^a + \varepsilon_{i,k,t}
\]
with \(a+b+c+d\approx1\).

#### Equilibrium and dynamics
- Slow drift: when \(c\) and \(b\) are small, local exemplar and articulation anchors dominate.
- Convergence: stronger migration/media (higher \(b,c\)) compress regional phonetic dispersion.
- Divergence: weak integration plus strong local articulation/identity anchoring sustain regional trajectories.
- Chain shifts: high contrast force \(\chi\) can create nonlinear jumps across multiple categories once one category moves enough.

### Why these two models are useful in an economics paper
- Model A maps cleanly to reduced-form panel/event-study specifications with region-time adoption shares.
- Model B justifies continuous phonetic distance outcomes and makes phase-transition predictions testable.
- Together they generate testable predictions on persistence, convergence/divergence, and tipping points under transport, schooling, and media shocks.

## (2) What we know from econ, political economy, economic history, and historical linguistics

### 2.1 Economics and political economy (language, identity, exchange)

#### 1) Falck et al. (2012)
**Citation**: Falck, O., Heblich, S., Lameli, A., and Suedekum, J. (2012). "Dialects, Cultural Identity, and Economic Exchange." *Journal of Urban Economics*, 72(2-3), 225-239. https://doi.org/10.1016/j.jue.2012.05.007
- Research question: do historical dialect similarities predict modern bilateral exchange?
- Data: 19th-century dialect geography and modern German internal migration flows.
- Identification/approach: gravity framework with geography controls.
- Key finding: stronger historical dialect similarity predicts higher migration exchange.
- Relevance: direct template for dialect-as-friction and dialect-as-identity channels.
- Extension for your project: UK county-pair migration/trade with historical dialect matrices.

#### 2) Lameli et al. (2015)
**Citation**: Lameli, A., Suedekum, J., Nitsch, V., and Wolf, N. (2015). "Same Same But Different: Dialects and Trade." *German Economic Review*, 16(3), 290-306. https://doi.org/10.1111/geer.12047
- Research question: do dialect differences matter for trade within a single-language country?
- Data: intra-German regional trade and dialect similarity measures.
- Identification/approach: within-country gravity with standard controls.
- Key finding: dialect similarity significantly raises trade.
- Relevance: evidence that communication and identity frictions survive common official language.
- Extension: UK inter-regional trade and sector heterogeneity by communication intensity.

#### 3) Melitz (2008)
**Citation**: Melitz, J. (2008). "Language and Foreign Trade." *European Economic Review*, 52(4), 667-699. https://doi.org/10.1016/j.euroecorev.2007.05.002
- Research question: magnitude/channels of language effects in international trade.
- Data: bilateral trade and language ties.
- Approach: gravity estimations.
- Key finding: common language has robust positive trade effects.
- Relevance: benchmark effect sizes for linguistic frictions.
- Extension: replace binary language links with graded phonetic/intelligibility distance.

#### 4) Melitz and Toubal (2014)
**Citation**: Melitz, J., and Toubal, F. (2014). "Native Language, Spoken Language, Translation and Trade." *Journal of International Economics*, 93(2), 351-363. https://doi.org/10.1016/j.jinteco.2014.04.004
- Research question: which language channels matter most in trade?
- Data: bilateral trade and multiple language-link measures.
- Approach: decomposed gravity design.
- Key finding: spoken and translation links are economically large.
- Relevance: motivates separate communication-cost and identity channels.
- Extension: model translation/media infrastructure as substitute for dialect similarity.

#### 5) Adsera and Pytlikova (2015)
**Citation**: Adsera, A., and Pytlikova, M. (2015). "The Role of Language in Shaping International Migration." *The Economic Journal*, 125(586), F49-F81. https://doi.org/10.1111/ecoj.12231
- Research question: does linguistic proximity shape migration flows?
- Data: bilateral migration panel across destinations.
- Approach: panel gravity with controls.
- Key finding: linguistic proximity strongly increases migration.
- Relevance: supports migration-driven linguistic convergence mechanisms.
- Extension: internal UK migration and accent-distance assimilation.

#### 6) Spolaore and Wacziarg (2009)
**Citation**: Spolaore, E., and Wacziarg, R. (2009). "The Diffusion of Development." *Quarterly Journal of Economics*, 124(2), 469-529. https://doi.org/10.1162/qjec.2009.124.2.469
- Research question: why diffusion from the frontier is uneven across societies?
- Data: cross-country income and distance measures.
- Approach: diffusion framework with rich controls.
- Key finding: cultural/historical distance predicts slower diffusion.
- Relevance: conceptual bridge to linguistic distance as diffusion barrier.
- Extension: subnational diffusion in Britain using dialect distance.

#### 7) Desmet et al. (2017)
**Citation**: Desmet, K., Ortuno-Ortin, I., and Wacziarg, R. (2017). "Culture, Ethnicity, and Diversity." *American Economic Review*, 107(9), 2479-2513. https://doi.org/10.1257/aer.20150243
- Research question: relationships among linguistic, ethnic, and cultural distance.
- Data: global measures of culture, language, and diversity.
- Approach: decomposition/regression analyses.
- Key finding: linguistic and cultural distances overlap but have separate explanatory content.
- Relevance: supports multi-mechanism empirical strategy, not a single "culture" control.
- Extension: decompose UK accent effects into communication vs identity channels.

#### 8) Clots-Figueras and Masella (2013)
**Citation**: Clots-Figueras, I., and Masella, P. (2013). "Education, Language and Identity." *The Economic Journal*, 123(570), F332-F357. https://doi.org/10.1111/ecoj.12051
- Research question: can language-of-instruction policy alter identity?
- Data: Catalonia survey/cohort exposure data.
- Identification: policy-cohort exposure design.
- Key finding: greater exposure to regional language strengthens regional identity and political attitudes.
- Relevance: policy can shift language-linked identity outcomes.
- Extension: UK schooling reforms and accent standardization/identity persistence.

#### 9) Fouka (2020)
**Citation**: Fouka, V. (2020). "Backlash: The Unintended Effects of Language Prohibition in U.S. Schools after World War I." *Review of Economic Studies*, 87(1), 204-239. https://doi.org/10.1093/restud/rdz024
- Research question: does forced language assimilation integrate minorities?
- Data: U.S. German-language school bans, long-run social/identity outcomes.
- Identification: policy exposure variation.
- Key finding: coercive assimilation generated backlash and stronger ethnic persistence.
- Relevance: critical warning against one-direction homogenization assumptions.
- Extension: evaluate nonlinearity in UK standardization policies.

#### 10) Alesina, Reich, and Riboni (2017 WP; 2020 JEG)
**Citation**: Alesina, A., Reich, B., and Riboni, A. (2017). "Nation-Building, Nationalism and Wars." NBER Working Paper 23435. https://doi.org/10.3386/w23435
- Research question: when do states invest in nation-building and homogenization?
- Data/model: formal political-economy model calibrated with historical motivation.
- Approach: theory of war technology, public goods, and homogenization incentives.
- Key finding: mass warfare/conscription incentives can increase nation-building investments.
- Relevance: theoretical microfoundation for state-led language standardization.
- Extension: add linguistic-state variable and media/school instruments to the model.

#### 11) Bandiera et al. (2019)
**Citation**: Bandiera, O., Mohnen, M., Rasul, I., and Viarengo, M. (2019). "Nation-Building Through Compulsory Schooling During the Age of Mass Migration." *The Economic Journal*, 129(617), 62-109. [DOI UNVERIFIED - check journal page before submission]
- Research question: was compulsory schooling used as nation-building policy?
- Data: U.S. state/county historical variation during mass migration era.
- Identification: variation in migrant composition and timing of compulsory schooling laws.
- Key finding: education policy operated partly as cultural integration technology.
- Relevance: direct state-language-identity mechanism for your framework.
- Extension: UK Education Acts and local accent trajectories.

#### 12) Fouka and Serlin (2024)
**Citation**: Fouka, V., and Serlin, T. (2024). "Industry and Identity: The Migration Linkage Between Economic and Cultural Change in 19th Century Britain." NBER Working Paper 33114. https://doi.org/10.3386/w33114
- Research question: how modernization changes identity through migration.
- Data: England and Wales microdata, migration, name-based cultural proxies.
- Approach: spatial quantitative model plus historical empirics.
- Key finding: modernization can produce both homogenization and local holdouts.
- Relevance: strongest direct UK bridge to your long-run accent question.
- Extension: replace/augment names with dialect/phonetic indicators.

### 2.2 Economic history and long-run development channels

#### 13) Dittmar (2011)
**Citation**: Dittmar, J. E. (2011). "Information Technology and Economic Change: The Impact of the Printing Press." *Quarterly Journal of Economics*, 126(3), 1133-1172. https://doi.org/10.1093/qje/qjr035
- Research question: did printing cause urban growth in early modern Europe?
- Data: city-level press adoption and urban growth.
- Identification: distance to Mainz instrument for early adoption.
- Key finding: early adopters grew faster.
- Relevance: clean template for communication technology as language-change shock.
- Extension: printing access and speed of orthographic/phonetic standardization.

#### 14) Becker and Woessmann (2009)
**Citation**: Becker, S. O., and Woessmann, L. (2009). "Was Weber Wrong? A Human Capital Theory of Protestant Economic History." *Quarterly Journal of Economics*, 124(2), 531-596. https://doi.org/10.1162/qjec.2009.124.2.531
- Research question: did literacy, not ethic alone, drive Protestant prosperity gaps?
- Data: county-level Prussian outcomes and education.
- Identification: distance to Wittenberg as IV.
- Key finding: literacy channel explains large part of prosperity differences.
- Relevance: schooling/literacy as mechanism linking language policy to growth.
- Extension: literacy by itself versus literacy plus linguistic standardization.

#### 15) Donaldson and Hornbeck (2016)
**Citation**: Donaldson, D., and Hornbeck, R. (2016). "Railroads and American Economic Growth: A 'Market Access' Approach." *Quarterly Journal of Economics*, 131(2), 799-858. https://doi.org/10.1093/qje/qjw002
- Research question: aggregate economic effect of railroad expansion.
- Data: county transport network and agricultural land values.
- Identification: market-access design with network counterfactuals.
- Key finding: railroads had large effects via market access.
- Relevance: key design language for railways-as-integration shocks affecting speech and markets.
- Extension: UK rail market access interacted with dialect convergence.

#### 16) Donaldson (2018)
**Citation**: Donaldson, D. (2018). "Railroads of the Raj: Estimating the Impact of Transportation Infrastructure." *American Economic Review*, 108(4-5), 899-934. https://doi.org/10.1257/aer.20101199
- Research question: welfare effects of railroads in colonial India.
- Data: district prices, trade, and rail network.
- Identification: route expansion and market-access framework.
- Key finding: railroads lowered trade costs and increased real incomes.
- Relevance: structural-empirical template for integration shocks.
- Extension: linguistic distance as additional trade-cost shifter.

#### 17) Adena et al. (2015)
**Citation**: Adena, M., Enikolopov, R., Petrova, M., Santarosa, V., and Zhuravskaya, E. (2015). "Radio and the Rise of the Nazis in Prewar Germany." *Quarterly Journal of Economics*, 130(4), 1885-1939. https://doi.org/10.1093/qje/qjv030
- Research question: how mass broadcasting affects political behavior.
- Data: radio signal strength, electoral outcomes, propaganda exposure.
- Identification: signal variation and panel/event designs.
- Key finding: media can strongly shift political behavior, with context dependence.
- Relevance: supports media-driven language convergence and identity-channel hypotheses.
- Extension: BBC/radio transmitter rollouts and accent standardization.

#### 18) Gregory and Marti-Henneberg (2016)
**Citation**: Gregory, I. N., and Marti-Henneberg, J. (2016). "The Railways, Urbanization, and Local Demography in England and Wales, 1825-1911." *Social Science History*, 40(1), 75-104. [DOI UNVERIFIED in current notes]
- Research question: demographic impact of railway spread in England and Wales.
- Data: GIS rail lines/stations and parish populations on harmonized boundaries.
- Approach: historical GIS and local demographic analysis.
- Key finding: rail diffusion aligns with local demographic change.
- Relevance: direct UK data backbone for rail-linguistic-change designs.
- Extension: add linguistic outcomes at parish/district level.

### 2.3 Historical linguistics and evolutionary language change (formal/quantitative)

#### 19) Weinreich, Labov, and Herzog (1968)
**Citation**: Weinreich, U., Labov, W., and Herzog, M. I. (1968). "Empirical Foundations for a Theory of Language Change." In W. Lehmann and Y. Malkiel (eds.), *Directions for Historical Linguistics*, University of Texas Press, pp. 95-188.
- Research question: what a theory of language change must explain (constraints, transition, embedding, evaluation, actuation).
- Data/approach: conceptual framework grounded in variation evidence.
- Key finding: language change is socially embedded and structurally constrained.
- Relevance: directly motivates your political economy embedding mechanism.
- Extension: map each WLH problem to observables in economic-historical panels.

#### 20) Labov (1994)
**Citation**: Labov, W. (1994). *Principles of Linguistic Change, Volume 1: Internal Factors*. Blackwell.
- Research question: internal dynamics of sound change and chain shifting.
- Approach: synthesis of empirical variation and theory.
- Key finding: regularities in change paths and chain movements.
- Relevance: gives micro-foundation for phase transitions and chain shifts.
- Extension: translate chain-shift logic into multi-category dynamic systems estimable with historical data.

#### 21) Blevins (2004)
**Citation**: Blevins, J. (2004). *Evolutionary Phonology: The Emergence of Sound Patterns*. Cambridge University Press. https://doi.org/10.1017/CBO9780511486357
- Research question: why some sound patterns are common and others rare.
- Approach: phonetic bias plus transmission framework.
- Key finding: recurrent sound change can emerge from production/perception biases.
- Relevance: direct foundation for articulation-cost terms in formal model.
- Extension: quantify biomechanical bias parameters in economic-model calibration.

#### 22) Pierrehumbert (2001)
**Citation**: Pierrehumbert, J. B. (2001). "Exemplar Dynamics: Word Frequency, Lenition and Contrast." In Bybee and Hopper (eds.), *Frequency and the Emergence of Linguistic Structure*, pp. 137-158. https://doi.org/10.1075/tsl.45.08pie
- Research question: how usage frequency and exemplar storage drive phonetic change.
- Approach: exemplar-theoretic modeling.
- Key finding: frequency and memory structure can generate directional change.
- Relevance: provides microfoundation for continuous-trait dynamics.
- Extension: connect market integration shocks to exemplar mixing intensity.

#### 23) Griffiths and Kalish (2007)
**Citation**: Griffiths, T. L., and Kalish, M. L. (2007). "Language Evolution by Iterated Learning with Bayesian Agents." *Cognitive Science*, 31(3), 441-480. https://doi.org/10.1080/15326900701326576
- Research question: how iterated learning shapes long-run language distributions.
- Approach: Bayesian iterated learning model.
- Key finding: long-run language structure reflects learner priors and transmission bottlenecks.
- Relevance: formal basis for intergenerational Bayesian transmission.
- Extension: embed economic environment in priors and likelihood.

#### 24) Kirby, Cornish, and Smith (2008)
**Citation**: Kirby, S., Cornish, H., and Smith, K. (2008). "Cumulative Cultural Evolution in the Laboratory: An Experimental Approach to the Origins of Structure in Human Language." *PNAS*, 105(31), 10681-10686. https://doi.org/10.1073/pnas.0707835105
- Research question: can structured language emerge through repeated learning and transmission.
- Data/approach: laboratory iterated-learning experiments.
- Key finding: structure accumulates endogenously across transmission rounds.
- Relevance: supports slow-moving but directional long-run dynamics.
- Extension: calibrate persistence parameters in macro-historical settings.

#### 25) Baxter et al. (2006)
**Citation**: Baxter, G. J., Blythe, R. A., Croft, W., and McKane, A. J. (2006). "Utterance Selection Model of Language Change." *Physical Review E*, 73(4), 046118. https://doi.org/10.1103/PhysRevE.73.046118
- Research question: how variant competition evolves in speech communities.
- Approach: stochastic evolutionary dynamics.
- Key finding: neutral drift and weak selection can produce long transition dynamics.
- Relevance: stochastic foundation for persistence and sudden shifts.
- Extension: add migration network and policy shocks for empirical tests.

#### 26) Harrington, Palethorpe, and Watson (2000)
**Citation**: Harrington, J., Palethorpe, S., and Watson, C. (2000). "Monophthongal Vowel Changes in Received Pronunciation: An Acoustic Analysis of the Queen's Christmas Broadcasts." *Journal of the International Phonetic Association*, 30(1-2), 63-78. [year/issue details verified from journal references; confirm final bibliographic format]
- Research question: can a single speaker track community-level sound change over time?
- Data: repeated recordings of Queen Elizabeth II broadcasts.
- Approach: acoustic formant analysis across decades.
- Key finding: within-speaker shifts align with broader RP movement.
- Relevance: demonstrates measurable long-run phonetic drift in elite speech.
- Extension: pair with media and class exposure variables.

#### 27) Newberry et al. (2017)
**Citation**: Newberry, M. G., Ahern, C. A., Clark, R., and Plotkin, J. B. (2017). "Detecting Evolutionary Forces in Language Change." *Nature*, 551, 223-226. https://doi.org/10.1038/nature24455
- Research question: selection versus drift in language change.
- Data: long-run historical corpora.
- Approach: inference framework adapted from population genetics.
- Key finding: some changes are selection-driven, others drift-like.
- Relevance: methodologically important for identifying mechanisms in your model.
- Extension: apply selection-versus-drift tests to UK phonetic proxies.

#### 28) Blythe and Croft (2021)
**Citation**: Blythe, R. A., and Croft, W. (2021). "How Individuals Change Language." *PLOS ONE*, 16(6): e0252582. https://doi.org/10.1371/journal.pone.0252582
- Research question: how individual trajectories aggregate to population S-curves.
- Approach: mathematical modeling with empirical grounding.
- Key finding: smooth aggregate S-curves can coexist with heterogeneous individual paths.
- Relevance: justifies aggregate event-study designs despite micro heterogeneity.
- Extension: derive testable age-cohort implications for historical datasets.

### 2.4 Political history and sociology anchors

#### 29) Anderson (1983/2006)
**Citation**: Anderson, B. (1983; revised 2006). *Imagined Communities: Reflections on the Origin and Spread of Nationalism*. Verso.
- Core contribution: print capitalism and shared language as nation-formation infrastructure.
- Relevance: first-principles mechanism linking media/language standardization and state formation.

#### 30) Weber (1976)
**Citation**: Weber, E. (1976). *Peasants into Frenchmen: The Modernization of Rural France, 1870-1914*. Stanford University Press.
- Core contribution: schooling, military service, transport, and administration build national identity.
- Relevance: direct long-run template for language convergence through state penetration.

#### 31) Gellner (1983)
**Citation**: Gellner, E. (1983). *Nations and Nationalism*. Cornell University Press.
- Core contribution: industrial society requires standardized high culture and communication.
- Relevance: macro-theory for why political economy drives linguistic homogenization.

### 2.5 Supplemental orientation source (non-peer-reviewed)
- Simon Roper's YouTube lectures can be used as exploratory orientation for historical linguistics narrative and terminology.
- Use case in this project: hypothesis generation, chronology checks, and finding candidate primary references.
- Restriction: do not treat videos as formal evidence; cite peer-reviewed papers/books/archives in the paper.

### 2.6 Synthesis: evidence vs inference
- Evidence: economics strongly supports language/dialect as friction for migration/trade and as identity marker.
- Evidence: historical work supports schooling, media, and transport as nation-building and integration technologies.
- Evidence: historical and evolutionary linguistics provides explicit microfoundations for persistence, gradual drift, and tipping.
- Inference: integrating these literatures supports a tractable political-economy model where language is both a state variable and an outcome variable.

## (3) Data map

### 3.1 Linguistic formation datasets (UK-first, then global)

| Dataset | Access | Unit | Time | Geography | Constructible linguistic measures | Merge strategy to political economy outcomes |
|---|---|---|---|---|---|---|
| Survey of English Dialects (LAVC/SED, University of Leeds) | Archival, mixed digital access | Locality-item-response | Main fieldwork 1950s; archive materials broader dates | England (dense rural points) | Feature prevalence, dialect distance, isogloss bundles | Spatially map localities to historical counties/districts and construct pairwise distance matrix. Source: https://explore.library.leeds.ac.uk/special-collections-explore/409355 |
| Linguistic Atlas of England (derived from SED) | Print/library plus digitization work | Map-feature-locality | Mid-20th century snapshot | England | Isogloss boundary intensity, regional feature index | GIS digitization then merge with district-year panel. |
| British Library Sounds: Accents and Dialects | Public listening; download/reuse restrictions vary | Recording-speaker-location | 20th century to present (collection-specific) | UK plus Ireland subsets | Acoustic features (F1/F2/prosody), lexical variants | Geocode recording metadata; merge to local labor markets and media coverage. Source: https://sounds.bl.uk/Accents-and-dialects |
| BBC Voices materials (in BL-related collections) | Public listening, reuse constraints | Recording-location | Early 2000s focus | UK regions | Contemporary dialect/accent variants | Benchmark modern endpoints against SED baselines. [Access terms to verify per collection] |
| Our Dialects (Leeds) | Public map; raw export permissions to confirm | User response-location | Contemporary | UK and Ireland | Crowdsourced variant frequencies | Aggregate to LAD/NUTS; use weights for sample representativeness. Source: https://www.ourdialects.uk/maps/ |
| Spoken BNC 1994 and Spoken BNC 2014 | License varies | Conversation-speaker | 1990s and 2010s | UK | Spoken lexical and grammatical change metrics | Build region/cohort language-change indices and match to labor outcomes. Sources: https://www.english-corpora.org/bnc/ and https://www.english-corpora.org/bnc2014/ |
| Hansard Corpus | Public interfaces; bulk constraints vary | Speech-speaker-date | Long run, especially modern parliamentary period | UK | Orthographic standardization and lexical formalization proxies | Link MP birthplace/constituency and time-varying policy/media shocks. |
| Old Bailey Proceedings Online | Public | Case/proceeding text | 1674-1913 | London (with origin clues in many records) | Nonstandard spelling and quoted-speech proxies | Build London-centric migration/contact language indicators. |
| EEBO-TCP and ECCO | Institutional access often required | Document-year-text | Early modern and 18th century | Britain-weighted but not fully local | Orthographic proxies for phonetic change (GVS-era features) | Region tagging plus printing-network linkage for early-modern designs. |
| Google Books Ngram (British English) | Public | Token-year frequency | 1500s-2019+ | Aggregate British English | Macro trend validation of variant spellings | Use as broad external validation, not local causal design. |
| ASJP | Public | Language-pair distance | Cross-sectional with updates | Global | Lexical similarity distance | Use in cross-country robustness and external-validity checks. Source: https://asjp.clld.org/ |
| PHOIBLE, WALS, Glottolog | Public | Language-level inventory and typology | Cross-section plus updates | Global | Phoneme inventory and typological distances | Construct macro linguistic-distance controls or instrument components. Sources: https://phoible.org/ ; https://wals.info/ ; https://glottolog.org/ |

### 3.2 Long-run political economy datasets to merge

| Dataset | Access | Unit | Time | Geography | Core variables | Link to linguistic measures |
|---|---|---|---|---|---|---|
| Integrated Census Microdata (I-CeM), UK Data Service | Registration and license conditions | Individual/household microdata | 1851-1911 (with known gaps by census) | UK | Occupation, migration, demographic structure | Aggregate to district-year; interact with dialect/accent indices. Source: https://ukdataservice.ac.uk/help/data-types/faqs-on-different-types-of-data/ |
| UK census portal (historical aggregates and microdata access paths) | Mixed by product | Multiple (aggregate, flow, microdata) | 1851-present depending product | UK | Population, education, labor, migration | Core economic outcomes panel. Source: https://ukdataservice.ac.uk/learning-hub/census/census-1851-1911/ |
| GB Historical GIS / A Vision of Britain | Public interfaces; some downloadable components | Administrative unit-time | 19th and 20th century rich coverage | Great Britain | Boundary changes, population, historical statistics | Boundary harmonization and crosswalk infrastructure for long-run merges. |
| Historical rail network GIS (Gregory and Marti-Henneberg framework) | Publication-based; data access to verify | Rail line/station plus parish-year | 1825-1911 emphasized | England and Wales | Rail access timing, station proximity | Event-study treatment timing for integration shocks. |
| COW Bilateral Trade v4.0 | Public | Country-pair-year | 1870-2014 | Global | Bilateral trade flows | Cross-country external validity for language-friction estimates. Source: https://correlatesofwar.org/data-sets/bilateral-trade/ |
| V-Dem v15 | Public download | Country-year | 1789-2024 | Global | State capacity, regime, participation, media indicators | Macro political controls and heterogeneous-effect tests. Source: https://www.v-dem.net/dsarchive.html |
| Maddison Project Database | Public | Country-year | Long-run historical to present | Global | GDP per capita and growth | Long-run development outcomes for cross-country linguistic-distance studies. |

### 3.3 Measurement construction plan

#### A. Dialect and accent distance
- Build pairwise distance matrix from SED feature vectors.
- Alternative: acoustic distance from BL/BBC recordings using standardized formant and prosodic features.
- Output: region-pair \(D_{ij}\) and region-year convergence index.

#### B. Historical phonetic-change proxies from text
- Define validated spelling sets tied to known sound changes.
- Compute region-year shares of innovative forms.
- Validate against independent dialect maps or audio when overlap exists.

#### C. State and media standardization intensity
- Schooling intensity: compulsory schooling exposure by cohort and area.
- Media intensity: transmitter and signal exposure by area-year.
- Administrative penetration: proxies from census and governance datasets.

### 3.4 Biggest risks and mitigations
- Measurement risk: spelling is not identical to speech.
  - Mitigation: triangulate text, atlas, and audio sources where possible.
- Endogeneity risk: integration shocks targeted to growth centers.
  - Mitigation: event studies with pre-trend diagnostics, route-planning instruments where credible.
- Access risk: archive audio and some microdata restrictions.
  - Mitigation: start with public MVP designs and define restricted-data upgrade path.
- Boundary risk: changing administrative units over time.
  - Mitigation: harmonized historical GIS crosswalks.

## (4) Empirical idea portfolio (7 ideas)

### Idea 1: Railways, market access, and dialect leveling in industrial Britain
- Hypothesis: earlier rail integration accelerates accent convergence and increases labor-market integration.
- Dependent variable: wage dispersion, migration flows, occupational mobility, plus linguistic convergence index.
- Key explanatory variable: rail market-access shock (district-year).
- Mechanism: lower interaction costs increase inter-dialect contact and reduce local linguistic isolation.
- Identification: staggered event-study DiD around rail arrival; market-access intensity design.
- Threats and limits: endogenous route placement; historical text-proxy error.
- Minimum viable version: district-year panel with one validated linguistic proxy.
- Ambitious version: multi-measure latent linguistic factor (text plus atlas plus audio anchors).

### Idea 2: Compulsory schooling and accent standardization
- Hypothesis: stronger exposure to standardized schooling reduces local phonetic divergence among cohorts.
- Dependent variable: cohort-specific accent distance to national standard; earnings and mobility downstream.
- Key explanatory variable: compulsory schooling exposure by cohort and district.
- Mechanism: standardized curriculum and peer mixing increase linguistic homogenization.
- Identification: cohort-by-district reform exposure (DiD/event study).
- Threats and limits: selective migration and schooling endogeneity.
- Minimum viable version: one reform episode with cohort design and robust controls.
- Ambitious version: multiple reforms plus interaction with local identity strength.

### Idea 3: Broadcast media rollout and phonetic convergence
- Hypothesis: radio/BBC signal expansion accelerates convergence toward broadcast norm.
- Dependent variable: local accent convergence and communication-sensitive labor outcomes.
- Key explanatory variable: transmitter coverage or signal strength over time.
- Mechanism: repeated exposure to prestige pronunciation lowers local variation.
- Identification: staggered transmitter rollout with border/signal-strength quasi-experiments.
- Threats and limits: correlated modernization trends; sparse early speech data.
- Minimum viable version: lexical standardization outcomes near coverage thresholds.
- Ambitious version: acoustic panel from archival recordings.

### Idea 4: Printing press diffusion and early-modern phonetic transition speed (GVS-era proxy)
- Hypothesis: stronger print-network integration accelerated local adoption of spelling proxies associated with vowel change and standardization.
- Dependent variable: region-year innovation share in targeted spelling sets; long-run urban/commercial persistence outcomes.
- Key explanatory variable: distance to early printing nodes and print-market integration.
- Mechanism: print capitalism and textual coordination change transmission equilibria.
- Identification: DiD or IV using early print access and route connectivity.
- Threats and limits: sparse geocoding in early texts; editorial normalization confounding.
- Minimum viable version: one region and two robust feature families.
- Ambitious version: Britain-wide manuscript-print panel with uncertainty modeling.

### Idea 5: Internal migration and spread of low-effort variants (for example glottalization)
- Hypothesis: migration inflows from high-innovation areas increase local adoption of low-effort variants.
- Dependent variable: local prevalence of target variant and worker matching outcomes.
- Key explanatory variable: shift-share predicted migrant inflow from source dialect regions.
- Mechanism: contact-driven exemplar mixing plus articulation-cost advantage.
- Identification: Bartik-style inflow instrument plus local fixed effects.
- Threats and limits: measurement of variant prevalence at fine geography.
- Minimum viable version: one salient feature in modern period.
- Ambitious version: multi-feature adoption system with dynamic diffusion estimation.

### Idea 6: Dialect distance and market integration in the UK
- Hypothesis: greater dialect distance reduces bilateral trade and mobility after geography and transport controls.
- Dependent variable: region-pair trade, commuting, and migration flows.
- Key explanatory variable: pairwise dialect/accent distance matrix.
- Mechanism: communication frictions and identity-based trust frictions.
- Identification: gravity with region-pair fixed effects and time-varying integration shocks.
- Threats and limits: omitted cultural-history confounders; restricted bilateral trade data.
- Minimum viable version: migration or commuting flows with public data.
- Ambitious version: firm-to-firm transaction network with sector heterogeneity.

### Idea 7: State formation and linguistic homogenization in a long-run cross-country panel
- Hypothesis: increases in state capacity and mass education reduce within-country linguistic fragmentation over time.
- Dependent variable: within-country linguistic dispersion index.
- Key explanatory variable: state capacity, schooling expansion, and media penetration indices.
- Mechanism: nation-building investments shift coordination equilibria toward standardized varieties.
- Identification: panel fixed effects with staggered reforms and historical shocks.
- Threats and limits: comparability of linguistic dispersion metrics across countries.
- Minimum viable version: Europe-only panel with transparent harmonization.
- Ambitious version: global panel integrating phoneme and lexical dispersion.

## (5) Suggested next steps to turn one idea into a working paper

### Recommended lead idea
**Idea 1 (Railways and dialect leveling in industrial Britain)** is the best first paper candidate based on identification strength, UK fit, and publication potential.

### 8-week execution plan

#### Weeks 1-2: Build skeleton dataset
1. Construct district-year panel with rail timing/intensity, census outcomes, and boundary harmonization.
2. Build first linguistic proxy (text-based) at district-year.
3. Pre-register core estimating equations and pre-trend tests in a design memo.

#### Weeks 3-4: Baseline estimations
1. Event-study around rail arrival.
2. Heterogeneity by baseline dialect isolation and urbanization.
3. Placebo outcomes and pseudo-treatment timing checks.

#### Weeks 5-6: Measurement validation
1. Cross-validate text proxy against at least one independent dialect benchmark.
2. Sensitivity to alternative feature dictionaries and OCR-cleaning rules.
3. Quantify measurement error bounds.

#### Weeks 7-8: Mechanism and writing package
1. Add migration-flow mechanism tests.
2. Add labor-market integration outcomes.
3. Draft complete paper outline (theory, empirics, robustness, mechanisms).

### Go/no-go criteria for this lead design
- Go if pre-trends are flat, first-stage linguistic proxy has external validity, and core effect is robust across reasonable specifications.
- Pivot to Idea 6 if linguistic proxy is too noisy but pairwise dialect matrix is reliable.

### Biggest residual risks
- Proxy validity for historical phonetic change remains the central scientific risk.
- Data access for some audio and bilateral trade components may delay full version.
- Boundary harmonization is nontrivial but manageable with GIS-first workflow.

## Notes on verification quality
- Citations above are restricted to references verified via journal, publisher, or working-paper repositories during this session.
- A small number of bibliographic fields are flagged as `[UNVERIFIED]` where publisher pages were not directly retrieved in this pass; these should be checked before manuscript submission.
