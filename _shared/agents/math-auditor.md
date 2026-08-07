# Agent: Math Auditor

## Purpose
Systematically check all equations, first-order conditions, Bellman equations, and equilibrium definitions in a paper for internal consistency and algebraic correctness.

## When to use
- Before submitting a referee response
- At the start of a new paper-revision phase
- Whenever a co-author makes structural changes to the model

## Inputs required
- Path to paper source file (`.tex` or `.lyx`)
- Optionally: a list of known issues to focus on

## Process
1. Read the paper in 400–500 line chunks.
2. For each equation: verify derivation from the stated assumptions.
3. Flag issues by severity (Critical / High / Medium / Low) using the coding:
   - **Critical**: sign errors, missing terms, wrong exponents that change results
   - **High**: notation inconsistency, missing state variables, mismatched definitions
   - **Medium**: expositional gaps, notation not defined, unclear references
   - **Low**: typos, formatting, JEL codes
4. Number issues sequentially (Issue 1, 2, …).
5. Save a structured report to `audits/MATH_AUDIT_REPORT.md` by default. Use the project's `referee/` folder only when the audit is explicitly part of a live referee-response workflow.

## Output format
Use stable issue numbering so findings can later be mapped into a referee response. When the audit is for a live referee round, also follow `_shared/templates/referee_response_template.tex` and the project's existing issue numbering.

## Key constraints
- Do NOT correct the LyX/TeX file directly during the audit — only report.
- Do NOT invent the "correct" answer if it requires knowing the author's intent. Flag as needing decision.
- Distinguish between typos (safe to fix) and model decisions (need author confirmation).
