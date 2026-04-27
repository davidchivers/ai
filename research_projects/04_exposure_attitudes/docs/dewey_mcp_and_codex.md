# Dewey MCP and Codex

This note records the cautious operating setup for using Dewey with Codex.

Last checked against Dewey documentation: 2026-04-25.

## Safe default

Use Codex for Dewey metadata and code, not raw rows.

Codex may help with:

- searching for relevant datasets
- comparing dataset metadata
- reading schemas and column descriptions
- writing download or query scripts
- debugging local scripts from error messages
- interpreting aggregate results

Codex should not:

- fetch raw row samples
- display raw Dewey data
- receive pasted extracts
- process downloaded datasets inside chat context
- store API keys in config files committed to Git

## MCP tools

Dewey's MCP guide says the MCP server exposes tools for:

- search and discovery
- dataset details and schemas
- access and sampling

The low-risk tools are metadata-oriented, such as dataset search, schema lookup, related datasets, and download metadata.

The high-risk tool is row sampling. In this repo, sampling raw Dewey rows through AI assistants is blocked by default.

## API keys

Use the `DEWEY_API_KEY` environment variable.

Do not put keys in:

- committed config files
- Markdown notes
- notebooks
- screenshots
- chat messages

Keep `.env.example` as the template and keep `.env` local.

## Local workflow

Preferred workflow:

1. Use Codex or Dewey metadata tools to identify datasets and schemas.
2. Write local scripts that download or query data into ignored folders.
3. Run raw-data analysis locally.
4. Bring only aggregate, non-reconstructable results back into the repo or assistant.

## Source links

- [Dewey MCP setup and usage guide](https://docs.deweydata.io/docs/dewey-mcp-setup-usage-guide)
- [Dewey subscription terms](https://docs.deweydata.io/docs/subscription-terms)
- [Access options](https://docs.deweydata.io/docs/data-access-options)
- [Quickstart: Dewey Client](https://docs.deweydata.io/docs/dewey-client)
- [Using DuckDB with Dewey](https://docs.deweydata.io/docs/using-duckdb-with-dewey)
