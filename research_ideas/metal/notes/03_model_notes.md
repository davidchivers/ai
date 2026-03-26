# 03 Model notes

Last updated: 2026-03-20
Status: working theory note

# Model 1: Country-level breakthrough as an entry shock

**Model type:** Reduced-form entry model in which visible local success changes the perceived
return to starting a band.

**Literature.**
The closest conceptual benchmarks are role-model spillovers, cultural entrepreneurship, and local
scene formation. Exact citations are intentionally omitted here until they are verified in
`notes/02_literature_and_synthesis.md`.

**How this applies to the question.**
Let `Entry_ct` denote new bands formed in country `c` and year `t`, and let `Hit_ct` denote a
major metal breakthrough in that country-year. The baseline idea is that a breakthrough changes
salience, expected payoff, and local scene legitimacy. A simple reduced-form starting point is:

$$
Entry_{ct} = \alpha_c + \lambda_t + \beta Hit_{c,t-k} + \varepsilon_{ct},
$$

where `k` allows for delayed entry after the shock. The interpretation of `\beta` is disciplined
but modest: it captures whether breakthrough timing is associated with later local startup waves.
It should not be read as fully causal unless the event timing is credibly exogenous.

**References.**
Verified references pending.

# Model 2: Country plus language-market spillovers

**Model type:** Cross-market diffusion model with both own-country and shared-language exposure.

**Literature.**
This model sits between country-based scene formation and broader cultural-market diffusion.
Verified references on language markets and cultural spillovers are still pending.

**How this applies to the question.**
The language extension says that a breakthrough can matter outside the home country when the album
travels in a shared cultural market. Let `LangHit_lt` denote breakthrough exposure in language
market `l`, and let `l(c)` map country `c` into its relevant language market. Then:

$$
Entry_{ct} = \alpha_c + \lambda_t + \beta Hit_{c,t-k} + \gamma LangHit_{l(c),t-k} + \varepsilon_{ct}.
$$

Here `\beta` captures own-country exposure and `\gamma` captures broader language spillovers. This
model is useful because some metal scenes may respond more to culturally legible external hits
than to geography alone. The main caution is that language coding may be noisier than country
coding, so this should remain a second-stage extension until the country-year panel is stable.

**References.**
Verified references pending.

# Model 3: Band influence as residualized downstream entry impact

**Model type:** Event-style ranking model that treats bands as startup catalysts rather than only
as style leaders.

**Literature.**
The relevant conceptual literature is likely to overlap with superstar effects, local role-model
effects, and scene-building. Exact anchors are still pending verification.

**How this applies to the question.**
Once the event panel exists, the project can rank bands by their downstream entry impact. The key
point is that "influential" means associated with later startup, not only with stylistic copying.
For a given band or album event `b`, define a residualized post-hit entry object such as:

$$
Influence_b = \sum_{j=0}^{J} \omega_j \widehat{Entry}_{c_b,t_b+j},
$$

where `\widehat{Entry}` is entry net of country and year structure, and the weights `\omega_j`
define the post-hit window. The same object can be constructed for:

- all-metal entry
- genre-family entry
- unsigned entry
- later signed entry

This model is useful because it converts the treatment panel into an interpretable ranking. The
main risk is overreading naive post-hit counts. The ranking must condition on baseline scene depth
and common year shocks.

**References.**
Verified references pending.

---

# Scenes Pivot: Collaborative Innovation Models

> Last updated: 2026-03-22. Full write-up in `model/scenes_as_collaborative_innovation.md`.

The project is pivoting from blockbuster shocks to **scenes as the unit of analysis**. The core question becomes: how do localised clusters of bands collectively produce a new genre? Genre creation is a form of innovation driven by mutual inspiration and personnel exchange, not standard competition.

> **Sequencing note.** Empirics first, model second. Build the membership network and characterise scene-level facts before committing to a framework.

## Mechanism summary

Three channels connect scenes to genre emergence:

1. **Localised knowledge spillovers** --- bands observe each other's shows, share rehearsal spaces, trade recordings. Imitation is celebrated, not free-riding (Marshall 1890; Jaffe, Trajtenberg & Henderson 1993).
2. **Member switching as labour mobility** --- musicians move between bands (often playing in several simultaneously), carrying stylistic vocabulary across projects (Saxenian 1994; Breschi & Lissoni 2009).
3. **Recombinant innovation** --- genre = novel combination of existing musical elements assembled by many bands experimenting in the same place (Weitzman 1998; Fleming 2001).

## Candidate frameworks: ranked

| Rank | Framework | Type | Novelty | Data fit | Journal ceiling |
|------|-----------|------|---------|----------|----------------|
| **1** | Network + community detection | Network science | High | Excellent | Top-5 possible |
| **2** | Diffusion on graphs | Network/econ hybrid | Medium-high | Excellent | Top field / top-5 |
| **3** | Public-good genre model | Standard econ | Medium | Good | Top field |
| **4** | Hybrid (network + public-good) | Hybrid | Medium-high | Excellent | Top field / top-5 |
| **5** | MAR spillover model | Standard econ | Low | Moderate | Field journal |

### Model D (recommended lead): Network community detection as endogenous genre definition

Define genre emergence **endogenously from the network** rather than from retrospective genre tags:

- Build band-band projection of the bipartite musician-band network for each region-year.
- Apply community detection (spectral clustering, stochastic block models, modularity maximisation) to identify dense subgraphs.
- A genre exists when a detected community's members also show observable style convergence.

**Key testable prediction:** the network community should be detectable *before* the genre label appears in common use, because social structure precedes naming.

Additional topology predictions:
- Small-world networks (high clustering, short path length) produce genres faster.
- Bridge musicians (high-degree nodes) accelerate diffusion disproportionately.
- Clustering coefficient at a given date predicts subsequent genre crystallisation.

