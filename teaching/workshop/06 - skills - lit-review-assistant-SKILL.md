---
name: lit-review-assistant
description: Search, verify, rank, summarize, and synthesize economics literature. Use when building a literature review, checking whether citations are real, mapping NBER or other working-paper versions to published journal versions, screening papers by fit and venue quality, or organizing a paper queue for economics research writing.
workflow_stage: literature
compatibility:
  - claude-code
  - cursor
  - codex
  - gemini-cli
author: Awesome Econ AI Community
version: 1.1.0
tags:
  - literature-review
  - papers
  - citations
  - synthesis
---

# Literature Review Assistant

## Purpose

Use this skill to build economics literature reviews that are explicit about three separate objects:

1. whether a paper is real
2. whether it is published, forthcoming, or still a working paper
3. how much evidentiary weight it should get in the review

Do not collapse those objects into one.

Recommended repo artifact:
- keep a single Excel-editable file at `literature/checklist/reference_checklist.csv`
- use `confirm_yn = Y` or `Yes` for papers that are confirmed and citation-ready
- keep blank or `N` for items that still need checking
- if the file does not exist yet, initialize it from `_shared/templates/reference_checklist_template.csv`

## Core rules

- Verify that every cited paper exists from a local PDF, DOI page, journal page, NBER page, IDEAS/RePEc entry, or other primary metadata source.
- Treat NBER, CEPR, IZA, CES, FRB, and similar series as real working-paper series, not as journal venues.
- If a published version exists, record the canonical citation using the published journal or edited volume.
- If the accessible file is an NBER or other working-paper PDF, record that separately as the available version.
- Use venue quality as a triage heuristic, not as a substitute for project fit.
- Keep challenge papers separate from the core review unless they materially change the interpretation.

## Instructions

### Step 1: define the research domain

Ask or infer:
1. the specific research question
2. the scope: narrow review, full paper-wide map, or broad search sweep
3. the time period and geography
4. the closest existing papers or seminal anchors
5. whether the user wants only locally verified papers or a wider queue that still needs PDFs

### Step 2: structure the search

Define:
1. primary concept terms
2. method or model filters
3. outcome terms
4. data or institutional terms
5. alternative labels for the same object

For economics topics, search across:
- EconLit
- IDEAS/RePEc
- journal and publisher pages
- NBER and other working-paper series
- local `literature/` folders

### Step 3: verify existence and normalize versions

For each paper, track these fields separately:
- `paper_exists`
- `confirm_yn`
- `publication_status`
- `canonical_venue`
- `available_version`

Use these statuses:
- `published`
- `forthcoming`
- `working_paper_only`
- `unclear`

Important rule:
- NBER is not a journal.
- "NBER Working Paper 26377" is a real paper identifier, but if that paper is later published in a journal, the canonical citation should use the journal venue.
- Keep the working-paper version in notes when that is the PDF currently in hand, but do not confuse access route with publication venue.
- If the repo uses `reference_checklist.csv`, do not treat a paper as drafting-ready until `confirm_yn = Y` or `Yes`.

### Step 4: apply a venue-quality screen

Use two open ranking sources as heuristics:
1. Tilburg University EconTop
2. IDEAS/RePEc journal rankings

Assign a rough venue tier:
- `tier_1`: top general or top field
- `tier_2`: leading applied or field
- `tier_3`: solid field or policy outlet
- `tier_4`: working-paper only, forthcoming, edited-volume, or challenge-paper status

Interpretation rules:
- A close-fit `tier_3` paper can be more useful than a distant `tier_1` paper.
- A `tier_4` working paper can still matter, but should not be described as carrying the same publication weight as a strong published article.
- Seminal papers should not be excluded just because modern rankings place the venue differently.

### Step 5: rank by fit

Separately from venue quality, rank fit to the project:
- `fit_a`: central to the paper's question or mechanism
- `fit_b`: strong supporting paper
- `fit_c`: useful background or measurement paper
- `fit_d`: challenge paper or edge case

The final read queue should be sorted by fit first, then by venue tier, then by recency where helpful.

### Step 6: organize and synthesize

For each paper, record:
- confirm_yn
- canonical citation
- publication status
- canonical venue
- available version
- venue-quality tier
- fit rank
- research question
- data and methods
- key findings
- limitations
- connection to the user's project

### Step 7: identify patterns and gaps

Ask:
- What do the highest-fit papers agree on?
- Where do high-fit papers disagree?
- Which claims rely mostly on working papers rather than published articles?
- Which mechanisms or margins are thinly covered?
- Which papers are only challenge reads and should not structure the main review?

## Literature summary template

```markdown
# Literature Review: [TOPIC]

## Search strategy

**Databases:** EconLit, IDEAS/RePEc, publisher pages, NBER, local PDFs
**Date range:** [years]
**Search terms:**
- [term group 1]
- [term group 2]

## Screening rule

- `paper_exists`: yes/no
- `publication_status`: published / forthcoming / working_paper_only / unclear
- `venue_tier`: tier_1 / tier_2 / tier_3 / tier_4
- `fit_rank`: fit_a / fit_b / fit_c / fit_d

## Core queue

| Paper | Confirm | Canonical venue | Publication status | Available version | Venue tier | Fit rank | Note |
|---|---|---|---|---|---|---|---|
| Author (Year) | Y | Journal | published | local PDF | tier_1 | fit_a | why it matters |
```

## Paper summary template

```markdown
## [Author(s)] ([Year])

**Title:** [full title]
**Canonical citation:** [use published venue if one exists]
**Publication status:** [published / forthcoming / working_paper_only / unclear]
**Canonical venue:** [journal / edited volume / working-paper series]
**Available version:** [local PDF / NBER page / DOI page / etc.]
**Venue-quality tier:** [tier_1 / tier_2 / tier_3 / tier_4]
**Fit rank:** [fit_a / fit_b / fit_c / fit_d]
**Ranking source check:** [Tilburg / IDEAS / both / not checked]

**Research question:** [one sentence]

**Data:**
- Source: [dataset]
- Period: [years]
- Sample: [unit of analysis]

**Identification or model strategy:** [one sentence]

**Main findings:**
1. [result 1]
2. [result 2]
3. [result 3]

**Limitations:**
- [concern 1]
- [concern 2]

**Relevance to the project:** [one sentence]
```

## Best practices

1. Track publication status separately from accessibility.
2. Prefer the published venue in canonical citations when it exists.
3. Keep a note when the PDF in hand is only a working-paper version.
4. Use venue quality to prioritize attention, not to replace substantive judgment.
5. Separate core papers from challenge papers.
6. Update the queue before any final draft transfer.

## Common pitfalls

- Treating an NBER working paper series as if it were the publication venue
- Using journal prestige as the only filter for inclusion
- Failing to distinguish between a real paper, a published paper, and the version currently in hand
- Mixing self-employment, entrepreneurship, and employer creation without clarifying the object
- Citing papers that have not been checked from a reliable source

## References

- [EconLit](https://www.aeaweb.org/econlit/)
- [IDEAS/RePEc](https://ideas.repec.org/)
- [NBER Working Papers](https://www.nber.org/papers)
- [Tilburg University EconTop](https://tilburguniversity.edu/about/schools/economics-and-management/organization/departments/economics/research/output/top-100)
