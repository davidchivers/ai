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
from build_annual_full_re_stationary_transition_calibrated import build_stationary_scenarios, stationary_targets


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
DEFAULT_T = 80
DEFAULT_SWITCH_T = 5


def scenario_map() -> dict[str, object]:
    scenarios = build_stationary_scenarios()
    return {scenario.name: scenario for scenario in scenarios}


def build_regime_path(horizon: int, switch_t: int) -> list[object]:
    scenarios = scenario_map()
    path = []
    for t in range(horizon):
        if t < switch_t:
            path.append(scenarios["baseline_d00_stock_data"])
        else:
            path.append(scenarios["benchmark_d00_stock_data"])
    return path


def full_path_implied_with_regime_path(
    summary: pd.DataFrame,
    regime_path: list[object],
    params,
    q_guesses: np.ndarray,
) -> tuple[np.ndarray, dict[str, list[float | str]]]:
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
        "regime": [],
    }

    for t in range(horizon):
        scenario_t = regime_path[t]
        metrics_t = extract_metrics(pop)
        theta_t = theta_from_metrics(metrics_t, params)
        demand_t = demand_index(metrics_t, refs, scenario_t.price_ratio, t, params)

        arrays["permits"][t + 1] = permit_update(
            arrays["permits"][t], theta_t, demand_t, arrays["stock"][t], q_guesses[t], params
        )
        update_construction(arrays, t, params)

        pop = update_population(summary, pop, scenario_t, q_guesses[t], t)
        metrics_next = extract_metrics(pop)
        scenario_next = regime_path[t + 1] if t + 1 < horizon else regime_path[-1]
        demand_next = demand_index(metrics_next, refs, scenario_next.price_ratio, t + 1, params)
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
        extras["regime"].append(str(scenario_t.name))

    return q_implied, extras


def solve_full_path_with_regime_path(
    summary: pd.DataFrame,
    regime_path: list[object],
    params,
    horizon: int,
) -> tuple[np.ndarray, dict[str, list[float | str]]]:
    q_guess = np.ones(horizon, dtype=float)
    for _ in range(600):
        q_implied, extras = full_path_implied_with_regime_path(summary, regime_path, params, q_guess)
        q_new = 0.60 * q_guess + 0.40 * q_implied
        if np.max(np.abs(q_new - q_guess)) < 1.0e-10:
            q_guess = q_new
            q_implied, extras = full_path_implied_with_regime_path(summary, regime_path, params, q_guess)
            break
        q_guess = q_new
    return q_implied, extras


def simulate_regime_path(summary: pd.DataFrame, regime_path: list[object], params, q_path: np.ndarray) -> pd.DataFrame:
    horizon = len(q_path)
    pop, arrays, refs = initial_state(summary, params, horizon)
    records: list[dict[str, float | int | str]] = []

    for t in range(horizon + 1):
        scenario_t = regime_path[t] if t < horizon else regime_path[-1]
        metrics = extract_metrics(pop)
        theta_t = theta_from_metrics(metrics, params)
        demand_t = demand_index(metrics, refs, scenario_t.price_ratio, t, params)

        records.append(
            {
                "scenario": f"baseline_to_benchmark_t{DEFAULT_SWITCH_T}_T{horizon}_full_re_stationary",
                "t": t,
                "regime": str(scenario_t.name),
                "q": float(arrays["q"][t]),
                "theta": float(theta_t),
                "permits": float(arrays["permits"][t]),
                "starts": float(arrays["starts"][t]),
                "completions": float(arrays["completions"][t]),
                "stock": float(arrays["stock"][t]),
                "young_owner_25_34": metrics["young_owner_25_34"],
                "young_mortgaged_owner_25_34": metrics["young_mortgage_25_34"],
                "owner_35_44": metrics["owner_35_44"],
                "demand_index": float(demand_t),
            }
        )

        if t == horizon:
            break

        q_effective = q_path[t]
        arrays["permits"][t + 1] = permit_update(arrays["permits"][t], theta_t, demand_t, arrays["stock"][t], q_effective, params)
        update_construction(arrays, t, params)
        pop = update_population(summary, pop, scenario_t, q_effective, t)
        arrays["q"][t + 1] = q_effective

    return pd.DataFrame.from_records(records)


