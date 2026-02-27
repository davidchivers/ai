# Website wizard

Open `index.html` in Edge or Chrome.

Recommended:
1. In File Explorer, go to this folder.
2. Double-click `index.html`.

Wizard flow:
1. Choose OS.
2. Choose AI agent(s).
3. Choose editor.
4. Install Git + Node.
5. Install AI CLI(s).
6. Choose starter pack: `Basic` or `Advanced`.
7. Download starter pack + optional teaching links.
8. Optional profile import.

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
- `aiCodingOverviewUrl` (optional)

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
