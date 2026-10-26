# Website wizard

Open `index.html` in Edge or Chrome.

Recommended:
1. In File Explorer, go to this folder.
2. Double-click `index.html`.

Wizard flow:
1. Choose OS.
2. Choose AI agent(s).
3. Install prerequisites:
   - choose editor (VS Code or Cursor)
   - run one install command for Git + Node + editor
   - optional "Not working?" manual install dropdown
4. Restart terminal (separate step).
5. Install AI agent:
   - run Codex/Claude install commands
   - if a command fails, paste the full error and ask for the exact next command
6. Basic starter folder setup (optional).
7. Optional profile import.
8. Pair with GitHub.
9. Glossary.
10. Done.

## Session note (2026-02-27)

- Pages 3-6 were initially collapsed into one install page.
- Then restart-terminal guidance was split into its own separate step before agent install.
- Windows fast path uses one `winget` command for editor + Git + Node.
- Mac fast path remains a short two-command path (`xcode-select` then `brew`).

If commands fail, paste the full terminal error into ChatGPT/Claude first.

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

## Starter-pack explainer text

Use this on download pages/docs:

`This is a starter pack, not a locked system. You can use it as-is, copy only parts of it, or start a brand-new folder anytime.`

## Publishing the installer

The March 2026 deployment note is superseded by the verified domain transfer on 26 October 2026.

- The only publishing repository is `davidchivers/davidchivers.co.uk`, branch `main`; installer files publish from its `ai_install/` directory.
- This folder is a source snapshot, not a separate publishing destination. Compare it with the current website files before copying changes so that newer content is preserved.
- Read `_shared/memory/WEBSITE_PUBLISHING.md` and the website repository's `AGENTS.md` and `SITE_MAP.md` before publication. Do not use the retired mirror repository or the unrelated `davidchivers/davidchivers` repository.
- Use a scoped feature branch and pull request. After merging, require the public-domain verification to pass for that exact `main` commit and inspect `https://davidchivers.co.uk/ai_install/` and any changed assets.
- The laptop website checkout is `C:\Users\Dave_\AI\other\davidchivers_website`; the desktop checkout is `E:\AI\other\davidchivers_site`. Check the actual Git remote and preserve existing changes before editing.
