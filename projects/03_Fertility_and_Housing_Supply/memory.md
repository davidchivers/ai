# memory.md — Fertility and Housing Supply

Most recent session first.

---

### Session: 2026-02-19 (repo reorganisation)
- Project moved from `PaperProjects/03_Fertility_and_Housing_Supply/` to `projects/03_Fertility_and_Housing_Supply/`
- `memory.md` created; `README.md` already existed
- No changes to paper content

---

## Key files

| Role | Path |
|---|---|
| Project plan | `projects/03_Fertility_and_Housing_Supply/PROJECT_PLAN.md` |
| Upstream sync log | `projects/03_Fertility_and_Housing_Supply/UPSTREAM_SYNC_LOG.md` |
| Upstream source | `projects/02_Nimbyism_and_Housing_Supply/` |

## Upstream relationship

This project **extends** `02_Nimbyism_and_Housing_Supply` by adding fertility mechanisms.
Any fix ported from project 02 should be logged in `UPSTREAM_SYNC_LOG.md` with status and date.

## Current status

Early stage. Folder structure exists (Code, Data, Figures, Literature, Notes, Referee, Slides) but most subfolders are empty placeholders. Paper not yet started.

## Next 3 concrete tasks (as of 2026-02-19)

1. Define the research question and contribution relative to project 02.
2. Populate `Literature/` with relevant fertility-housing papers.
3. Port any code fixes from project 02 as they become available.

## Key conventions

Inherits all conventions from `02_Nimbyism_and_Housing_Supply`:
- LyX for paper source
- MATLAB for model solution
- Stata for data pipeline
- Do NOT commit `.mat` or `.dta` files
