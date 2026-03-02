# AI Sci Word BibTeX

**Project type**: side project (citation lookup and BibTeX insertion service)
**Status**: planning stage
**Last updated**: 2026-02-27
**Canonical status tracker**: `projects/ai_sci_word/ai_sci_word_bibtex/STATUS.md`

---

## What this project is

AI Sci Word BibTeX is a companion service for paper writing:

1. look up references from DOI, title, author/year, or URL
2. return clean BibTeX entries
3. insert/update entries in project bibliography with stable keys

This project is intended to integrate with `projects/ai_sci_word/` and remain open source.

## Current focus

1. Paper-first workflow only.
2. Fast "search and insert citation" loop.
3. Deterministic and clean BibTeX generation.

## Initial MVP scope

1. DOI lookup to BibTeX using content negotiation where available.
2. Title lookup fallback via metadata APIs.
3. BibTeX key normalization and duplicate detection.
4. Insert/update flow against a `.bib` file.
5. Lightweight provider adapter for metadata sources.

## Next 3 concrete tasks

1. Define lookup pipeline order (DOI first, then title/author fallback).
2. Define BibTeX key policy and duplicate resolution rules.
3. Build a minimal API/CLI that returns BibTeX JSON plus raw BibTeX text.

## Open source intent

This project is intended to be open source and published on Git/GitHub.
