# Political coalition extension

## Direction

If the extension should make NIMBYism worse, the natural direction is not to weaken demand or strengthen competitive supply.

The natural direction is to strengthen the political transmission from homeowner exposure to supply restriction.

That means moving away from:

- equal vote weights
- no bargaining
- no coalition formation

and toward:

- higher effective turnout or influence for anti-supply owners
- coalition blocs among politically aligned owners
- supply policy that responds nonlinearly once an anti-development bloc becomes dominant

This is also consistent with the existing slide language that the baseline has "No coalitions or bargaining".

## Baseline political object

The current code effectively uses:

`net_vote = sum(dens4 .* pref4, 'all')`

where:

- `dens4` is the state density
- `pref4` is the sign of the marginal value of a higher house price

This treats each household-state as carrying equal political weight per unit mass.

## Worsening NIMBYism: first extension

### Idea

Replace equal political weight with coalition-weighted political weight.

The simplest extension is:

`net_vote = sum(weights .* dens4 .* pref4, 'all')`

where `weights` are larger for households that are more politically effective and more anti-supply.

## Recommended coalition weights

For a first pass, weight up groups that plausibly organize against new housing:

1. owners relative to renters
2. older owners relative to younger owners
3. highly leveraged owners relative to outright renters
4. households with larger housing positions

These all tend to push the model toward more severe NIMBY outcomes because the anti-price-decline bloc becomes more influential than in the one-person-one-weight baseline.

## Practical coalition formula

Define political weight as:

`w = 1 + alpha_owner * owner + alpha_old_owner * old_owner + alpha_leverage * leveraged_owner + alpha_bighouse * housing_share`

with all `alpha` parameters non-negative.

Interpretation:

- `alpha_owner`: broad homeowner overrepresentation
- `alpha_old_owner`: captures older, settled owners as a stronger anti-building bloc
- `alpha_leverage`: captures owners whose balance sheets are especially sensitive to price declines
- `alpha_bighouse`: captures the idea that larger incumbent owners have more at stake

## Coalition logic

This can be read in two ways:

### Reduced-form politics

Some groups have higher turnout, better organization, and more local political access.

### Proto-coalition model

These groups form a coalition around the common objective of restricting supply even if their reasons differ:

- older owners want to protect wealth
- leveraged owners want to protect collateral values
- large owners want to protect high housing wealth exposure

## How to implement in current code

The minimum intervention later is to replace:

`sum(dens4.*pref4,'all')`

with a weighted object computed from:

- housing holdings from `aaaa`
- liquid asset positions from `bbbb`
- age index from the final dimension
- a parameter struct for coalition weights

That is what the MATLAB helper in this folder is designed to do.

## Political-side roadmap after that

### Stage A: weighted majority

Keep preferences exactly as in the baseline and only change political weights.

This is the safest first extension because it isolates the role of coalition power.

### Stage B: threshold or agenda-setting rule

Make supply respond nonlinearly to the anti-supply bloc:

- if weighted anti-supply vote exceeds a threshold, supply tightens sharply
- otherwise supply is only mildly restricted

This creates periods where a coalition captures local politics.

### Stage C: explicit coalition formation

Let the anti-supply bloc be the union of specific groups, for example:

- older owners
- leveraged middle-aged owners
- landlords / multi-unit owners if the state space can proxy them

At that stage the model becomes a coalition game rather than a simple weighted referendum.

## Recommendation

Do not jump directly to bargaining.

Start with coalition-weighted voting because:

- it nests the baseline when all alphas are zero
- it is easy to calibrate or sensitivity-test
- it cleanly answers whether stronger homeowner political power makes NIMBYism materially worse
- it is computationally much cheaper than a full bargaining or lobbying game
