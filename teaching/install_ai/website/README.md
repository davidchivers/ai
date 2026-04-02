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

- `github.owner`
- `github.repo`
- `github.branchBasic`
- `github.branchAdvanced`
- `oneDriveFolderUrlBasic` (optional fallback)
- `oneDriveFolderUrlAdvanced` (optional fallback)
- `vscodeProfileUrl` (optional)
- `cursorProfileUrl` (optional)
- `teachingSlidesUrl` (optional)
- `githubEducationUrl` (optional)

Example ZIP outputs:

- `https://github.com/davidchivers/ai_install/archive/refs/heads/starter_basic.zip`
- `https://github.com/davidchivers/ai_install/archive/refs/heads/starter_advanced.zip`

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
- Workshop slides:
  - `teaching/ai_workshop/ai_coding_agents_workshop_slides.pptx`
  - `teaching/ai_workshop/slides_outline.md`

## Starter-pack explainer text

Use this on download pages/docs:

`This is a starter pack, not a locked system. You can use it as-is, copy only parts of it, or start a brand-new folder anytime.`

## Deployment note (2026-03-17)

- Evidence: the live files at `https://davidchivers.co.uk/ai_install/index.html` and `https://davidchivers.co.uk/ai_install/app.js` match `thomshutt/davidchivers` on branch `master`, with cache-buster `app.js?v=20260310-1`.
- Evidence: `thomshutt/davidchivers` `master` contains the active `ai_install/` website; its `gh-pages` branch is a separate older academic site.
- Evidence: `https://github.com/davidchivers/davidchivers` is a different repo and should not be treated as the live `ai_install` source.
- Operational rule: update the live installer in `thomshutt/davidchivers` `master`.
- Local note: the previously recorded Desktop clone path no longer exists on this machine, so verify the live-repo clone location before editing or deploying.
