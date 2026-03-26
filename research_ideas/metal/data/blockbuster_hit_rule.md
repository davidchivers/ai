# Blockbuster hit rule

Last updated: 2026-03-20

## Purpose

This file defines the first operational treatment rule for the `metal` project.

It does two separate jobs:

- define which albums belong in the curated seed
- define what counts as a country-level hit event once those albums are extracted from official
  sources

## Scope filter

For the first pass, keep the seed restricted to:

- bands inside the project's metal scope
- full-length studio albums
- release year `>= 1995`

Why:

- the treatment-side official archives are much easier from about `1995` onward
- the current outcome panel is already strongest in that window
- the project is an all-metal Metallum project, not a broad heavy-music project

## Seed inclusion rule

Each album in `data/blockbuster_album_seed.csv` must satisfy one of two rules.

### Tier A: global anchor

Use `tier_a_global_anchor` when the album is a strong prior candidate for official hit evidence
in multiple core markets.

Operationally, this means:

- the album is a well-known blockbuster or near-blockbuster within the metal field
- it is a good candidate for top-10 chart entry, number-1 status, or certification evidence in
  at least two core markets

Use case:

- build the baseline cross-country treatment variation

### Tier B: home-market flagship

Use `tier_b_home_market_flagship` when the album is especially important for the artist's home
country or language market, even if its cross-country reach may be narrower than Tier A.

Operationally, this means:

- the album is a plausible domestic breakthrough or flagship release
- it is still likely to leave an official chart or certification trace in the home market

Use case:

- keep the domestic-exemplar mechanism visible
- preserve non-Anglophone and peripheral-market cases in the seed

## First hit timing rule

The baseline album-country hit event is:

- the first official top-10 entry of the album in the national albums chart

Why this is the default timing measure:

- it is closer to the original demand shock than certification timing
- it is available in several core countries from official chart archives
- it gives a single, auditable event date per album-country pair

## Fallback timing rule

If a market does not give a usable top-10 chart archive for that album-country pair, use:

- the first official gold-or-higher certification date

This fallback should be explicitly marked in the extraction notes.

Interpretation:

- chart entry is the preferred timing event
- certification is a fallback timing measure and a secondary intensity measure

## Blocked-market manual supplement rule

If the direct official chart or certification page is blocked in this environment, a manual
supplement row is allowed only when:

- the row cites an official band, label, or trade-body page that clearly reports the market hit, or
- the row cites a clearly labeled secondary source that preserves an attributed chart or
  certification trace when the official page is not retrievable

Rules for those manual rows:

- keep the row in a separate manual supplement file
- state clearly in `manual_notes` whether the source is official or secondary
- if only year-level timing is recoverable, record `hit_year` and do not pretend that a precise
  weekly chart date has been observed

Current use case:

- Brazil, where direct Pro-Musica retrieval is blocked in this environment

## Baseline aggregation rule

Once album-country rows are collected, aggregate them to country-year treatment measures:

- `hit_top10_ct`: count of seed albums whose first top-10 entry occurs in country `c`, year `t`
- `hit_no1_ct`: count of seed albums hitting number 1 in country `c`, year `t`
- `hit_chart_weeks_ct`: total weeks on chart from the seed albums in country `c`, year `t`
- `hit_certified_ct`: count of seed albums receiving first gold-or-higher certification in
  country `c`, year `t`

Baseline estimating variable for the first pass:

- `hit_top10_ct`

Why:

- it is the cleanest timing measure
- it is easier to interpret than certification lags
- it avoids turning the first pass into a weighting argument

## Treatment precedence

For the first pass, use this priority order when the source gives multiple signals:

1. first top-10 chart entry
2. number-1 indicator
3. weeks on chart
4. certification level and certification date

That means:

- top-10 entry sets baseline event timing
- number-1 and weeks are intensity enrichments
- certifications are secondary intensity and fallback timing

## Broader band-market visibility comparison

The baseline country-year treatment still stays anchored on `hit_top10_ct`, but the downstream
band-influence workflow should now compare three band-market event definitions side by side:

- `first_presence_by_band_market`
  - first recovered chart-presence or certification signal by band-market
- `first_certification_by_band_market`
  - first gold-or-higher certification by band-market
- `first_top10_by_band_market`
  - first recovered top-10 album-chart hit by band-market

Interpretation:

- `presence` is the broad visibility margin
- `certification` is the commercial-recognition margin
- `top10` is the conservative blockbuster margin

Why this comparison now matters:

- metal is still better measured through albums than through singles
- some home-market cases, especially in Brazil and Italy, show up first as chart presence or
  certification rather than as a clean top-10 album event
- the project should not mistake "no top-10 row" for "no visible success"

## Current practical implication

The project should now proceed like this:

1. use `data/blockbuster_album_seed.csv` as the working seed
2. expand the UK and Italy extraction from the pilot sample to this seed
3. aggregate those rows to a country-year hit panel
4. extend blocked markets like Germany and Brazil through clearly labeled manual supplements when needed

## Deliberate non-goals for the first pass

Do not do these yet:

- full country-year album sales panels
- artist-level language spillovers
- complicated weighting schemes across chart peaks, chart runs, and certifications

Those are second-stage extensions only after the first country-year hit panel exists.
