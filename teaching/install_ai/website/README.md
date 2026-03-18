# Website wizard

Open `index.html` in Edge or Chrome.

Recommended:
1. In File Explorer, go to this folder.
2. Double-click `index.html`.

Wizard flow:
1. Choose OS.
2. Choose AI agent.
3. Install prerequisites:
   - choose editor (VS Code or Cursor)
   - run one install command for Git + Node + editor
   - optional "Not working?" manual install dropdown
4. Restart terminal (separate step).
5. Install AI agent:
   - run the CLI install command
   - if a command fails, paste the full error and ask for the exact next command
6. Sign in / auth step:
   - Codex: `codex --login`
   - Claude Code: `claude`
   - Gemini CLI: set API key, then run `gemini` after reopening terminal; if the integrated terminal still misses the key, fully restart the IDE
7. Starter folder setup (optional).
8. Optional profile import.
9. Pair with GitHub.
10. Glossary.
11. Done.

## Session note (2026-02-27)

- Pages 3-6 were initially collapsed into one install page.
- Then restart-terminal guidance was split into its own separate step before agent install.
- Windows fast path uses one `winget` command for editor + Git + Node.
- Mac fast path remains a short two-command path (`xcode-select` then `brew`).

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
