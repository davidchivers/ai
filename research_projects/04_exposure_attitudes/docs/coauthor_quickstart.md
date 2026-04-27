# Coauthor quickstart

This is the plain-English guide for using `research_projects/04_exposure_attitudes` in the shared `ai` repo with Codex.

Dave is the project organizer. Eren and Diego can work independently on branches and project ideas, then share work back through pull requests.

## First rule

Do not add Dewey raw data to Git or paste raw rows into Codex.

Use Codex for code, metadata, schemas, and aggregate results.

## First time

Clone or open the shared `ai` repo from GitHub, then work inside:

```text
research_projects/04_exposure_attitudes
```

When Codex starts, say:

```text
Read the repo AGENTS.md and research_projects/04_exposure_attitudes/AGENTS.md first. Then help me work on project 04_exposure_attitudes. I am <your_name>.
```

Codex should then read:

- repo-level `AGENTS.md`
- `research_projects/04_exposure_attitudes/AGENTS.md`
- `research_projects/04_exposure_attitudes/README.md`
- `research_projects/04_exposure_attitudes/STATUS.md`
- `research_projects/04_exposure_attitudes/DATA_POLICY.md`
- `research_projects/04_exposure_attitudes/WORKSTREAMS.md`
- `research_projects/04_exposure_attitudes/workstreams/<your_name>.md`
- `research_projects/04_exposure_attitudes/docs/hamilton_workflow.md` if using Hamilton/HPC

## Normal work session

Say:

```text
Pull the latest project branch, then create a branch called <your_name>/04_exposure_attitudes/<short_task>.
```

Example:

```text
Pull the latest project branch, then create a branch called eren/04_exposure_attitudes/schema_notes.
```

Then ask Codex to do the work.

Ask Codex to log active notes in your workstream file:

```text
Keep notes for this branch in workstreams/<your_name>.md. Do not edit other people's workstream files.
```

Before sharing, say:

```text
Check that no data or secrets are included, then push this branch and prepare a pull request.
```

## If using Hamilton

Before using Hamilton, read:

```text
research_projects/04_exposure_attitudes/docs/hamilton_workflow.md
```

Use lowercase underscore names, keep large data and intermediate outputs outside Git, and run intensive jobs through Slurm rather than on login nodes.

## What "pull" means

Pull means: get the latest changes from GitHub into your local folder.

Use it before starting work and after someone else merges changes.

If you already changed files, Codex should check before pulling so your work is not overwritten.

## What "push" means

Push means: upload your committed branch to GitHub.

Pushing your branch does not put it into `main`. It makes it available for review.

## What "pull request" means

A pull request asks the team to merge your branch into `main`.

This is where coauthors review code, notes, and policy-sensitive changes.

## What to do if Codex mentions a conflict

A conflict means your branch and another branch changed the same place.

Ask Codex:

```text
Explain the conflict in plain language and show me the choices before changing anything.
```

## Good Codex prompts

```text
Read AGENTS.md and the project STATUS.md first. Then summarize the next 3 tasks.
```

```text
Create a branch for my work on this project. Use my name and a short task name.
```

```text
Update my workstream file with what I did today, but do not change the canonical STATUS.md yet.
```

```text
Prepare a STATUS.md update for Dave to review.
```

```text
Before pushing, check for raw data, secrets, and accidental large files.
```

```text
Push my branch and draft a pull request summary.
```

```text
Pull main, then update my branch with the latest changes.
```

## Bad Codex prompts

```text
Show me a few rows from the Dewey data.
```

```text
Commit this downloaded CSV.
```

```text
Put my API key in the config.
```

```text
Push straight to main.
```

If a prompt asks for raw data or secrets, Codex should stop and point back to `DATA_POLICY.md`.
