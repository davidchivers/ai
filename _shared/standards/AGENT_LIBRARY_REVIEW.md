# Agent Library Review — Quarterly Checklist

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

### 2. Promote new reusable agents from actual usage
- [ ] Review recent sessions. Was any ad hoc prompt or approach used more than twice?
- [ ] If yes: write it up as a new agent in `_shared/agents/` (use `_AGENT_TEMPLATE.md` if it exists).
- [ ] Check that each new agent has: purpose, trigger condition, inputs, output format, key constraints.

### 3. Prune obsolete prompts and skills
- [ ] Open `_shared/prompts/`. Delete or archive any prompt not used in the last 6 months.
- [ ] Open `_shared/skills/`. Do all SKILL.md files still match the tools/libraries being used?
- [ ] Archive pruned items to `_playground/backups/YYYY-MM-DD-pruned/` rather than deleting.

### 4. Check project READMEs are accurate
- [ ] Open each `research_projects/<name>/README.md`. Does the "current status" still reflect reality?
- [ ] Update "next 3 concrete tasks" to reflect what actually comes next.
- [ ] If a project has concluded or stalled, update status accordingly (e.g., "Published", "On hold").

### 5. Check project memory files
- [ ] Open each `research_projects/<name>/memory.md`. Are key file paths still correct?
- [ ] Have any conventions changed? Have new conventions emerged that aren't documented?
- [ ] Update notes from recent sessions.

### 6. Referee template accuracy
- [ ] Compare `_shared/templates/referee_response_template.tex` to the most recent actual response.
- [ ] If the structure has evolved (new sections, new macros, new conventions), update the template.
- [ ] Update `_shared/standards/referee_response_standard.md` to match.
- [ ] Replace `_shared/templates/referee_response_example.tex` with the most recent complete example if a better one now exists.

---

## After the Review

- Commit the updated files with message: `chore: quarterly agent library review YYYY-MM-DD`
- Note any major changes in `_shared/memory/RESEARCH_STYLE.md` if style preferences changed.

