from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import INPUT_SUMMARY, Scenario, load_initial_cross_section
from build_annual_snapshot_state_transition_permits_starts_stock_calibrated import (
    demand_index,
    extract_metrics,
    implied_q_next,
    permit_update,
    resolve_calibrated_params,
    theta_from_metrics,
    update_population,
)
from build_annual_full_path_re_permits_starts_stock_calibrated import initial_state, solve_full_path, update_construction
from build_annual_full_re_stationary_transition_calibrated import (
    build_stationary_scenarios,
    simulate_stationary_re_path,
)
from build_annual_full_re_stationary_transition_endogenous_fertility import (
    DEFAULT_MAX_ABS as DEFAULT_FERT_MAX_ABS,
    DEFAULT_MORTGAGE_GAIN as DEFAULT_FERT_MORTGAGE_GAIN,
    DEFAULT_OWNER_GAIN as DEFAULT_FERT_OWNER_GAIN,
    DEFAULT_Q_GAIN as DEFAULT_FERT_Q_GAIN,
    DEFAULT_RHO as DEFAULT_FERT_RHO,
    fertility_target,
    stationary_targets_extended,
)
from build_annual_full_re_stationary_transition_political_state import political_easing_target


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
DEFAULT_T = 80
DEFAULT_SUPPORT_RHO = 0.85
DEFAULT_SUPPORT_PRICE_GAIN = 0.75
DEFAULT_SUPPORT_MORTGAGE_GAP_GAIN = 0.60
DEFAULT_SUPPORT_OWNER_GAP_GAIN = 0.25
DEFAULT_SUPPORT_MAX = 1.0
DEFAULT_THETA_SUPPORT_GAIN = 0.12


def interpolated_support_scenario(base: Scenario, target: Scenario, support_state: float) -> Scenario:
    s = float(np.clip(support_state, 0.0, 1.0))
    return Scenario(
        name=f"{target.name}_support_state",
        price_ratio=target.price_ratio,
        deposit_help_weight=base.deposit_help_weight + s * (target.deposit_help_weight - base.deposit_help_weight),
        qualification_weight=base.qualification_weight + s * (target.qualification_weight - base.qualification_weight),
        deposit_help_horizon=0,
        qualification_horizon=0,
        targeted_support=target.targeted_support,
        support_center=target.support_center,
        support_width=target.support_width,
        mid_age_scale=target.mid_age_scale,
    )


