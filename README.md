# Economics Research Workspace

Personal research workspace for economics paper projects, AI-assisted workflows, and shared tooling.

## Structure

```
Economics/
  research_projects/  <- mature paper-track research projects
  research_ideas/     <- early-stage speculative research ideas
  teaching/           <- teaching materials and workshops
  book/               <- book writing and interview workflow
  other/              <- non-paper miscellaneous projects
  _shared/            <- reusable assets across all projects
    memory/           <- persistent preferences and style notes
    agents/           <- specialist agent definitions
    skills/           <- knowledge packs (SKILL.md files)
    templates/        <- document templates (referee response, etc.)
    standards/        <- conventions and checklists
    prompts/          <- reusable prompt fragments
  _playground/        <- scratch work, learning material, backups
  AGENTS.md           <- how AI assistants should behave (read first)
  CLAUDE.md           <- tool-specific instructions (Stata paths, etc.)
```

## Projects

| # | Project | Status |
|---|---------|--------|
| 01 | Necessity Entrepreneurs | Draft in progress |
| 02 | NIMBYism and the Housing Supply | Published (JME 2025) |
| 03 | Fertility and Housing Supply | Early stage |

## Quick start for AI sessions

1. Read `AGENTS.md` (steering rules)
2. Read `_shared/memory/RESEARCH_STYLE.md` (style preferences)
3. Read `research_projects/<name>/README.md` and `research_projects/<name>/memory.md` (project state)

## Notes

- This repository is local and synced via OneDrive.
- Rebuildable/temp artifacts are excluded by `.gitignore`.
- Referee responses use the template in `_shared/templates/referee_response_template.tex`.
