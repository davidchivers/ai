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
    simulate,
    theta_from_metrics,
    update_population,
)
from build_annual_full_path_re_permits_starts_stock_calibrated import initial_state, update_construction
from build_annual_full_re_stationary_transition_calibrated import build_stationary_scenarios


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
DEFAULT_T = 80
DEFAULT_RHO = 0.85
DEFAULT_Q_GAIN = 0.05
DEFAULT_OWNER_GAIN = 0.03
DEFAULT_MORTGAGE_GAIN = 0.08
DEFAULT_MAX_ABS = 0.08


def stationary_targets_extended(summary: pd.DataFrame, params, scenarios: list) -> pd.DataFrame:
    rows: list[dict[str, float | str]] = []
    for scenario in scenarios:
        frame = simulate(summary, scenario, params, T=300)
        tail = frame.tail(20)
        rows.append(
            {
                "scenario": scenario.name,
                "q_ss": float(tail["q"].mean()),
                "young_owner_ss": float(tail["young_owner_25_34"].mean()),
                "young_mortgage_ss": float(tail["young_mortgaged_owner_25_34"].mean()),
                "owner_35_44_ss": float(tail["owner_35_44"].mean()),
            }
        )
    return pd.DataFrame(rows)


def fertility_target(
    q_current: float,
    metrics_next: dict[str, float],
    ss: pd.Series,
    q_gain: float,
    owner_gain: float,
    mortgage_gain: float,
) -> float:
    q_term = q_gain * np.log(max(float(ss["q_ss"]), 1.0e-6) / max(q_current, 1.0e-6))
    owner_term = owner_gain * (metrics_next["young_owner_25_34"] - float(ss["young_owner_ss"]))
    mortgage_term = mortgage_gain * (metrics_next["young_mortgage_25_34"] - float(ss["young_mortgage_ss"]))
    return float(q_term + owner_term + mortgage_term)


def full_path_implied_with_endogenous_fertility(
    summary: pd.DataFrame,
    scenario,
    params,
    q_guesses: np.ndarray,
    ss: pd.Series,
    rho: float,
    q_gain: float,
    owner_gain: float,
    mortgage_gain: float,
    max_abs: float,
) -> tuple[np.ndarray, np.ndarray, dict[str, list[float]]]:
    horizon = len(q_guesses)
    pop, arrays, refs = initial_state(summary, params, horizon)
    q_implied = np.zeros(horizon, dtype=float)
    fert_state = np.zeros(horizon + 1, dtype=float)
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
        demand_t = demand_index(metrics_t, refs, scenario.price_ratio, t, params) * (1.0 + fert_state[t])

        arrays["permits"][t + 1] = permit_update(
            arrays["permits"][t], theta_t, demand_t, arrays["stock"][t], q_guesses[t], params
        )
        update_construction(arrays, t, params)

        pop = update_population(summary, pop, scenario, q_guesses[t], t)
        metrics_next = extract_metrics(pop)

        target = fertility_target(q_guesses[t], metrics_next, ss, q_gain, owner_gain, mortgage_gain)
        fert_state[t + 1] = float(np.clip(rho * fert_state[t] + (1.0 - rho) * target, -max_abs, max_abs))

        demand_next = demand_index(metrics_next, refs, scenario.price_ratio, t + 1, params) * (1.0 + fert_state[t + 1])
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

    return q_implied, fert_state, extras


def solve_full_path_with_endogenous_fertility(
    summary: pd.DataFrame,
    scenario,
    params,
    horizon: int,
    ss: pd.Series,
    rho: float,
    q_gain: float,
    owner_gain: float,
    mortgage_gain: float,
    max_abs: float,
) -> tuple[np.ndarray, np.ndarray, dict[str, list[float]]]:
    q_guess = np.ones(horizon, dtype=float)

    for _ in range(600):
        q_implied, fert_state, extras = full_path_implied_with_endogenous_fertility(
            summary, scenario, params, q_guess, ss, rho, q_gain, owner_gain, mortgage_gain, max_abs
        )
        q_new = 0.60 * q_guess + 0.40 * q_implied
        if np.max(np.abs(q_new - q_guess)) < 1.0e-10:
            q_guess = q_new
            q_implied, fert_state, extras = full_path_implied_with_endogenous_fertility(
                summary, scenario, params, q_guess, ss, rho, q_gain, owner_gain, mortgage_gain, max_abs
            )
            break
        q_guess = q_new

    return q_implied, fert_state, extras


