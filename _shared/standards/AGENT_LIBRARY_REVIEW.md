# Agent library review - quarterly checklist

Run this review approximately every quarter (or before starting a new major project phase).
Goal: keep `_shared/` lean and accurate. Remove dead weight; promote what is actually used.

---

## When to Run

- Before starting a new project or paper revision
- After a major phase completes (e.g., referee response round, calibration rerun)
- When adding a third new agent/skill in a short period (signals it's time to consolidate)

---

## Checklist

### 1. Review agents for duplication
- [ ] Open `_shared/agents/`. Does any pair of agents do overlapping work?
- [ ] If yes: merge the two into one, or demote the weaker one to `_playground/`.
- [ ] Rename any agent whose title no longer matches what it actually does.

### 2. Promote only proven reusable workflows
- [ ] Review repeated work. Does a workflow need repository-specific instructions that the base model and existing resources do not already supply?
- [ ] If yes, add the smallest suitable agent or skill; otherwise keep the task-specific instruction local.
- [ ] Check that each new resource has a clear trigger, purpose, inputs, output contract, and constraints.

### 3. Prune obsolete prompts and skills
- [ ] Open `_shared/prompts/`. Delete obsolete tracked material because Git preserves it. Archive only unique human work or genuine milestones.
- [ ] Open `_shared/skills/`. Do all SKILL.md files still match the tools/libraries being used?
- [ ] Check that each skill has only `name` and a trigger-rich `description` in frontmatter, stays concise, and moves optional examples or resources out of the main file.
- [ ] Verify `_shared/skills/`, `.agents/skills/`, and `.claude/skills/` expose the same intended catalogue.

### 4. Check project READMEs are accurate
- [ ] Open each `research_projects/<name>/README.md`. Does its stable overview still reflect the project?
- [ ] Check that it points to `STATUS.md` rather than duplicating the live task list.
- [ ] If a project has concluded or stalled, update status accordingly (e.g., "Published", "On hold").

### 5. Check project state files
- [ ] Confirm each `STATUS.md` has exactly one `## Snapshot` and one `## Next 3 Tasks` heading.
- [ ] Keep snapshots to 1-3 lines and detailed history outside the live status sections.
- [ ] Open each `research_projects/<name>/memory.md`. Are durable paths, conventions, and decisions still correct?
- [ ] Remove session-diary repetition while preserving durable conventions, decisions, and unique context.

### 6. Referee template accuracy
- [ ] Compare `_shared/templates/referee_response_template.tex` to the most recent actual response.
- [ ] If the structure has evolved (new sections, new macros, new conventions), update the template.
- [ ] Update `_shared/standards/referee_response_standard.md` to match.
- [ ] Replace `_shared/templates/referee_response_example.tex` with the most recent complete example if a better one now exists.

---

## After the Review

- [ ] Search instruction and skill files for stale branch names and mojibake.
- [ ] Run `&_shared/scripts/audit_agent_library.ps1` (or call it with `powershell.exe -ExecutionPolicy Bypass -File` when local execution policy requires it).
- [ ] Commit intentionally after inspecting the diff; do not make automatic review commits.
- [ ] Update `_shared/memory/RESEARCH_STYLE.md` only if a stable substantive preference changed.
