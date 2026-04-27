# Stantcheva regression summary

## Source

Aggregate output inspected:

```text
C:\Users\Dave_\Dropbox\exposure_attitudes\code\output\Regressions_stantcheva_etal26_expseg.xlsx
```

No underlying survey data were opened.

## Regression design

The workbook contains modified Table 4-style regressions using:

- respondent current-county exposure
- respondent ages 10-19 exposure
- respondent lifetime exposure, variant 1
- parents' grow-up exposure

Each regression includes three focal variables:

- exposure segregation
- income residential segregation
- racial residential segregation

The three columns progressively add immigrant-generation controls:

1. baseline controls and fixed effects
2. add child-of-immigrant control
3. add grandchild-of-immigrant control

Controls and fixed effects include demographic controls, wave fixed effects, state fixed effects, race fixed effects, and the Table 4-style control set in `con_stantcheva_etal2026_expseg_regressions.do`.

These are associations, not causal estimates.

## Main pattern

The strongest and most consistent signal is for respondent exposure segregation in the county where the respondent grew up between ages 10 and 19.

The broad pattern is:

- higher ages-10-19 exposure segregation is associated with lower pro-redistribution attitudes
- higher ages-10-19 exposure segregation is associated with lower probability of donation
- higher ages-10-19 exposure segregation is weakly associated with lower donation amount
- current-county exposure and lifetime exposure have less stable patterns
- parental exposure segregation is mostly weak, except for a positive association with "luck more important than effort"
- generalized trust shows no clear relationship with exposure segregation
- racial residential segregation is generally not the main signal in these tables
- income residential segregation appears in some race-attitudes and zero-sum-information specifications, but interpretation depends on outcome coding

## Significant exposure-segregation findings

### Pro-redistribution index

Respondent ages 10-19 exposure segregation is negative and significant in all three columns:

- about `-0.54`, `-0.52`, and `-0.48`

Income residential segregation for ages 10-19 is positive and significant in the same table.

Interpretation: respondents who grew up in counties with higher exposure segregation are less pro-redistribution, conditional on income and racial residential segregation and controls.

### Luck more important than effort

Parents' grow-up exposure segregation is positive and significant in all three columns:

- about `0.24` to `0.25`

Respondent ages 10-19 exposure is positive only in the first column and loses significance after adding immigrant-generation controls.

Interpretation: parental-location exposure segregation has some association with beliefs that luck matters more than effort, but this needs careful interpretation.

### Petition support

The evidence is weak.

- ages 10-19 exposure is negative and marginal only in column 3
- lifetime exposure is negative and significant in columns 1 and 2, but not column 3

Samples for this outcome are much smaller than for the main attitude indices.

### Donation outcomes

Donation participation:

- current-county exposure segregation is negative and marginally significant in all three columns, but the sample is small
- ages 10-19 exposure segregation is negative and significant in all three columns, around `-0.33`

Donation amount:

- current-county exposure segregation is negative and significant in all three columns, but the sample is small
- ages 10-19 exposure segregation is negative and marginally significant in columns 2 and 3

Interpretation: the donation outcomes line up with the idea that higher exposure segregation is associated with lower pro-social giving, especially for age-10-19 exposure.

## Non-results and weaker patterns

### Generalized trust

No exposure-segregation coefficient is significant across current, ages 10-19, lifetime, or parental exposure definitions.

### Race attitudes index

Exposure segregation is not significant.

Income residential segregation is positive and significant in:

- current-county exposure specifications, columns 1 and 2
- ages 10-19 specifications, all columns

The substantive interpretation depends on the coding direction of `race_index_z`.

### Correct on incentivized zero-sum question

Exposure segregation is not significant.

Parental income residential segregation is negative and significant in all three columns. This is a residential-segregation result, not an exposure-segregation result.

## Caveats

- The coefficients are on the raw exposure-segregation scale, not standardized effects. Standardized tables would be easier to interpret.
- Several outcomes have much smaller samples in the current-county and lifetime specifications.
- These regressions are not instrumented and should be described as conditional associations.
- The current-county and lifetime exposure constructions depend on inferred location histories and may have more measurement error.
- The workbook does not currently populate dependent-variable and regressor standard-deviation rows, which limits quick effect-size interpretation.

## Bottom line

The most promising Stantcheva result is the ages-10-19 exposure-segregation association with pro-redistribution and donation outcomes. The result is consistent with the idea that growing up in more segregated activity-space environments is associated with weaker pro-social or redistributive attitudes later, but the evidence should be treated as descriptive unless a stronger identification strategy is added.
