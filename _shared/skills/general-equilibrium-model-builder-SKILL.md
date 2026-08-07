---
name: general-equilibrium-model-builder
description: Build, derive, solve, and check Walrasian general-equilibrium models, with emphasis on pure-exchange economies and Julia computation. Use when formulating consumer problems, market-clearing conditions, equilibrium or welfare claims, comparative statics, or numerical solution routines for microeconomic general-equilibrium work.
---

# General Equilibrium Model Builder

Build the economic object before writing solver code. Treat an exercise, manuscript, and live implementation as potentially different authorities; identify which one governs and report discrepancies rather than silently reconciling them.

## Establish the model contract

Infer as much as possible from the supplied material. Ask only about an unresolved choice that changes the equilibrium concept, derivation, or computation.

Record a compact ledger:

| Field | Required content |
|---|---|
| Scope | Pure exchange, production, uncertainty, dynamics, or another environment |
| Agents and goods | Index sets, dimensions, and heterogeneity |
| Primitives | Preferences, technologies if any, endowments, constraints, and parameters |
| Equilibrium concept | Prices, allocations, individual optimality, feasibility, and market clearing |
| Requested result | Derivation, proof, comparative statics, code, figure, or teaching explanation |
| Authority | Exercise, manuscript section, code path, or explicit user instruction |

Do not add production, uncertainty, transfers, a social planner, or a welfare criterion unless the task requires them.

## Formulate the economy

Present intuition first, define variables second, and write equations third. Define every symbol before use.

For a pure-exchange economy, state the primitives as

$$\mathcal E=\{(u_i,\omega_i)\}_{i=1}^I,$$

then write each consumer problem at prices $p$:

$$\max_{x_i\geq 0} u_i(x_i)\quad\text{s.t.}\quad p\cdot x_i\leq p\cdot\omega_i.$$

Derive demand from the stated preferences. Check whether monotonicity makes the budget bind and whether interior first-order conditions are valid. Handle corners, kinks, zero endowments, non-convexities, or satiation explicitly rather than applying interior formulas mechanically.

Define excess demand as

$$z(p)=\sum_i x_i(p,p\cdot\omega_i)-\sum_i\omega_i.$$

Define an equilibrium as individual optimality plus feasibility or market clearing. State a price normalization because only relative prices are identified. Use Walras' law as a check and, where its assumptions hold, to remove one redundant market-clearing equation.

## Derive and qualify results

1. Derive individual demands or optimality conditions.
2. Substitute them into market-clearing conditions.
3. Solve analytically when structure permits; otherwise expose the residual system for computation.
4. State the assumptions supporting existence, uniqueness, efficiency, or comparative-statics claims next to those claims.
5. Distinguish a necessary first-order condition from a sufficient optimum and a computed root from an equilibrium.

Do not claim uniqueness from a single numerical solution. Do not infer Pareto efficiency from market clearing alone. If a welfare theorem is relevant, check local nonsatiation, convexity, completeness of markets, and any transfer assumptions actually needed.

## Implement the numerical problem

Follow the existing language and project conventions. For Julia work, inspect the current environment and APIs before selecting a nonlinear solver; do not add packages unless authorized.

Construct computation around economic functions rather than a monolithic example:

- map primitives and parameters into individual demand or policy functions;
- compute wealth from current prices and endowments;
- return aggregate excess demand with a documented goods ordering;
- solve $L-1$ independent residuals under an explicit normalization;
- preserve positive prices with a log-relative-price or other justified parameterization;
- make tolerances, iteration limits, and solver status visible;
- try economically distinct initial values or continuation steps when multiplicity or poor conditioning is plausible.

Never paste an untested canned solver. Run the live code when execution is in scope, and keep analytical formulas and implementation conventions aligned.

## Verify the candidate

Report numerical checks with tolerances, not only a convergence flag:

| Check | Evidence |
|---|---|
| Individual feasibility | Nonnegative choices and budget residuals |
| Individual optimality | FOCs plus second-order or global checks appropriate to preferences |
| Market clearing | Good-by-good residuals and their maximum norm |
| Walras' law | $p\cdot z(p)$ when applicable |
| Price validity | Positivity and stated normalization |
| Resource feasibility | Aggregate allocation versus aggregate endowment |
| Robustness | Multiple starts, nearby parameters, or alternative solver settings |

For two-good interior allocations, equality of marginal rates of substitution can be a useful welfare diagnostic, but it is not a general-purpose efficiency proof. Treat boundary allocations separately.

## Cross-check and deliver

Compare notation, parameter transformations, indexing, normalization, and residual definitions across the manuscript and code. Report any mismatch with its consequence.

Deliver only the requested combination of:

- a primitives-to-equilibrium derivation;
- reproducible code integrated with the existing project;
- a verification table with actual residuals;
- comparative statics that separate theoretical sign predictions from numerical findings;
- a diagram whose axes, origins, endowments, budget line, and allocations are internally consistent.

Do not invent parameter values, numerical results, citations, or theorem assumptions. Mark anything not verified from the supplied sources as unresolved.
