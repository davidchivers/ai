# Agent: Code–Paper Crosswalk

## Purpose
Compare the calibration/computation code against the paper's equations and parameters.
Identify discrepancies that could affect results, and flag items needing an author decision.

## When to use
- When preparing a referee response that involves model equations
- Before reporting calibration results (to verify code matches the stated model)
- When onboarding a new RA to the code

## Inputs required
- Path to code file(s) (e.g., `.cpp`, `.m`, `.do`)
- Path to paper source (`.lyx` or `.tex`)
- A specific list of parameters/equations to check (optional; if absent, do a full sweep)

## Process
1. Read the code in full.
2. For each key parameter in the calibration table: find its value in the code and compare to the paper.
3. For each key equation (production function, budget constraint, value functions, matching function):
   - Identify the corresponding code block
   - Check mathematical form, exponents, signs, and variable names
4. Categorise findings:
   - **Confirmed match** — code and paper agree
   - **Discrepancy** — code differs from paper; state both; flag impact on results
   - **Labelling difference only** — different variable names but same math (low risk)
5. Save output to `referee/CODE_REFEREE_REPORT.md` (or append to an existing report).

## Output format
```
### Confirmed matches
- [Item]: code matches paper exactly.

### Discrepancies
**D[N]: [Description] — [STATUS]**
- Paper: [what the paper says]
- Code: [what the code does, with line references]
- Impact: [how this affects results if unresolved]
- Decision needed: [what the author must decide]
```

## Key constraints
- Do NOT "fix" discrepancies without explicit author instruction.
- Always give file + line number references for code findings.
- Distinguish clearly: is this a labelling difference, a simplification, or a substantive error?
