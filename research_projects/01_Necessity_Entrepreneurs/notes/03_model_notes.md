# 03 Model notes

Empirical calibration targets for the self-employment version are documented separately in
`notes/06_self_employment_targets.md`.

## Self-employment as the root occupational state

This note sketches a candidate extension. The goal is to let entrepreneurship begin as
self-employment, with hiring as a later margin, rather than forcing every entrepreneur
to be an employer immediately.

### Current production block

The current draft effectively uses an employer-only production technology:

$$
y = x k^{\alpha} (z n)^{\gamma}
$$

with profit

$$
\pi(x,k,n) = x k^{\alpha} (z n)^{\gamma}
- w (1 + \psi \tau) z n
- r k
- \kappa \frac{\rho z n}{q(\theta)}.
$$

The key implication is immediate:

$$
n = 0 \implies y = 0.
$$

So the current setup does not admit a true self-employed corner. It admits only
"entrepreneur as employer."

### Candidate production block with self-employment at the root

Let the owner supply own labor directly. Denote owner labor by $\ell_e$ and hired labor
by $n_h$. A simple nested specification is

$$
y = x k^{\alpha} \left( \ell_e + \xi z n_h \right)^{\gamma},
$$

where:

- $x$ is entrepreneurial ability
- $k$ is capital
- $\ell_e$ is owner labor, often normalized to $1$
- $n_h$ is hired labor
- $\xi$ scales hired labor relative to owner labor

The corresponding profit function is

$$
\pi(x,k,n_h) =
x k^{\alpha} \left( \ell_e + \xi z n_h \right)^{\gamma}
- w (1 + \psi \tau) z n_h
- r k
- \kappa \frac{\rho z n_h}{q(\theta)}
- f_h \mathbf{1}\{n_h > 0\}.
$$

The fixed cost term $f_h$ is optional, but it is useful if the model is meant to
generate a genuine separation between self-employed firms and employer firms.

### Why this changes the economics

Under this specification,

$$
n_h = 0 \implies y = x k^{\alpha} \ell_e^{\gamma} > 0,
$$

so a self-employed entrepreneur can operate without hired workers.

This creates a clean occupational ladder:

1. worker
2. self-employed entrepreneur
3. employer entrepreneur

The choice to hire is no longer the same thing as the choice to enter entrepreneurship.

### First-order condition for hired labor

For an interior employer choice with $n_h > 0$, the FOC for hired labor is

$$
\gamma x k^{\alpha} \left( \ell_e + \xi z n_h \right)^{\gamma - 1} \xi z
=
w (1 + \psi \tau) + \frac{\rho \kappa}{q(\theta)}.
$$

Equivalently, the entrepreneur hires workers up to the point where the marginal product
of an extra hired worker equals the wage plus the replacement-cost term.

At the self-employed corner, the relevant condition is

$$
\gamma x k^{\alpha} \ell_e^{\gamma - 1} \xi z
\le
w (1 + \psi \tau) + \frac{\rho \kappa}{q(\theta)} + f_h^\prime,
$$

where the exact threshold term depends on how the fixed hiring cost is modeled. The
economic point is simple: if the first hired worker is too expensive relative to its
marginal product, the entrepreneur remains self-employed.

### First-order condition for capital

If capital is chosen freely in the entrepreneurial problem, the interior FOC is

$$
\alpha x k^{\alpha - 1} \left( \ell_e + \xi z n_h \right)^{\gamma} = r.
$$

So capital is chosen jointly with the hiring margin, but self-employment remains feasible
even when $n_h = 0$.

### Interpreting $x$ when self-employment is the root

This is the main conceptual question. In the current model, education type $h$ maps into
both worker productivity $z$ and entrepreneurial talent $x$. Once self-employment is added,
there are two coherent ways to interpret $x$.

The simplest first-pass interpretation is:

- $z$ = worker productivity in paid employment
- $x$ = business productivity, which applies both to self-employment and to employer firms

Under that interpretation, no extra penalty on $x$ is needed in the first version. The
same entrepreneurial type drives both own-account production and employer production:

$$
y = x k^{\alpha} \left( \ell_e + \xi z n_h \right)^{\gamma}.
$$

This is a reasonable first proxy. If $h$ already maps into both $z$ and $x$, then the
model can be read as saying that education shapes both paid-work productivity and the
ability to run a business, even before the business hires workers.

