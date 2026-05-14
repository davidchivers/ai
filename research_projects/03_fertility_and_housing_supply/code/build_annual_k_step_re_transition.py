from __future__ import annotations

import argparse
from dataclasses import dataclass
from math import exp, log
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import (
    INPUT_SUMMARY,
    STATE_ORDER,
    Scenario,
    adjust_matrix,
    build_base_transition_matrices,
    load_initial_cross_section,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

OUTPUT_STEM = "annual_k_step_re_transition"
TERMINAL_DRIFT = 1.05
T = 21
HORIZONS = (1, 2, 3, 5, 8, 12, 20)
RE_WEIGHTS = (0.25, 0.50, 0.75, 1.00, 1.25)
DEFAULT_MIN_Q = 0.80
DEFAULT_MAX_Q = 1.25
MAX_ITER = 600
TOL = 1.0e-9


@dataclass(frozen=True)
class REScenario:
    name: str
    deposit_help_weight: float
    qualification_weight: float
    targeted_support: bool = True
    support_center: float = 0.18
    support_width: float = 0.04
    mid_age_scale: float = 0.80


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run a bounded k-step RE sweep on the annual transition object."
    )
    parser.add_argument(
        "--output-stem",
        default=OUTPUT_STEM,
        help="Output filename stem in notes/build/.",
    )
    parser.add_argument(
        "--min-q",
        type=float,
        default=DEFAULT_MIN_Q,
        help="Lower bound for admissible annual price ratios during RE iteration.",
    )
    parser.add_argument(
        "--max-q",
        type=float,
        default=DEFAULT_MAX_Q,
        help="Upper bound for admissible annual price ratios during RE iteration.",
    )
    return parser.parse_args()


def housing_pressure_index_from_row(row: pd.Series) -> float:
    return float(
        row["young_mortgaged_owner_share_25_34"]
        + row["young_renter_with_debt_share_25_34"]
        + 0.5 * (1.0 - row["owner_share_35_44"])
    )


def simulate_price_path(
    summary: pd.DataFrame,
    scenario: Scenario,
    price_path: np.ndarray,
    terminal_price_ratio: float,
    T: int,
) -> pd.DataFrame:
    base_matrices = build_base_transition_matrices()
    age_blocks = list(summary["age_block"])
    widths = (summary["age_hi"] - summary["age_lo"] + 1).to_numpy(dtype=float)
    block_masses = summary["block_mass"].to_numpy(dtype=float)
    pop = summary.loc[:, STATE_ORDER].to_numpy(dtype=float) * block_masses[:, None]
    entrant_mix = summary.loc[
        summary["age_block"] == "25-34", STATE_ORDER
    ].iloc[0].to_numpy(dtype=float)

    records: list[dict[str, float | str | int]] = []
    for t in range(T):
        total = float(pop.sum())
        young_idx = 0
        mid_idx = 1
        current_price = 1.0 if t == 0 else (
            float(price_path[t - 1]) if t - 1 < len(price_path) else terminal_price_ratio
        )
        records.append(
            {
                "t": t,
                "price_ratio": current_price,
                "young_owner_share_25_34": float(
                    (pop[young_idx, 2] + pop[young_idx, 3]) / block_masses[young_idx]
                ),
                "young_mortgaged_owner_share_25_34": float(
                    pop[young_idx, 2] / block_masses[young_idx]
                ),
                "young_renter_with_debt_share_25_34": float(
                    pop[young_idx, 1] / block_masses[young_idx]
                ),
                "young_crunch_share_25_34": float(
                    (pop[young_idx, 1] + pop[young_idx, 2]) / block_masses[young_idx]
                ),
                "owner_share_35_44": float(
                    (pop[mid_idx, 2] + pop[mid_idx, 3]) / block_masses[mid_idx]
                ),
                "mortgaged_owner_share_35_44": float(
                    pop[mid_idx, 2] / block_masses[mid_idx]
                ),
                "aggregate_owner_share": float((pop[:, 2] + pop[:, 3]).sum() / total),
                "aggregate_mortgaged_owner_share": float(pop[:, 2].sum() / total),
            }
        )

        post = np.zeros_like(pop)
        transition_price = (
            float(price_path[t]) if t < len(price_path) else terminal_price_ratio
        )
        for i, age_block in enumerate(age_blocks):
            matrix = adjust_matrix(
                base_matrices[age_block],
                age_block=age_block,
                price_ratio=transition_price,
                deposit_help_weight=scenario.deposit_help_weight,
                qualification_weight=scenario.qualification_weight,
                deposit_help_horizon=0,
                qualification_horizon=0,
                targeted_support=scenario.targeted_support,
                support_center=scenario.support_center,
                support_width=scenario.support_width,
                mid_age_scale=scenario.mid_age_scale,
                t=t,
            )
            post[i, :] = pop[i, :] @ matrix

        new_pop = np.zeros_like(pop)
        outflows = np.zeros_like(pop)
        for i in range(len(age_blocks)):
            outflows[i, :] = post[i, :] / widths[i]
            new_pop[i, :] += post[i, :] - outflows[i, :]
        for i in range(1, len(age_blocks)):
            new_pop[i, :] += outflows[i - 1, :]

        entrant_mass = float(outflows[-1, :].sum())
        new_pop[0, :] += entrant_mass * entrant_mix
        pop = new_pop

    return pd.DataFrame.from_records(records)