def full_path_implied_with_support_state(
    summary: pd.DataFrame,
    base_scenario: Scenario,
    target_scenario: Scenario,
    params,
    q_guesses: np.ndarray,
    ss: pd.Series,
    fert_rho: float,
    fert_q_gain: float,
    fert_owner_gain: float,
    fert_mortgage_gain: float,
    fert_max_abs: float,
    support_rho: float,
    support_price_gain: float,
    support_mortgage_gap_gain: float,
    support_owner_gap_gain: float,
    support_max: float,
    theta_support_gain: float,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, dict[str, list[float]]]:
    horizon = len(q_guesses)
    pop, arrays, refs = initial_state(summary, params, horizon)
    q_implied = np.zeros(horizon, dtype=float)
    fertility_state = np.zeros(horizon + 1, dtype=float)
    support_state = np.zeros(horizon + 1, dtype=float)
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
        scenario_t = interpolated_support_scenario(base_scenario, target_scenario, support_state[t])
        metrics_t = extract_metrics(pop)
        theta_base_t = theta_from_metrics(metrics_t, params)
        theta_effective_t = float(np.clip(theta_base_t - theta_support_gain * support_state[t], 0.0, 0.95))
        fertility_multiplier_t = 1.0 + fertility_state[t]
        demand_t = demand_index(metrics_t, refs, scenario_t.price_ratio, t, params) * fertility_multiplier_t

        arrays["permits"][t + 1] = permit_update(
            arrays["permits"][t],
            theta_effective_t,
            demand_t,
            arrays["stock"][t],
            q_guesses[t],
            params,
        )
        update_construction(arrays, t, params)

        pop = update_population(summary, pop, scenario_t, q_guesses[t], t)
        metrics_next = extract_metrics(pop)

        fert_target_t = fertility_target(
            q_guesses[t],
            metrics_next,
            ss,
            fert_q_gain,
            fert_owner_gain,
            fert_mortgage_gain,
        )
        fertility_state[t + 1] = float(
            np.clip(
                fert_rho * fertility_state[t] + (1.0 - fert_rho) * fert_target_t,
                -fert_max_abs,
                fert_max_abs,
            )
        )

        support_target_t = political_easing_target(
            q_guesses[t],
            metrics_next,
            refs,
            support_price_gain,
            support_mortgage_gap_gain,
            support_owner_gap_gain,
        )
        support_state[t + 1] = float(
            np.clip(
                support_rho * support_state[t] + (1.0 - support_rho) * support_target_t,
                0.0,
                support_max,
            )
        )

        scenario_next = interpolated_support_scenario(base_scenario, target_scenario, support_state[t + 1])
        fertility_multiplier_next = 1.0 + fertility_state[t + 1]
        demand_next = demand_index(metrics_next, refs, scenario_next.price_ratio, t + 1, params) * fertility_multiplier_next
        current_q = implied_q_next(current_q, demand_next, arrays["stock"][t + 1], params)
        q_implied[t] = current_q

        extras["theta_base"].append(float(theta_base_t))
        extras["theta_effective"].append(float(theta_effective_t))
        extras["permits"].append(float(arrays["permits"][t + 1]))
        extras["starts"].append(float(arrays["starts"][t + 1]))
        extras["completions"].append(float(arrays["completions"][t + 1]))
        extras["stock"].append(float(arrays["stock"][t + 1]))
        extras["young_mortgage"].append(float(metrics_next["young_mortgage_25_34"]))
        extras["owner_35_44"].append(float(metrics_next["owner_35_44"]))

    return q_implied, fertility_state, support_state, extras


def solve_full_path_with_support_state(
    summary: pd.DataFrame,
    base_scenario: Scenario,
    target_scenario: Scenario,
    params,
    horizon: int,
    ss: pd.Series,
    fert_rho: float,
    fert_q_gain: float,
    fert_owner_gain: float,
    fert_mortgage_gain: float,
    fert_max_abs: float,
    support_rho: float,
    support_price_gain: float,
    support_mortgage_gap_gain: float,
    support_owner_gap_gain: float,
    support_max: float,
    theta_support_gain: float,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, dict[str, list[float]]]:
    q_guess = np.ones(horizon, dtype=float)

    for _ in range(600):
        q_implied, fertility_state, support_state, extras = full_path_implied_with_support_state(
            summary,
            base_scenario,
            target_scenario,
            params,
            q_guess,
            ss,
            fert_rho,
            fert_q_gain,
            fert_owner_gain,
            fert_mortgage_gain,
            fert_max_abs,
            support_rho,
            support_price_gain,
            support_mortgage_gap_gain,
            support_owner_gap_gain,
            support_max,
            theta_support_gain,
        )
        q_new = 0.60 * q_guess + 0.40 * q_implied
        if np.max(np.abs(q_new - q_guess)) < 1.0e-10:
            q_guess = q_new
            q_implied, fertility_state, support_state, extras = full_path_implied_with_support_state(
                summary,
                base_scenario,
                target_scenario,
                params,
                q_guess,
                ss,
                fert_rho,
                fert_q_gain,
                fert_owner_gain,
                fert_mortgage_gain,
                fert_max_abs,
                support_rho,
                support_price_gain,
                support_mortgage_gap_gain,
                support_owner_gap_gain,
                support_max,
                theta_support_gain,
            )
            break
        q_guess = q_new

    return q_implied, fertility_state, support_state, extras


