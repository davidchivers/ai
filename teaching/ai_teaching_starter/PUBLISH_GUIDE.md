# Publish guide (starter ZIPs)

Historical note:

- The old standalone repo `davidchivers/ai_install` has been deleted.
- Do not follow the old branch-based publish flow unless a new dedicated distribution repo is created on purpose.
- Starter ZIP downloads are now static website assets published from `other/davidchivers_site/ai_install/downloads/`.

Use `teaching/install_ai/REPO_MAP.md` as the canonical repo-location reference.

## Current source folders

1. Edit local source folders in this workspace:
   - `teaching/ai_teaching_starter/starter_basic/`
   - `teaching/ai_teaching_starter/starter_advanced/`
2. Before publishing, open each root `README.md` and make sure the handover text still matches what you want workshop participants to see first.
3. Rebuild:
   - `other/davidchivers_site/ai_install/downloads/starter_basic.zip`
   - `other/davidchivers_site/ai_install/downloads/starter_advanced.zip`
4. Keep the website links in `teaching/install_ai/website/app.js` pointed at `downloads/starter_basic.zip` and `downloads/starter_advanced.zip`.
