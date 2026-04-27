# Two-arm design and measurement issues

## Core framing

The project has two related arms.

## Arm 1: Which places are inclusive?

The first arm is descriptive and measurement-focused.

Question:

> Which types of points of interest and public or commercial spaces bring together more diverse visitors?

The core object is a POI-by-time measure of visitor composition. Advan mobility data can attribute visits to points of interest and, through visitor home census block groups, approximate the socioeconomic and racial composition of visitors.

The basic example:

- a focal POI receives visitors from multiple CBGs
- each origin CBG has demographic and socioeconomic characteristics from Census/ACS
- the POI's visitor-origin mix can be used to construct racial and SES mixing indices
- this can be measured by month or week, depending on the data extract

This allows descriptive comparisons across:

- POI categories
- public versus private/commercial spaces
- cities or MSAs
- time periods
- day/time windows if available
- central versus suburban locations
- high-visit versus low-visit POIs

The conceptual contribution is to ask not only whether neighborhoods are segregated, but which everyday destinations generate cross-group exposure.

## Arm 2: Does exposure matter for outcomes?

The second arm links exposure patterns to aggregate outcomes.

Question:

> Do counties or MSAs with more mixed activity spaces have stronger social capital, economic connectedness, civic participation, volunteering, or different attitudes?

Candidate outcomes already in the project include:

- Chetty et al. social capital and economic connectedness measures
- volunteering and civic organization measures
- Stantcheva et al. zero-sum attitude outcomes
- potentially donations or other behavioral civic outcomes, if available

The causal challenge is that attitudes and social capital may shape where people choose to go, rather than only being shaped by exposure. The project therefore needs a disciplined identification strategy and should clearly separate descriptive facts from causal claims.

## Measurement caveats

### Visitors versus workers

Advan/SafeGraph-style visitor data measures visitors to a POI, not necessarily employees or staff. In some settings, such as gas stations, convenience stores, restaurants, and shops, customer-worker interaction may be more meaningful than customer-customer interaction.

Implication:

- be precise and call the measure visitor mixing or activity-space exposure
- avoid claiming it directly measures interpersonal interaction
- consider whether worker composition can be proxied separately using LEHD/LODES, QCEW, County Business Patterns, or occupation/industry patterns

### Co-presence versus interaction

The data can show that groups visit the same POI, but not necessarily that individuals interact.

Potential language:

- "potential exposure"
- "activity-space co-presence"
- "visitor-origin mixing"
- "opportunity for contact"

Avoid:

- "interaction" unless the measure truly captures temporal overlap or repeated co-presence

### Timing

Visitor composition may differ sharply by time of day or day of week. A pub, restaurant, park, gas station, or workplace may have different social meaning in the morning, afternoon, evening, weekday, and weekend.

If timestamps permit, construct separate measures by:

- weekday versus weekend
- working hours versus evening
- commute windows
- late-night windows
- school/workday versus leisure windows

If only weekly or monthly data are available, frame the result as aggregate visitor mixing, not direct temporal co-presence.

### Visit purpose and group travel

People often visit restaurants, parks, shops, or entertainment venues with family or friends. Co-presence at a POI does not guarantee cross-group contact.

This is not fatal, but it means the project should distinguish:

- exposure opportunity
- passive co-presence
- meaningful contact
- repeated interaction

### Selection

People choose where to go. More tolerant or more cosmopolitan people may choose more diverse places, and places may become diverse because of existing attitudes rather than causing them.

The first arm can remain descriptive. The second arm needs identification or cautious language.

## Suggested measurement families

For each POI and time period:

- visitor-origin entropy or diversity
- racial exposure/isolation indices
- SES exposure/isolation indices
- distance from local residential baseline
- over-representation of out-group visitors relative to the POI's surrounding area
- share of visits crossing CBG racial or SES distance thresholds
- category-level average mixing
- within-category residual mixing after controlling for city, neighborhood, size, chain status, and visit volume

For CBG or MSA aggregates:

- destination-side exposure: where residents of a CBG go
- origin-side exposure: who comes into a CBG or POI
- non-diagonal origin exposure: inward exposure excluding same-CBG flows
- category-specific exposure: exposure generated by restaurants, retail, parks, religious/civic spaces, entertainment, workplaces, schools, etc.

## Main empirical warning

The strongest paper should not claim that mobility data reveal attitudes directly.

A safer sequence is:

1. document where cross-group exposure opportunities occur
2. validate that exposure measures differ from residential segregation
3. show which POI categories explain the difference
4. then, separately, test whether exposure measures predict social-capital or attitude outcomes
5. reserve causal language for specifications with credible identification

## Open design questions

- Which POI categories count as public spaces versus private commercial spaces?
- Should employees/workers be incorporated, and if so with which data?
- Is weekly timing enough, or can the project use finer time-of-day variation?
- Should the main inclusion measure be racial diversity, SES diversity, or both?
- Should inclusivity be measured relative to national diversity, local MSA diversity, or nearby-neighborhood diversity?
- Which outcome family should anchor arm 2: Chetty social capital, volunteering/donations, or Stantcheva attitudes?