def build_comparison_table(
    switch_paths: pd.DataFrame,
    benchmark_paths: pd.DataFrame,
    stationary: pd.DataFrame,
    checkpoints: list[int],
    horizon: int,
    switch_t: int,
) -> pd.DataFrame:
    benchmark_map = benchmark_paths.set_index(["scenario", "t"])
    benchmark_ss = stationary.set_index("scenario").loc["benchmark_d00_stock_data"]
    rows: list[dict[str, float | int | str]] = []
    switch_name = f"baseline_to_benchmark_t{switch_t}_T{horizon}_full_re_stationary"

    for _, row in switch_paths.loc[switch_paths["t"].isin(checkpoints)].iterrows():
        benchmark = benchmark_map.loc[(f"benchmark_d00_stock_data_T{horizon}_full_re_stationary", int(row["t"])), :]
        rows.append(
            {
                "scenario": switch_name,
                "t": int(row["t"]),
                "regime": str(row["regime"]),
                "q": float(row["q"]),
                "q_gap_vs_benchmark_re": float(row["q"] - benchmark["q"]),
                "q_gap_vs_benchmark_stationary": float(row["q"] - benchmark_ss["q_ss"]),
                "young_mortgaged_owner_25_34": float(row["young_mortgaged_owner_25_34"]),
                "young_mortgage_gap_vs_benchmark_re": float(
                    row["young_mortgaged_owner_25_34"] - benchmark["young_mortgaged_owner_25_34"]
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
    switch_t: int,
) -> None:
    benchmark_ss = stationary.set_index("scenario").loc["benchmark_d00_stock_data"]
    lines = [
        f"# Annual full RE with explicit support-regime path (T={horizon})",
        "",
        "This note adds the next rung on the annual full-RE ladder: an explicit anticipated support-regime path inside the stationary annual housing block.",
        "",
        "Regime path used here:",
        "",
        f"- baseline support regime for `t < {switch_t}`",
        f"- benchmark support regime for `t >= {switch_t}`",
        "- agents internalize the entire switch path when forming the RE price path",
        "",
        "## Benchmark stationary endpoint",
        "",
        f"- `q_ss ≈ {benchmark_ss['q_ss']:.3f}`",
        f"- young mortgaged-owner 25-34_ss `≈ {benchmark_ss['young_mortgage_ss']:.3f}`",
        "",
        "## Regime-path full-RE path excerpts",
        "",
        "| Scenario | q1 | q5 | q10 | q20 | q40 | q80 |",
        "|---|---:|---:|---:|---:|---:|---:|",
    ]

    for row in fixed_points.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.q1:.3f}` | `{row.q5:.3f}` | `{row.q10:.3f}` | `{row.q20:.3f}` | `{row.q40:.3f}` | `{row.q80:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints relative to always-benchmark full RE",
            "",
            "| Scenario | t | Active regime | q | q gap vs benchmark RE | Young mortgaged-owner 25-34 | Young mortgage gap vs benchmark RE |",
            "|---|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in comparisons.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.regime}` | `{row.q:.3f}` | `{row.q_gap_vs_benchmark_re:.3f}` | "
            f"`{row.young_mortgaged_owner_25_34:.3f}` | `{row.young_mortgage_gap_vs_benchmark_re:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is the first annual RE object in which policy/support persistence is part of the anticipated path rather than just a fixed scenario label.",
            "- It is still not a fully recursive political equilibrium, because the regime path is imposed rather than solved from a forecasted policy state.",
            "- If this remains tame, the next rung is a genuinely forecasted policy or political state rather than another imposed path.",
        ]
    )

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--T", type=int, default=DEFAULT_T)
    parser.add_argument("--switch-t", type=int, default=DEFAULT_SWITCH_T, dest="switch_t")
    args = parser.parse_args()

    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    horizon = int(args.T)
    switch_t = int(args.switch_t)
    checkpoints = [t for t in [1, 5, 10, 20, 40, 80] if t <= horizon]

    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = resolve_calibrated_params(summary)
    scenarios = build_stationary_scenarios()
    stationary = stationary_targets(summary, params, scenarios)

    benchmark_scenario = scenario_map()["benchmark_d00_stock_data"]
    benchmark_regime_path = [benchmark_scenario for _ in range(horizon)]
    q_path_benchmark, _ = solve_full_path_with_regime_path(summary, benchmark_regime_path, params, horizon)
    benchmark_paths = simulate_regime_path(summary, benchmark_regime_path, params, q_path_benchmark)
    benchmark_paths["scenario"] = f"benchmark_d00_stock_data_T{horizon}_full_re_stationary"

    regime_path = build_regime_path(horizon, switch_t)
    q_path_switch, _ = solve_full_path_with_regime_path(summary, regime_path, params, horizon)
    switch_paths = simulate_regime_path(summary, regime_path, params, q_path_switch)
    switch_paths["scenario"] = f"baseline_to_benchmark_t{switch_t}_T{horizon}_full_re_stationary"

    fixed_points = pd.DataFrame(
        [
            {
                "scenario": f"baseline_to_benchmark_t{switch_t}",
                "q1": float(q_path_switch[0]),
                "q5": float(q_path_switch[4]) if horizon >= 5 else np.nan,
                "q10": float(q_path_switch[9]) if horizon >= 10 else np.nan,
                "q20": float(q_path_switch[19]) if horizon >= 20 else np.nan,
                "q40": float(q_path_switch[39]) if horizon >= 40 else np.nan,
                "q80": float(q_path_switch[79]) if horizon >= 80 else np.nan,
            }
        ]
    )

    comparisons = build_comparison_table(switch_paths, benchmark_paths, stationary, checkpoints, horizon, switch_t)

    stem = f"annual_full_re_stationary_transition_regime_path_t{switch_t}_T{horizon}"
    fixed_points.to_csv(BUILD / f"{stem}_fixed_points.csv", index=False)
    comparisons.to_csv(BUILD / f"{stem}_checkpoints.csv", index=False)
    write_note(BUILD / f"{stem}.md", fixed_points, comparisons, stationary, horizon, switch_t)


if __name__ == "__main__":
    main()