def build_anchor_paths(summary: pd.DataFrame, max_horizon: int) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    baseline = Scenario(
        "anchor_baseline",
        TERMINAL_DRIFT,
        0.0,
        0.0,
        0,
        0,
        True,
        support_center=0.18,
        support_width=0.04,
        mid_age_scale=0.80,
    )
    no_shock_path = simulate_price_path(
        summary,
        baseline,
        price_path=np.full(max_horizon, 1.0),
        terminal_price_ratio=1.0,
        T=max_horizon + 1,
    )
    drift_path = simulate_price_path(
        summary,
        baseline,
        price_path=np.full(max_horizon, TERMINAL_DRIFT),
        terminal_price_ratio=TERMINAL_DRIFT,
        T=max_horizon + 1,
    )

    no_shock_pressures = np.array(
        [
            housing_pressure_index_from_row(
                no_shock_path.loc[no_shock_path["t"] == t].iloc[0]
            )
            for t in range(1, max_horizon + 1)
        ],
        dtype=float,
    )
    drift_pressures = np.array(
        [
            housing_pressure_index_from_row(
                drift_path.loc[drift_path["t"] == t].iloc[0]
            )
            for t in range(1, max_horizon + 1)
        ],
        dtype=float,
    )

    slopes = np.zeros(max_horizon, dtype=float)
    for i in range(max_horizon):
        gap = drift_pressures[i] - no_shock_pressures[i]
        slopes[i] = 0.0 if abs(gap) < 1.0e-12 else log(TERMINAL_DRIFT) / gap
    return no_shock_pressures, drift_pressures, slopes


