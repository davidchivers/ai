# Land-unavailability heterogeneity and identification

## Current status

This note records the identification idea discussed by Dave and the project team on 2026-04-27. It is a working design memo, not a settled causal claim.

The project has measures of census-block-group-level land unavailability, plus constructed measures of local variability in land unavailability. The land unavailability measure is Saiz-style in spirit: geographic constraints such as slope and water bodies limit developable land. The team also mentioned an updated measure by Chandler Lutz/Luz, but the exact spelling and source should be verified before citation.

## Core economic logic

The supply-side logic is:

1. Some areas have less developable land because of exogenous geographic constraints, such as steep slopes, rivers, lakes, coastlines, or other water bodies.
2. When land supply is constrained, a similar positive demand shock can produce a sharper increase in housing prices.
3. Conditional on development occurring in these constrained areas, higher prices can select higher-SES residents and support higher-quality or higher-cost amenities.
4. This can create very local SES variation across nearby neighborhoods.
5. Nearby high- and low-SES neighborhoods may then share or cross-use amenities, producing more scope for visitor-origin mixing and lower exposure segregation.

The key point is not simply that constrained land makes a place richer. The more distinctive project idea is that **local variability** in land unavailability can create fine-grained demographic and amenity heterogeneity, which may affect daily activity-space exposure.

## Proposed first stage

The intended first stage is:

> Higher local variability in land unavailability predicts lower exposure segregation.

The interpretation is:

- local geography creates uneven development costs and uneven housing-price responses
- this generates nearby neighborhoods with different SES compositions
- amenities in one neighborhood may attract visitors from nearby neighborhoods with different demographics
- the resulting activity-space flows produce more cross-group exposure than residential patterns alone would imply

Dave's current recollection of the results is that the first stage becomes negative once population size is controlled for: higher land-unavailability variability is associated with lower exposure segregation. This should be verified directly from the first-stage tables before being treated as a result.

## Why this is attractive

The idea has several strengths.

It gives the project a source of variation that is not just individual choice over where to go. It also speaks to the urban mechanism: built environment, amenity placement, neighborhood sorting, and activity-space mixing. Finally, it naturally links arm 1 and arm 2 of the project, because the same source of local spatial heterogeneity can be used to explain why some places generate more exposure opportunities.

## Main identification problem

The hard part is the exclusion restriction.

If land-unavailability variability is used as an instrument for exposure segregation, the exclusion restriction requires that, conditional on controls, local land-unavailability variability affects outcomes only through exposure segregation. That is a strong assumption.

Likely non-exposure channels include:

- residential segregation
- housing prices, rents, and wealth sorting
- local income, education, and occupational composition
- amenity quality and amenity category mix
- fiscal capacity, schools, local public goods, and tax bases
- density, commuting structure, and centrality
- historical city form and neighborhood age
- proximity to water, coastlines, mountains, parks, and environmental amenities
- gentrification or redevelopment dynamics

This does not kill the idea, but it means the paper should be careful. The design is most credible if the instrument is framed as shifting exposure after controlling for the obvious residential, price, density, and amenity channels.

## Controls and sensitivity checks

Candidate controls or robustness checks:

- residential segregation, both racial and socioeconomic
- population size and population density
- income distribution, education, race composition, and age structure
- housing prices or rents, if available
- amenity density and POI category composition
- urbanicity, commuting patterns, and centrality
- region, state, or MSA fixed effects where appropriate
- coastal, river, lake, and mountain indicators if feasible
- baseline or historical covariates measured before the exposure/outcome period
- separate results for county and MSA aggregation
- leave-out checks excluding coastal places, mountain-heavy areas, or very large metros
- compare local variability measures against level measures of land unavailability
- check whether the first stage is linear or nonlinear, especially before and after population controls

## Preferred empirical sequence

A cautious sequence would be:

1. Document the first stage: local land-unavailability variability predicts lower exposure segregation, conditional on population and core geography controls.
2. Show that this is not just residential segregation by controlling for residential segregation directly.
3. Show reduced-form relationships between land-unavailability variability and social-capital or attitude outcomes.
4. Only then present IV estimates, with explicit caveats about conditional exclusion.
5. Use mechanism evidence from POI categories and visitor-origin flows to support the interpretation that the channel runs through activity-space exposure.

## Panel and event-study ideas

Panel variation is likely difficult for the main outcomes. Urban landscapes and amenity systems adjust slowly, and many attitude or social-capital outcomes are not measured as individual panels over long enough horizons.

POI openings, such as a new Starbucks or Walmart, may still be useful for arm 1. They could show how a new amenity changes visitor-origin mixing around a location. But they are less likely to identify medium-run attitude change unless there is a credible outcome panel or repeated local survey measure.

## Next checks

The next concrete step is to locate and summarize the existing first-stage outputs:

- which outcome is used as exposure segregation
- which land-unavailability variability measure is strongest
- whether the sign changes after population controls
- whether the result survives residential segregation controls
- whether the result is county-level, MSA-level, or both
- whether coefficients are standardized and comparable across specifications

Once those facts are locked, this note can be turned into a tighter identification section for the project README or a future paper draft.
