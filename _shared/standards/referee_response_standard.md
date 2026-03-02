# Referee Response Standard

**Template**: `_shared/templates/referee_response_template.tex`
**Best example**: `_shared/templates/referee_response_example.tex`
(copied from `research_projects/01_necessity_entrepreneurs/referee/RESPONSE_TO_REFEREE.tex`)

---

## 1. Document Structure

The response is a LaTeX article (`\documentclass[11pt]{article}`) with `1in` margins.

Sections are ordered by priority tier, matching the referee report's own structure:

1. **Critical Issues** — must be addressed before resubmission
2. **High Priority Issues** — important for correctness/clarity
3. **Medium Priority Issues** — notation, consistency, expositional
4. **Low Priority Issues** — typos, JEL codes, minor additions
5. **Additional Corrections** *(optional)* — self-initiated fixes not in the referee report
6. **Code–Paper Crosswalk** *(optional)* — when a code audit accompanies the response
7. **Outstanding Items** — numbered list of items deferred or pending decisions

---

## 2. Heading Convention

Each issue gets its own `\subsection*{}` heading:

```latex
\subsection*{Issue N: Short plain-English description}
```

- **Issue numbers match the referee report exactly** — do not renumber.
- Descriptions are short (5–8 words), specific, and non-defensive.
- If a range of issues is grouped (e.g., "Issues 20–22, 25–26"), use a combined heading.

---

## 3. Status Macros

Three custom commands signal action type at the start of each response:

| Macro | Colour | Meaning |
|---|---|---|
| `\fixed` | Teal / bold `[FIXED]` | The issue has been corrected in the manuscript |
| `\added` | Blue / bold `[ADDED]` | New text or material has been added |
| `\noted` | Orange / bold `[NOTE]` | Issue acknowledged but not yet resolved (explain why) |

**Rule**: every subsection begins with exactly one of these macros. Do not mix two macros in one subsection without clear justification.

---

## 4. Corrected Equations

When a fix involves an equation:

- State the original error briefly ("Previously the equation had…").
- Display the corrected equation in a `\[ … \]` displayed block.
- If the fix affects multiple equations, list them with sub-items using `enumerate[(a)]`.

Example pattern:
```latex
\fixed{} The profit function (Eq.~6) had a missing $\alpha$ exponent.
Corrected equation:
\[
  \nu(k,x) = (1-\gamma)\bigl[\cdots\bigr]^{\frac{\gamma}{1-\gamma}}(xk^\alpha)^{\frac{1}{1-\gamma}} - rk.
\]
```

---

## 5. Typo Tables

Collect all minor textual corrections in a single `tabular` table under a `\fixed{}` heading:

```latex
\begin{center}
\begin{tabular}{ll}
\hline\hline
\textbf{Was} & \textbf{Now} \\
\hline
[old spelling] & [corrected spelling] \\
\hline\hline
\end{tabular}
\end{center}
```

---

## 6. Deferred Items (`\noted`)

When an issue is not addressed in the current round:

- Say so explicitly: "Not addressed in this round."
- Give a concrete reason (e.g., "requires co-author input", "needs code verification").
- Add it to the **Outstanding Items** section with a named owner.

---

## 7. Code–Paper Crosswalk (when applicable)

If a code audit is conducted alongside the referee response, append an optional section:

- `\subsection*{Confirmed matches}` — bullet list of things that agree.
- `\subsubsection*{D[N]: Description — STATUS}` — each discrepancy, with:
  - `\textbf{Paper}:` what the paper says
  - `\textbf{Code}:` what the code does
  - Status label: e.g., `--- FIXED`, `--- NEEDS DECISION`

Discrepancies that affect results are flagged explicitly with a call to action.

---

## 8. Outstanding Items Section

Close the document with a numbered list of every unresolved item:

```latex
\section*{Outstanding Items}
\begin{enumerate}
    \item \textbf{[Issue/Discrepancy label]}: [What must be done, who decides.]
\end{enumerate}
```

This list is the working to-do for the next revision session.

---

## 9. Title and Metadata

```latex
\title{Response to Referee Report\\[6pt]
\large [Authors] ``[Paper Title]''}
\author{}   % leave blank
\date{[Month Year]}
```

Author field is left blank. Date uses month + year (e.g., `February 2026`).

---

## 10. File Naming

Store in the project's `referee/` subdirectory:

```
research_projects/<project>/referee/RESPONSE_TO_REFEREE.tex
research_projects/<project>/referee/RESPONSE_TO_REFEREE.pdf   ← compiled output
```

Build artifacts (`.aux`, `.log`, `.out`) should not be committed.