### Optional attenuation of $x$ in self-employment

If the concern is that $x$ is too specifically "talent for managing firms" rather than
general business talent, then the clean extension is to attenuate $x$ in the self-employed
regime.

Define effective entrepreneurial talent as

$$
x_{\mathrm{eff}}(n_h)
=
x \left[ \lambda_{se} + (1-\lambda_{se}) \mathbf{1}\{n_h > 0\} \right],
\quad 0 < \lambda_{se} \le 1.
$$

Then output becomes

$$
y = x_{\mathrm{eff}}(n_h) k^{\alpha} \left( \ell_e + \xi z n_h \right)^{\gamma}.
$$

This gives:

$$
\text{self-employed: } y_{se} = \lambda_{se} x k^{\alpha} \ell_e^{\gamma},
$$

and

$$
\text{employer: } y_{emp} = x k^{\alpha} \left( \ell_e + \xi z n_h \right)^{\gamma},
\quad n_h > 0.
$$

The parameter $\lambda_{se}$ measures how much of employer-management talent carries over
to own-account production.

- If $\lambda_{se} = 1$, self-employment uses the full entrepreneurial talent draw.
- If $\lambda_{se} < 1$, self-employment uses the same talent draw but at lower intensity.

This is the cleanest mathematical way to impose the penalty the user raised.

### Contrast with an alternative multiplicative form

A tempting alternative would be

$$
y = x k^{\alpha} \ell_e^{\eta} (z n_h)^{\gamma}.
$$

But this does not solve the core problem, because

$$
n_h = 0 \implies y = 0.
$$

So this form still makes hired labor essential for any production at all. If the goal is
to make self-employment the root state, the additive labor aggregator is the cleaner first
step.

### Optional taste for being your own boss

A separate "taste for autonomy" should not enter the production function. It should enter
utility.

For example, let the value of self-employment include an additive utility shifter
$\chi_{se}$:

$$
V_{se} = u(c) + \chi_{se} + \beta \mathbb{E} V',
$$

while employer entrepreneurship could have its own shifter $\chi_{emp}$:

$$
V_{emp} = u(c) + \chi_{emp} + \beta \mathbb{E} V'.
$$

That term captures the non-pecuniary value of being one's own boss. It is conceptually
separate from productivity and should be treated as a calibration object rather than the
first modeling change.

### Thinking through $\chi$ before writing the Bellman equations

The clean interpretation is:

- $x$ remains pecuniary business productivity
- $\chi$ captures the non-pecuniary value of autonomy

So the two objects should be kept conceptually separate. A household may be good at
running a business because it has high $x$, and it may like being its own boss because
it has high $\chi$. Those are different channels.

The first design choice is whether $\chi$ should apply to all entrepreneurship, or mainly
to self-employment.

The cleanest first-pass specification is

$$
u(c) + \chi_{se}\mathbf{1}\{n_h = 0,\ \mathcal{I}_e = 1\}
+ \chi_{emp}\mathbf{1}\{n_h > 0,\ \mathcal{I}_e = 1\}.
$$

This keeps the taste shifter entirely on the utility side, without changing the
production technology.

Conceptually, I would start from

$$
\chi_{se} \geq \chi_{emp}.
$$

The reason is that "being your own boss" sounds most naturally like a self-employment
object. Once the entrepreneur hires workers, the occupation becomes part autonomy and part
management burden, so the autonomy premium may be smaller.

For parsimony, the best first calibration is probably even simpler:

$$
\chi_{emp} = 0, \qquad \chi_{se} > 0.
$$

That gives a one-parameter autonomy extension. It says the extra non-pecuniary payoff is
attached to own-account entrepreneurship, not to employer status more generally.

### What not to do with $\chi$

I would avoid making $\chi$ depend directly on whether the agent was previously employed
or unemployed. If that is done, the model starts baking necessity/opportunity distinctions
directly into tastes rather than generating them from outside options and risk.

So the safer structure is:

- labor-market status affects payoffs through wages, unemployment risk, and UI
- autonomy enters only through the occupational utility shifter

### What $\chi$ would likely do quantitatively

A positive $\chi_{se}$ will:

1. raise entry into self-employment near the margin
2. be strongest for agents with modest $x$ or weak outside options
3. tend to increase measured necessity entrepreneurship unless calibrated carefully

So there is a real identification issue: if $\chi_{se}$ is too large, it can soak up what
the current paper wants to attribute to labor-market risk and insurance.

