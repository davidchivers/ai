# Data policy

Last checked against Dewey documentation: 2026-04-26.

This is an operating policy for this repository, not legal advice. If Dewey, Durham, a funder, a journal, or a data provider gives stricter instructions, use the stricter rule.

## Core rule

Do not commit raw Dewey data, row-level samples, extracts, credentials, or reconstructable proprietary outputs to this repository.

The repo should contain code and documentation. The data should live in local folders that are ignored by Git or in approved secure storage.

## Allowed in this repo

- code that accesses Dewey data locally
- documentation of the workflow
- Dewey dataset names, slugs, schemas, and DOI links when not restricted by provider terms
- codebooks and variable dictionaries
- synthetic examples
- aggregate statistics that cannot reveal raw rows
- figures based on sufficiently aggregated results
- model outputs, coefficients, and trained parameters, where they do not reveal raw data
- notebooks only if they contain no raw rows or outputs that reveal raw rows

## Not allowed in this repo

- downloaded Dewey files
- `.csv`, `.tsv`, `.parquet`, `.dta`, `.xlsx`, `.duckdb`, `.sqlite`, `.zip`, or similar files containing data
- row-level samples, even if anonymized, unless Dewey has explicitly approved the exact sharing
- screenshots of raw data
- logs that print rows or quasi-identifiers
- API keys, tokens, cookies, or credentials
- `.env` files
- provider documents that are not licensed for redistribution
- outputs that let someone rebuild or closely approximate the original data

## AI assistant rule

Do not paste or upload raw Dewey data into Codex, ChatGPT, Claude, Gemini, or any similar assistant by default.

The safe default is:

1. use AI for metadata, schemas, code, and aggregate results
2. run raw-data work locally
3. keep local data paths out of Git
4. share only non-reconstructable aggregates back into the assistant

Dewey's current subscription guidance says Type 1 LLMs that retain user-provided data are not permitted for sharing Dewey datasets to manage, process, or analyze data. The repo therefore treats raw data in AI context as blocked unless written permission or an approved institutional setup changes that rule.

## Dewey-specific operating notes

Dewey documentation says:

- Dewey data is licensed, not sold.
- Raw data may not be shared, distributed, or published to third parties.
- Only authorized users covered by the license may access or use the data.
- Publications and presentations must attribute the original provider and Dewey.
- External collaborator access depends on the subscription and Dewey project role.
- Project status matters for post-term use.
- Code and processing logic can be shared if they do not include, expose, or reconstruct raw data.

The repo should preserve a replication path by sharing code and instructions while directing replicators to Dewey for licensed access to the raw data.

## Local data paths

Use local ignored folders such as:

```text
data/
raw/
processed/
downloads/
local_data/
scratch/
```

These paths are ignored by `.gitignore`. Before writing scripts that create data, confirm the output path is ignored.

## Secrets

Store secrets outside Git.

Use environment variables such as:

```text
DEWEY_API_KEY
DEWEY_PROJECT_ID
```

Keep `.env.example` in the repo as a template. Never commit `.env`.

## If someone accidentally commits data

Stop work and do not push.

Then:

1. identify exactly what was committed
2. remove the file from the branch
3. rotate any exposed credentials
4. if the commit was already pushed, ask before rewriting history
5. document the incident in the relevant project `STATUS.md`

## Source links

- [Dewey subscription terms](https://docs.deweydata.io/docs/subscription-terms)
- [Post-term use and replication requirements](https://docs.deweydata.io/docs/post-term-use-replication-requirements)
- [Dewey projects](https://docs.deweydata.io/docs/projects)
- [Defining and handling PII at Dewey](https://docs.deweydata.io/docs/defining-and-handling-pii-at-dewey)
- [Dewey MCP setup and usage guide](https://docs.deweydata.io/docs/dewey-mcp-setup-usage-guide)
