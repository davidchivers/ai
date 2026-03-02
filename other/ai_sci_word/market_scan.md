# AI Sci Word market scan

Last updated: 2026-02-27

## Question

Are there already tools similar to AI Sci Word (simple math writing, live output, collaboration, citations), and should we build from scratch?

## Closest existing tools

1. Overleaf
- Strong on real-time collaboration, comments, tracked changes, and history.
- Still LaTeX-first, which keeps the "clunky if you do not want raw LaTeX" problem.
- Source: https://docs.overleaf.com/collaborating/collaborating-in-overleaf
- Source: https://www.overleaf.com/learn/latex/Using_the_History_feature

2. Typst web app + Typst compiler
- Web app supports collaboration and live preview.
- Compiler is open source (Apache-2.0), but web app is commercial/proprietary.
- Strong candidate if Typst syntax is acceptable.
- Source: https://typst.app/docs/web-app/
- Source: https://typst.app/open-source/
- Source: https://github.com/typst/typst

3. TeXlyre
- Open-source, local-first collaborative web editor for LaTeX and Typst.
- Includes in-browser compilation and collaboration stack already.
- Strong candidate for "start small, open source, web-first" if forking is acceptable.
- Source: https://texlyre.github.io/
- Source: https://github.com/TeXlyre/texlyre

4. Fidus Writer
- Collaborative academic editor with formulas and citation focus.
- Open source (AGPL) and has citation/BibTeX integration patterns.
- Strong citation workflow reference point.
- Source: https://www.fiduswriter.org/how-it-works/
- Source: https://www.fiduswriter.org/help-us/
- Source: https://www.fiduswriter.org/2017/10/11/fidus-writer-3-3-citation-management-integration/

5. GNU TeXmacs
- Open-source WYSIWYG scientific editor with strong math editing.
- Desktop-first and not a modern collaboration-first workflow.
- Source: https://www.texmacs.org/

6. LyX
- Open-source and actively released (still current), but known UX friction remains.
- Source: https://www.lyx.org/Download.

## BibTeX lookup APIs we can reuse

1. DOI content negotiation can return BibTeX directly (`Accept: application/x-bibtex`).
- Source: https://www.crossref.org/documentation/retrieve-metadata/content-negotiation/
- Source: https://www.doi.org/doi-handbook/HTML/content-negotiation.html

2. DOI Citation Formatter has HTTP endpoints for formatted citation and metadata.
- Source: https://citation.doi.org/api-docs.html

3. Metadata enrichment options:
- OpenAlex API (works, DOI lookup)
  - Source: https://help.openalex.org/hc/en-us/articles/27526559172759-How-do-I-find-a-publication-s-OpenAlex-work-ID
- Semantic Scholar API
  - Source: https://www.semanticscholar.org/product/api

## Recommendation (inference)

Given your constraints (simple, paper-first, open source, start small), the most practical path is:

1. Build AI Sci Word as a thin web-first layer focused on simple writing UX.
2. Reuse existing open infrastructure instead of rebuilding compilers/collab from scratch:
   - either fork TeXlyre for base editor/collab stack,
   - or build a minimal editor shell and integrate Typst/LaTeX compile later.
3. Keep BibTeX automation as a separate service (`ai_sci_word_bibtex`) using DOI and metadata APIs.

This avoids building an entire Overleaf replacement from zero on day one.
