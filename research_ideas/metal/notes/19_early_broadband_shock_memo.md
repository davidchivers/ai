# Early broadband shock memo

Last updated: 2026-03-31

## Question

What do we currently know in this project about city- and county-level internet or broadband
shocks, and what does the literature suggest as the best path if we want a credible early-rollout
design?

## Direct read from local work

### 1. We do not currently have a credible early city-level broadband shock for the metal paper

The only real city-level broadband object currently built in this project is the Ookla-based panel
described in `notes/18_city_broadband_data.md`.

Current facts:

- source: official Ookla Open Data fixed-broadband parquet files
- coverage: `2019 Q1` to `2025 Q4`
- panel built for this project:
  `data/processed/scene_networks/diffusion/black_metal_city_broadband_2019_2025_radius15km.csv`
- scale: `895` cities and `25,060` city-quarter rows

That is a real city-level broadband workflow, but it is too late for the early internet question in
the main metal paper.

### 2. The actual city-level probe is exploratory and too small

I reran the city-level probe in:

- `code/56_probe_black_metal_city_broadband.py`

Current output:

- `data/processed/scene_networks/diffusion/black_metal_city_broadband_probe_summary.md`
- `data/processed/scene_networks/diffusion/black_metal_city_broadband_probe_results.csv`

Current read:

- sample: `47` city-year observations
- cities: `33`
- years: `2020-2022`
- events: `33`
- `local thickness x broadband = 0.0906`, `p = 0.8627`
- `hub exposure x broadband = 0.1958`, `p = 0.7986`

So this is a genuine city-level broadband test, but it is late-period, tiny, and not decision-grade.

### 3. The broader internet result we have is only a smoke test

The broader result is from:

- `code/55_smoke_black_metal_internet_diffusion.py`
- `data/processed/scene_networks/diffusion/black_metal_internet_diffusion_smoke_summary.md`

That merges country-year internet and broadband variables onto city-year black-metal diffusion
outcomes. It is useful as a descriptive screen, but not as a clean causal design.

Current coefficients:

- `local thickness x internet = 0.0449***`
- `hub exposure x internet = -0.0193***`
- `local thickness x broadband = 0.0561***`
- `hub exposure x broadband = -0.0175**`

Interpretation:

- this points to a pattern where rising internet access may strengthen local-scene thickness more
  than external hub exposure
- but the treatment is only at the country-year level, so it cannot be sold as a city-level or
  county-level shock

### 4. Elsewhere in the repo we have a county or district build plan, not a finished estimate

In `research_ideas/learning_by_viewing`, there is a real public-data design scaffold around FCC
Form 477:

- `research_ideas/learning_by_viewing/data/strategy_3_broadband_panel/schema.md`
- `research_ideas/learning_by_viewing/data/strategy_3_broadband_panel/raw_to_canonical_mapping.md`

That plan is real and technically grounded, but it is still a panel-build specification, not an
estimated county-level result.

## Literature and data search

### A. Best examples with real local rollout data

#### Norway: municipality-level rollout and adoption

There are Norwegian papers using municipality-level broadband availability and subscriptions during
the main rollout period.

Useful source:

- BFI working paper using municipality-level availability and subscriptions and treating rollout as
  plausibly exogenous:
  https://bfi.uchicago.edu/wp-content/uploads/2023/02/BFI_WP_2023-21.pdf

Why this matters:

- the paper states that it has municipality-level information on broadband availability and
  subscriptions for `2000-2010`
- rollout occurred progressively across municipalities
- availability is used as an instrument for adoption

This is the cleanest example of true local administrative rollout data rather than a proxy.

#### Ireland: local ADSL availability over time

Useful source:

- Lyons, `Timing and Determinants of Local Residential Broadband Adoption: Evidence from Ireland`
  https://www.esri.ie/publications/timing-and-determinants-of-local-residential-broadband-adoption-evidence-from-0

Why this matters:

- uses small-area data on broadband take-up
- links it to GIS-based local ADSL availability over time
- directly studies local adoption dynamics right after service arrives

This is good evidence that early local rollout can be studied with actual telecom geography when
those data exist.

### B. Best proxy designs for early broadband rollout

#### Germany: distance to the main distribution frame

Useful source:

- Heblich summary of Falck, Gold, and Heblich:
  https://wol.iza.org/uploads/articles/294/pdfs/effect-of-internet-on-voting-behavior.pdf