### Suggested calibration logic

If the model is extended this way, the clean target mapping would be:

- $\chi_{se}$ pins the self-employed share among entrepreneurs, or the share of firms with
  zero employees
- $\chi_{emp}$, if allowed to vary, pins the employer share conditional on entrepreneurship

That is why I would start with a single autonomy parameter for self-employment only. It is
easier to interpret, easier to calibrate, and less likely to blur the main necessity
mechanism.

### Scale implications and relation to span of control

This is an important clarification. Making self-employment feasible does not by itself
mean that agents first enter as self-employed and only later become employers.

In a standard span-of-control logic, scale is chosen optimally at entry given talent,
prices, and constraints. So if the entrepreneurial problem is

$$
\max_{k,n_h \ge 0} \; \pi(x,k,n_h),
$$

then a high-$x$ entrepreneur can enter immediately with $n_h > 0$. The model does not
force an intermediate self-employment stage unless some additional friction makes the
small-scale corner attractive early on.

So the additive production function

$$
y = x k^{\alpha} \left( \ell_e + \xi z n_h \right)^{\gamma}
$$

should be interpreted as making self-employment a feasible corner, not as imposing a
lifecycle in which all entrepreneurs start at $n_h = 0$.

### When would the model generate self-employed-to-employer transitions?

The cleanest mechanism is exactly the one the user suggested: a borrowing constraint.

Suppose entrepreneurial capital must satisfy

$$
k \leq \lambda a
$$

for some tightness parameter $\lambda$, where $a$ is available assets. Then the marginal
product of hiring depends on a constrained capital stock. At the self-employed corner,
the entrepreneur hires only if

$$
\gamma x k^{\alpha} \ell_e^{\gamma - 1} \xi z
>
w (1 + \psi \tau) + \frac{\rho \kappa}{q(\theta)} + f_h^\prime.
$$

If low assets imply low feasible $k$, that inequality may fail initially even for a
talented entrepreneur. After asset accumulation, the same entrepreneur may cross the
threshold and begin hiring workers.

So with a borrowing constraint, the model can naturally generate:

1. low assets $\Rightarrow$ self-employed
2. higher assets later $\Rightarrow$ employer

Without such a friction, the model is much closer to a static span-of-control choice:

1. low-$x$ agents remain workers or small self-employed
2. high-$x$ agents enter directly at employer scale

### Practical implication for the extension

If the aim is only to broaden the entrepreneurship margin so that own-account work is
included, then the additive production function is enough.

If the aim is specifically to model a progression from self-employment to employer status,
then some state-dependent scale friction is needed. The borrowing constraint is the
cleanest first candidate.

### Does the borrowing constraint make the model unclean?

Not necessarily. The key point is that the current model already has asset heterogeneity,
so wealth is already in the state vector. If entrepreneurial capital is constrained by
existing assets, then the extension does not add a new state variable; it changes the
entrepreneurial choice set.

The cleanest version is

$$
k \leq \lambda a,
$$

or, with limited external finance,

$$
k \leq \lambda a + \bar{b}_k.
$$

Under this formulation:

- $a$ is already part of the household problem
- wealth heterogeneity is already present
- the new ingredient is that wealth now matters directly for firm scale

So the extension is not mathematically unclean. It is economically richer, but still
quite disciplined.

### What becomes less clean

What does become less clean is the interpretation of entrepreneurial entry. Once wealth
matters for scale, the model no longer says only:

1. labor-market risk pushes people into entrepreneurship

It also says:

2. wealth constrains whether that entrepreneurship appears as self-employment or as an
   employer firm

So the decomposition of outcomes becomes:

- outside-option effect
- autonomy/taste effect, if $\chi_{se}$ is included
- liquidity/scale effect through assets

That is more complicated, but not in a bad way. It is probably closer to the underlying
economics.

### Why the borrowing constraint may actually improve the model

Without a borrowing constraint, self-employment risks becoming a purely static corner:

- low-$x$ types choose tiny scale
- high-$x$ types jump straight to employer status

With a borrowing constraint, the model can generate the more realistic pattern:

- some high-$x$ but low-asset types enter first as self-employed
- after accumulating assets, they expand and hire

That dynamic is exactly what is missing from a pure span-of-control formulation.

### Recommended discipline

The model will stay reasonably clean if the extension is kept to:

