# 06 Self-employment targets

## Purpose

This note sets out empirical targets for the self-employment version of the model.
The immediate question is whether the new baseline is in the right ballpark before
we treat it as the main model.

Current self-employment baseline (`case 141`, `UI=0.40`, `MaxIterAgg=40`, `RngSeed=12345`)
implies:

- entrepreneur share among all households: `0.38345`
- self-employed share among entrepreneurs: `0.61307`
- employer share among entrepreneurs: `0.38693`

So the model currently implies:

- self-employed share among all households: `0.38345 * 0.61307 = 0.2351`
- employer share among all households: `0.38345 * 0.38693 = 0.1484`

Those are the objects that need discipline.

## Recommended mapping

The cleanest empirical mapping is:

- model `self-employed` = owner-worker with no paid employees
- model `employer entrepreneur` = business owner with paid employees
- model `entrepreneur` = self-employed + employer entrepreneur

Under that mapping, the most useful external benchmarks are:

1. person-based self-employment shares from BLS CPS
2. business-count employer vs nonemployer shares from Census
3. older BLS evidence on the fraction of self-employed who have paid employees

## Official data points

### 1. BLS CPS annual averages, 2024: unincorporated self-employment

From BLS annual averages table 12:

- total employed persons in 2024: `161.346` million
- unincorporated self-employed in agriculture: `0.661` million
- unincorporated self-employed in nonagriculture: `9.259` million
- total unincorporated self-employed: `9.920` million

This implies:

- unincorporated self-employed share among employed:
  `9.920 / 161.346 = 0.0615`

Interpretation:

- if the model's self-employed state is meant to capture the unincorporated owner-worker
  margin, then `6.1%` is the cleanest person-based target.

Source:

- BLS CPS annual averages table 12:
  https://www.bls.gov/cps/aa2025/cpsaat12.htm

Important measurement note:

- in these annual class-of-worker tables, incorporated self-employed are classified with
  wage and salary workers, so the annual table gives a direct benchmark for the
  unincorporated margin, not total broad self-employment.

### 2. BLS CPS monthly table A-9, January 2026: broad self-employment cross-check

Latest monthly BLS table A-9 reports:

- incorporated self-employed: `6.896` million
- unincorporated self-employed: `9.647` million
- total self-employed: `16.543` million
- total employed: `163.090` million

This implies:

- total self-employment share among employed: `16.543 / 163.090 = 0.1014`
- incorporated self-employment share among employed: `0.0423`
- unincorporated self-employment share among employed: `0.0592`
- composition within self-employment:
  - incorporated: `41.7%`
  - unincorporated: `58.3%`

Interpretation:

- broad U.S. self-employment is currently around `10%` of employment
- the split between incorporated and unincorporated is roughly `42/58`
- this is a useful cross-check for a broad entrepreneurship target, even though it is
  a monthly rather than annual observation

Source:

- BLS Employment Situation, table A-9:
  https://www.bls.gov/news.release/empsit.t09.htm

### 3. Census business counts, 2023: employer vs nonemployer composition

Latest Census releases imply:

- employer businesses: `21.6%`
- nonemployer businesses: `78.4%`

Interpretation:

- if each entrepreneur in the model maps to one business, most entrepreneurial units
  should be no-employee firms
- this is a business-count benchmark, not a person-count benchmark, so it should be used
  as a composition guide rather than the single main target

Sources:

- Census 2023 County Business Patterns:
  https://www.census.gov/library/stories/2025/09/counting-american-businesses.html
- Census 2023 Nonemployer Statistics:
  https://www.census.gov/library/stories/2025/07/you-dont-need-employees-to-own-a-business.html

### 4. BLS person-based employer split, annual averages 2015

BLS Spotlight on Statistics reports for 2015:

- unincorporated self-employed with paid employees: `14.3%`
- incorporated self-employed with paid employees: `42.1%`
- self-employment composition:
  - unincorporated: `63.4%`
  - incorporated: `36.6%`

Using those weights gives an approximate employer share among self-employed persons of:

- `0.634 * 0.143 + 0.366 * 0.421 = 0.2447`

So an older person-based benchmark is:

- employer share among self-employed persons: about `24.5%`
- no-employee share among self-employed persons: about `75.5%`

Interpretation:

- this is older than the CPS and Census benchmarks above
- but it is still useful because it is a direct person-based benchmark for the
  employer/nonemployer split within self-employment

Source:

- BLS Spotlight on Statistics:
  https://www.bls.gov/spotlight/2016/self-employment-in-the-united-states/

## Recommended target set

### Preferred hard targets

These are the moments I would actually target in the first recalibration:

1. self-employed share among all households/employed:
   `0.061` to `0.075`

Why this range:

- lower end = direct 2024 BLS unincorporated self-employment share (`6.1%`)
- upper end = allows for the possibility that the model's self-employed state captures
  some incorporated owner-workers as well

2. total entrepreneur share among all households/employed:
   about `0.10`

Why:

- broad current U.S. self-employment is around `10.1%` in latest BLS monthly data
- if the model's entrepreneur state includes both self-employed and employer owners,
  this is the right broad magnitude

3. employer share among entrepreneurs:
   `0.22` to `0.25`

Why this range:

- lower end = current Census employer-business share (`21.6%`)
- upper end = older BLS person-based employer share among the self-employed (`24.5%`)

### Secondary moments

After matching the three moments above, use these as auxiliary checks:

- mean hired labor among employers
- upper tail of firm size
- education composition of self-employment
- response of self-employment and employer entry to lower UI

## Comparison with the current self-employment baseline

Current model baseline implies:

- entrepreneur share among all households: `38.3%`
- self-employed share among all households: `23.5%`
- employer share among all households: `14.8%`
- employer share among entrepreneurs: `38.7%`

Against the recommended targets, the model is currently:

- too entrepreneurial overall
- too self-employed overall
- too employer-heavy within entrepreneurship

That last point matters. The current baseline does create many one-person firms, but not
enough relative to the total number of entrepreneurs it creates.

## Calibration sequence

I would recalibrate in this order:

1. bring down total entrepreneurial entry
2. then adjust the employer/nonemployer split
3. only then return to policy experiments

Concretely:

1. Lower broad entrepreneurship

- use a common entrepreneurial fixed cost or utility shifter
- if needed, lower owner-labor productivity in self-employment

2. Shift composition toward no-employee firms

- add or raise a fixed cost of hiring `f_h`
- raise effective hiring frictions
- reduce the relative productivity of hired labor if needed

3. Recheck baseline moments

- entrepreneur share
- self-employed share
- employer share among entrepreneurs

4. Only after baseline is disciplined, rerun:

- `UI=0.40`
- `UI=0.05`
- `UI=0.00`

## Practical recommendation

For the first recalibration pass, I would treat these as the targets:

- target entrepreneur share: `10%`
- target self-employed/no-employee share among entrepreneurs: `75%`
- target employer share among entrepreneurs: `25%`

That is simple, easy to communicate, and tightly connected to the official BLS and Census
evidence above.