Direct design facts from that source:

- early DSL quality depended on distance to the main distribution frame, or `MDF`
- the key threshold is `4.2 km`
- MDF locations were determined in the `1960s`, long before DSL

Why this matters:

- this is a strong engineering-based proxy for early broadband availability
- it is much cleaner than using raw broadband penetration levels alone

#### Germany: broadband availability and employment growth

Useful source:

- Stockinger, `Broadband internet availability and establishments’ employment growth in Germany`
  https://link.springer.com/article/10.1186/s12651-019-0257-0

Why this matters:

- the paper explicitly uses the German telecommunications network and the DSL technology
  constraint
- it is another example of using network engineering to get plausibly exogenous early broadband
  variation

#### Ireland: exchange-area DSL enablement, middle-mile fibre, and backhaul proxies

Useful source:

- McCoy et al., `The impact of broadband and other infrastructure on the location of new business establishments`
  https://www.lse.ac.uk/GranthamInstitute/wp-content/uploads/2017/10/Working-paper-282_McCoy-et-al.pdf

Direct design facts from that paper:

- local broadband proxy based on Eircom DSL enablement in `1,060` local telecom exchange areas
- time span: `2001-2010`
- adds middle-mile `MAN` rollout and a backhaul competition proxy

Why this matters:

- this is a serious local-rollout design built from telecom infrastructure rather than generic
  county broadband counts

### C. U.S. public data options

#### FCC Form 477 county-level connection data

Useful source:

- FCC Connect2Health data explainer page:
  https://c2h.fcc.gov/bh-data.html

Direct fact from that page:

- FCC provides a county-level connection measure for residential internet adoption

#### Limits of historical local Form 477 detail

Useful source:

- FCC OEA Working Paper 50:
  https://docs.fcc.gov/public/attachments/DOC-368773A1.pdf

Direct facts from that paper:

- tract-level Form 477 subscription data begin with the `December 2008` release
- earlier vintages mainly reported state-level counts plus zip-code usage lists
- the paper aggregates tract-level connections up to counties for `2008`, `2012`, and `2017`

Why this matters:

- U.S. county-level broadband work is feasible
- but the early period is not as strong as the German or Irish engineering-proxy papers

#### National Broadband Map

Useful source:

- FGDC report on the National Broadband Map:
  https://www.fgdc.gov/resources/whitepapers-reports/annual%20reports/2011/web-version

Direct facts from that page:

- the first National Broadband Map launched on `February 17, 2011`
- it provided detailed geographic availability information and county comparisons

Why this matters:

- useful for later availability mapping
- still not an ideal source for the very first broadband rollout years

## Inference and recommendation

### 1. Best read for the current metal paper

The main metal paper should **not** claim a local broadband shock.

Best current treatment of the internet question:

- keep the broad digital-era split as a descriptive robustness check
- if useful, mention the country-year internet smoke test as suggestive only
- do not try to upgrade the current city-level Ookla panel into an early-rollout identification
  design

Reason:

- the only real city-level panel starts in `2019`
- the genuine city-level probe is tiny and very late
- the broader smoke test is only country-year

### 2. Best serious design if we want a real early broadband extension

The strongest path is a **single-country local-rollout design based on telecom engineering**, not a
global city panel.

Best candidates from the literature:

- Germany: `MDF` distance / `4.2 km` DSL threshold
- Ireland: exchange-area DSL enablement
- Norway: municipality-level staged rollout and adoption

Reason:

- these designs exploit local infrastructure constraints or rollout timing directly
- they are much more credible than generic county broadband penetration levels

### 3. Best U.S. public-data fallback

If we want a U.S. county-level public-data design, the practical route is:

- FCC Form 477 county or tract data
- possibly supplemented by the National Broadband Map
- with a treatment window starting effectively around `2008` or later

That is feasible, but it is weaker for an "early broadband" story than the European
engineering-proxy designs.

## Bottom line

The local project evidence says we do **not** yet have a convincing early city- or county-level
internet shock for the metal paper. The literature suggests that the best papers do one of two
things:

- use actual local rollout or subscription data from a country with good telecom records
- or use engineering-based proxies such as exchange or MDF distance

If we want the cleanest next step, it should be a country-specific side project or extension,
not an attempt to force the current global metal panel into a local broadband-shock design.
