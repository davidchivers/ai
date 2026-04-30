# Website wizard

Open `index.html` in Edge or Chrome.

Recommended:
1. In File Explorer, go to this folder.
2. Double-click `index.html`.

Wizard flow:
1. Choose OS.
2. Choose AI agent.
3. Install editor + AI tool:
   - choose editor (VS Code or Cursor)
   - download editor, Git, and Node manually
   - open the same editor and run the AI agent install command
4. Sign in / auth step:
   - Codex: `codex --login`
   - Claude Code: `claude`
   - Gemini CLI: set API key, then run `gemini` after reopening terminal; if the integrated terminal still misses the key, fully restart the IDE
5. Starter folder setup (optional).
6. Optional profile import.
7. Pair with GitHub.
8. Glossary.
9. Done.

## Session note (2026-02-27)

- Pages 3-6 were initially collapsed into one install page.
- Then restart-terminal guidance was split into its own separate step before agent install.
- Windows fast path uses one `winget` command for editor + Git + Node.
- Mac fast path remains a short two-command path (`xcode-select` then `brew`).

## Session note (2026-04-01)

- Collapsed editor install, terminal restart, and AI agent install back into one page.
- Removed the fast-install command blocks and left only the manual download/install route.
- Added a simple-app fallback note on the first pages so users can open starter folders in ChatGPT/Codex or Claude without the full terminal route.
- Added a warning that the starter folders are still mainly tuned for VS Code/Cursor, so some preset/profile files are editor-specific.

## Session note (2026-04-02)

- Added a real `Simple route` branch that skips the full VS Code/Cursor + terminal steps and jumps straight to the starter ZIP download page.
- Softened the starter-folder warning so it says editor-specific files are fine and can be deleted later with help from the AI if needed.
- Bumped the `app.js` cache-buster in `index.html` so browsers pick up the new route logic.

If commands fail, paste the full terminal error into ChatGPT/Claude first.
If in doubt, paste the full terminal error into the AI tool you installed and ask for the exact next command.

## Distribution config

Set these in `app.js` under `distribution`:

- `starterZipUrls.basic`
- `starterZipUrls.advanced`
- `github.owner` (optional branch-ZIP fallback only)
- `github.repo` (optional branch-ZIP fallback only)
- `github.branchBasic` (optional branch-ZIP fallback only)
- `github.branchAdvanced` (optional branch-ZIP fallback only)
- `oneDriveFolderUrlBasic` (optional fallback)
- `oneDriveFolderUrlAdvanced` (optional fallback)
- `vscodeProfileUrl` (optional)
- `cursorProfileUrl` (optional)
- `teachingSlidesUrl` (optional)
- `githubEducationUrl` (optional)

Historical note:

- The old standalone starter-pack repo `davidchivers/ai_install` has been deleted.
- Starter ZIP downloads now point at static website assets under `/ai_install/downloads/`, generated from the current local starter folders.
- If GitHub branch ZIP downloads are reintroduced, point `distribution.github.owner` and `distribution.github.repo` at the new deliberate target instead of assuming the old repo still exists.

## Slide link auto-update

Use one stable URL for `teachingSlidesUrl`, then keep replacing the same file.

GitHub pattern:
1. Store `slides/ai_coding_agents_workshop_slides.pptx` in your site or starter repo.
2. Keep the filename/path unchanged.
3. Commit + push updates to that same path.
4. The wizard link points to the latest file automatically.

You can use:
- GitHub file URL (`blob` page)
- GitHub raw URL (`raw.githubusercontent.com`)
- OneDrive share link

## Workshop source paths in this repo

- Website snapshot: `teaching/install_ai/website/`
- Starter-pack source folders:
  - `teaching/ai_teaching_starter/starter_basic/`
  - `teaching/ai_teaching_starter/starter_advanced/`
- Published starter ZIPs:
  - `other/davidchivers_site/ai_install/downloads/starter_basic.zip`
  - `other/davidchivers_site/ai_install/downloads/starter_advanced.zip`
- Workshop slides:
  - `teaching/ai_workshop/ai_coding_agents_workshop_slides.pptx`
  - `teaching/ai_workshop/slides_outline.md`

## Starter-pack explainer text

Use this on download pages/docs:

`This is a starter pack, not a locked system. You can use it as-is, copy only parts of it, or start a brand-new folder anytime.`

## Deployment note (2026-04-08)

- Canonical repo-location map for this workspace: `teaching/install_ai/REPO_MAP.md`.
- Canonical personal-site source repo: `davidchivers/davidchivers.co.uk`.
- Main workspace repo: `davidchivers/ai`.
- Deleted standalone starter repo: `davidchivers/ai_install`.
- Temporary live-domain bridge: `thomshutt/davidchivers`. Treat this as a Pages bridge only until the custom domain is unpaired from it.
- When asked to publish to the website, use `davidchivers/davidchivers.co.uk` as the source repo, not `thomshutt/davidchivers`.
