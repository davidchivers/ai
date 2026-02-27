# AI Workshop Slides Outline (20-30 min)

Audience: beginners
Topic: how to use Claude code/Codex effectively

## Slide plan
1. Welcome + goals (2 min)
2. What Claude code/Codex is (2 min)
3. Core workflow: prompt -> inspect -> edit -> test (3 min)
4. Writing better prompts (3 min)
5. Live example 1: simple file edit (4 min)
6. Live example 2: debug + verify (5 min)
7. Common mistakes and how to avoid them (3 min)
8. Safety + review habits (2 min)
9. Q&A / recap (2-4 min)

## Total time
Approximately 26-28 minutes, adjustable to 20-30 minutes by shortening demos or Q&A.

## Session Handoff (2026-02-22)

### Completed this session
- Renamed workshop example folder from `projects/teaching/Academic_Economics_AI_Template_2026-02-22` to `projects/teaching/global`.
- Updated wizard page for template distribution in `projects/teaching/install_ai/website/app.js`:
  - Added GitHub ZIP download support (auto-build URL from owner/repo/branch).
  - Added optional OneDrive folder fallback link.
- Replaced "Profile (Coming Soon)" with live profile import instructions in `projects/teaching/install_ai/website/app.js`.
- Added configurable `vsCodeProfileUrl` in `projects/teaching/install_ai/website/app.js`.
- Documented the link config in `projects/teaching/install_ai/website/README.md`.

### Current status
- Functionality is in place, but links are still placeholders.
- No GitHub repo has been wired into the wizard config yet.

### To-Do (Dave)
1. Create or choose a dedicated GitHub repo for workshop assets (recommended: keep `global/` and `website/` together).
2. Push these folders into that repo:
   - `projects/teaching/global`
   - `projects/teaching/install_ai/website`
3. Set real values in `projects/teaching/install_ai/website/app.js` under `distribution`:
   - `github.owner`
   - `github.repo`
   - `github.branch`
   - `oneDriveFolderUrl` (optional)
   - `vsCodeProfileUrl`
4. Confirm the generated ZIP link works:
   - `https://github.com/OWNER/REPO/archive/refs/heads/main.zip`
5. Confirm the VS Code profile link opens and imports correctly.
6. Run one end-to-end rehearsal of the wizard (Windows + Mac path check).
7. Decide final participant instruction text:
   - "Download ZIP" as primary
   - "OneDrive copy" as fallback (or remove fallback if not needed)

### To-Do (Next coding pass)
1. Replace remaining "Coming Soon" sections in the wizard with final workshop content.
2. Add a short "Troubleshooting" step with 3 common install failures and fixes.
3. Add a final "Pre-workshop checklist" page for participants.

## Session Handoff (2026-02-27)

### Completed this session
- Confirmed and pushed `projects/teaching/install_ai` updates to `origin/starter_advanced`.
- Collapsed wizard pages 3-6 into one combined install page in `projects/teaching/install_ai/website/app.js`.
- Added Windows one-command fast path:
  - `winget install <editor> Git.Git OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements`
- Kept Mac fast path compact (xcode tools + brew install).
- Updated `projects/teaching/install_ai/website/README.md` to match the new flow and document the collapse.

### Current status
- The install wizard now has a simpler beginner flow with one combined install page.
- Branch `starter_advanced` is pushed and tracks `origin/starter_advanced`.

### Next checks
1. Run one full click-through test on Windows and Mac paths.
2. Confirm wording uses `winget` consistently in all participant-facing materials.
3. Optionally refresh the long-form `install_vs_code_and_ai_agents.md` so it matches the collapsed wizard flow.
