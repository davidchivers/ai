from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import INPUT_SUMMARY, load_initial_cross_section
from build_annual_snapshot_state_transition_permits_starts_stock_calibrated import (
    demand_index,
    extract_metrics,
    permit_update,
    resolve_calibrated_params,
    theta_from_metrics,
    update_population,
)
from build_annual_full_path_re_permits_starts_stock_calibrated import initial_state, update_construction
from build_annual_full_re_stationary_transition_calibrated import (
    build_stationary_scenarios,
    stationary_targets,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
DEFAULT_T = 80
DEFAULT_SHOCK0 = 0.05
DEFAULT_RHO = 0.90


def fertility_multiplier_path(horizon: int, shock0: float, rho: float) -> np.ndarray:
    multipliers = np.ones(horizon + 1, dtype=float)
    for t in range(1, horizon + 1):
        multipliers[t] = 1.0 + shock0 * (rho ** (t - 1))
    return multipliers


def full_path_implied_with_fertility_shock(
    summary: pd.DataFrame,
    scenario,
    params,
    q_guesses: np.ndarray,
    fertility_multipliers: np.ndarray,
) -> tuple[np.ndarray, dict[str, list[float]]]:
    horizon = len(q_guesses)
    pop, arrays, refs = initial_state(summary, params, horizon)
    q_implied = np.zeros(horizon, dtype=float)
    current_q = arrays["q"][0]

    extras = {
        "theta": [],
        "permits": [],
        "starts": [],
        "completions": [],
        "stock": [],
        "young_mortgage": [],
    }

    for t in range(horizon):
        metrics_t = extract_metrics(pop)
        theta_t = theta_from_metrics(metrics_t, params)
        demand_t = demand_index(metrics_t, refs, scenario.price_ratio, t, params) * fertility_multipliers[t]

        arrays["permits"][t + 1] = permit_update(
            arrays["permits"][t], theta_t, demand_t, arrays["stock"][t], q_guesses[t], params
        )
        update_construction(arrays, t, params)

        pop = update_population(summary, pop, scenario, q_guesses[t], t)
        metrics_next = extract_metrics(pop)
        demand_next = demand_index(metrics_next, refs, scenario.price_ratio, t + 1, params) * fertility_multipliers[t + 1]
        current_q = np.clip(
            np.exp(np.log(max(current_q, 1.0e-6)) + params.price_damping * params.price_gap_gain * (demand_next - arrays["stock"][t + 1])),
            params.q_min,
            params.q_max,
        )
        q_implied[t] = current_q

        extras["theta"].append(float(theta_t))
        extras["permits"].append(float(arrays["permits"][t + 1]))
        extras["starts"].append(float(arrays["starts"][t + 1]))
        extras["completions"].append(float(arrays["completions"][t + 1]))
        extras["stock"].append(float(arrays["stock"][t + 1]))
        extras["young_mortgage"].append(float(metrics_next["young_mortgage_25_34"]))

    return q_implied, extras


def solve_full_path_with_fertility_shock(
    summary: pd.DataFrame,
    scenario,
    params,
    horizon: int,
    fertility_multipliers: np.ndarray,
) -> tuple[np.ndarray, dict[str, list[float]]]:
    q_guess = np.ones(horizon, dtype=float)
    q_implied, extras = full_path_implied_with_fertility_shock(summary, scenario, params, q_guess, fertility_multipliers)

    for _ in range(600):
        q_implied, extras = full_path_implied_with_fertility_shock(summary, scenario, params, q_guess, fertility_multipliers)
        q_new = 0.60 * q_guess + 0.40 * q_implied
        if np.max(np.abs(q_new - q_guess)) < 1.0e-10:
            q_guess = q_new
            q_implied, extras = full_path_implied_with_fertility_shock(summary, scenario, params, q_guess, fertility_multipliers)
            break
        q_guess = q_new

    return q_implied, extras


def simulate_stationary_re_path_with_fertility_shock(
    summary: pd.DataFrame,
    scenario,
    params,
    q_path: np.ndarray,
    fertility_multipliers: np.ndarray,
) -> pd.DataFrame:
    horizon = len(q_path)
    pop, arrays, refs = initial_state(summary, params, horizon)
    records: list[dict[str, float | int | str]] = []

    for t in range(horizon + 1):
        metrics = extract_metrics(pop)
        theta_t = theta_from_metrics(metrics, params)
        demand_t = demand_index(metrics, refs, scenario.price_ratio, t, params) * fertility_multipliers[t]

        records.append(
            {
                "scenario": f"{scenario.name}_fertility_shock_T{horizon}_full_re_stationary",
                "t": t,
                "fertility_multiplier": float(fertility_multipliers[t]),
                "q": float(arrays["q"][t]),
                "theta": float(theta_t),
                "permits": float(arrays["permits"][t]),
                "starts": float(arrays["starts"][t]),
                "completions": float(arrays["completions"][t]),
                "stock": float(arrays["stock"][t]),
                "young_owner_25_34": metrics["young_owner_25_34"],
                "young_mortgaged_owner_25_34": metrics["young_mortgage_25_34"],
                "owner_35_44": metrics["owner_35_44"],
                "demand_index_with_shock": float(demand_t),
            }
        )

        if t == horizon:
            break

        q_effective = q_path[t]
        arrays["permits"][t + 1] = permit_update(arrays["permits"][t], theta_t, demand_t, arrays["stock"][t], q_effective, params)
        update_construction(arrays, t, params)
        pop = update_population(summary, pop, scenario, q_effective, t)
        arrays["q"][t + 1] = q_effective

    return pd.DataFrame.from_records(records)


def build_comparison_table(
    shock_paths: pd.DataFrame,
    no_shock_paths: pd.DataFrame,
    stationary: pd.DataFrame,
    checkpoints: list[int],
    horizon: int,
) -> pd.DataFrame:
    no_shock_map = no_shock_paths.set_index(["scenario", "t"])
    stationary_map = stationary.set_index("scenario")
    rows: list[dict[str, float | int | str]] = []
    suffix = f"_fertility_shock_T{horizon}_full_re_stationary"

    for _, row in shock_paths.loc[shock_paths["t"].isin(checkpoints)].iterrows():
        base_name = row["scenario"].replace(suffix, "")
        no_shock = no_shock_map.loc[(f"{base_name}_fertility_shock_T{horizon}_full_re_stationary", int(row["t"])), :]
        ss = stationary_map.loc[base_name]
        rows.append(
            {
                "scenario": row["scenario"],
                "base_scenario": base_name,
                "t": int(row["t"]),
                "fertility_multiplier": float(row["fertility_multiplier"]),
                "q": float(row["q"]),
                "q_gap_vs_no_shock_re": float(row["q"] - no_shock["q"]),
                "q_gap_vs_stationary": float(row["q"] - ss["q_ss"]),
                "young_mortgaged_owner_25_34": float(row["young_mortgaged_owner_25_34"]),
                "young_mortgage_gap_vs_no_shock_re": float(
                    row["young_mortgaged_owner_25_34"] - no_shock["young_mortgaged_owner_25_34"]
                ),
                "young_mortgage_gap_vs_stationary": float(
                    row["young_mortgaged_owner_25_34"] - ss["young_mortgage_ss"]
                ),
            }
        )

    return pd.DataFrame(rows)


def write_note(
    path: Path,
    fixed_points: pd.DataFrame,
    comparisons: pd.DataFrame,
    stationary: pd.DataFrame,
    horizon: int,
    shock0: float,
    rho: float,
) -> None:
    lines = [
        f"# Annual full RE with exogenous fertility-demand shock (T={horizon})",
        "",
        "This note adds the next rung on the full-RE ladder: a **temporary fertility-demand shock path** inside the stationary annual full-RE housing block.",
        "",
        "Interpretation:",
        "",
        "- this is still full-path RE in house prices",
        "- fertility is **not yet endogenous** in the RE loop",
        "- instead, future fertility pressure enters as an exogenous demand multiplier that households internalize through the model-consistent price path",
        "",
        "Shock path used here:",
        "",
        f"- multiplier at `t = 1`: `1 + {shock0:.3f}`",
        f"- persistence: `rho = {rho:.2f}`",
        "- multiplier decays geometrically back to `1.0`",
        "",
        "## Stationary annual endpoints",
        "",
        "| Scenario | q_ss | Young mortgaged-owner 25-34_ss | Owner 35-44_ss |",
        "|---|---:|---:|---:|",
    ]

    for row in stationary.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.q_ss:.3f}` | `{row.young_mortgage_ss:.3f}` | `{row.owner_35_44_ss:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Shocked full-RE path excerpts",
            "",
            "| Scenario | q1 | q5 | q10 | q20 | q40 | q80 |",
            "|---|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in fixed_points.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.q1:.3f}` | `{row.q5:.3f}` | `{row.q10:.3f}` | `{row.q20:.3f}` | `{row.q40:.3f}` | `{row.q80:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints relative to no-shock full RE",
            "",
            "| Scenario | t | Fertility multiplier | q | q gap vs no-shock RE | Young mortgaged-owner 25-34 | Young mortgage gap vs no-shock RE |",
            "|---|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in comparisons.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.fertility_multiplier:.3f}` | `{row.q:.3f}` | `{row.q_gap_vs_no_shock_re:.3f}` | "
            f"`{row.young_mortgaged_owner_25_34:.3f}` | `{row.young_mortgage_gap_vs_no_shock_re:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is the first annual full-RE object in which **future fertility pressure explicitly affects future house prices**, even though fertility itself is not yet endogenous.",
            "- If this behaves well, the next rung is a reduced-form endogenous fertility law inside the same stationary full-RE housing block.",
            "- Only after that should the project try a fully structural annual fertility-housing RE model.",
        ]
    )

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--T", type=int, default=DEFAULT_T)
    parser.add_argument("--shock0", type=float, default=DEFAULT_SHOCK0)
    parser.add_argument("--rho", type=float, default=DEFAULT_RHO)
    args = parser.parse_args()

    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    horizon = int(args.T)
    shock0 = float(args.shock0)
    rho = float(args.rho)
    checkpoints = [t for t in [1, 5, 10, 20, 40, 80] if t <= horizon]

    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = resolve_calibrated_params(summary)
    scenarios = build_stationary_scenarios()
    stationary = stationary_targets(summary, params, scenarios)
    fertility_multipliers = fertility_multiplier_path(horizon, shock0, rho)

    no_shock_frames = []
    shock_frames = []
    fixed_rows: list[dict[str, float | str]] = []

    for scenario in scenarios:
        zero_shock = np.ones(horizon + 1, dtype=float)
        q_path_no_shock, _ = solve_full_path_with_fertility_shock(summary, scenario, params, horizon, zero_shock)
        no_shock_frames.append(
            simulate_stationary_re_path_with_fertility_shock(summary, scenario, params, q_path_no_shock, zero_shock)
        )

        q_path_shock, _ = solve_full_path_with_fertility_shock(summary, scenario, params, horizon, fertility_multipliers)
        shock_frames.append(
            simulate_stationary_re_path_with_fertility_shock(summary, scenario, params, q_path_shock, fertility_multipliers)
        )

        fixed_rows.append(
            {
                "scenario": scenario.name,
                "q1": float(q_path_shock[0]),
                "q5": float(q_path_shock[4]) if horizon >= 5 else np.nan,
                "q10": float(q_path_shock[9]) if horizon >= 10 else np.nan,
                "q20": float(q_path_shock[19]) if horizon >= 20 else np.nan,
                "q40": float(q_path_shock[39]) if horizon >= 40 else np.nan,
                "q80": float(q_path_shock[79]) if horizon >= 80 else np.nan,
            }
        )

    no_shock_paths = pd.concat(no_shock_frames, ignore_index=True)
    shock_paths = pd.concat(shock_frames, ignore_index=True)
    fixed_points = pd.DataFrame(fixed_rows)
    comparisons = build_comparison_table(shock_paths, no_shock_paths, stationary, checkpoints, horizon)

    stem = f"annual_full_re_stationary_transition_fertility_shock_T{horizon}"
    fixed_points.to_csv(BUILD / f"{stem}_fixed_points.csv", index=False)
    no_shock_paths.to_csv(BUILD / f"{stem}_no_shock_paths.csv", index=False)
    shock_paths.to_csv(BUILD / f"{stem}.csv", index=False)
    comparisons.to_csv(BUILD / f"{stem}_checkpoints.csv", index=False)
    write_note(BUILD / f"{stem}.md", fixed_points, comparisons, stationary, horizon, shock0, rho)


if __name__ == "__main__":
    main()
