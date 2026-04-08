# Input files for structural extension runs

This folder is for local, non-committed MATLAB endpoint files used by the structural extension scripts.

Accepted inputs:

- raw legacy files:
  - `SS_iter.mat`
  - `SS_iter_boom.mat`
- or lightweight endpoint files:
  - `baseline_endpoint.mat`
  - `boom_endpoint.mat`

The automatic pipeline will:

1. look for lightweight endpoint files here first
2. if they do not exist, look for raw `SS_iter*.mat` files here
3. if raw files exist, export lightweight endpoint files automatically
4. run the structural anticipated-demographics benchmark

Expected fields in lightweight endpoint files:

- `price`
- `vote_support`

The repo-wide `.gitignore` should already prevent `.mat` files from being committed. This `README.md` is the only tracked file intended to live in this folder.