def solve_k_step_re(
    summary: pd.DataFrame,
    re_scenario: REScenario,
    horizon: int,
    re_weight: float,
    pressure_anchor: np.ndarray,
    slopes: np.ndarray,
    min_q: float,
    max_q: float,
) -> tuple[dict[str, float | int | str | bool], pd.DataFrame]:
    q = np.full(horizon, TERMINAL_DRIFT, dtype=float)
    converged = False
    status = "max_iter"
    last_path = simulate_price_path(
        summary,
        Scenario(
            re_scenario.name,
            TERMINAL_DRIFT,
            re_scenario.deposit_help_weight,
            re_scenario.qualification_weight,
            0,
            0,
            re_scenario.targeted_support,
            support_center=re_scenario.support_center,
            support_width=re_scenario.support_width,
            mid_age_scale=re_scenario.mid_age_scale,
        ),
        price_path=q,
        terminal_price_ratio=TERMINAL_DRIFT,
        T=max(T, horizon + 1),
    )
    residual = float("nan")

    for iteration in range(1, MAX_ITER + 1):
        path = simulate_price_path(
            summary,
            Scenario(
                re_scenario.name,
                TERMINAL_DRIFT,
                re_scenario.deposit_help_weight,
                re_scenario.qualification_weight,
                0,
                0,
                re_scenario.targeted_support,
                support_center=re_scenario.support_center,
                support_width=re_scenario.support_width,
                mid_age_scale=re_scenario.mid_age_scale,
            ),
            price_path=q,
            terminal_price_ratio=TERMINAL_DRIFT,
            T=max(T, horizon + 1),
        )
        pressures = np.array(
            [
                housing_pressure_index_from_row(path.loc[path["t"] == t].iloc[0])
                for t in range(1, horizon + 1)
            ],
            dtype=float,
        )
        implied_q = np.exp(
            np.log(TERMINAL_DRIFT)
            + re_weight * slopes[:horizon] * (pressures - pressure_anchor[:horizon])
        )
        updated_q = 0.5 * q + 0.5 * implied_q
        residual = float(np.max(np.abs(updated_q - q)))

        if not np.all(np.isfinite(updated_q)):
            status = "non_finite"
            q = updated_q
            last_path = path
            break
        if float(updated_q.min()) < min_q or float(updated_q.max()) > max_q:
            status = "out_of_bounds"
            q = updated_q
            last_path = path
            break
        if residual < TOL:
            q = updated_q
            last_path = path
            converged = True
            status = "converged"
            break

        q = updated_q
        last_path = path

    result = {
        "scenario": re_scenario.name,
        "horizon": horizon,
        "re_weight": re_weight,
        "status": status,
        "converged": int(converged),
        "iterations": iteration,
        "residual": residual,
        "q_min": float(np.nanmin(q)),
        "q_max": float(np.nanmax(q)),
        "q1": float(q[0]),
        "qk": float(q[horizon - 1]),
        "young_mortgage_t1": float(
            last_path.loc[last_path["t"] == 1, "young_mortgaged_owner_share_25_34"].iloc[0]
        ),
        "young_mortgage_t5": float(
            last_path.loc[last_path["t"] == 5, "young_mortgaged_owner_share_25_34"].iloc[0]
        ),
        "young_mortgage_t20": float(
            last_path.loc[last_path["t"] == 20, "young_mortgaged_owner_share_25_34"].iloc[0]
        ),
    }

    path_out = last_path.loc[last_path["t"].isin((0, 1, 2, 3, 5, 8, 12, 20))].copy()
    path_out.insert(0, "scenario", re_scenario.name)
    path_out.insert(1, "horizon", horizon)
    path_out.insert(2, "re_weight", re_weight)
    path_out.insert(3, "status", status)
    return result, path_out