def simulate_stationary_re_path_with_endogenous_fertility(
    summary: pd.DataFrame,
    scenario,
    params,
    q_path: np.ndarray,
    fert_state: np.ndarray,
) -> pd.DataFrame:
    horizon = len(q_path)
    pop, arrays, refs = initial_state(summary, params, horizon)
    records: list[dict[str, float | int | str]] = []

    for t in range(horizon + 1):
        metrics = extract_metrics(pop)
        theta_t = theta_from_metrics(metrics, params)
        fert_multiplier = 1.0 + float(fert_state[t])
        demand_t = demand_index(metrics, refs, scenario.price_ratio, t, params) * fert_multiplier

        records.append(
            {
                "scenario": f"{scenario.name}_endogenous_fertility_T{horizon}_full_re_stationary",
                "t": t,
                "fertility_state": float(fert_state[t]),
                "fertility_multiplier": float(fert_multiplier),
                "q": float(arrays["q"][t]),
                "theta": float(theta_t),
                "permits": float(arrays["permits"][t]),
                "starts": float(arrays["starts"][t]),
                "completions": float(arrays["completions"][t]),
                "stock": float(arrays["stock"][t]),
                "young_owner_25_34": metrics["young_owner_25_34"],
                "young_mortgaged_owner_25_34": metrics["young_mortgage_25_34"],
                "owner_35_44": metrics["owner_35_44"],
                "demand_index_with_fertility": float(demand_t),
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
    endog_paths: pd.DataFrame,
    no_shock_paths: pd.DataFrame,
    stationary: pd.DataFrame,
    checkpoints: list[int],
    horizon: int,
) -> pd.DataFrame:
    no_shock_map = no_shock_paths.set_index(["scenario", "t"])
    stationary_map = stationary.set_index("scenario")
    rows: list[dict[str, float | int | str]] = []
    suffix = f"_endogenous_fertility_T{horizon}_full_re_stationary"

    for _, row in endog_paths.loc[endog_paths["t"].isin(checkpoints)].iterrows():
        base_name = row["scenario"].replace(suffix, "")
        no_shock = no_shock_map.loc[(f"{base_name}_endogenous_fertility_T{horizon}_full_re_stationary", int(row["t"])), :]
        ss = stationary_map.loc[base_name]
        rows.append(
            {
                "scenario": row["scenario"],
                "base_scenario": base_name,
                "t": int(row["t"]),
                "fertility_state": float(row["fertility_state"]),
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
    rho: float,
    q_gain: float,
    owner_gain: float,
    mortgage_gain: float,
    max_abs: float,
) -> None:
    lines = [
        f"# Annual full RE with reduced-form endogenous fertility (T={horizon})",
        "",
        "This note adds the next rung on the annual full-RE ladder: fertility is no longer an exogenous shock path, but a reduced-form state that responds to prices and ownership access relative to the stationary endpoint.",
        "",
        "Law of motion:",
        "",
        "- fertility state starts at `0`",
        f"- persistence `rho = {rho:.2f}`",
        f"- price response coefficient `{q_gain:.3f}` on `log(q_ss / q_t)`",
        f"- young owner response coefficient `{owner_gain:.3f}`",
        f"- young mortgaged-owner response coefficient `{mortgage_gain:.3f}`",
        f"- state clipped to `±{max_abs:.3f}`",
        "- annual demand is multiplied by `1 + fertility_state_t`",
        "",
        "## Stationary annual endpoints",
        "",
        "| Scenario | q_ss | Young owner 25-34_ss | Young mortgaged-owner 25-34_ss | Owner 35-44_ss |",
        "|---|---:|---:|---:|---:|",
    ]

    for row in stationary.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.q_ss:.3f}` | `{row.young_owner_ss:.3f}` | `{row.young_mortgage_ss:.3f}` | `{row.owner_35_44_ss:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Endogenous-fertility full-RE path excerpts",
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
            "| Scenario | t | Fertility state | Fertility multiplier | q | q gap vs no-shock RE | Young mortgaged-owner 25-34 | Young mortgage gap vs no-shock RE |",
            "|---|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in comparisons.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.fertility_state:.3f}` | `{row.fertility_multiplier:.3f}` | `{row.q:.3f}` | "
            f"`{row.q_gap_vs_no_shock_re:.3f}` | `{row.young_mortgaged_owner_25_34:.3f}` | `{row.young_mortgage_gap_vs_no_shock_re:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is the first annual full-RE object in which fertility is an endogenous state rather than an imposed shock path.",
            "- It is still reduced-form: fertility responds to prices and housing access, then feeds back into demand and prices.",
            "- If this remains tame, the next serious rung is to make regime or political states forecasted alongside prices rather than to push fertility all the way to the full structural block immediately.",
        ]
    )

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--T", type=int, default=DEFAULT_T)
    parser.add_argument("--rho", type=float, default=DEFAULT_RHO)
    parser.add_argument("--q-gain", type=float, default=DEFAULT_Q_GAIN, dest="q_gain")
    parser.add_argument("--owner-gain", type=float, default=DEFAULT_OWNER_GAIN, dest="owner_gain")
    parser.add_argument("--mortgage-gain", type=float, default=DEFAULT_MORTGAGE_GAIN, dest="mortgage_gain")
    parser.add_argument("--max-abs", type=float, default=DEFAULT_MAX_ABS, dest="max_abs")
    args = parser.parse_args()

    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    horizon = int(args.T)
    checkpoints = [t for t in [1, 5, 10, 20, 40, 80] if t <= horizon]

    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = resolve_calibrated_params(summary)
    scenarios = build_stationary_scenarios()
    stationary = stationary_targets_extended(summary, params, scenarios)

    no_shock_frames = []
    endog_frames = []
    fixed_rows: list[dict[str, float | str]] = []

    for scenario in scenarios:
        zero_fert_state = np.zeros(horizon + 1, dtype=float)
        q_path_no_shock = np.ones(horizon, dtype=float)
        # reuse the endogenous-fertility machinery with zero coefficients for the baseline comparison
        q_path_no_shock, no_shock_state, _ = solve_full_path_with_endogenous_fertility(
            summary,
            scenario,
            params,
            horizon,
            stationary.set_index("scenario").loc[scenario.name],
            rho=0.0,
            q_gain=0.0,
            owner_gain=0.0,
            mortgage_gain=0.0,
            max_abs=0.0,
        )
        no_shock_frames.append(
            simulate_stationary_re_path_with_endogenous_fertility(summary, scenario, params, q_path_no_shock, no_shock_state)
        )

        q_path_endog, fert_state, _ = solve_full_path_with_endogenous_fertility(
            summary,
            scenario,
            params,
            horizon,
            stationary.set_index("scenario").loc[scenario.name],
            rho=float(args.rho),
            q_gain=float(args.q_gain),
            owner_gain=float(args.owner_gain),
            mortgage_gain=float(args.mortgage_gain),
            max_abs=float(args.max_abs),
        )
        endog_frames.append(
            simulate_stationary_re_path_with_endogenous_fertility(summary, scenario, params, q_path_endog, fert_state)
        )

        fixed_rows.append(
            {
                "scenario": scenario.name,
                "q1": float(q_path_endog[0]),
                "q5": float(q_path_endog[4]) if horizon >= 5 else np.nan,
                "q10": float(q_path_endog[9]) if horizon >= 10 else np.nan,
                "q20": float(q_path_endog[19]) if horizon >= 20 else np.nan,
                "q40": float(q_path_endog[39]) if horizon >= 40 else np.nan,
                "q80": float(q_path_endog[79]) if horizon >= 80 else np.nan,
            }
        )

    no_shock_paths = pd.concat(no_shock_frames, ignore_index=True)
    endog_paths = pd.concat(endog_frames, ignore_index=True)
    fixed_points = pd.DataFrame(fixed_rows)
    comparisons = build_comparison_table(endog_paths, no_shock_paths, stationary, checkpoints, horizon)

    stem = f"annual_full_re_stationary_transition_endogenous_fertility_T{horizon}"
    fixed_points.to_csv(BUILD / f"{stem}_fixed_points.csv", index=False)
    comparisons.to_csv(BUILD / f"{stem}_checkpoints.csv", index=False)
    write_note(
        BUILD / f"{stem}.md",
        fixed_points,
        comparisons,
        stationary,
        horizon,
        float(args.rho),
        float(args.q_gain),
        float(args.owner_gain),
        float(args.mortgage_gain),
        float(args.max_abs),
    )


if __name__ == "__main__":
    main()
