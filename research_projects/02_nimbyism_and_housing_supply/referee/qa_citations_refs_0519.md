# Citation/reference QA - May 19, 2026

Scope: citation/reference/source consistency only. No manuscript files edited.

Canonical source audited:
`C:\Users\Dave_\Dropbox\Zac and David\2026_May_Submission\Gross and Chivers (2025) NIMBYism and the Housing Supply.tex`

Mirror check: the Dropbox TeX and LyX hashes match the mirror files in
`C:\Users\Dave_\AI\research_projects\02_nimbyism_and_housing_supply`.

## Clean checks

- `\paperlink{...}{...}` targets: all 59 `\paperlink` keys have matching `\bibtarget` labels.
- Duplicate reference targets: no duplicate `\bibtarget` keys found.
- Duplicate reference heads: no exact duplicate author/year reference heads found.
- Compile log: no undefined `ref:` link warnings found in the current `.log`/`.aux`.

## Findings and proposed fixes

1. Missing reference and author spelling error: `Gyourko and Malloy 2015`

- Source line 322: `localities (Gyourko and Malloy 2015).`
- Reference list: no Gyourko/Malloy or Gyourko/Molloy reference target.
- Problem: "Malloy" should be "Molloy". Local literature contains `Gyourko and Molloy 2014 Regulation and Housing supply.pdf`; NBER working paper metadata gives Joseph Gyourko and Raven Molloy, NBER WP 20536, October 2014. RePEc also lists a 2015 Handbook version.
- Proposed fix: change line 322 to `\paperlink{gyourko_molloy2015}{Gyourko and Molloy (2015)}` if citing the final Handbook chapter, and add the matching `\bibtarget`. If citing the local NBER PDF, use 2014 instead.

2. Fischel homevoter year/link mismatch

- Source line 155: `\paperlink{fischel2002}{Fischel (2002)}`
- Source line 372: `(\paperlink{fischel1999}{Fischel 1999}, 2001).`
- Reference lines 1336-1338: `\bibtarget{fischel2002}{Fischel, W. A. (2002).} The homevoter hypothesis... Cambridge, MA: Harvard University Press.`
- Problem: line 372 claims a 2001 homevoter source, but the reference target is keyed/listed as 2002. Targeted spot checks indicate the Harvard University Press book is 2001. If line 155 is intended to cite the zoning-history article, the local PDF is the Urban Studies article published in 2004, not this book entry.
- Proposed fix: either change the book target to `fischel2001` and cite it consistently as `Fischel (2001)`, or add a separate Fischel zoning-history article entry for line 155 and reserve the homevoter book for line 372.

3. Missing `Kogan et al. 2018` reference

- Source lines 375-376: `elections which in general tend to be from these two groups (Kogan` / `et al. 2018, \paperlink{oliver_ha2007}{Oliver and Ha 2007}).`
- Reference list: no Kogan reference target.
- Proposed fix: add a `\paperlink` and reference entry for the intended paper. Likely candidate from targeted check: Kogan, Lavertu, and Peskowitz (2018), "Election Timing, Electorate Composition, and Policy Outcomes: Evidence from School Districts," American Journal of Political Science, 62(3), 637-651.

4. Missing Diaz/Luengo-Prado reference and likely author-display correction

- Source line 930: `period's non-transitory income, based on D\'iaz et al. (2008).`
- Reference list: no Diaz reference target.
- Problem: the likely housing life-cycle calibration source is Diaz and Luengo-Prado (2008), not "Diaz et al."
- Proposed fix: change the text to `\paperlink{diaz_luengo_prado2008}{D\'iaz and Luengo-Prado (2008)}` and add the full reference entry, if that is the intended source.

5. LTV source inconsistency: Greenwald vs. Guerrieri and Iacoviello

- Source line 932: `The maximum loan-to-value (LTV) is set at 0.9 in line with \paperlink{greenwald2018}{Greenwald (2018)}.`
- Source line 955: `$m$ & 0.9 & Maximum LTV & Guerrieri and Iacoviello (2017)\tabularnewline`
- Reference list: Greenwald (2018) exists at lines 1349-1351; Guerrieri and Iacoviello (2017) is not in the reference list.
- Problem: the same parameter has two different stated sources, one of which has no reference target.
- Proposed fix: choose one provenance. If Greenwald is intended, change the table source on line 955 to `\paperlink{greenwald2018}{Greenwald (2018)}`. If Guerrieri and Iacoviello is intended, change line 932 and add the full reference.

