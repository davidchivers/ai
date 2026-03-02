# STATUS - AI Sci Word BibTeX

## Snapshot

- Last updated: 2026-02-27
- Overall state: side project created; requirements now focused on DOI-first citation lookup and clean BibTeX insertion.
- Canonical tracker: this file is the single source of truth for status and next actions.

## Completed

- Created project governance files (`README.md`, `STATUS.md`, `memory.md`).
- Locked role as side project supporting `projects/ai_sci_word/`.
- Locked high-level scope: lookup references and insert normalized BibTeX entries.

## In Progress

- Defining MVP lookup and normalization contract, including:
  - DOI-first lookup path
  - title/author fallback path
  - duplicate key handling
  - output schema for AI Sci Word integration

## Next 3 Tasks

1. Define metadata source order and failure fallback behavior.
2. Define canonical BibTeX key format and collision policy.
3. Build a small prototype service (API or CLI) and test on a paper-scale sample bibliography.

## Blockers

- Metadata source strategy is not locked (Crossref-only vs multi-source merge).
- Exact output schema for AI Sci Word integration is not locked.
- Open-source release details are not locked (license and repo naming).

## Open Decisions

- Final metadata source stack (Crossref, DOI formatter, OpenAlex, Semantic Scholar).
- Confidence and validation rules before writing a BibTeX entry.
- Hosting model for v1 (local CLI only vs local service with HTTP endpoint).
- Open-source license choice (MIT vs Apache-2.0 vs MPL-2.0).

## References

- Project overview: `projects/ai_sci_word/ai_sci_word_bibtex/README.md`
- Session memory: `projects/ai_sci_word/ai_sci_word_bibtex/memory.md`
- Parent project: `projects/ai_sci_word/README.md`
- Tool scan including API references: `projects/ai_sci_word/market_scan.md`
- Governance instructions: `AGENTS.md`
