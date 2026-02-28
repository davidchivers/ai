# GitHub Setup Checklist (Data Lab)

## 1) Create the private repository

1. In GitHub, click `New repository`.
2. Repository name: `data-lab` (or your preferred name).
3. Visibility: `Private`.
4. Do not add a README if this local repo already exists.
5. Click `Create repository`.

## 2) Connect this local folder to GitHub

Run from `/mnt/c/Users/Dave_/OneDrive/Desktop/Economics`:

```bash
git remote add origin <YOUR_GITHUB_REPO_URL>
git branch -M main
git push -u origin main
```

If `origin` already exists:

```bash
git remote set-url origin <YOUR_GITHUB_REPO_URL>
git push -u origin main
```

## 3) Add collaborators (3-4 people)

1. Go to `Settings` -> `Collaborators and teams`.
2. Click `Add people`.
3. Invite each collaborator with `Write` access.

## 4) Protect `main` branch

1. Go to `Settings` -> `Branches`.
2. Click `Add branch protection rule`.
3. Branch name pattern: `main`.
4. Enable:
   - `Require a pull request before merging`
   - `Require approvals` = `1`
   - `Dismiss stale pull request approvals when new commits are pushed` (recommended)
   - `Require conversation resolution before merging` (recommended)
5. Enable `Do not allow bypassing the above settings` (if available).
6. Save changes.

## 5) Team branch naming

Use one branch per task:

- `david/<task>`
- `johnpaul/<task>`
- `demid/<task>`

Examples:

- `david/mission-statement-revision`
- `johnpaul/website-offer-page`
- `demid/pilot-course-outline`

## 6) Daily workflow (safe collaboration)

```bash
git checkout main
git pull origin main
git checkout -b david/<task>
# work with Codex
git add .
git commit -m "area: why this change matters"
git push -u origin david/<task>
```

Then open PR in GitHub, request 1 review, merge to `main`.

## 7) Avoid editing over each other

- Never commit directly to `main`.
- If two people need the same file, coordinate before opening PRs.
- Keep active drafts in `projects/data_lab/09_shared_workspace/`.
- Move approved files to `projects/data_lab/10_final_outputs/`.

## 8) OneDrive + GitHub together

- Keep using your local folder under `projects/` (as now).
- GitHub is the collaboration source of truth.
- OneDrive is fine for sync/backup, but do not rely on it for version control or conflict handling.

## 9) Optional quality guardrails (recommended)

1. Add a `CODEOWNERS` file later if you want automatic reviewers.
2. Add a PR template with 3 checks:
   - scope clear
   - files in correct folders
   - no accidental generated artifacts
