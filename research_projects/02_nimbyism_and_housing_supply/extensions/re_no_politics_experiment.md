# RE no-politics experiment

## Purpose

This note defines a clean extension of the NIMBY model where house prices are determined in a rational-expectations equilibrium without the political voting block.

The goal is to separate two mechanisms:

1. demographic and household-demand effects on housing outcomes
2. the political endogenous-supply channel

This is useful because the current project combines both, while some existing notes/slides describe house prices as effectively unforecastable or treated with a reduced expectations shortcut.

## Core question

Can we solve a rational-expectations housing equilibrium in the NIMBY model if we shut down the political game entirely?

If yes, the next question is whether a political version with rational expectations is computationally feasible at all.

## Proposed experiment

### Baseline comparison object

Use the published NIMBY model as the benchmark object:

- same household problem
- same life-cycle structure
- same demographic shocks
- same borrowing / tenure environment

but remove the political determination of housing supply.

### Extension object

Construct a no-politics RE version with:

- no voting block
- no median-voter equilibrium condition
- no endogenous political tightening from homeowner composition
- housing supply determined by a non-political rule or market-clearing condition
- house prices determined by a rational-expectations fixed point

## Conceptual design

### Current model intuition

In the published model, demographics affect prices partly because they change the coalition of voters and therefore the supply of housing.

### No-politics RE intuition

In the extension, demographics affect prices only through demand and market clearing. Households form expectations consistent with the equilibrium price path rather than treating future price changes as random or unforecastable.

This turns the exercise into a cleaner asset-pricing / housing-market equilibrium problem.

## Minimal implementation plan

### Step 1: shut down politics

Replace the political block with a fixed supply rule or direct clearing condition.

Candidate versions:

- fixed housing stock
- exogenous supply path
- elastic non-political supply rule
- static competitive supply with zero-profit rental condition

### Step 2: impose RE on prices

Solve for a price path such that expected future prices used by households equal the realized equilibrium path.

Practical fixed-point version:

1. guess a price path
2. solve household decisions under that path
3. aggregate housing demand by period
4. update the price path from market clearing
5. iterate to convergence

### Step 3: compare against the political model

Main outputs:

- house-price path
- rent path
- ownership rates
- wealth distribution
- cohort welfare
- boom-generation versus later-generation outcomes

## Why this extension matters

This experiment answers whether the demographic mechanism alone can generate meaningful price dynamics before adding political feedback.

If the no-politics RE model already produces strong dynamics, then the political block is an amplification mechanism.

If the no-politics RE model produces weak dynamics, then the political channel is likely doing most of the work.

## Next step after this experiment

If the no-politics RE version is numerically tractable, the next step is to ask whether the full political model can also be solved under rational expectations.

That harder version would require households to forecast prices knowing that:

- prices affect tenure and wealth
- tenure and wealth affect votes
- votes affect supply
- supply feeds back into future prices

That is a much harder fixed-point problem and may or may not be computationally feasible in the current codebase.

## Suggested first coding target

Do not start with the full political RE problem.

Start with:

- no-politics
- fixed or simple elastic supply
- deterministic demographic shock
- rational-expectations price-path iteration

Only after that converges should the political feedback be reconsidered.

## Open questions

- Which existing MATLAB file is the best base for a no-politics equilibrium version:
  `SolveSS.m`, `SolveSS_function.m`, `SolveSS_iter.m`, or an IRF folder variant?
- Should rental pricing also be endogenized through the zero-profit condition at the same time?
- Should the first RE test be steady-state only, or a full transition path after a baby-boom shock?
- Are expectations truly random in the current working implementation, or only treated that way in exposition/slides?

## Recommended separate-chat starting prompt

Build a no-politics rational-expectations extension of the NIMBY model in `research_projects/02_nimbyism_and_housing_supply/extensions/`.
Use the existing steady-state MATLAB code as the base, remove the voting block, and start with a simple deterministic price-path fixed point before attempting any political RE version.
