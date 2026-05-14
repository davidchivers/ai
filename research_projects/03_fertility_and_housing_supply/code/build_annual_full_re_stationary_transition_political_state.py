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
from build_annual_full_path_re_permits_starts_stock_calibrated import initial_state, solve_full_path, update_construction
from build_annual_full_re_stationary_transition_calibrated import (
    build_stationary_scenarios,
    simulate_stationary_re_path,
    stationary_targets,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
DEFAULT_T = 80
DEFAULT_RHO = 0.90
DEFAULT_PRICE_GAIN = 0.50
DEFAULT_MORTGAGE_GAP_GAIN = 0.45
DEFAULT_OWNER_GAP_GAIN = 0.20
DEFAULT_THETA_STATE_GAIN = 0.32
DEFAULT_MAX_ABS = 0.15


def political_easing_target(
    q_current: float,
    metrics_next: dict[str, float],
    refs: dict[str, float],
    price_gain: float,
    mortgage_gap_gain: float,
    owner_gap_gain: float,
) -> float:
    price_term = price_gain * np.log(max(q_current, 1.0e-6))
    mortgage_term = mortgage_gap_gain * (refs["young_mortgage_25_34"] - metrics_next["young_mortgage_25_34"])
    owner_term = owner_gap_gain * (refs["owner_35_44"] - metrics_next["owner_35_44"])
    return float(price_term + mortgage_term + owner_term)


def full_path_implied_with_political_state(
    summary: pd.DataFrame,
    scenario,
    params,
    q_guesses: np.ndarray,
    rho: float,
    price_gain: float,
    mortgage_gap_gain: float,
    owner_gap_gain: float,
    theta_state_gain: float,
    max_abs: float,
) -> tuple[np.ndarray, np.ndarray, dict[str, list[float]]]:
    horizon = len(q_guesses)
    pop, arrays, refs = initial_state(summary, params, horizon)
    q_implied = np.zeros(horizon, dtype=float)
    political_state = np.zeros(horizon + 1, dtype=float)
    current_q = arrays["q"][0]

    extras = {
        "theta_base": [],
        "theta_effective": [],
        "permits": [],
        "starts": [],
        "completions": [],
        "stock": [],
        "young_mortgage": [],
        "owner_35_44": [],
    }

    for t in range(horizon):
        metrics_t = extract_metrics(pop)
        theta_base_t = theta_from_metrics(metrics_t, params)
        theta_effective_t = float(np.clip(theta_base_t - theta_state_gain * political_state[t], 0.0, 0.95))
        demand_t = demand_index(metrics_t, refs, scenario.price_ratio, t, params)

        arrays["permits"][t + 1] = permit_update(
            arrays["permits"][t], theta_effective_t, demand_t, arrays["stock"][t], q_guesses[t], params
        )
        update_construction(arrays, t, params)

        pop = update_population(summary, pop, scenario, q_guesses[t], t)
        metrics_next = extract_metrics(pop)

        target_t = political_easing_target(
            q_guesses[t],
            metrics_next,
            refs,
            price_gain,
            mortgage_gap_gain,
            owner_gap_gain,
        )
        political_state[t + 1] = float(np.clip(rho * political_state[t] + (1.0 - rho) * target_t, 0.0, max_abs))

        demand_next = demand_index(metrics_next, refs, scenario.price_ratio, t + 1, params)
        current_q = np.clip(
            np.exp(
                np.log(max(current_q, 1.0e-6))
                + params.price_damping * params.price_gap_gain * (demand_next - arrays["stock"][t + 1])
            ),
            params.q_min,
            params.q_max,
        )
        q_implied[t] = current_q

        extras["theta_base"].append(float(theta_base_t))
        extras["theta_effective"].append(float(theta_effective_t))
        extras["permits"].append(float(arrays["permits"][t + 1]))
        extras["starts"].append(float(arrays["starts"][t + 1]))
        extras["completions"].append(float(arrays["completions"][t + 1]))
        extras["stock"].append(float(arrays["stock"][t + 1]))
        extras["young_mortgage"].append(float(metrics_next["young_mortgage_25_34"]))
        extras["owner_35_44"].append(float(metrics_next["owner_35_44"]))

    return q_implied, political_state, extras


def solve_full_path_with_political_state(
    summary: pd.DataFrame,
    scenario,
    params,
    horizon: int,
    rho: float,
    price_gain: float,
    mortgage_gap_gain: float,
    owner_gap_gain: float,
    theta_state_gain: float,
    max_abs: float,
) -> tuple[np.ndarray, np.ndarray, dict[str, list[float]]]:
    q_guess = np.ones(horizon, dtype=float)

    for _ in range(600):
        q_implied, political_state, extras = full_path_implied_with_political_state(
            summary,
            scenario,
            params,
            q_guess,
            rho,
            price_gain,
            mortgage_gap_gain,
            owner_gap_gain,
            theta_state_gain,
            max_abs,
        )
        q_new = 0.60 * q_guess + 0.40 * q_implied
        if np.max(np.abs(q_new - q_guess)) < 1.0e-10:
            q_guess = q_new
            q_implied, political_state, extras = full_path_implied_with_political_state(
                summary,
                scenario,
                params,
                q_guess,
                rho,
                price_gain,
                mortgage_gap_gain,
                owner_gap_gain,
                theta_state_gain,
                max_abs,
            )
            break
        q_guess = q_new

    return q_implied, political_state, extras


def simulate_stationary_re_path_with_political_state(
    summary: pd.DataFrame,
    scenario,
    params,
    q_path: np.ndarray,
    political_state: np.ndarray,
    theta_state_gain: float,
) -> pd.DataFrame:
    horizon = len(q_path)
    pop, arrays, refs = initial_state(summary, params, horizon)
    records: list[dict[str, float | int | str]] = []

    for t in range(horizon + 1):
        metrics = extract_metrics(pop)
        theta_base_t = theta_from_metrics(metrics, params)
        theta_effective_t = float(np.clip(theta_base_t - theta_state_gain * political_state[t], 0.0, 0.95))
        demand_t = demand_index(metrics, refs, scenario.price_ratio, t, params)

        records.append(
            {
                "scenario": f"{scenario.name}_political_state_T{horizon}_full_re_stationary",
                "t": t,
                "political_easing_state": float(political_state[t]),
                "q": float(arrays["q"][t]),
                "theta_base": float(theta_base_t),
                "theta_effective": float(theta_effective_t),
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
        arrays["permits"][t + 1] = permit_update(
            arrays["permits"][t],
            theta_effective_t,
            demand_t,
            arrays["stock"][t],
            q_effective,
            params,
        )
        update_construction(arrays, t, params)
        pop = update_population(summary, pop, scenario, q_effective, t)
        arrays["q"][t + 1] = q_effective

    return pd.DataFrame.from_records(records)


def build_comparison_table(
    political_paths: pd.DataFrame,
    no_state_paths: pd.DataFrame,
    stationary: pd.DataFrame,
    checkpoints: list[int],
    horizon: int,
) -> pd.DataFrame:
    no_state_map = no_state_paths.set_index(["scenario", "t"])
    stationary_map = stationary.set_index("scenario")
    rows: list[dict[str, float | int | str]] = []
    suffix = f"_political_state_T{horizon}_full_re_stationary"

    for _, row in political_paths.loc[political_paths["t"].isin(checkpoints)].iterrows():
        base_name = row["scenario"].replace(suffix, "")
        no_state = no_state_map.loc[(f"{base_name}_T{horizon}_full_re_stationary", int(row["t"])), :]
        ss = stationary_map.loc[base_name]
        rows.append(
            {
                "scenario": row["scenario"],
                "base_scenario": base_name,
                "t": int(row["t"]),
                "political_easing_state": float(row["political_easing_state"]),
                "q": float(row["q"]),
                "q_gap_vs_no_state_re": float(row["q"] - no_state["q"]),
                "q_gap_vs_stationary": float(row["q"] - ss["q_ss"]),
                "theta_effective": float(row["theta_effective"]),
                "theta_gap_vs_no_state_re": float(row["theta_effective"] - no_state["theta"]),
                "young_mortgaged_owner_25_34": float(row["young_mortgaged_owner_25_34"]),
                "young_mortgage_gap_vs_no_state_re": float(
                    row["young_mortgaged_owner_25_34"] - no_state["young_mortgaged_owner_25_34"]
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
    price_gain: float,
    mortgage_gap_gain: float,
    owner_gap_gain: float,
    theta_state_gain: float,
    max_abs: float,
) -> None:
    lines = [
        f"# Annual full RE with forecasted political-easing state (T={horizon})",
        "",
        "This note adds the next rung after the imposed regime-path experiment: a forecasted political-easing state inside the stationary annual full-RE block.",
        "",
        "Interpretation:",
        "",
        "- the annual support regime still stays fixed within each scenario",
        "- but the supply-side political environment is no longer imposed as a one-off switch path",
        "- instead, a mild political-easing state responds to rising prices and worsening ownership access relative to the observed `t = 0` snapshot",
        "- that state shifts effective local restrictiveness `theta`, which then feeds permits, stock, and future prices",
        "",
        "Law of motion used here:",
        "",
        f"- persistence: `rho = {rho:.2f}`",
        f"- price gain on `log(q_t)`: `{price_gain:.2f}`",
        f"- young-mortgage access gap gain: `{mortgage_gap_gain:.2f}`",
        f"- owner 35-44 access gap gain: `{owner_gap_gain:.2f}`",
        f"- theta shift gain: `{theta_state_gain:.2f}`",
        f"- political-easing state clipped to `[0, {max_abs:.2f}]`",
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
            "## Political-state full-RE path excerpts",
            "",
            "| Scenario | q1 | q5 | q10 | q20 | q40 | q80 | s5 | s20 | s80 |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in fixed_points.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.q1:.3f}` | `{row.q5:.3f}` | `{row.q10:.3f}` | `{row.q20:.3f}` | "
            f"`{row.q40:.3f}` | `{row.q80:.3f}` | `{row.s5:.3f}` | `{row.s20:.3f}` | `{row.s80:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints relative to no-political-state full RE",
            "",
            "| Scenario | t | Political-easing state | q | q gap vs no-state RE | Effective theta | Theta gap vs no-state RE | Young mortgaged-owner 25-34 | Young mortgage gap vs no-state RE |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in comparisons.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.political_easing_state:.3f}` | `{row.q:.3f}` | `{row.q_gap_vs_no_state_re:.3f}` | "
            f"`{row.theta_effective:.3f}` | `{row.theta_gap_vs_no_state_re:.3f}` | `{row.young_mortgaged_owner_25_34:.3f}` | "
            f"`{row.young_mortgage_gap_vs_no_state_re:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is the first annual full-RE object in which future local political restrictiveness is forecast as a state rather than imposed as a known switch path.",
            "- Because that state only enters through effective `theta`, the experiment isolates the supply-side recursive margin cleanly.",
            "- If the resulting `q` gaps remain modest while effective `theta` moves in the expected direction, then the annual branch can now claim a genuine recursive politics -> permits -> stock -> prices layer.",
            "- The next remaining rung would be to join this political state with the reduced-form endogenous fertility state rather than treating them separately.",
        ]
    )

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--T", type=int, default=DEFAULT_T)
    parser.add_argument("--rho", type=float, default=DEFAULT_RHO)
    parser.add_argument("--price-gain", type=float, default=DEFAULT_PRICE_GAIN, dest="price_gain")
    parser.add_argument(
        "--mortgage-gap-gain",
        type=float,
        default=DEFAULT_MORTGAGE_GAP_GAIN,
        dest="mortgage_gap_gain",
    )
    parser.add_argument("--owner-gap-gain", type=float, default=DEFAULT_OWNER_GAP_GAIN, dest="owner_gap_gain")
    parser.add_argument("--theta-state-gain", type=float, default=DEFAULT_THETA_STATE_GAIN, dest="theta_state_gain")
    parser.add_argument("--max-abs", type=float, default=DEFAULT_MAX_ABS, dest="max_abs")
    args = parser.parse_args()

    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    horizon = int(args.T)
    checkpoints = [t for t in [5, 10, 20, 40, 80] if t <= horizon]

    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = resolve_calibrated_params(summary)
    scenarios = build_stationary_scenarios()
    stationary = stationary_targets(summary, params, scenarios)

    no_state_frames = []
    political_frames = []
    fixed_rows: list[dict[str, float | str]] = []

    for scenario in scenarios:
        no_state_q_path, _, _ = solve_full_path(summary, scenario, params, horizon)
        no_state_frames.append(simulate_stationary_re_path(summary, scenario, params, no_state_q_path))

        political_q_path, political_state, _ = solve_full_path_with_political_state(
            summary,
            scenario,
            params,
            horizon,
            rho=float(args.rho),
            price_gain=float(args.price_gain),
            mortgage_gap_gain=float(args.mortgage_gap_gain),
            owner_gap_gain=float(args.owner_gap_gain),
            theta_state_gain=float(args.theta_state_gain),
            max_abs=float(args.max_abs),
        )
        political_frames.append(
            simulate_stationary_re_path_with_political_state(
                summary,
                scenario,
                params,
                political_q_path,
                political_state,
                theta_state_gain=float(args.theta_state_gain),
            )
        )

        fixed_rows.append(
            {
                "scenario": scenario.name,
                "q1": float(political_q_path[0]),
                "q5": float(political_q_path[4]) if horizon >= 5 else np.nan,
                "q10": float(political_q_path[9]) if horizon >= 10 else np.nan,
                "q20": float(political_q_path[19]) if horizon >= 20 else np.nan,
                "q40": float(political_q_path[39]) if horizon >= 40 else np.nan,
                "q80": float(political_q_path[79]) if horizon >= 80 else np.nan,
                "s5": float(political_state[5]) if horizon >= 5 else np.nan,
                "s20": float(political_state[20]) if horizon >= 20 else np.nan,
                "s80": float(political_state[80]) if horizon >= 80 else np.nan,
            }
        )

    no_state_paths = pd.concat(no_state_frames, ignore_index=True)
    political_paths = pd.concat(political_frames, ignore_index=True)
    fixed_points = pd.DataFrame(fixed_rows)
    checkpoint_table = build_comparison_table(political_paths, no_state_paths, stationary, checkpoints, horizon)

    stem = f"annual_full_re_stationary_transition_political_state_T{horizon}"
    fixed_points.to_csv(BUILD / f"{stem}_fixed_points.csv", index=False)
    no_state_paths.to_csv(BUILD / f"{stem}_no_state_paths.csv", index=False)
    political_paths.to_csv(BUILD / f"{stem}.csv", index=False)
    checkpoint_table.to_csv(BUILD / f"{stem}_checkpoints.csv", index=False)
    stationary.to_csv(BUILD / f"{stem}_stationary_targets.csv", index=False)
    write_note(
        BUILD / f"{stem}.md",
        fixed_points,
        checkpoint_table,
        stationary,
        horizon,
        rho=float(args.rho),
        price_gain=float(args.price_gain),
        mortgage_gap_gain=float(args.mortgage_gap_gain),
        owner_gap_gain=float(args.owner_gap_gain),
        theta_state_gain=float(args.theta_state_gain),
        max_abs=float(args.max_abs),
    )


if __name__ == "__main__":
    main()