def main() -> None:
    args = parse_args()
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    summary = load_initial_cross_section(INPUT_SUMMARY)
    _, pressure_anchor, slopes = build_anchor_paths(summary, max(HORIZONS))

    cases = [
        REScenario("baseline", 0.0, 0.0),
        REScenario("benchmark", 0.15, 0.25),
        REScenario("robustness", 0.30, 0.40),
    ]

    summary_rows: list[dict[str, float | int | str | bool]] = []
    path_rows: list[pd.DataFrame] = []
    for case in cases:
        for re_weight in RE_WEIGHTS:
            for horizon in HORIZONS:
                result, path = solve_k_step_re(
                    summary=summary,
                    re_scenario=case,
                    horizon=horizon,
                    re_weight=re_weight,
                    pressure_anchor=pressure_anchor,
                    slopes=slopes,
                    min_q=args.min_q,
                    max_q=args.max_q,
                )
                summary_rows.append(result)
                path_rows.append(path)

    results = pd.DataFrame.from_records(summary_rows)
    paths = pd.concat(path_rows, ignore_index=True)

    frontier_rows: list[dict[str, float | str | int | None]] = []
    for (scenario, re_weight), group in results.groupby(["scenario", "re_weight"], sort=False):
        group = group.sort_values("horizon")
        stable = group.loc[group["status"] == "converged"]
        frontier_rows.append(
            {
                "scenario": scenario,
                "re_weight": re_weight,
                "max_stable_horizon": int(stable["horizon"].max()) if not stable.empty else 0,
                "first_nonconverged_horizon": (
                    int(group.loc[group["status"] != "converged", "horizon"].iloc[0])
                    if (group["status"] != "converged").any()
                    else ""
                ),
            }
        )
    frontier = pd.DataFrame.from_records(frontier_rows)

    results.to_csv(BUILD / f"{args.output_stem}.csv", index=False)
    paths.to_csv(BUILD / f"{args.output_stem}_paths.csv", index=False)
    frontier.to_csv(BUILD / f"{args.output_stem}_frontier.csv", index=False)

    lines = [
        "# Annual k-step RE transition sweep",
        "",
        "This note extends the bounded annual RE layer beyond one-step-ahead prices.",
        "It is still not full infinite-horizon RE. The object is a finite-horizon fixed point on the next `k` annual house-price levels, with the tail closed by the standing `+5%` drift rule.",
        "",
        "## Setup",
        "",
        f"- terminal drift after the RE horizon: `{TERMINAL_DRIFT:.3f}`",
        f"- RE weight sweep: `{', '.join(f'{w:.2f}' for w in RE_WEIGHTS)}`",
        f"- horizon sweep: `{', '.join(str(h) for h in HORIZONS)}`",
        f"- admissible price box during iteration: `[{args.min_q:.2f}, {args.max_q:.2f}]`",
        "- scenarios:",
        "  - `baseline`: no support",
        "  - `benchmark`: qualification `0.25`, family help `0.15`",
        "  - `robustness`: qualification `0.40`, family help `0.30`",
        "",
        "## Stability frontier",
        "",
        "| Scenario | RE weight | Max stable horizon | First non-converged horizon |",
        "|---|---:|---:|---:|",
    ]
    for row in frontier.itertuples(index=False):
        first_bad = "" if row.first_nonconverged_horizon == "" else str(int(row.first_nonconverged_horizon))
        lines.append(
            f"| `{row.scenario}` | `{row.re_weight:.2f}` | `{int(row.max_stable_horizon)}` | `{first_bad}` |"
        )

    lines.extend(
        [
            "",
            "## Sweep summary",
            "",
            "| Scenario | RE weight | Horizon | Status | Iterations | q1 | qk | Young mortgaged-owner t=1 | t=5 | t=20 |",
            "|---|---:|---:|---|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for row in results.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.re_weight:.2f}` | `{int(row.horizon)}` | `{row.status}` | "
            f"`{int(row.iterations)}` | `{row.q1:.3f}` | `{row.qk:.3f}` | "
            f"`{row.young_mortgage_t1:.3f}` | `{row.young_mortgage_t5:.3f}` | `{row.young_mortgage_t20:.3f}` |"
        )

    stable_benchmark = results.loc[
        (results["scenario"] == "benchmark") & (results["status"] == "converged")
    ].sort_values(["re_weight", "horizon"])
    stable_robust = results.loc[
        (results["scenario"] == "robustness") & (results["status"] == "converged")
    ].sort_values(["re_weight", "horizon"])
    lines.extend(
        [
            "",
            "## Read",
            "",
            "- `k = 1` reproduces the earlier bounded RE logic as the smallest case.",
            "- Increasing `k` asks for more internal consistency on near-term prices without trying to solve the full annual path.",
            "- If the sweep converges for longer horizons, that says the bounded RE layer is numerically tame in this reduced-form box.",
            "- If the sweep stops converging or leaves the admissible price box, that is the first sign that the RE layer is starting to go mental.",
            "",
            f"- Benchmark stable cases counted: `{len(stable_benchmark)}`.",
            f"- Robustness stable cases counted: `{len(stable_robust)}`.",
        ]
    )

    (BUILD / f"{args.output_stem}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
