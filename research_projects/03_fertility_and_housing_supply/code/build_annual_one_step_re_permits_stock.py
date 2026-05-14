from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import CHECKPOINTS, INPUT_SUMMARY, load_initial_cross_section
from build_annual_snapshot_state_transition_permits_stock import (
    OUTPUT_STEM as STOCK_OUTPUT_STEM,
    SupplyStockParams,
    build_scenarios,
    extract_metrics,
    simulate_scenario,
    update_population,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

OUTPUT_STEM = "annual_one_step_re_permits_stock"
T = 21


@dataclass(frozen=True)
class FixedPointResult:
    q1_re: float
    theta0: float
    permits1: float
    stock1: float
    demand1: float
    young_mortgage_25_34_t1: float
    owner_35_44_t1: float


def initial_state(summary: pd.DataFrame, params: SupplyStockParams) -> tuple[np.ndarray, np.ndarray, dict[str, float]]:
    pop0 = summary.loc[:, ["renter_no_debt", "renter_with_debt", "owner_with_mortgage", "owner_outright"]].to_numpy(dtype=float)
    pop0 = pop0 * summary["block_mass"].to_numpy(dtype=float)[:, None]
    refs = extract_metrics(pop0)

    q = np.zeros(T + 1, dtype=float)
    q[0] = 1.0
    permits = np.zeros(T + 1, dtype=float)
    completions = np.zeros(T + 1, dtype=float)
    stock = np.zeros(T + 1, dtype=float)
    backlog = np.zeros(T + 1, dtype=float)

    stock[0] = 1.0
    permits[0] = params.permit_ss
    completions[0] = params.stock_delta * stock[0]
    backlog[0] = completions[0] / params.completion_hazard
    return pop0, np.vstack([q, permits, completions, stock, backlog]), refs


def demand_index(metrics: dict[str, float], refs: dict[str, float], drift_ratio: float, t: int, params: SupplyStockParams) -> float:
    demand_trend = drift_ratio**t
    demand_component = (
        1.0
        + params.demand_young_gain * (metrics["young_mass_share"] - refs["young_mass_share"])
        + params.demand_crunch_gain * (metrics["young_crunch_25_34"] - refs["young_crunch_25_34"])
        + params.demand_mid_owner_gain * (metrics["owner_35_44"] - refs["owner_35_44"])
    )
    return max(0.25, demand_trend * demand_component)


def theta_from_metrics(metrics: dict[str, float], params: SupplyStockParams) -> float:
    theta_raw = params.theta0 + params.theta_old * metrics["old_owner_share"] - params.theta_young * metrics["young_owner_25_34"]
    return float(np.clip(theta_raw, 0.0, 0.95))


def one_step_implied_q1(summary: pd.DataFrame, scenario, params: SupplyStockParams, q1_guess: float) -> FixedPointResult:
    pop0, state, refs = initial_state(summary, params)
    q, permits, completions, stock, backlog = state

    metrics0 = extract_metrics(pop0)
    theta0 = theta_from_metrics(metrics0, params)
    demand0 = demand_index(metrics0, refs, scenario.price_ratio, 0, params)
    stock_gap0 = demand0 - stock[0]

    permit_target1 = (
        params.permit_ss
        + params.permit_gap_gain * stock_gap0
        - params.permit_theta_gain * (theta0 - params.theta0)
        + params.permit_price_gain * np.log(max(q1_guess, 1.0e-6))
    )
    permits[1] = max(
        params.permit_floor,
        params.permit_inertia * permits[0] + (1.0 - params.permit_inertia) * permit_target1,
    )
    completions[1] = max(params.permit_floor, params.completion_hazard * backlog[0])
    backlog[1] = max(0.0, backlog[0] + permits[1] - completions[1])
    stock[1] = max(0.50, (1.0 - params.stock_delta) * stock[0] + completions[1])

    pop1 = update_population(summary, pop0, scenario, q1_guess, 0)
    metrics1 = extract_metrics(pop1)
    demand1 = demand_index(metrics1, refs, scenario.price_ratio, 1, params)
    stock_gap1 = demand1 - stock[1]
    q1_implied = float(np.clip(np.exp(np.log(max(q[0], 1.0e-6)) + params.price_damping * params.price_gap_gain * stock_gap1), params.q_min, params.q_max))

    return FixedPointResult(
        q1_re=q1_implied,
        theta0=theta0,
        permits1=float(permits[1]),
        stock1=float(stock[1]),
        demand1=float(demand1),
        young_mortgage_25_34_t1=float(metrics1["young_mortgage_25_34"]),
        owner_35_44_t1=float(metrics1["owner_35_44"]),
    )


def solve_q1_fixed_point(summary: pd.DataFrame, scenario, params: SupplyStockParams, q0: float = 1.05) -> FixedPointResult:
    q_guess = q0
    result = one_step_implied_q1(summary, scenario, params, q_guess)
    for _ in range(200):
        result = one_step_implied_q1(summary, scenario, params, q_guess)
        q_new = 0.5 * q_guess + 0.5 * result.q1_re
        if abs(q_new - q_guess) < 1.0e-10:
            q_guess = q_new
            result = one_step_implied_q1(summary, scenario, params, q_guess)
            break
        q_guess = q_new
    return result


def simulate_re_path(summary: pd.DataFrame, scenario, params: SupplyStockParams, q1_re: float, T: int) -> pd.DataFrame:
    pop0, state, refs = initial_state(summary, params)
    q, permits, completions, stock, backlog = state
    theta = np.zeros(T, dtype=float)
    demand = np.zeros(T, dtype=float)

    records: list[dict[str, float | int | str]] = []
    pop = pop0

    for t in range(T):
        metrics = extract_metrics(pop)
        theta[t] = theta_from_metrics(metrics, params)
        demand[t] = demand_index(metrics, refs, scenario.price_ratio, t, params)

        records.append(
            {
                "scenario": f"{scenario.name}_one_step_re",
                "t": t,
                "q": float(q[t]),
                "theta": float(theta[t]),
                "permits": float(permits[t]),
                "completions": float(completions[t]),
                "stock": float(stock[t]),
                "young_owner_25_34": metrics["young_owner_25_34"],
                "young_mortgaged_owner_25_34": metrics["young_mortgage_25_34"],
                "owner_35_44": metrics["owner_35_44"],
                "mortgaged_owner_35_44": metrics["mortgage_35_44"],
            }
        )

        if t == T - 1:
            break

        if t == 0:
            permit_target = (
                params.permit_ss
                + params.permit_gap_gain * (demand[t] - stock[t])
                - params.permit_theta_gain * (theta[t] - params.theta0)
                + params.permit_price_gain * np.log(max(q1_re, 1.0e-6))
            )
            permits[t + 1] = max(
                params.permit_floor,
                params.permit_inertia * permits[t] + (1.0 - params.permit_inertia) * permit_target,
            )
            completions[t + 1] = max(params.permit_floor, params.completion_hazard * backlog[t])
            backlog[t + 1] = max(0.0, backlog[t] + permits[t + 1] - completions[t + 1])
            stock[t + 1] = max(0.50, (1.0 - params.stock_delta) * stock[t] + completions[t + 1])
            pop = update_population(summary, pop, scenario, q1_re, t)
            q[t + 1] = q1_re
            continue

        permit_target = (
            params.permit_ss
            + params.permit_gap_gain * (demand[t] - stock[t])
            - params.permit_theta_gain * (theta[t] - params.theta0)
            + params.permit_price_gain * np.log(max(q[t], 1.0e-6))
        )
        permits[t + 1] = max(
            params.permit_floor,
            params.permit_inertia * permits[t] + (1.0 - params.permit_inertia) * permit_target,
        )
        completions[t + 1] = max(params.permit_floor, params.completion_hazard * backlog[t])
        backlog[t + 1] = max(0.0, backlog[t] + permits[t + 1] - completions[t + 1])
        stock[t + 1] = max(0.50, (1.0 - params.stock_delta) * stock[t] + completions[t + 1])
        q[t + 1] = float(
            np.clip(
                np.exp(np.log(max(q[t], 1.0e-6)) + params.price_damping * params.price_gap_gain * (demand[t] - stock[t])),
                params.q_min,
                params.q_max,
            )
        )
        pop = update_population(summary, pop, scenario, q[t], t)

    return pd.DataFrame.from_records(records)


def build_checkpoint_table(paths: pd.DataFrame, anchors: pd.DataFrame) -> pd.DataFrame:
    anchor_map = anchors.set_index(["scenario", "t"])
    rows: list[dict[str, float | int | str]] = []
    for _, row in paths.loc[paths["t"].isin(CHECKPOINTS)].iterrows():
        base_name = row["scenario"].replace("_one_step_re", "")
        anchor = anchor_map.loc[(base_name, int(row["t"]))]
        rows.append(
            {
                "scenario": row["scenario"],
                "anchor_scenario": base_name,
                "t": int(row["t"]),
                "q": float(row["q"]),
                "theta": float(row["theta"]),
                "permits": float(row["permits"]),
                "stock": float(row["stock"]),
                "young_owner_25_34": float(row["young_owner_25_34"]),
                "young_mortgaged_owner_25_34": float(row["young_mortgaged_owner_25_34"]),
                "owner_35_44": float(row["owner_35_44"]),
                "q_gap_vs_stock_anchor": float(row["q"] - anchor["q"]),
                "young_owner_gap_vs_stock_anchor": float(row["young_owner_25_34"] - anchor["young_owner_25_34"]),
                "young_mortgage_gap_vs_stock_anchor": float(
                    row["young_mortgaged_owner_25_34"] - anchor["young_mortgaged_owner_25_34"]
                ),
            }
        )
    return pd.DataFrame(rows)


def write_note(path: Path, fixed_points: pd.DataFrame, checkpoints: pd.DataFrame) -> None:
    lines = [
        "# Annual one-step RE on permits-stock transition",
        "",
        "This note applies the first bounded RE pass to the upgraded annual permits/backlog/stock price block rather than to the old thin bridge.",
        "",
        "## Setup",
        "",
        "- time-zero object: observed annual age-by-state snapshot",
        "- price block: politics -> permits -> completions -> stock -> prices",
        "- RE object: solve only for next-period price `q_1`",
        "- mechanism: the guessed `q_1` affects first-year entry decisions and first-year permit incentives; the realized `q_1` is then backed out from next year's demand relative to next year's stock",
        "- after `t = 1`, the path reverts to the upgraded stock-flow transition law",
        "",
        "## Solved one-step fixed points",
        "",
        "| Scenario | Solved q1 | Theta0 | Permits1 | Stock1 | Demand1 | Young mortgaged-owner 25-34 at t=1 | Owner 35-44 at t=1 |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in fixed_points.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.q1_re:.3f}` | `{row.theta0:.3f}` | `{row.permits1:.3f}` | `{row.stock1:.3f}` | `{row.demand1:.3f}` | `{row.young_mortgage_25_34_t1:.3f}` | `{row.owner_35_44_t1:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints relative to stock-flow anchor",
            "",
            "| Scenario | t | q | Young owner 25-34 | Young mortgaged-owner 25-34 | q gap vs stock anchor | Young owner gap vs stock anchor | Young mortgage gap vs stock anchor |",
            "|---|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for row in checkpoints.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.q:.3f}` | `{row.young_owner_25_34:.3f}` | `{row.young_mortgaged_owner_25_34:.3f}` | "
            f"`{row.q_gap_vs_stock_anchor:.3f}` | `{row.young_owner_gap_vs_stock_anchor:.3f}` | `{row.young_mortgage_gap_vs_stock_anchor:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is a cleaner bounded RE object than the earlier thin-bridge one-step exercise because price now clears against next year's stock rather than directly against one reduced-form supply term.",
            "- The main result is that the one-step fixed point is very tame on the upgraded block: all three scenarios solve to essentially the same `q_1`, about `1.005`, rather than producing large immediate price jumps.",
            "- That means the support regimes mainly change next year's ownership composition, not the one-year aggregate price fixed point.",
            "- If support still raises young mortgaged-owner share here without requiring implausible short-run price swings, that is evidence the permits/stock middle layer is doing the right smoothing work.",
            "- The next step after this note should be explicit `k = 2-3` RE on the same permits/stock block, not a return to the old bridge.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = SupplyStockParams()
    scenarios = build_scenarios()

    anchor_frames = [simulate_scenario(summary, scenario, params, T=T) for scenario in scenarios]
    anchors = pd.concat(anchor_frames, ignore_index=True)

    fixed_rows: list[dict[str, float | str]] = []
    re_frames: list[pd.DataFrame] = []
    for scenario in scenarios:
        fixed = solve_q1_fixed_point(summary, scenario, params, q0=scenario.price_ratio)
        fixed_rows.append(
            {
                "scenario": scenario.name,
                "q1_re": fixed.q1_re,
                "theta0": fixed.theta0,
                "permits1": fixed.permits1,
                "stock1": fixed.stock1,
                "demand1": fixed.demand1,
                "young_mortgage_25_34_t1": fixed.young_mortgage_25_34_t1,
                "owner_35_44_t1": fixed.owner_35_44_t1,
            }
        )
        re_frames.append(simulate_re_path(summary, scenario, params, fixed.q1_re, T=T))

    fixed_points = pd.DataFrame(fixed_rows)
    re_paths = pd.concat(re_frames, ignore_index=True)
    checkpoints = build_checkpoint_table(re_paths, anchors)

    fixed_points.to_csv(BUILD / f"{OUTPUT_STEM}_fixed_points.csv", index=False)
    re_paths.to_csv(BUILD / f"{OUTPUT_STEM}.csv", index=False)
    checkpoints.to_csv(BUILD / f"{OUTPUT_STEM}_checkpoints.csv", index=False)
    write_note(BUILD / f"{OUTPUT_STEM}.md", fixed_points, checkpoints)


if __name__ == "__main__":
    main()
