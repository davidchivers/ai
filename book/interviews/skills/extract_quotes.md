# Skill: Extract Quotes (Pass 3)

## Input
- Transcript chunks and pass1/pass2 notes.

## Output
- `outputs/notes_pass3_quotes.md`
- Updated `outputs/fact_checks.md` entries for quote-linked claims.

## Rules
- Quotes must be verbatim with timestamp.
- Every quote needs context and manuscript purpose.
- Flag claims requiring verification with `Fact-check flag = yes`.
- Prefer precision over volume; keep only high-value quotes.

## Procedure
1. Pull candidate quotes with strongest explanatory or narrative value.
2. Add context line for each quote (what question/claim prompted it).
3. Add "why useful" from book perspective (argument, scene, tension, bridge).
4. Mark high-risk factual claims for fact-checking.
5. Rank top 10 pull quotes for likely chapter insertion.

