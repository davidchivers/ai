# Coauthor Setup for NIMBY Housing Supply

This file is for Zac or any other collaborator working from the compact
`gross-chivers-research` repository.

## Quick Start

1. Clone the collaboration repo:

   ```text
   https://github.com/davidchivers/gross-chivers-research
   ```

2. Work in `nimby_housing_supply/`.
3. Read `STATUS.md` before starting. The current live thread is the Moll/direct
   price-beliefs route under `drafts_re/moll_direct_price_beliefs/`.
4. Use `_shared/agents/` and `_shared/skills/` from the repo root as optional
   Codex helpers. They are David's defaults; tailor them if they are not useful
   for your workflow.

## External Data and Large Assets

The GitHub repo does not include every large local or Hamilton output. For code
that needs the shared external project assets, use one of these layouts:

- Preferred explicit setting: set `ZAC_DAVID_EXTERNAL_ROOT` to the folder that
  contains `Data/`, `Code/SteadyState/`, and `Code/Codes_ABB/`.
- David's large-data mirror: `D:\research_data\zac_and_david`.
- Dropbox fallback: `%USERPROFILE%\Dropbox\Zac and David`.

The MATLAB helpers in `code/steadystate/` and `code/codes_abb/` search those
locations in that order, with Dave's old `C:\Users\Dave_\Dropbox\Zac and David`
path kept only as a final legacy fallback. The Stata data merge script follows
the same convention.

## Paths That Need Care

Older notes and Hamilton handoff files may mention:

- `C:\Users\Dave_\AI\...`
- `D:\AI_storage\spillover\...`
- `D:\SteadyState\...`
- `C:\Users\Dave_\COMPECON`
- `hamilton8`
- `/nobackup/hfnt93/...`

Treat those as Dave's historical local or Durham/Hamilton paths unless a script
explicitly exposes them as parameters. For a new run, prefer project-relative
paths, `ZAC_DAVID_EXTERNAL_ROOT`, or your own Hamilton username and scratch root.

## Current NIMBY Extension Thread

The active work is not the published JME paper itself; it is the post-publication
NIMBY extension trying alternatives to full rational expectations. The current
Moll-aligned route is documented in:

- `drafts_re/moll_direct_price_beliefs/route_options.md`
- `drafts_re/moll_direct_price_beliefs/workbench/moll_avenues_report.md`
- `drafts_re/hamilton_jobs/workflow_moll_direct_0514.md`
- `STATUS.md`

The compact repo includes source, notes, and selected diagnostics, not every
large generated result. If a closeout script expects Hamilton
`truth/...` outputs, those need to be copied from Hamilton or regenerated.
