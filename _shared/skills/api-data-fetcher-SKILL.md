---
name: api-data-fetcher
description: Fetch economic and social-science data reproducibly from FRED, the World Bank, and similar APIs. Use when a task requires locating series, authenticating where necessary, handling pagination or rate limits, validating metadata and coverage, and saving documented raw data for later analysis.
---

# API data fetcher

Use this workflow to acquire documented source data, not merely to make an API request succeed.

## Establish the request

Inspect the project context and existing data policy first. Infer the requested concept, geography, period, frequency, unit, output format, and downstream use. Ask only about unresolved choices that materially change the dataset.

Before coding:

- verify access and authentication requirements;
- confirm the provider's series or indicator definition, units, seasonal adjustment, frequency, revision policy, and geographic coverage;
- distinguish current-release data from vintages or real-time releases;
- estimate output size and choose a storage location consistent with the project policy;
- identify the raw-data preservation and refresh strategy.

Do not claim data access from documentation alone. Test a small request before planning a bulk pull.

## Select and verify the provider

Likely starting points include:

| Need | Likely provider |
|---|---|
| US macroeconomic time series | FRED or ALFRED |
| Cross-country development indicators | World Bank |
| US labour statistics | BLS |
| OECD harmonised indicators | OECD |
| IMF macroeconomic series | IMF |

Treat this as routing guidance, not a fixed package recommendation. Check the provider's current official API documentation before implementing the client, parameters, pagination, or rate-limit handling.

## Implement reproducibly

1. Reuse an existing project or bundled runtime. Ask before installing a package.
2. Keep credentials in session environment variables or approved secret storage. Never print, log, or commit them.
3. In PowerShell, a session-only variable uses syntax such as `$env:FRED_API_KEY = '...'`; do not put a real key in a tracked script.
4. Separate acquisition from transformation. Save the provider response or lossless raw extract immutably before producing analysis-ready data.
5. Handle pagination, rate limits, transient failures, and provider error payloads explicitly. Use bounded retries rather than unending loops.
6. Record the request parameters, retrieval time, endpoint, series metadata, software/runtime, and any provider revision or vintage identifier.
7. Use stable filenames unless the project explicitly needs dated or vintage-specific snapshots.
8. For large results, stream, batch, aggregate, or sample deliberately instead of loading the full response into memory by default.

## Validate before handoff

Check:

- expected row count, date range, frequency, geography, units, and missingness;
- duplicates and unexpected gaps;
- joins across providers or frequencies;
- plausibility against provider metadata or a small manual spot-check;
- whether revisions or suppression rules affect interpretation;
- whether the saved raw file can reproduce the processed output.

Never silently interpolate, rescale, seasonally adjust, or combine series. Document each transformation and preserve the original units.

## Output contract

Return:

- the verified provider and series or indicator identifiers;
- the reproducible retrieval script;
- the immutable raw-data location and processed-data location;
- a metadata or README file describing definitions, coverage, retrieval, and transformations;
- a short validation report, including unresolved access or quality limitations.

## Common failure modes

- Hard-coded credentials.
- A valid response for the wrong concept or units.
- Ignored pagination, rate limits, revisions, or vintages.
- Unchecked frequency conversion or geographic joins.
- Treating a synthetic or sample response as proof that the full dataset is available.
- Saving large rebuildable outputs on `C:` when the repository policy routes them to `D:`.

## Primary documentation

- [FRED API](https://fred.stlouisfed.org/docs/api/)
- [World Bank Indicators API](https://datahelpdesk.worldbank.org/knowledgebase/topics/125589)
- [BLS public data API](https://www.bls.gov/developers/)
