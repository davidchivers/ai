from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import CHECKPOINTS, INPUT_SUMMARY, load_initial_cross_section
from build_annual_snapshot_state_transition_permits_starts_stock_calibrated import (
    StartsStockParams,
    build_scenarios,
    demand_index,
    extract_metrics,
    implied_q_next,
    initialize_inventories,
    permit_update,
    rename_scenario,
    resolve_calibrated_params,
    simulate,
    theta_from_metrics,
    update_population,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

T = 21
ACTIVE_CHECKPOINTS = [t for t in CHECKPOINTS if t <= T - 1]


def initial_state(summary: pd.DataFrame, params: StartsStockParams) -> tuple[np.ndarray, dict[str, np.ndarray], dict[str, float]]:
    pop0 = summary.loc[:, ["renter_no_debt", "renter_with_debt", "owner_with_mortgage", "owner_outright"]].to_numpy(dtype=float)
    pop0 = pop0 * summary["block_mass"].to_numpy(dtype=float)[:, None]
    refs = extract_metrics(pop0)

    arrays = {
        "q": np.zeros(T + 1, dtype=float),
        "permits": np.zeros(T + 1, dtype=float),
        "starts": np.zeros(T + 1, dtype=float),
        "completions": np.zeros(T + 1, dtype=float),
        "stock": np.zeros(T + 1, dtype=float),
        "permit_inventory": np.zeros(T + 1, dtype=float),
        "uc_inventory": np.zeros(T + 1, dtype=float),
    }
    arrays["q"][0] = 1.0
    arrays["stock"][0] = 1.0
    arrays["permits"][0] = params.permit_ss
    arrays["permit_inventory"][0], arrays["uc_inventory"][0] = initialize_inventories(params)
    arrays["starts"][0] = min(arrays["permit_inventory"][0], params.start_hazard * arrays["permit_inventory"][0])
    arrays["completions"][0] = min(arrays["uc_inventory"][0], params.completion_hazard * arrays["uc_inventory"][0])
    return pop0, arrays, refs


def update_construction(arrays: dict[str, np.ndarray], t: int, params: StartsStockParams) -> None:
    available_authorized = arrays["permit_inventory"][t] + arrays["permits"][t + 1]
    arrays["starts"][t + 1] = min(available_authorized, params.start_hazard * available_authorized)
    arrays["permit_inventory"][t + 1] = max(0.0, available_authorized - arrays["starts"][t + 1])

    available_uc = arrays["uc_inventory"][t] + arrays["starts"][t + 1]
    arrays["completions"][t + 1] = min(available_uc, params.completion_hazard * available_uc)
    arrays["uc_inventory"][t + 1] = max(0.0, available_uc - arrays["completions"][t + 1])

    arrays["stock"][t + 1] = max(
        0.50,
        (1.0 - params.stock_delta) * arrays["stock"][t] + arrays["completions"][t + 1],
    )


def k_step_implied(summary: pd.DataFrame, scenario, params: StartsStockParams, q_guesses: np.ndarray) -> tuple[np.ndarray, dict[str, list[float]]]:
    k = len(q_guesses)
    pop, arrays, refs = initial_state(summary, params)
    q_implied = np.zeros(k, dtype=float)
    current_q = arrays["q"][0]

    extras = {
        "theta": [],
        "permits": [],
        "starts": [],
        "completions": [],
        "stock": [],
        "young_mortgage": [],
    }

    for t in range(k):
        metrics_t = extract_metrics(pop)
        theta_t = theta_from_metrics(metrics_t, params)
        demand_t = demand_index(metrics_t, refs, scenario.price_ratio, t, params)

        arrays["permits"][t + 1] = permit_update(arrays["permits"][t], theta_t, demand_t, arrays["stock"][t], q_guesses[t], params)
        update_construction(arrays, t, params)

        pop = update_population(summary, pop, scenario, q_guesses[t], t)
        metrics_next = extract_metrics(pop)
        demand_next = demand_index(metrics_next, refs, scenario.price_ratio, t + 1, params)
        current_q = implied_q_next(current_q, demand_next, arrays["stock"][t + 1], params)
        q_implied[t] = current_q

        extras["theta"].append(float(theta_t))
        extras["permits"].append(float(arrays["permits"][t + 1]))
        extras["starts"].append(float(arrays["starts"][t + 1]))
        extras["completions"].append(float(arrays["completions"][t + 1]))
        extras["stock"].append(float(arrays["stock"][t + 1]))
        extras["young_mortgage"].append(float(metrics_next["young_mortgage_25_34"]))

    return q_implied, extras


def solve_fixed_point(summary: pd.DataFrame, scenario, params: StartsStockParams, k: int) -> tuple[np.ndarray, dict[str, list[float]]]:
    q_guess = np.array([scenario.price_ratio ** (i + 1) for i in range(k)], dtype=float)
    q_implied, extras = k_step_implied(summary, scenario, params, q_guess)
    for _ in range(400):
        q_implied, extras = k_step_implied(summary, scenario, params, q_guess)
        q_new = 0.5 * q_guess + 0.5 * q_implied
        if np.max(np.abs(q_new - q_guess)) < 1.0e-10:
            q_guess = q_new
            q_implied, extras = k_step_implied(summary, scenario, params, q_guess)
            break
        q_guess = q_new
    return q_implied, extras


def simulate_re_path(summary: pd.DataFrame, scenario, params: StartsStockParams, q_path: np.ndarray, horizon: int) -> pd.DataFrame:
    pop, arrays, refs = initial_state(summary, params)
    theta = np.zeros(horizon, dtype=float)
    demand = np.zeros(horizon, dtype=float)
    records: list[dict[str, float | int | str]] = []
    scenario_name = f"{rename_scenario(scenario.name)}_{len(q_path)}step_re"

    for t in range(horizon):
        metrics = extract_metrics(pop)
        theta[t] = theta_from_metrics(metrics, params)
        demand[t] = demand_index(metrics, refs, scenario.price_ratio, t, params)

        records.append(
            {
                "scenario": scenario_name,
                "t": t,
                "q": float(arrays["q"][t]),
                "theta": float(theta[t]),
                "permits": float(arrays["permits"][t]),
                "starts": float(arrays["starts"][t]),
                "completions": float(arrays["completions"][t]),
                "stock": float(arrays["stock"][t]),
                "young_owner_25_34": metrics["young_owner_25_34"],
                "young_mortgaged_owner_25_34": metrics["young_mortgage_25_34"],
                "owner_35_44": metrics["owner_35_44"],
            }
        )

        if t == horizon - 1:
            break

        q_effective = q_path[t] if t < len(q_path) else arrays["q"][t]
        arrays["permits"][t + 1] = permit_update(arrays["permits"][t], theta[t], demand[t], arrays["stock"][t], q_effective, params)
        update_construction(arrays, t, params)
        pop = update_population(summary, pop, scenario, q_effective, t)
        arrays["q"][t + 1] = q_effective if t < len(q_path) else implied_q_next(arrays["q"][t], demand[t], arrays["stock"][t + 1], params)

    return pd.DataFrame.from_records(records)


def build_checkpoint_table(paths: pd.DataFrame, anchors: pd.DataFrame, k: int) -> pd.DataFrame:
    anchor_map = anchors.set_index(["scenario", "t"])
    rows: list[dict[str, float | int | str]] = []
    suffix = f"_{k}step_re"
    for _, row in paths.loc[paths["t"].isin(ACTIVE_CHECKPOINTS)].iterrows():
        base_name = row["scenario"].replace(suffix, "")
        anchor = anchor_map.loc[(base_name, int(row["t"]))]
        rows.append(
            {
                "scenario": row["scenario"],
                "anchor_scenario": base_name,
                "t": int(row["t"]),
                "q": float(row["q"]),
                "starts": float(row["starts"]),
                "completions": float(row["completions"]),
                "stock": float(row["stock"]),
                "young_mortgaged_owner_25_34": float(row["young_mortgaged_owner_25_34"]),
                "q_gap_vs_stock_anchor": float(row["q"] - anchor["q"]),
                "young_mortgage_gap_vs_stock_anchor": float(
                    row["young_mortgaged_owner_25_34"] - anchor["young_mortgaged_owner_25_34"]
                ),
            }
        )
    return pd.DataFrame(rows)


def write_note(path: Path, fixed_points: pd.DataFrame, checkpoints: pd.DataFrame, k: int) -> None:
    q_cols = " | ".join([f"q{i + 1}" for i in range(k)])
    q_headers = " | ".join(["---:" for _ in range(k)])
    q_refs = " | ".join([f"`{{row.q{i + 1}_re:.3f}}`" for i in range(k)])
    step_headers = []
    for i in range(k):
        step = i + 1
        step_headers.extend([f"Permits{step}", f"Starts{step}", f"Completions{step}", f"Stock{step}", f"Young mortgage t={step}"])
    step_header_row = " | ".join(step_headers)
    step_header_align = " | ".join(["---:" for _ in step_headers])

    lines = [
        f"# Annual {k}-step RE on calibrated permits-starts-stock transition",
        "",
        f"This note applies bounded RE with an explicit {k}-period price horizon to the calibrated annual construction-flow block.",
        "",
        "## Solved fixed points",
        "",
        f"| Scenario | {q_cols} | {step_header_row} |",
        f"|---|{q_headers}|{step_header_align}|",
    ]

    for row in fixed_points.itertuples(index=False):
        q_bits = " | ".join(getattr(row, f"q{i + 1}_re").__format__(".3f") for i in range(k))
        step_bits: list[str] = []
        for i in range(k):
            step = i + 1
            step_bits.extend(
                [
                    getattr(row, f"permits{step}").__format__(".3f"),
                    getattr(row, f"starts{step}").__format__(".3f"),
                    getattr(row, f"completions{step}").__format__(".3f"),
                    getattr(row, f"stock{step}").__format__(".3f"),
                    getattr(row, f"young_mortgage_t{step}").__format__(".3f"),
                ]
            )
        lines.append(f"| `{row.scenario}` | `{q_bits.replace(' | ', '` | `')}` | `{('` | `'.join(step_bits))}` |")

    lines.extend(
        [
            "",
            "## Checkpoints relative to calibrated stock-flow anchor",
            "",
            "| Scenario | t | q | Starts | Completions | Stock | Young mortgaged-owner 25-34 | q gap vs anchor | Young mortgage gap vs anchor |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for row in checkpoints.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.q:.3f}` | `{row.starts:.3f}` | `{row.completions:.3f}` | `{row.stock:.3f}` | "
            f"`{row.young_mortgaged_owner_25_34:.3f}` | `{row.q_gap_vs_stock_anchor:.3f}` | `{row.young_mortgage_gap_vs_stock_anchor:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            f"- If the solved `q_1` through `q_{k}` stay close to the calibrated stock-flow anchor, the earlier annual RE pathology was coming from the thin price block rather than from short-horizon expectations themselves.",
            "- The live question after this pass is no longer whether bounded RE is numerically feasible; it is whether the calibrated construction-flow block should become the main annual price block in the draft.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--k", type=int, choices=[1, 2, 3, 5, 8, 20], required=True)
    args = parser.parse_args()

    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = resolve_calibrated_params(summary)
    scenarios = build_scenarios()
    output_stem = f"annual_{args.k}_step_re_permits_starts_stock_calibrated"

    anchor_frames = []
    for scenario in scenarios:
        frame = simulate(summary, scenario, params, T=T)
        frame["scenario"] = rename_scenario(scenario.name)
        anchor_frames.append(frame)
    anchors = pd.concat(anchor_frames, ignore_index=True)

    fixed_rows: list[dict[str, float | str]] = []
    re_frames: list[pd.DataFrame] = []
    for scenario in scenarios:
        q_path, extras = solve_fixed_point(summary, scenario, params, args.k)
        row: dict[str, float | str] = {"scenario": rename_scenario(scenario.name)}
        for i in range(args.k):
            step = i + 1
            row[f"q{step}_re"] = float(q_path[i])
            row[f"permits{step}"] = float(extras["permits"][i])
            row[f"starts{step}"] = float(extras["starts"][i])
            row[f"completions{step}"] = float(extras["completions"][i])
            row[f"stock{step}"] = float(extras["stock"][i])
            row[f"young_mortgage_t{step}"] = float(extras["young_mortgage"][i])
        fixed_rows.append(row)
        re_frames.append(simulate_re_path(summary, scenario, params, q_path, horizon=T))

    fixed_points = pd.DataFrame(fixed_rows)
    re_paths = pd.concat(re_frames, ignore_index=True)
    checkpoints = build_checkpoint_table(re_paths, anchors, args.k)

    fixed_points.to_csv(BUILD / f"{output_stem}_fixed_points.csv", index=False)
    re_paths.to_csv(BUILD / f"{output_stem}.csv", index=False)
    checkpoints.to_csv(BUILD / f"{output_stem}_checkpoints.csv", index=False)
    write_note(BUILD / f"{output_stem}.md", fixed_points, checkpoints, args.k)


if __name__ == "__main__":
    main()
