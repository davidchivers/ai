# 03 Model notes

Last updated: 2026-03-30
Status: working economics model note for the scene paper

## What the model has to do

The paper is not trying to explain:

- technological progress in the patent sense
- global genre origins
- network structure for its own sake

It is trying to explain something narrower and more economic:

- why some cities become able to sustain a new local creative niche earlier than others

In the live paper:

- bands are projects
- musicians are skilled workers
- subgenres are differentiated creative varieties inside a broader product space
- a local scene emerges when a `city x genre` cell becomes thick enough to support repeated entry

So the model needs to rationalize:

1. why thicker local target-genre activity predicts later scene emergence
2. why local spinout formation predicts later scene emergence
3. why overlapping workers across local projects predict later scene emergence

## Candidate economics models

### Candidate 1. Local variety-creation model

This is the best main candidate.

Interpretation:

- subgenres are differentiated varieties
- cities differ in local capability to support a niche variety
- entry into the niche becomes easier as relevant local capability accumulates

What it explains well:

- why target-genre active bands matter
- why the outcome is economically meaningful even though it is not technological innovation
- why the paper belongs in economics rather than only music studies

Closest anchors:

- Dixit-Stiglitz
- Romer
- Glaeser / Duranton-Puga style local externalities

Weakness:

- by itself it does not yet explain why multi-band musicians and spawning should be special

### Candidate 2. Spinout model

This is the best mechanism for `local spawning flow`.

Interpretation:

- new bands inherit routines, contacts, and tacit know-how from incumbent local bands
- embedded participants create new projects rather than completely de novo entrants doing so

What it explains well:

- why spawning is not just “more bands”
- why local project lineage matters
- why scenes can become locally self-reinforcing

Closest anchors:

- Franco-Filson
- Klepper-style spinout logic

Weakness:

- alone, it is too narrow to carry the whole paper

### Candidate 3. Recombinant worker-mobility model

This is the best mechanism for `target-genre multi-band musicians`.

Interpretation:

- musicians accumulate tacit know-how in projects
- overlapping membership and project switching raise the scope for recombination
- new bands and new local varieties draw on those recombined inputs

What it explains well:

- why individuals with multiple project ties matter
- why role composition is secondary
- why the stable result is about overlapping worker depth rather than one instrument

Closest anchors:

- Weitzman
- worker-mobility spillover papers

Weakness:

- alone, it can drift toward vague “ideas spread” language

### Candidate 4. Diffusion model

This is useful only as an extension.

Interpretation:

- once a niche becomes legible in some hubs, templates can spread across cities

What it explains well:

- the maps
- the broad cultural intuition that styles spread

Weakness:

- the current regression evidence says local thickness dominates once both are included
- so diffusion should not be the core model

## Best choice

The best model is a hybrid with one clear center:

1. baseline: local variety creation
2. mechanism 1: spinouts
3. mechanism 2: recombination through overlapping workers
4. extension only: diffusion

That keeps the theory mainstream enough for economics and close enough to the actual evidence.

## Formal microfoundation

### Environment

Time is discrete. Cities are indexed by `c`, genre niches by `g`, and years by `t`.

Within each city-genre cell there is a differentiated-product market for niche metal projects. A
band is one variety in that niche. Demand is not modeled in full detail, but the clean benchmark is
a Dixit-Stiglitz style environment in which a larger set of viable local varieties can be supported
when projects can be formed at lower cost and with higher expected quality.

In each period, a mass of potential founders considers creating a new band in niche `g` in city
`c`.

### Agents

Potential founder `i` is characterized by:

- `e_i \in {0,1}`: embedded local founder status
- `m_i \ge 0`: overlapping project experience
- `f_i`: idiosyncratic fixed cost of forming a band

Interpretation:

- `e_i = 1` means the founder comes from the existing local scene and is therefore a spinout-type
  entrant
- `m_i` captures experience accumulated by working across multiple local bands
- `f_i` captures founder-specific barriers to entry

The city-genre state is:

- `B_{cgt}`: active local bands in niche `g`
- `M_{cgt}`: multi-band musicians active in niche `g`
- `A_{ct}`: broader city-level metal infrastructure

The local spinout flow observed in the data is the realized count of new bands founded by embedded
participants. In the model it is an equilibrium outcome of the mass of embedded founders entering.

### Quality and entry costs

If founder `i` enters, expected project quality is:

$$
q_{icgt} = \bar{q}_g + \gamma_e e_i + \gamma_m m_i + \varepsilon_i,
$$

