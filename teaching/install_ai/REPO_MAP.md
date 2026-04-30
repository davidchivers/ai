# Repo Map For Website And Starter Packs

This file is the canonical repo-location reference for the installer website, starter ZIPs, and related public assets.

## Canonical ownership

- `C:\Users\Dave_\AI` is the local research and teaching workspace.
- The main GitHub repo for this workspace is `davidchivers/ai`.
- The public personal website source repo is `davidchivers/davidchivers.co.uk`.
- If the installer stays at `https://davidchivers.co.uk/ai_install/`, the website files should live in that repo under `/ai_install/`.
- There is currently no standalone `davidchivers/ai_install` distribution repo. That repo has been deleted.
- `thomshutt/davidchivers` is still a temporary GitHub Pages bridge until the custom domain is unpaired from it.
- Do not treat the `thomshutt/davidchivers` bridge or any deleted standalone repo as deployment authority.

## What this workspace owns

- `other/davidchivers_site/`
  Local checkout of the personal website repo for publishing public pages such as `/email_app/`.
- `teaching/install_ai/website/`
  Local source snapshot for the installer website pages and browser logic.
- `teaching/ai_teaching_starter/starter_basic/`
  Source folder for the `starter_basic` teaching starter contents.
- `teaching/ai_teaching_starter/starter_advanced/`
  Source folder for the `starter_advanced` teaching starter contents.
- `other/davidchivers_site/ai_install/downloads/`
  Published static ZIP downloads generated from the starter-pack source folders.
- `teaching/ai_workshop/ai_coding_agents_workshop_slides.pptx`
  Local source file for the workshop slides before they are copied into a public delivery location.
- `other/email_app/`
  Workflow pack that can be published later, but it should publish via the personal website repo rather than from this workspace.

## Decision rules

- If you are editing the public installer page, update `teaching/install_ai/website/` here and then sync the website output to `other/davidchivers_site/` before pushing `davidchivers/davidchivers.co.uk`.
- If you are editing another public website section such as `/email_app/`, update the source folder here and then sync the publishable files to `other/davidchivers_site/` before pushing.
- If you are editing the starter-pack source folders, update the matching `teaching/ai_teaching_starter/` folder here first. Do not assume a standalone GitHub distribution repo exists.
- If you are refreshing starter ZIP downloads, rebuild `starter_basic.zip` and `starter_advanced.zip` from the matching source folders and publish them under `other/davidchivers_site/ai_install/downloads/`.
- If you need a hotfix before the website migration is complete, verify the actual live repo first instead of assuming the legacy repo is still authoritative.
- If repo ownership changes again, update this file first and then update any local docs that reference it.

## Transition status

- Active repos:
  - Workspace repo: `davidchivers/ai`
  - Public website repo: `davidchivers/davidchivers.co.uk`
- Temporary bridge during Pages migration:
  - `thomshutt/davidchivers`
- Deleted standalone repos:
  - `davidchivers/ai_install`
  - `davidchivers/stuff`
  - `davidchivers/uncertainty`