1. one self-employment production adjustment
2. one borrowing constraint linking $k$ to $a$
3. at most one autonomy shifter $\chi_{se}$

It will get messy only if all of the following are introduced at once:

- separate self-employment talent and employer talent
- multiple fixed costs
- occupation-specific borrowing limits
- autonomy tastes that vary by prior labor-market state

So the disciplined version is still quite manageable.

### Recommended implementation sequence

Yes, it is worth doing this in two stages rather than introducing self-employment and a
borrowing constraint at the same time.

Important coding note: the current C++ already contains asset-dependent entrepreneurial
scale through `find_credit_const()`, `k_opt_constrained()`, and the policy objects
`k_opt_vec`, `n_opt_vec`, and `rev_opt_vec`. So in practice the code already has a
wealth-to-scale mechanism of some kind. The clean "stage 1 vs stage 2" distinction should
therefore be interpreted as:

1. stage 1 = change the production structure and measure the implied self-employed mass
   while leaving the existing asset-dependent scale block unchanged
2. stage 2 = decide whether the existing constraint is enough, or whether it should be
   tightened/reinterpreted explicitly as the borrowing constraint behind self-employment
   dynamics

#### Stage 1: new baseline with self-employment only

First, replace the employer-only technology with the self-employment-root production
function, but do not yet add any new financing friction beyond what is already in the
code. Then compare that baseline against the current baseline.

The purpose is diagnostic:

1. measure the share of one-person firms
2. measure the employer share among entrepreneurs
3. compare the firm-size distribution against the old model
4. see whether the new margin changes aggregate entrepreneurship too much even without
   finance frictions

The key object to inspect is:

$$
\Pr(n_h = 0 \mid \mathcal{I}_e = 1),
$$

or in practice a near-zero version such as

$$
\Pr(n_h \le \varepsilon \mid \mathcal{I}_e = 1).
$$

If this first-stage baseline already produces a plausible mass of one-person firms, then
the extension is doing something economically meaningful.

If instead almost nobody is self-employed, or almost everybody is self-employed, that is
valuable information before layering on more structure.

#### Stage 2: add the borrowing constraint

Only after the self-employment baseline is understood should the model sharpen the
financing side into an explicit borrowing-constraint interpretation such as

$$
k \leq \lambda a.
$$

That second step tells us whether wealth heterogeneity is needed mainly to:

1. create a realistic self-employed mass
2. generate transitions from self-employed to employer
3. improve the firm-size distribution

#### Why this sequence is better

If both changes are introduced at once, it becomes much harder to tell what is driving the
results:

- the production-function change
- the new self-employment corner
- the wealth-to-scale channel

Running the self-employment baseline first gives a clean comparison to the current model.
Then the borrowing constraint can be evaluated as a targeted additional mechanism rather
than part of one large opaque redesign.

### Bellman representation under the self-employment-root extension

The cleanest first formulation does not require a new occupational state. Keep the
existing binary contemporaneous choice:

- work
- entrepreneurship

but allow the entrepreneurial branch to choose either self-employment or employer scale
endogenously through $n_h$.

Let the state be $(a,x,i,h)$, where:

- $a$ is assets
- $x$ is business productivity
- $i \in \{e,n,u\}$ is previous occupational/labor-market status
- $h$ determines worker productivity $z(h)$ and separation risk $\rho(h)$

Then the Bellman equation can be written as

$$
V(a,x,i,h) = \max \left\{ V^W(a,x,i,h),\; V^E(a,x,i,h) \right\}.
$$

The worker branch remains the current object, with employment and unemployment transitions
driven by $\rho(h)$ and $p(\theta)$.

The entrepreneurial branch becomes

