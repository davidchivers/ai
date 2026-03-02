# UK Policy Notes (verified, England-focused)

Scope note: This file summarizes England undergraduate tuition/loan rules relevant to the project, using official sources checked on 2026-02-23.

## Institutional facts (verified)

### 1) Tuition fee cap and typical charged fee
- For academic year 2025/26 (from 1 August 2025), maximum tuition fees at approved (fee-cap) providers with TEF and APP are:
  - `GBP 9,535` (standard full-time)
  - `GBP 11,440` (accelerated full-time)
  - `GBP 7,145` (part-time)
- Prior cap level referenced by government release: `GBP 9,250` before the 2025/26 uplift.
- `[INFERENCE]` For baseline calibration of a standard full-time undergraduate in England, setting annual tuition `F = 9,535` is a policy-consistent benchmark for 2025/26.

### 2) Repayment thresholds by cohort/plan (current published thresholds)
- Current yearly thresholds shown in GOV.UK repayment guidance:
  - Plan 2: `GBP 28,470`
  - Plan 5: `GBP 25,000`
- Plan 2 cohort definition (terms and conditions): undergraduate starters between `1 September 2012` and `31 July 2023`.
- Plan 5 cohort definition (terms and conditions): new plan for starters on/after `1 August 2023`.

### 3) Repayment rate above threshold
- Both Plan 2 and Plan 5 repay `9%` of income above threshold.

### 4) Interest rate formula
- Plan 2: interest is RPI-based and income-contingent after study; while studying, normally `RPI + 3%`.
- Plan 5: interest normally set at `RPI` only.

### 5) Write-off rules
- Plan 2: outstanding balance cancelled `30 years` after repayments become due.
- Plan 5: outstanding balance cancelled `40 years` after repayments become due.

### 6) Evidence on upfront family payment vs borrowing
- SLC reports `7.3%` of full-time loan borrowers in 2024/25 took only a Tuition Fee Loan and no Maintenance Loan.
- SLC also states it can no longer publish estimated tuition-fee-loan take-up against the eligible population (data-series change from November 2025).
- `[INFERENCE]` Direct measurement of "paid tuition upfront with no tuition loan" is not published in this series; model scenarios for upfront payment should be treated as assumptions and sensitivity-tested.

## Model mapping implications (for v0)
- The project objective references a "post-2012" regime. In current policy terms, this spans two different cohorts:
  - Plan 2 (2012-2023 starters): threshold 28,470, variable RPI-to-RPI+3%, 30-year write-off.
  - Plan 5 (2023+ starters): threshold 25,000, RPI interest, 40-year write-off.
- `[INFERENCE]` For a single baseline regime, choose one cohort explicitly (Plan 2 legacy or Plan 5 current) and run the other as a robustness scenario.

## Source log (verified links)
1. GOV.UK, "Changes to tuition fees: 2025 to 2026 academic year" (updated 26 November 2025):
   - https://www.gov.uk/government/publications/tuition-fees-and-student-support-2025-to-2026-academic-year/changes-to-tuition-fees-2025-to-2026-academic-year
2. GOV.UK, "Repaying your student loan: How much you repay" (accessed 2026-02-23):
   - https://www.gov.uk/repaying-your-student-loan/what-you-pay
3. GOV.UK, "Student loans: a guide to terms and conditions 2025 to 2026" (accessed 2026-02-23):
   - https://www.gov.uk/government/publications/student-loans-a-guide-to-terms-and-conditions/student-loans-a-guide-to-terms-and-conditions-2025-to-2026
4. GOV.UK / SLC statistics, "Student support for higher education in England 2025" (updated 11 December 2025):
   - https://www.gov.uk/government/statistics/student-support-for-higher-education-in-england-2025/student-support-for-higher-education-in-england-2025
5. GOV.UK / SLC statistics, "Income Contingent Student Loan repayment plans, interest rates and calculations (England)" (2024/25 release):
   - https://www.gov.uk/government/statistics/student-loans-in-england-2024-to-2025/income-contingent-student-loan-repayment-plans-interest-rates-and-calculations-england