6. Missing/uncertain `Mian et al. 2017` source for rental discount

- Source line 961: `$\theta^{rent}$ & 0.9 & Rental discount & Mian et al (2017)\tabularnewline`
- Reference list: no Mian reference target.
- Problem: targeted checks found standard Mian, Sufi, and Verner (2017) citations, but not an obvious source for a rental-utility discount of 0.9. This should not be added mechanically without verifying the intended calibration source.
- Proposed fix: verify the exact source for `\theta^{rent}=0.9`, then add a `\paperlink` and reference entry. If no source supports it, replace the table source with `Internally calibrated` or the correct calibration source.

7. Figure data-source labels are incomplete relative to the reference list

- Source line 255: `Data source: CPS (2022).`
- Source line 263: `Data source: CPS (2022).`
- Source lines 298-299: `Data source: UN (2019). Note: dashed line indicates population` / `forecasts from 2020 onward assuming medium immigration.`
- Reference list: no CPS or UN data-source entries.
- Proposed fix: either add full source details in the captions/figure notes, or add reference entries for the exact CPS extract and UN projection used.

8. Incomplete Bunten reference text

- Reference lines 1301-1302: `\bibtarget{bunten2017}{Bunten, D. (2017).} Is the rent too high? Aggregate implications of` / `local land-use regulation.`
- Problem: the entry lacks venue/series details.
- Proposed fix: complete as Finance and Economics Discussion Series 2017-064, Board of Governors of the Federal Reserve System, with DOI `10.17016/FEDS.2017.064`, if this is the intended version.

9. Incomplete Frieden reference text

- Reference line 1340: `\bibtarget{frieden1979}{Frieden, B. J. (1979).} Environmental protection hustle. United States.`
- Problem: `United States.` is malformed/incomplete reference text.
- Proposed fix: complete as `The Environmental Protection Hustle. Cambridge, MA: MIT Press.`

10. Double punctuation in Li reference

- Reference lines 1403-1404: `\bibtarget{li2022}{Li, X. (2022).} Do new housing units in your backyard raise your rents?.` / `Journal of Economic Geography, 22(6), 1309-1352.`
- Problem: title ends `?.`
- Proposed fix: remove the extra period after the question mark.

11. Malformed Mumtaz-Sustek year punctuation

- Reference lines 1421-1422: `\bibtarget{mumtaz_sustek2023}{Mumtaz, H. and \v{S}ustek, R., 2023.} Global house prices since 1950. Working` / `Paper.`
- Problem: this breaks the surrounding author-year format.
- Proposed fix: change to `Mumtaz, H. and \v{S}ustek, R. (2023). Global house prices since 1950. Working Paper.`

12. Author capitalization in Turner et al. reference

- Reference line 1456: `\bibtarget{turner_etal2014}{Turner, M. A., Haughwout, A., \& Van Der Klaauw, W. (2014).} Land use`
- Problem: the author's surname is conventionally styled `van der Klaauw`, not `Van Der Klaauw`.
- Proposed fix: change to `Turner, M. A., Haughwout, A., \& van der Klaauw, W. (2014).`

## External spot-check links used

- Fischel book year: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=294711
- Gyourko and Molloy metadata: https://ideas.repec.org/p/nbr/nberwo/20536.html
- Kogan/Lavertu/Peskowitz metadata: https://ideas.repec.org/a/wly/amposc/v62y2018i3p637-651.html
- Diaz and Luengo-Prado metadata: https://e-archivo.uc3m.es/entities/publication/304cd7e6-2f66-483a-a67b-baab46f93ebc
- Guerrieri and Iacoviello metadata: https://ideas.repec.org/a/eee/moneco/v90y2017icp28-49.html
- Bunten reference details: https://www.federalreserve.gov/econres/feds/files/2017064pap.pdf
- Frieden publisher details: https://mitpress.mit.edu/9780262060684/the-environmental-protection-hustle/
- Turner/Haughwout/van der Klaauw metadata: https://www.econometricsociety.org/publications/econometrica/2014/07/01/land-use-regulation-and-welfare