with `\gamma_e, \gamma_m > 0`.

Interpretation:

- embedded founders inherit routines, contacts, and tacit niche knowledge from incumbent projects
- founders with broader overlapping experience can recombine more local know-how

The effective fixed cost of forming and sustaining a new local niche project is:

$$
F_{icgt} = f_i - \phi_B \log(1+B_{cgt}) - \phi_M \log(1+M_{cgt}) - \phi_A A_{ct},
$$

with `\phi_B,\phi_M,\phi_A > 0`.

Interpretation:

- thicker local niche stock lowers search, matching, and organizational costs
- more overlapping workers make it easier to assemble a viable team
- broader local metal infrastructure also lowers project-formation costs

### Expected profits and entry decision

Let `\pi(q_{icgt})` denote operating profit from supplying one differentiated niche variety, with
`\pi'(\cdot) > 0`.

Founder `i` enters if:

$$
\Pi_{icgt} = \pi(q_{icgt}) - F_{icgt} \ge 0.
$$

Substituting for quality and cost:

$$
\Pi_{icgt}
= \pi\left(\bar{q}_g + \gamma_e e_i + \gamma_m m_i + \varepsilon_i\right)
- f_i + \phi_B \log(1+B_{cgt}) + \phi_M \log(1+M_{cgt}) + \phi_A A_{ct}.
$$

This is the core micro mechanism:

- higher `B_{cgt}` raises entry by lowering effective formation costs
- higher `M_{cgt}` raises entry both by lowering costs and by increasing founder quality through
  recombination
- embedded founders are more likely to enter successfully because they have higher expected quality

### Aggregate entry

Let `H` be the joint distribution of founder types `(e_i,m_i,f_i,\varepsilon_i)`. Then total niche
entry in `c,g,t` is:

$$
N_{cgt} = \int \mathbf{1}\{\Pi_{icgt} \ge 0\}\, dH(i).
$$

Comparative statics follow immediately:

$$
\frac{\partial N_{cgt}}{\partial B_{cgt}} > 0,
\qquad
\frac{\partial N_{cgt}}{\partial M_{cgt}} > 0,
\qquad
\frac{\partial N_{cgt}}{\partial \Pr(e_i=1)} > 0.
$$

That last term is the model-side object behind the empirical spawning variable: if a larger share
of potential entrants is drawn from embedded local participants, more niche entry should occur.

The paper's observed spawning variable is city-year rather than city-genre specific. Let `\rho_{ct}`
denote the city-year share of potential founders who are embedded local participants, and let
realized local spawning flow be:

$$
S_{ct} = \rho_{ct} \sum_{g'} N_{cg't}.
$$

This is best read as a proxy for broad local spinout intensity. Cities with more incumbent depth
and more overlapping workers should generate more embedded founders, and that city-wide
entrepreneurial circulation should raise the supply of viable founders who can enter focal niche
`g`.

### Dynamics

The stock of active niche bands evolves as:

$$
B_{cg,t+1} = (1-\delta_B)B_{cgt} + N_{cgt},
$$

where `\delta_B` is exit.

Overlapping worker depth evolves as:

$$
M_{cg,t+1} = (1-\delta_M)M_{cgt} + \mu_1 B_{cgt} + \mu_2 N_{cgt},
$$

with `\mu_1,\mu_2 > 0`.

The mass of embedded founders evolves as:

$$
\Pr(e_{i,t+1}=1) = G(B_{cgt},M_{cgt}),
$$

with `G_B, G_M > 0`.

Interpretation:

- more incumbent bands generate more future local founders
- more overlapping workers create more experienced participants who can launch spinouts later

### Emergence

A scene emerges once the local niche passes a viability threshold:

$$
E_{cgt} = \mathbf{1}\{B_{cgt} \ge \bar{B}\}.
$$

In the paper, `\bar{B}` is operationalized as `5` active bands. This is not the ontological birth
of a genre. It is the point at which the local niche becomes thick enough to sustain repeated entry.

For cells that are still below the threshold, define the one-period transition hazard:

$$
h_{cgt} = \Pr(E_{cg,t+1}=1 \mid E_{cgt}=0).
$$

Because `B_{cg,t+1} = (1-\delta_B)B_{cgt} + N_{cgt}`, that hazard is increasing in current
`B_{cgt}`, `M_{cgt}`, and the latent embedded-founder share `\rho_{ct}`. In the data, the exact-
year reduced-form regression uses lagged `B_{cg,t-1}`, `M_{cg,t-1}`, and city-year spawning flow
`S_{c,t-1}` as proxies for those transition forces.

