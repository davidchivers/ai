from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import CHECKPOINTS, INPUT_SUMMARY, load_initial_cross_section
from build_annual_snapshot_state_transition_permits_stock import (
    SupplyStockParams,
    build_scenarios,
    extract_metrics,
    simulate_scenario,
    update_population,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

OUTPUT_STEM = "annual_two_step_re_permits_stock"
T = 21


@dataclass(frozen=True)
class TwoStepFixedPoint:
    q1_re: float
    q2_re: float
    theta0: float
    theta1: float
    permits1: float
    permits2: float
    stock1: float
    stock2: float
    demand1: float
    demand2: float
    young_mortgage_25_34_t1: float
    young_mortgage_25_34_t2: float


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


def implied_q_next(q_current: float, demand_t: float, stock_t: float, params: SupplyStockParams) -> float:
    return float(
        np.clip(
            np.exp(np.log(max(q_current, 1.0e-6)) + params.price_damping * params.price_gap_gain * (demand_t - stock_t)),
            params.q_min,
            params.q_max,
        )
    )


def permit_update(permits_t: float, theta_t: float, demand_t: float, stock_t: float, q_effective: float, params: SupplyStockParams) -> float:
    permit_target = (
        params.permit_ss
        + params.permit_gap_gain * (demand_t - stock_t)
        - params.permit_theta_gain * (theta_t - params.theta0)
        + params.permit_price_gain * np.log(max(q_effective, 1.0e-6))
    )
    return max(params.permit_floor, params.permit_inertia * permits_t + (1.0 - params.permit_inertia) * permit_target)


def backlog_stock_update(backlog_t: float, stock_t: float, permits_next: float, params: SupplyStockParams) -> tuple[float, float]:
    completions_next = max(params.permit_floor, params.completion_hazard * backlog_t)
    backlog_next = max(0.0, backlog_t + permits_next - completions_next)
    stock_next = max(0.50, (1.0 - params.stock_delta) * stock_t + completions_next)
    return backlog_next, stock_next


def two_step_implied(summary: pd.DataFrame, scenario, params: SupplyStockParams, q1_guess: float, q2_guess: float) -> TwoStepFixedPoint:
    pop0, state, refs = initial_state(summary, params)
    q, permits, completions, stock, backlog = state

    # t = 0 -> 1
    metrics0 = extract_metrics(pop0)
    theta0 = theta_from_metrics(metrics0, params)
    demand0 = demand_index(metrics0, refs, scenario.price_ratio, 0, params)
    permits[1] = permit_update(permits[0], theta0, demand0, stock[0], q1_guess, params)
    completions[1] = max(params.permit_floor, params.completion_hazard * backlog[0])
    backlog[1], stock[1] = backlog_stock_update(backlog[0], stock[0], permits[1], params)
    pop1 = update_population(summary, pop0, scenario, q1_guess, 0)
    metrics1 = extract_metrics(pop1)
    theta1 = theta_from_metrics(metrics1, params)
    demand1 = demand_index(metrics1, refs, scenario.price_ratio, 1, params)
    q1_implied = implied_q_next(q[0], demand1, stock[1], params)

    # t = 1 -> 2
    permits[2] = permit_update(permits[1], theta1, demand1, stock[1], q2_guess, params)
    completions[2] = max(params.permit_floor, params.completion_hazard * backlog[1])
    backlog[2], stock[2] = backlog_stock_update(backlog[1], stock[1], permits[2], params)
    pop2 = update_population(summary, pop1, scenario, q2_guess, 1)
    metrics2 = extract_metrics(pop2)
    demand2 = demand_index(metrics2, refs, scenario.price_ratio, 2, params)
    q2_implied = implied_q_next(q1_implied, demand2, stock[2], params)

    return TwoStepFixedPoint(
        q1_re=q1_implied,
        q2_re=q2_implied,
        theta0=theta0,
        theta1=theta1,
        permits1=float(permits[1]),
        permits2=float(permits[2]),
        stock1=float(stock[1]),
        stock2=float(stock[2]),
        demand1=float(demand1),
        demand2=float(demand2),
        young_mortgage_25_34_t1=float(metrics1["young_mortgage_25_34"]),
        young_mortgage_25_34_t2=float(metrics2["young_mortgage_25_34"]),
    )


def solve_q12_fixed_point(summary: pd.DataFrame, scenario, params: SupplyStockParams, q1_0: float, q2_0: float) -> TwoStepFixedPoint:
    q1_guess = q1_0
    q2_guess = q2_0
    result = two_step_implied(summary, scenario, params, q1_guess, q2_guess)
    for _ in range(300):
        result = two_step_implied(summary, scenario, params, q1_guess, q2_guess)
        q1_new = 0.5 * q1_guess + 0.5 * result.q1_re
        q2_new = 0.5 * q2_guess + 0.5 * result.q2_re
        if abs(q1_new - q1_guess) < 1.0e-10 and abs(q2_new - q2_guess) < 1.0e-10:
            q1_guess = q1_new
            q2_guess = q2_new
            result = two_step_implied(summary, scenario, params, q1_guess, q2_guess)
            break
        q1_guess = q1_new
        q2_guess = q2_new
    return result


def simulate_re_path(summary: pd.DataFrame, scenario, params: SupplyStockParams, q1_re: float, q2_re: float, T: int) -> pd.DataFrame:
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
                "scenario": f"{scenario.name}_two_step_re",
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
            permits[1] = permit_update(permits[0], theta[t], demand[t], stock[t], q1_re, params)
            completions[1] = max(params.permit_floor, params.completion_hazard * backlog[0])
            backlog[1], stock[1] = backlog_stock_update(backlog[0], stock[0], permits[1], params)
            pop = update_population(summary, pop, scenario, q1_re, 0)
            q[1] = q1_re
            continue

        if t == 1:
            permits[2] = permit_update(permits[1], theta[t], demand[t], stock[t], q2_re, params)
            completions[2] = max(params.permit_floor, params.completion_hazard * backlog[1])
            backlog[2], stock[2] = backlog_stock_update(backlog[1], stock[1], permits[2], params)
            pop = update_population(summary, pop, scenario, q2_re, 1)
            q[2] = q2_re
            continue

        permits[t + 1] = permit_update(permits[t], theta[t], demand[t], stock[t], q[t], params)
        completions[t + 1] = max(params.permit_floor, params.completion_hazard * backlog[t])
        backlog[t + 1], stock[t + 1] = backlog_stock_update(backlog[t], stock[t], permits[t + 1], params)
        q[t + 1] = implied_q_next(q[t], demand[t], stock[t + 1], params)
        pop = update_population(summary, pop, scenario, q[t], t)

    return pd.DataFrame.from_records(records)


def build_checkpoint_table(paths: pd.DataFrame, anchors: pd.DataFrame) -> pd.DataFrame:
    anchor_map = anchors.set_index(["scenario", "t"])
    rows: list[dict[str, float | int | str]] = []
    for _, row in paths.loc[paths["t"].isin(CHECKPOINTS)].iterrows():
        base_name = row["scenario"].replace("_two_step_re", "")
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
        "# Annual two-step RE on permits-stock transition",
        "",
        "This note extends bounded RE on the upgraded annual permits/backlog/stock price block from one-step-ahead prices to an explicit two-step price horizon.",
        "",
        "## Setup",
        "",
        "- time-zero object: observed annual age-by-state snapshot",
        "- price block: politics -> permits -> completions -> stock -> prices",
        "- RE horizon: jointly solve `q_1` and `q_2`",
        "- `q_1` affects year-1 entry decisions and year-1 permit incentives",
        "- `q_2` affects year-2 entry decisions and year-2 permit incentives",
        "- after `t = 2`, the path reverts to the upgraded stock-flow transition law",
        "",
        "## Solved two-step fixed points",
        "",
        "| Scenario | q1 | q2 | Theta0 | Theta1 | Permits1 | Permits2 | Stock1 | Stock2 | Young mortgage 25-34 at t=1 | Young mortgage 25-34 at t=2 |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in fixed_points.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.q1_re:.3f}` | `{row.q2_re:.3f}` | `{row.theta0:.3f}` | `{row.theta1:.3f}` | "
            f"`{row.permits1:.3f}` | `{row.permits2:.3f}` | `{row.stock1:.3f}` | `{row.stock2:.3f}` | "
            f"`{row.young_mortgage_25_34_t1:.3f}` | `{row.young_mortgage_25_34_t2:.3f}` |"
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
            "- This is the first explicit multi-period RE pass on the upgraded permits/stock block.",
            "- If the solved `q_1` and `q_2` remain moderate and the paths stay close to the stock-flow anchors, that means the upgraded block is absorbing near-horizon expectations much more smoothly than the old thin bridge.",
            "- If this two-step pass remains economically tame, the next rung is explicit `k = 3` RE on the same upgraded block.",
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
        fixed = solve_q12_fixed_point(summary, scenario, params, q1_0=scenario.price_ratio, q2_0=scenario.price_ratio**2)
        fixed_rows.append(
            {
                "scenario": scenario.name,
                "q1_re": fixed.q1_re,
                "q2_re": fixed.q2_re,
                "theta0": fixed.theta0,
                "theta1": fixed.theta1,
                "permits1": fixed.permits1,
                "permits2": fixed.permits2,
                "stock1": fixed.stock1,
                "stock2": fixed.stock2,
                "demand1": fixed.demand1,
                "demand2": fixed.demand2,
                "young_mortgage_25_34_t1": fixed.young_mortgage_25_34_t1,
                "young_mortgage_25_34_t2": fixed.young_mortgage_25_34_t2,
            }
        )
        re_frames.append(simulate_re_path(summary, scenario, params, fixed.q1_re, fixed.q2_re, T=T))

    fixed_points = pd.DataFrame(fixed_rows)
    re_paths = pd.concat(re_frames, ignore_index=True)
    checkpoints = build_checkpoint_table(re_paths, anchors)

    fixed_points.to_csv(BUILD / f"{OUTPUT_STEM}_fixed_points.csv", index=False)
    re_paths.to_csv(BUILD / f"{OUTPUT_STEM}.csv", index=False)
    checkpoints.to_csv(BUILD / f"{OUTPUT_STEM}_checkpoints.csv", index=False)
    write_note(BUILD / f"{OUTPUT_STEM}.md", fixed_points, checkpoints)


if __name__ == "__main__":
    main()