**Why this over off-the-shelf:** Metallum gives us the complete bipartite network with dated entry/exit --- almost unheard of in innovation economics. A generic MAR model wastes this. Community detection turns the data's unique structure into the paper's identifying feature.

### Model B: Diffusion on graphs

Bands are nodes, shared members are edges. Style propagates along edges:

$$s_i^{t+1} = s_i^t + \beta \sum_{j: (i,j) \in G_t} (s_j^t - s_i^t) + \varepsilon_i^t$$

Familiar via Jackson (2008). Generates topology predictions but less novel than D.

### Model C: Public-good genre model

Genre as a club good. Bands choose effort $e_i$; payoff $\pi_i = Q \cdot g(d_i) - c(e_i)$ where $Q$ is collective genre quality and $d_i$ is own distinctiveness. Captures the similarity-vs-variety tension. Good fallback if network data is too sparse or noisy.

### Model A: MAR spillover (not recommended)

Standard agglomeration with bands. "Jaffe-Trajtenberg but for music" is not a contribution.

## Key references for scenes pivot

- Florida, Mellander & Stolarick (2010). "Music Scenes to Music Clusters." *Environment and Planning A*.
- Kim & Askin (2024). "Feature-Based Structures of Opportunity: Genre Innovation in American Popular Music." *ASR*.
- Crossley (2009, 2015). Network dynamics in punk/post-punk scenes. *Poetics* / Manchester UP.
- Newman (2006). "Modularity and Community Structure in Networks." *PNAS*.
- Uzzi & Spiro (2005). "Collaboration and Creativity: The Small World Problem." *AJS*.
- Vedres & Stark (2010). "Structural Folds: Generative Disruption in Overlapping Groups." *AJS*.

## Pilot network results: Norwegian black metal (2026-03-22)

First pilot network built from Wikipedia sources. Full stats in
`data/processed/scene_networks/norwegian_bm_network_stats.md`.

- 28 bands, 38 musicians, 33 band-band edges (via shared members)
- Density: 0.087 (sparse overall, dense core)
- Average clustering coefficient: 0.345 (high --- consistent with small-world structure)
- 22 of 38 musicians (58%) played in 2+ bands --- extraordinary multi-band rate
- Hub bands: Emperor (degree 6), Arcturus (5), Borknagar (5), Mayhem (4), Gorgoroth (4)
- Top bridge musicians: Carl-Michael Eide (4 bands), Varg Vikernes (3), Samoth (3), Garm (3), Tchort (3)
- Darkthrone is isolated (degree 0) despite being a genre-defining band --- interesting outlier

**Implication:** the network approach is viable. Even a quick Wikipedia-sourced pilot produces a
non-trivial graph with clear hub-and-bridge structure. The dense core maps onto the bands that
defined the genre.

## Dual-network idea: membership + influences

Wikipedia band pages typically carry two types of relational data:

1. **Shared members** (already built) --- the bipartite musician-band graph projected onto band-band
   space. This captures direct personnel exchange as a channel for style transfer.

2. **Influence / associated-acts links** --- most Wikipedia band pages list "associated acts" in the
   infobox and sometimes cite explicit influences in the prose. This gives a second, independent
   network layer: not who shared members, but who cited or was influenced by whom.

**Why two layers matter:**

- The membership network captures **labour-mobility spillovers** (Breschi & Lissoni). A shared
  member literally carries musical knowledge between bands.
- The influence network captures **observational spillovers** (Marshall, Jaffe-Trajtenberg). A band
  can be influenced by another without ever sharing a member --- through attending shows, hearing
  recordings, or deliberate emulation.

**Testable predictions from the dual network:**

- If membership edges are stronger predictors of style convergence than influence edges, the
  labour-mobility channel dominates. If influence edges are stronger, observational spillovers
  dominate.
- If bands connected by *both* membership and influence edges converge fastest, the channels are
  complementary.
- The influence network may be more *directional* (band A influenced band B, but not vice versa),
  while the membership network is inherently undirected. That asymmetry is itself informative ---
  it can test whether innovation flows from early to late entrants as the theory predicts.
- Influence links may span cities and even countries (e.g., Bathory in Sweden influencing the
  Norwegian scene), while membership links are overwhelmingly local. Testing which network
  predicts genre formation would distinguish local vs. non-local spillovers.

**Data construction:**

For the pilot scenes, the influence network can be built from the same Wikipedia pages used for
membership. Each band's infobox contains an "Associated acts" field. Individual band pages
often list influences in the "Musical style" or "History" sections. This is hand-collectible
for 20--30 band scenes without any scraping.

A richer version could later use Metal Archives, which lists "similar artists" and "related
links" on many band pages, or Last.fm's "similar artists" API.

**Where this sits in the model ranking:**

The dual-network approach strengthens Model D (community detection) by giving it two independent
network layers to detect communities on. A community that appears in *both* networks is much
more credible than one that appears in only one. It also generates a natural decomposition of
the innovation mechanism: how much of genre formation is carried by people moving between bands
vs. bands listening to each other?

## Next steps

1. ~~Build membership network for Norwegian black metal.~~ Done (2026-03-22).
2. Build membership network for 2--3 more pilot scenes (Tampa death metal, Gothenburg melodic death, Birmingham NWOBHM) from Wikipedia.
3. Build influence/associated-acts network for Norwegian black metal from Wikipedia band infoboxes.
4. Characterise network topology across scenes: clustering coefficient, path length, degree distribution, community structure over time.
5. Test dual-network predictions: does membership or influence better predict style convergence?
6. Test "community precedes label" informally.
7. Let empirical patterns determine framework choice.