## Comparative statics

The model delivers the paper’s core comparative statics directly.

### Proposition 1. Thicker local niche stock raises the probability of emergence.

If `\phi_B > 0`, then a higher `B_{cgt}` lowers effective entry costs and therefore raises niche
entry `N_{cgt}`. This makes crossing `\bar{B}` more likely.

This is the direct economics interpretation of the positive `target-genre active bands`
coefficient.

### Proposition 2. More overlapping workers raise the probability of emergence.

If `\phi_M > 0` and `\gamma_m > 0`, then higher `M_{cgt}` both lowers effective entry costs and
raises expected founder quality. It also raises future embedded-founder mass through the dynamics.

This is the cleanest interpretation of the positive `target-genre multi-band musicians`
coefficient: overlapping worker depth lowers effective entry costs by increasing local
recombination capacity.

### Proposition 3. More city-year local spawning raises the probability of emergence.

If embedded founders have `\gamma_e > 0`, then a higher city-year share of local embedded founders
raises the supply of entrants with stronger expected project quality. In the data, higher realized
spawning flow is the equilibrium footprint of that mechanism.

This is the economics interpretation of the positive spawning coefficient.

### Proposition 4. Local self-reinforcement is possible without strong causal claims.

Because `B`, `M`, and `S` all feed into future entry, the model permits cumulative local niche
formation:

- more bands create more overlapping workers
- more overlapping workers create more spinouts
- more spinouts create more future bands

That is enough to rationalize local scene thickening as a reduced-form empirical pattern without
claiming point identification of the underlying causal channel.

## Why this model fits the current regression better than alternatives

The model fits the evidence because:

- it makes `target-genre active bands` central
- it gives `target-genre multi-band musicians` an independent role
- it treats `spawning flow` as a distinct mechanism
- it leaves diffusion secondary

It also explains why some alternative branches are weak:

- role composition is not central because the key object is overlapping experience, not one
  privileged instrument class
- `all metal` is not the best outcome because the theoretical object is niche formation inside a
  broader field, not generic metal agglomeration
- diffusion is not the core model because the current exposure results mostly wash out once local
  thickness is included

## Main critique and response

The strongest critique is that this may still be partly mechanical. If the same small group of
people appears in many local bands, then more bands and more links may arise together even without
economically meaningful spillovers.

The model response should stay modest:

- the paper does not claim to observe ideas moving directly
- the paper does not claim that every overlapping worker generates a new scene
- the paper only claims that local entry costs are lower where local capability, spinouts, and
  overlapping experience are thicker

That is exactly why the empirical language should remain:

- `predicts`
- `tracks`
- `is associated with`

rather than stronger causal phrasing.

## Digital-era extension

The digital-era split suggests a useful extension, but not a different main model.

One simple way to represent digitization is to let remote access reduce the importance of local
stock for some margins:

$$
F_{icgt} = F_{icgt}(B_{cgt},M_{cgt},S_{ct}; d_t),
$$

where higher `d_t` means better remote access to music, information, and models from elsewhere.

Then:

- the cost-reducing role of `B` may weaken as `d_t` rises
- the cost-reducing role of `S` may also weaken if imitation becomes easier
- but the local role of `M` may remain strong because overlapping workers still matter for actual
  project formation and recombination

That matches the current descriptive split better than a crude story that “the internet killed
scenes.”

## What to put in the paper

The paper does not need a long formal-model section.

It needs:

1. one paragraph on the economic object:
   local variety creation in a project-based industry
2. one paragraph on the three mechanisms:
   labor pooling, spinouts, recombination
3. one compact equation:

$$
\Pr(E_{cgt}=1) = F\left(\alpha_{cg} + \lambda_t + \beta_1 S_{c,t-1} + \beta_2 B_{cg,t-1} +
\beta_3 M_{cg,t-1}\right)
$$

4. one sentence on why the outcome is meaningful:
   emergence marks the point at which a local niche becomes thick enough to sustain repeated entry

The longer note should stay here in `03`. The paper should keep only the compact version.

## Working takeaway

The best economics model for the project is:

- a local variety-creation model
- with spinouts and overlapping worker mobility as the micro-mechanisms
- and diffusion treated as a secondary extension

That is the cleanest bridge between the actual regressions and a mainstream economics framing.
