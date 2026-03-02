# matching rules

## strict match definition (main analysis)
Require match on:
- model family,
- CPU generation/class,
- RAM,
- storage,
- screen size,
- OS edition,
- warranty term (where available).

## text-processing workflow
1. Normalize `sku_text_raw` (case, punctuation, common abbreviations).
2. Extract structured attributes with regex dictionaries.
3. Generate candidate benchmark SKUs using exact token filters.
4. Score candidates with fuzzy similarity and attribute consistency checks.
5. Assign confidence score `0-1`.

## confidence tiers
- High (`>=0.90`): main analysis sample.
- Medium (`0.75-0.89`): appendix robustness only.
- Low (`<0.75`): excluded.

## override protocol
- Manual adjudication allowed only with logged reason and reviewer initials.
- Keep machine score and manual override side by side for auditability.

## TODO
- TODO_DATA: build attribute dictionary from first parsed sample.
- TODO_QA: inter-rater agreement exercise on 100 random lines.
