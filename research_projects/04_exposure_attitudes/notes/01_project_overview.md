# Project overview

## One-paragraph summary

The exposure attitudes project asks whether experienced segregation in everyday activity spaces affects social capital and related attitudes. It combines mobility-derived exposure segregation measures with county/MSA social capital outcomes and a survey-attitudes extension. The main causal design uses land unavailability and local variability in land unavailability (`VARLU`) as instruments for segregation or exposure patterns.

## Research question

How does exposure segregation, meaning who people actually encounter in daily movement and public or commercial spaces, affect social capital, economic connectedness, civic participation, and political/social attitudes?

## Core mechanism

The working mechanism is that residential sorting and city structure shape the venues and neighborhoods people actually visit. If activity spaces are more segregated, people may have fewer cross-group encounters, weaker bridging ties, and different beliefs about redistribution, zero-sum competition, or out-groups.

## Main empirical strands

### Arm 1: which places generate mixing?

The first arm is descriptive and asks which POI categories and public or commercial spaces bring together more racially or socioeconomically diverse visitors. The main object is visitor-origin mixing at the POI level, using Advan/SafeGraph-style visits linked to visitor home CBG characteristics.

This arm should be framed as measuring potential exposure or activity-space co-presence, not direct interpersonal interaction.

### Arm 2: does exposure matter for outcomes?

The second arm asks whether places with more mixed activity spaces have stronger social capital, economic connectedness, civic participation, volunteering, donations, or different attitudes. This is where identification and endogeneity are central.

### Social capital paper

The county/MSA paper links mobility-based experienced segregation to social capital outcomes from Chetty et al. (2022). Outcomes include economic connectedness, exposure to high-SES individuals, volunteering, civic organizations, and related social-capital measures.

### Stantcheva attitudes extension

The survey extension merges county segregation measures onto Stantcheva et al. location histories and estimates modified Table 4-style regressions. The current instructions separate respondent exposure, parental exposure, and lifetime exposure concepts.

### CBG/POI exposure measures

The newer pipeline works at CBG and POI levels. Tommy's handoff indicates a run order of `pipeline_poi.py`, `pipeline_msa.py`, and `pipeline_cbg.py`. The current design issue is how to distinguish destination exposure, origin exposure, inward non-diagonal exposure, and distance-based cross-group exposure measures.

## Identification strategy

The current project uses land unavailability and `VARLU` instruments. The logic, following a Saiz-style supply constraint argument, is that geography-driven land constraints shape housing supply, urban sorting, amenity placement, and daily activity patterns. The project then uses these instruments to isolate variation in experienced segregation.

## Current status

Documents indicate that:

- county and MSA master build scripts exist
- the main exposure segregation pipeline exists
- first-stage diagnostics exist and are partly promising
- draft tables and figures exist
- the paper draft is incomplete and contains placeholders
- the Stantcheva extension has detailed specifications
- the newer CBG/POI exposure pipeline is active but still has design decisions to resolve

## Important caveat

This summary is based on safe project documents and code metadata. It does not reflect inspection of raw data files.

See `04_two_arm_design_and_measurement_issues.md` for the clarified two-arm design and the main measurement caveats.