$$
V^E(a,x,i,h)
=
\max_{a',k,n_h \ge 0}
\left\{
u(c)
+ \chi_{se}\mathbf{1}\{n_h \le \varepsilon\}
+ \chi_{emp}\mathbf{1}\{n_h > \varepsilon\}
+ \beta \mathbb{E} V(a',x',e,h)
\right\}
$$

subject to

$$
c + a'
\le
(1+r-\delta)a + \pi(x,k,n_h;h) - \tau_{\pi} - T^{LS},
$$

$$
a' \ge \underline{a},
$$

and, if the financing friction is made explicit,

$$
k \le \bar{k}(a),
\qquad
\bar{k}(a) = \lambda a
\quad \text{or} \quad
\bar{k}(a) = \lambda a + \bar{b}_k.
$$

Here entrepreneurial profit is

$$
\pi(x,k,n_h;h)
=
x k^{\alpha} \left(\ell_e + \xi z(h) n_h \right)^{\gamma}
- w(1+\psi\tau) z(h) n_h
- r k
- \kappa \frac{\rho(h) z(h) n_h}{q(\theta)}
- f_h \mathbf{1}\{n_h > \varepsilon\}.
$$

This means:

- self-employed entrepreneur: $n_h \le \varepsilon$
- employer entrepreneur: $n_h > \varepsilon$

So self-employment is not a separate Bellman state in the first pass. It is a corner of
the entrepreneurial problem.

### Code translation in the current C++ structure

The current code is well suited to this extension because it already separates:

1. the static entrepreneurial scale problem
2. the dynamic savings/occupation problem
3. the simulation/reporting layer

#### 1. Static entrepreneurial scale block

The key code block is already concentrated in:

- `a_unconstrained_func()`
- `a_constrained_func()`
- `k_opt_constrained()`
- `find_credit_const()`

These routines currently build `k_opt_vec[a,x,h]`, `n_opt_vec[a,x,h]`, and
`rev_opt_vec[a,x,h]`.

For the self-employment extension, this is the first place to change the math:

- replace the current employer-only production formula with
  $x k^{\alpha}(\ell_e + \xi z n_h)^{\gamma}$
- replace the current marginal-product condition for hired labor with the new FOC
- allow the optimum to hit the corner $n_h = 0$
- compute profits/revenues using the self-employment-capable profit function

The key implementation discipline is: keep the policy object dimensions unchanged at first.
There is no need to add a new occupation index just to represent self-employment.

#### 2. Dynamic occupation/savings block

The entrepreneurial branch of the household problem is currently handled inside
`solve_opt()` when `i_occp1 == 0`.

Once `find_credit_const()` has produced self-employment-capable values for:

- `k_opt_vec`
- `n_opt_vec`
- `rev_opt_vec`

the dynamic problem can continue to treat entrepreneurship as one branch. The main new
objects to add are:

- `chi_self_emp`
- `chi_employer`
- `n_self_emp_threshold`

Then, in the entrepreneurial branch of `solve_opt()`, utility can be shifted by:

$$
\chi_{se}\mathbf{1}\{n_h \le \varepsilon\}
+ \chi_{emp}\mathbf{1}\{n_h > \varepsilon\}.
$$

That is a local code change, not a full rewrite of the value-function iteration.

#### 3. Simulation and diagnostics

The simulation block already records `n_sim`, `k0_sim`, `y_sim`, entrepreneurship shares,
and firm-size moments. For the self-employment baseline, the most important additions are
new diagnostics:

- self-employed share among entrepreneurs:
  $\Pr(n_h \le \varepsilon \mid \mathcal{I}_e = 1)$
- employer share among entrepreneurs:
  $\Pr(n_h > \varepsilon \mid \mathcal{I}_e = 1)$
- mean hired labor conditional on employer status
- by-education self-employed shares

In code terms, that means adding counters in `simulation()` using the already available
entrepreneur realization `n0_sim_tmp` / `n_sim[ppl_sim]`.

#### 4. Practical first-pass coding roadmap

The clean coding sequence is:

1. modify only the static firm block so entrepreneur policies can return `n_h = 0`
2. keep the entrepreneur/worker occupation choice binary
3. add self-employment diagnostics in simulation
4. run the new baseline and compare it to the current baseline
5. only then decide whether the existing asset-dependent scale logic should be tightened
   into a more explicit borrowing-constraint specification

So "do the math and the code" does not mean rewriting the whole model at once. The
current code structure already suggests a narrow first implementation margin.

### Main modeling implication

With this change, necessity entrepreneurship can split into two conceptually different
margins:

1. necessity self-employment
2. necessity employer entry

That distinction is likely closer to the empirical object than the current model, which
treats all entrepreneurship as employer entrepreneurship.

### Recommended sequencing

The cleanest implementation order is:

1. First pass: let the same $x$ govern both self-employment and employer production.
2. Second pass: if that makes self-employment too attractive for high-$x$ types, introduce
   the attenuation parameter $\lambda_{se}$.
3. Third pass: only after the production side is settled, consider adding a calibrated
   autonomy taste shifter such as $\chi_{se}$.