def simulate_stationary_re_path_with_support_state(
    summary: pd.DataFrame,
    base_scenario: Scenario,
    target_scenario: Scenario,
    params,
    q_path: np.ndarray,
    fertility_state: np.ndarray,
    support_state: np.ndarray,
    theta_support_gain: float,
) -> pd.DataFrame:
    horizon = len(q_path)
    pop, arrays, refs = initial_state(summary, params, horizon)
    records: list[dict[str, float | int | str]] = []

    for t in range(horizon + 1):
        scenario_t = interpolated_support_scenario(base_scenario, target_scenario, support_state[t])
        metrics = extract_metrics(pop)
        theta_base_t = theta_from_metrics(metrics, params)
        theta_effective_t = float(np.clip(theta_base_t - theta_support_gain * support_state[t], 0.0, 0.95))
        fertility_multiplier_t = 1.0 + float(fertility_state[t])
        demand_t = demand_index(metrics, refs, scenario_t.price_ratio, t, params) * fertility_multiplier_t

        records.append(
            {
                "scenario": f"{target_scenario.name}_support_state_T{horizon}_full_re_stationary",
                "t": t,
                "fertility_state": float(fertility_state[t]),
                "fertility_multiplier": float(fertility_multiplier_t),
                "support_state": float(support_state[t]),
                "deposit_help_weight": float(scenario_t.deposit_help_weight),
                "qualification_weight": float(scenario_t.qualification_weight),
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
        pop = update_population(summary, pop, scenario_t, q_effective, t)
        arrays["q"][t + 1] = q_effective

    return pd.DataFrame.from_records(records)


def build_comparison_table(
    support_paths: pd.DataFrame,
    fixed_target_paths: pd.DataFrame,
    checkpoints: list[int],
    horizon: int,
) -> pd.DataFrame:
    fixed_map = fixed_target_paths.set_index(["scenario", "t"])
    rows: list[dict[str, float | int | str]] = []
    suffix = f"_support_state_T{horizon}_full_re_stationary"

    for _, row in support_paths.loc[support_paths["t"].isin(checkpoints)].iterrows():
        base_name = row["scenario"].replace(suffix, "")
        fixed_target = fixed_map.loc[(f"{base_name}_T{horizon}_full_re_stationary", int(row["t"])), :]
        rows.append(
            {
                "scenario": row["scenario"],
                "target_scenario": base_name,
                "t": int(row["t"]),
                "fertility_state": float(row["fertility_state"]),
                "support_state": float(row["support_state"]),
                "deposit_help_weight": float(row["deposit_help_weight"]),
                "qualification_weight": float(row["qualification_weight"]),
                "q": float(row["q"]),
                "q_gap_vs_fixed_support_re": float(row["q"] - fixed_target["q"]),
                "theta_effective": float(row["theta_effective"]),
                "theta_gap_vs_fixed_support_re": float(row["theta_effective"] - fixed_target["theta"]),
                "young_mortgaged_owner_25_34": float(row["young_mortgaged_owner_25_34"]),
                "young_mortgage_gap_vs_fixed_support_re": float(
                    row["young_mortgaged_owner_25_34"] - fixed_target["young_mortgaged_owner_25_34"]
                ),
            }
        )

    return pd.DataFrame(rows)


def write_note(
    path: Path,
    fixed_points: pd.DataFrame,
    comparisons: pd.DataFrame,
    horizon: int,
    fert_rho: float,
    fert_q_gain: float,
    fert_owner_gain: float,
    fert_mortgage_gain: float,
    fert_max_abs: float,
    support_rho: float,
    support_price_gain: float,
    support_mortgage_gap_gain: float,
    support_owner_gap_gain: float,
    support_max: float,
    theta_support_gain: float,
) -> None:
    lines = [
        f"# Annual full RE with recursive support state (T={horizon})",
        "",
        "This note pushes the annual branch closer to a fuller recursive equilibrium by making the support regime itself forecasted inside the stationary full-RE solve.",
        "",
        "Object:",
        "",
        "- support state scales deposit help and qualification support between baseline and the target support regime",
        "- the same support state also lowers effective local restrictiveness `theta` on the supply side",
        "- fertility remains a reduced-form endogenous state on the demand side",
        "",
        "Fertility law of motion:",
        "",
        f"- persistence `rho = {fert_rho:.2f}`",
        f"- price response coefficient `{fert_q_gain:.3f}` on `log(q_ss / q_t)`",
        f"- young owner response coefficient `{fert_owner_gain:.3f}`",
        f"- young mortgaged-owner response coefficient `{fert_mortgage_gain:.3f}`",
        f"- state clipped to `±{fert_max_abs:.3f}`",
        "",
        "Support-state law of motion:",
        "",
        f"- persistence `rho = {support_rho:.2f}`",
        f"- price gain on `log(q_t)`: `{support_price_gain:.2f}`",
        f"- young-mortgage access gap gain: `{support_mortgage_gap_gain:.2f}`",
        f"- owner 35-44 access gap gain: `{support_owner_gap_gain:.2f}`",
        f"- support state clipped to `[0, {support_max:.2f}]`",
        f"- theta support gain: `{theta_support_gain:.2f}`",
        "",
        "## Recursive-support full-RE path excerpts",
        "",
        "| Scenario | q1 | q5 | q10 | q20 | q40 | q80 | f5 | f20 | s5 | s20 | s40 | s80 |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]

    for row in fixed_points.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.q1:.3f}` | `{row.q5:.3f}` | `{row.q10:.3f}` | `{row.q20:.3f}` | `{row.q40:.3f}` | `{row.q80:.3f}` | "
            f"`{row.f5:.3f}` | `{row.f20:.3f}` | `{row.s5:.3f}` | `{row.s20:.3f}` | `{row.s40:.3f}` | `{row.s80:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints relative to fixed-support full RE",
            "",
            "| Scenario | t | Support state | Deposit help | Qualification | q | q gap vs fixed-support RE | Young mortgaged-owner 25-34 | Young mortgage gap vs fixed-support RE |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in comparisons.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.support_state:.3f}` | `{row.deposit_help_weight:.3f}` | `{row.qualification_weight:.3f}` | `{row.q:.3f}` | "
            f"`{row.q_gap_vs_fixed_support_re:.3f}` | `{row.young_mortgaged_owner_25_34:.3f}` | `{row.young_mortgage_gap_vs_fixed_support_re:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is closer to a full recursive policy RE object than the earlier theta-only easing-state run, because the forecasted state now changes the household transition object itself.",
            "- If the support state turns on meaningfully by `t = 20-40`, then the annual branch now has a genuine forecasted support-policy layer rather than only an imposed regime path.",
            "- If the recursive-support path remains far from the fixed-support benchmark in the main transition window, then the support-state object is economically distinct enough to justify its own appendix or robustness role.",
        ]
    )

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--T", type=int, default=DEFAULT_T)
    parser.add_argument("--fert-rho", type=float, default=DEFAULT_FERT_RHO, dest="fert_rho")
    parser.add_argument("--fert-q-gain", type=float, default=DEFAULT_FERT_Q_GAIN, dest="fert_q_gain")
    parser.add_argument("--fert-owner-gain", type=float, default=DEFAULT_FERT_OWNER_GAIN, dest="fert_owner_gain")
    parser.add_argument(
        "--fert-mortgage-gain",
        type=float,
        default=DEFAULT_FERT_MORTGAGE_GAIN,
        dest="fert_mortgage_gain",
    )
    parser.add_argument("--fert-max-abs", type=float, default=DEFAULT_FERT_MAX_ABS, dest="fert_max_abs")
    parser.add_argument("--support-rho", type=float, default=DEFAULT_SUPPORT_RHO, dest="support_rho")
    parser.add_argument("--support-price-gain", type=float, default=DEFAULT_SUPPORT_PRICE_GAIN, dest="support_price_gain")
    parser.add_argument(
        "--support-mortgage-gap-gain",
        type=float,
        default=DEFAULT_SUPPORT_MORTGAGE_GAP_GAIN,
        dest="support_mortgage_gap_gain",
    )
    parser.add_argument("--support-owner-gap-gain", type=float, default=DEFAULT_SUPPORT_OWNER_GAP_GAIN, dest="support_owner_gap_gain")
    parser.add_argument("--support-max", type=float, default=DEFAULT_SUPPORT_MAX, dest="support_max")
    parser.add_argument("--theta-support-gain", type=float, default=DEFAULT_THETA_SUPPORT_GAIN, dest="theta_support_gain")
    args = parser.parse_args()

    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    horizon = int(args.T)
    checkpoints = [t for t in [1, 5, 10, 20, 40, 80] if t <= horizon]

    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = resolve_calibrated_params(summary)
    scenarios = build_stationary_scenarios()
    base_scenario = scenarios[0]
    target_scenarios = scenarios[1:]
    stationary = stationary_targets_extended(summary, params, scenarios)
    stationary_map = stationary.set_index("scenario")

    fixed_target_frames = []
    support_frames = []
    fixed_rows: list[dict[str, float | str]] = []

    for target_scenario in target_scenarios:
        ss = stationary_map.loc[target_scenario.name]

        fixed_target_q_path, _, _ = solve_full_path(summary, target_scenario, params, horizon)
        fixed_target_frames.append(simulate_stationary_re_path(summary, target_scenario, params, fixed_target_q_path))

        support_q_path, fertility_state, support_state, _ = solve_full_path_with_support_state(
            summary,
            base_scenario,
            target_scenario,
            params,
            horizon,
            ss,
            fert_rho=float(args.fert_rho),
            fert_q_gain=float(args.fert_q_gain),
            fert_owner_gain=float(args.fert_owner_gain),
            fert_mortgage_gain=float(args.fert_mortgage_gain),
            fert_max_abs=float(args.fert_max_abs),
            support_rho=float(args.support_rho),
            support_price_gain=float(args.support_price_gain),
            support_mortgage_gap_gain=float(args.support_mortgage_gap_gain),
            support_owner_gap_gain=float(args.support_owner_gap_gain),
            support_max=float(args.support_max),
            theta_support_gain=float(args.theta_support_gain),
        )
        support_frames.append(
            simulate_stationary_re_path_with_support_state(
                summary,
                base_scenario,
                target_scenario,
                params,
                support_q_path,
                fertility_state,
                support_state,
                theta_support_gain=float(args.theta_support_gain),
            )
        )

        fixed_rows.append(
            {
                "scenario": target_scenario.name,
                "q1": float(support_q_path[0]),
                "q5": float(support_q_path[4]) if horizon >= 5 else np.nan,
                "q10": float(support_q_path[9]) if horizon >= 10 else np.nan,
                "q20": float(support_q_path[19]) if horizon >= 20 else np.nan,
                "q40": float(support_q_path[39]) if horizon >= 40 else np.nan,
                "q80": float(support_q_path[79]) if horizon >= 80 else np.nan,
                "f5": float(fertility_state[5]) if horizon >= 5 else np.nan,
                "f20": float(fertility_state[20]) if horizon >= 20 else np.nan,
                "s5": float(support_state[5]) if horizon >= 5 else np.nan,
                "s20": float(support_state[20]) if horizon >= 20 else np.nan,
                "s40": float(support_state[40]) if horizon >= 40 else np.nan,
                "s80": float(support_state[80]) if horizon >= 80 else np.nan,
            }
        )

    fixed_target_paths = pd.concat(fixed_target_frames, ignore_index=True)
    support_paths = pd.concat(support_frames, ignore_index=True)
    fixed_points = pd.DataFrame(fixed_rows)
    comparisons = build_comparison_table(support_paths, fixed_target_paths, checkpoints, horizon)

    stem = f"annual_full_re_stationary_transition_support_state_T{horizon}"
    fixed_points.to_csv(BUILD / f"{stem}_fixed_points.csv", index=False)
    fixed_target_paths.to_csv(BUILD / f"{stem}_fixed_target_paths.csv", index=False)
    support_paths.to_csv(BUILD / f"{stem}.csv", index=False)
    comparisons.to_csv(BUILD / f"{stem}_checkpoints.csv", index=False)
    write_note(
        BUILD / f"{stem}.md",
        fixed_points,
        comparisons,
        horizon,
        float(args.fert_rho),
        float(args.fert_q_gain),
        float(args.fert_owner_gain),
        float(args.fert_mortgage_gain),
        float(args.fert_max_abs),
        float(args.support_rho),
        float(args.support_price_gain),
        float(args.support_mortgage_gap_gain),
        float(args.support_owner_gap_gain),
        float(args.support_max),
        float(args.theta_support_gain),
    )


if __name__ == "__main__":
    main()
