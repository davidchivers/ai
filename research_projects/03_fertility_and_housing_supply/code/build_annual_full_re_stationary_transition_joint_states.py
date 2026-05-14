from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import INPUT_SUMMARY, load_initial_cross_section
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
from build_annual_full_re_stationary_transition_calibrated import simulate_stationary_re_path
from build_annual_full_re_stationary_transition_endogenous_fertility import (
    DEFAULT_MAX_ABS as DEFAULT_FERT_MAX_ABS,
    DEFAULT_MORTGAGE_GAIN as DEFAULT_FERT_MORTGAGE_GAIN,
    DEFAULT_OWNER_GAIN as DEFAULT_FERT_OWNER_GAIN,
    DEFAULT_Q_GAIN as DEFAULT_FERT_Q_GAIN,
    DEFAULT_RHO as DEFAULT_FERT_RHO,
    fertility_target,
    simulate_stationary_re_path_with_endogenous_fertility,
    solve_full_path_with_endogenous_fertility,
    stationary_targets_extended,
)
from build_annual_full_re_stationary_transition_political_state import (
    DEFAULT_MAX_ABS as DEFAULT_POL_MAX_ABS,
    DEFAULT_MORTGAGE_GAP_GAIN as DEFAULT_POL_MORTGAGE_GAP_GAIN,
    DEFAULT_OWNER_GAP_GAIN as DEFAULT_POL_OWNER_GAP_GAIN,
    DEFAULT_PRICE_GAIN as DEFAULT_POL_PRICE_GAIN,
    DEFAULT_RHO as DEFAULT_POL_RHO,
    DEFAULT_THETA_STATE_GAIN,
    political_easing_target,
    simulate_stationary_re_path_with_political_state,
    solve_full_path_with_political_state,
)
from build_annual_full_re_stationary_transition_calibrated import build_stationary_scenarios


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
DEFAULT_T = 80


def full_path_implied_with_joint_states(
    summary: pd.DataFrame,
    scenario,
    params,
    q_guesses: np.ndarray,
    ss: pd.Series,
    fert_rho: float,
    fert_q_gain: float,
    fert_owner_gain: float,
    fert_mortgage_gain: float,
    fert_max_abs: float,
    pol_rho: float,
    pol_price_gain: float,
    pol_mortgage_gap_gain: float,
    pol_owner_gap_gain: float,
    theta_state_gain: float,
    pol_max_abs: float,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, dict[str, list[float]]]:
    horizon = len(q_guesses)
    pop, arrays, refs = initial_state(summary, params, horizon)
    q_implied = np.zeros(horizon, dtype=float)
    fertility_state = np.zeros(horizon + 1, dtype=float)
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
        fertility_multiplier_t = 1.0 + fertility_state[t]
        demand_t = demand_index(metrics_t, refs, scenario.price_ratio, t, params) * fertility_multiplier_t

        arrays["permits"][t + 1] = permit_update(
            arrays["permits"][t],
            theta_effective_t,
            demand_t,
            arrays["stock"][t],
            q_guesses[t],
            params,
        )
        update_construction(arrays, t, params)

        pop = update_population(summary, pop, scenario, q_guesses[t], t)
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

        pol_target_t = political_easing_target(
            q_guesses[t],
            metrics_next,
            refs,
            pol_price_gain,
            pol_mortgage_gap_gain,
            pol_owner_gap_gain,
        )
        political_state[t + 1] = float(
            np.clip(
                pol_rho * political_state[t] + (1.0 - pol_rho) * pol_target_t,
                0.0,
                pol_max_abs,
            )
        )

        fertility_multiplier_next = 1.0 + fertility_state[t + 1]
        demand_next = demand_index(metrics_next, refs, scenario.price_ratio, t + 1, params) * fertility_multiplier_next
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

    return q_implied, fertility_state, political_state, extras


def solve_full_path_with_joint_states(
    summary: pd.DataFrame,
    scenario,
    params,
    horizon: int,
    ss: pd.Series,
    fert_rho: float,
    fert_q_gain: float,
    fert_owner_gain: float,
    fert_mortgage_gain: float,
    fert_max_abs: float,
    pol_rho: float,
    pol_price_gain: float,
    pol_mortgage_gap_gain: float,
    pol_owner_gap_gain: float,
    theta_state_gain: float,
    pol_max_abs: float,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, dict[str, list[float]]]:
    q_guess = np.ones(horizon, dtype=float)

    for _ in range(600):
        q_implied, fertility_state, political_state, extras = full_path_implied_with_joint_states(
            summary,
            scenario,
            params,
            q_guess,
            ss,
            fert_rho,
            fert_q_gain,
            fert_owner_gain,
            fert_mortgage_gain,
            fert_max_abs,
            pol_rho,
            pol_price_gain,
            pol_mortgage_gap_gain,
            pol_owner_gap_gain,
            theta_state_gain,
            pol_max_abs,
        )
        q_new = 0.60 * q_guess + 0.40 * q_implied
        if np.max(np.abs(q_new - q_guess)) < 1.0e-10:
            q_guess = q_new
            q_implied, fertility_state, political_state, extras = full_path_implied_with_joint_states(
                summary,
                scenario,
                params,
                q_guess,
                ss,
                fert_rho,
                fert_q_gain,
                fert_owner_gain,
                fert_mortgage_gain,
                fert_max_abs,
                pol_rho,
                pol_price_gain,
                pol_mortgage_gap_gain,
                pol_owner_gap_gain,
                theta_state_gain,
                pol_max_abs,
            )
            break
        q_guess = q_new

    return q_implied, fertility_state, political_state, extras


def simulate_stationary_re_path_with_joint_states(
    summary: pd.DataFrame,
    scenario,
    params,
    q_path: np.ndarray,
    fertility_state: np.ndarray,
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
        fertility_multiplier_t = 1.0 + float(fertility_state[t])
        demand_t = demand_index(metrics, refs, scenario.price_ratio, t, params) * fertility_multiplier_t

        records.append(
            {
                "scenario": f"{scenario.name}_joint_states_T{horizon}_full_re_stationary",
                "t": t,
                "fertility_state": float(fertility_state[t]),
                "fertility_multiplier": float(fertility_multiplier_t),
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
                "demand_index_with_fertility": float(demand_t),
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
    joint_paths: pd.DataFrame,
    no_state_paths: pd.DataFrame,
    fertility_only_paths: pd.DataFrame,
    political_only_paths: pd.DataFrame,
    stationary: pd.DataFrame,
    checkpoints: list[int],
    horizon: int,
) -> pd.DataFrame:
    no_state_map = no_state_paths.set_index(["scenario", "t"])
    fertility_only_map = fertility_only_paths.set_index(["scenario", "t"])
    political_only_map = political_only_paths.set_index(["scenario", "t"])
    stationary_map = stationary.set_index("scenario")
    rows: list[dict[str, float | int | str]] = []
    suffix = f"_joint_states_T{horizon}_full_re_stationary"

    for _, row in joint_paths.loc[joint_paths["t"].isin(checkpoints)].iterrows():
        base_name = row["scenario"].replace(suffix, "")
        no_state = no_state_map.loc[(f"{base_name}_T{horizon}_full_re_stationary", int(row["t"])), :]
        fertility_only = fertility_only_map.loc[
            (f"{base_name}_endogenous_fertility_T{horizon}_full_re_stationary", int(row["t"])),
            :,
        ]
        political_only = political_only_map.loc[
            (f"{base_name}_political_state_T{horizon}_full_re_stationary", int(row["t"])),
            :,
        ]
        ss = stationary_map.loc[base_name]
        rows.append(
            {
                "scenario": row["scenario"],
                "base_scenario": base_name,
                "t": int(row["t"]),
                "fertility_state": float(row["fertility_state"]),
                "fertility_multiplier": float(row["fertility_multiplier"]),
                "political_easing_state": float(row["political_easing_state"]),
                "q": float(row["q"]),
                "q_gap_vs_no_state_re": float(row["q"] - no_state["q"]),
                "q_gap_vs_fertility_only_re": float(row["q"] - fertility_only["q"]),
                "q_gap_vs_political_only_re": float(row["q"] - political_only["q"]),
                "q_gap_vs_stationary": float(row["q"] - ss["q_ss"]),
                "theta_effective": float(row["theta_effective"]),
                "theta_gap_vs_no_state_re": float(row["theta_effective"] - no_state["theta"]),
                "theta_gap_vs_political_only_re": float(row["theta_effective"] - political_only["theta_effective"]),
                "young_mortgaged_owner_25_34": float(row["young_mortgaged_owner_25_34"]),
                "young_mortgage_gap_vs_no_state_re": float(
                    row["young_mortgaged_owner_25_34"] - no_state["young_mortgaged_owner_25_34"]
                ),
                "young_mortgage_gap_vs_fertility_only_re": float(
                    row["young_mortgaged_owner_25_34"] - fertility_only["young_mortgaged_owner_25_34"]
                ),
                "young_mortgage_gap_vs_political_only_re": float(
                    row["young_mortgaged_owner_25_34"] - political_only["young_mortgaged_owner_25_34"]
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
    fert_rho: float,
    fert_q_gain: float,
    fert_owner_gain: float,
    fert_mortgage_gain: float,
    fert_max_abs: float,
    pol_rho: float,
    pol_price_gain: float,
    pol_mortgage_gap_gain: float,
    pol_owner_gap_gain: float,
    theta_state_gain: float,
    pol_max_abs: float,
) -> None:
    lines = [
        f"# Annual full RE with joint fertility and political states (T={horizon})",
        "",
        "This note joins the two reduced-form recursive layers inside one stationary annual full-RE solve:",
        "",
        "- endogenous fertility pressure on the demand side",
        "- forecasted political easing on the supply side",
        "",
        "Interpretation:",
        "",
        "- fertility responds to prices and ownership access relative to the stationary endpoint",
        "- political easing responds to rising prices and worsening ownership access relative to the observed snapshot",
        "- fertility then shifts demand, while political easing lowers effective `theta` and shifts permits and stock",
        "",
        "Fertility law of motion:",
        "",
        f"- persistence `rho = {fert_rho:.2f}`",
        f"- price response coefficient `{fert_q_gain:.3f}` on `log(q_ss / q_t)`",
        f"- young owner response coefficient `{fert_owner_gain:.3f}`",
        f"- young mortgaged-owner response coefficient `{fert_mortgage_gain:.3f}`",
        f"- state clipped to `±{fert_max_abs:.3f}`",
        "",
        "Political law of motion:",
        "",
        f"- persistence `rho = {pol_rho:.2f}`",
        f"- price gain on `log(q_t)`: `{pol_price_gain:.2f}`",
        f"- young-mortgage access gap gain: `{pol_mortgage_gap_gain:.2f}`",
        f"- owner 35-44 access gap gain: `{pol_owner_gap_gain:.2f}`",
        f"- theta shift gain: `{theta_state_gain:.2f}`",
        f"- state clipped to `[0, {pol_max_abs:.2f}]`",
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
            "## Joint-state full-RE path excerpts",
            "",
            "| Scenario | q1 | q5 | q10 | q20 | q40 | q80 | f5 | f20 | f80 | p5 | p20 | p80 |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in fixed_points.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.q1:.3f}` | `{row.q5:.3f}` | `{row.q10:.3f}` | `{row.q20:.3f}` | `{row.q40:.3f}` | `{row.q80:.3f}` | "
            f"`{row.f5:.3f}` | `{row.f20:.3f}` | `{row.f80:.3f}` | `{row.p5:.3f}` | `{row.p20:.3f}` | `{row.p80:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints relative to no-state and single-state RE",
            "",
            "| Scenario | t | Fertility state | Political state | q | q gap vs no-state RE | q gap vs fertility-only RE | q gap vs political-only RE |",
            "|---|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in comparisons.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.fertility_state:.3f}` | `{row.political_easing_state:.3f}` | `{row.q:.3f}` | "
            f"`{row.q_gap_vs_no_state_re:.3f}` | `{row.q_gap_vs_fertility_only_re:.3f}` | `{row.q_gap_vs_political_only_re:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is the first annual full-RE object in which fertility and local political restrictiveness are both forecast recursively inside the same solve.",
            "- Relative to the fertility-only object, the joint solve shows whether the extra price pressure from fertility is enough to activate the political easing margin earlier in the transition.",
            "- Relative to the political-only object, the joint solve shows whether the fertility channel is the missing force needed to move the recursive political state out of the tail and into the main transition window.",
            "- If the joint object still only changes the tail, the reduced-form recursive block is probably good enough for appendix or robustness use, but not yet the main annual transition headline.",
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
    parser.add_argument("--pol-rho", type=float, default=DEFAULT_POL_RHO, dest="pol_rho")
    parser.add_argument("--pol-price-gain", type=float, default=DEFAULT_POL_PRICE_GAIN, dest="pol_price_gain")
    parser.add_argument(
        "--pol-mortgage-gap-gain",
        type=float,
        default=DEFAULT_POL_MORTGAGE_GAP_GAIN,
        dest="pol_mortgage_gap_gain",
    )
    parser.add_argument("--pol-owner-gap-gain", type=float, default=DEFAULT_POL_OWNER_GAP_GAIN, dest="pol_owner_gap_gain")
    parser.add_argument("--theta-state-gain", type=float, default=DEFAULT_THETA_STATE_GAIN, dest="theta_state_gain")
    parser.add_argument("--pol-max-abs", type=float, default=DEFAULT_POL_MAX_ABS, dest="pol_max_abs")
    args = parser.parse_args()

    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    horizon = int(args.T)
    checkpoints = [t for t in [1, 5, 10, 20, 40, 80] if t <= horizon]

    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = resolve_calibrated_params(summary)
    scenarios = build_stationary_scenarios()
    stationary = stationary_targets_extended(summary, params, scenarios)
    stationary_map = stationary.set_index("scenario")

    no_state_frames = []
    fertility_only_frames = []
    political_only_frames = []
    joint_frames = []
    fixed_rows: list[dict[str, float | str]] = []

    for scenario in scenarios:
        ss = stationary_map.loc[scenario.name]

        no_state_q_path, _, _ = solve_full_path(summary, scenario, params, horizon)
        no_state_frames.append(simulate_stationary_re_path(summary, scenario, params, no_state_q_path))

        fertility_only_q_path, fertility_only_state, _ = solve_full_path_with_endogenous_fertility(
            summary,
            scenario,
            params,
            horizon,
            ss,
            rho=float(args.fert_rho),
            q_gain=float(args.fert_q_gain),
            owner_gain=float(args.fert_owner_gain),
            mortgage_gain=float(args.fert_mortgage_gain),
            max_abs=float(args.fert_max_abs),
        )
        fertility_only_frames.append(
            simulate_stationary_re_path_with_endogenous_fertility(
                summary,
                scenario,
                params,
                fertility_only_q_path,
                fertility_only_state,
            )
        )

        political_only_q_path, political_only_state, _ = solve_full_path_with_political_state(
            summary,
            scenario,
            params,
            horizon,
            rho=float(args.pol_rho),
            price_gain=float(args.pol_price_gain),
            mortgage_gap_gain=float(args.pol_mortgage_gap_gain),
            owner_gap_gain=float(args.pol_owner_gap_gain),
            theta_state_gain=float(args.theta_state_gain),
            max_abs=float(args.pol_max_abs),
        )
        political_only_frames.append(
            simulate_stationary_re_path_with_political_state(
                summary,
                scenario,
                params,
                political_only_q_path,
                political_only_state,
                theta_state_gain=float(args.theta_state_gain),
            )
        )

        joint_q_path, fertility_state, political_state, _ = solve_full_path_with_joint_states(
            summary,
            scenario,
            params,
            horizon,
            ss,
            fert_rho=float(args.fert_rho),
            fert_q_gain=float(args.fert_q_gain),
            fert_owner_gain=float(args.fert_owner_gain),
            fert_mortgage_gain=float(args.fert_mortgage_gain),
            fert_max_abs=float(args.fert_max_abs),
            pol_rho=float(args.pol_rho),
            pol_price_gain=float(args.pol_price_gain),
            pol_mortgage_gap_gain=float(args.pol_mortgage_gap_gain),
            pol_owner_gap_gain=float(args.pol_owner_gap_gain),
            theta_state_gain=float(args.theta_state_gain),
            pol_max_abs=float(args.pol_max_abs),
        )
        joint_frames.append(
            simulate_stationary_re_path_with_joint_states(
                summary,
                scenario,
                params,
                joint_q_path,
                fertility_state,
                political_state,
                theta_state_gain=float(args.theta_state_gain),
            )
        )

        fixed_rows.append(
            {
                "scenario": scenario.name,
                "q1": float(joint_q_path[0]),
                "q5": float(joint_q_path[4]) if horizon >= 5 else np.nan,
                "q10": float(joint_q_path[9]) if horizon >= 10 else np.nan,
                "q20": float(joint_q_path[19]) if horizon >= 20 else np.nan,
                "q40": float(joint_q_path[39]) if horizon >= 40 else np.nan,
                "q80": float(joint_q_path[79]) if horizon >= 80 else np.nan,
                "f5": float(fertility_state[5]) if horizon >= 5 else np.nan,
                "f20": float(fertility_state[20]) if horizon >= 20 else np.nan,
                "f80": float(fertility_state[80]) if horizon >= 80 else np.nan,
                "p5": float(political_state[5]) if horizon >= 5 else np.nan,
                "p20": float(political_state[20]) if horizon >= 20 else np.nan,
                "p80": float(political_state[80]) if horizon >= 80 else np.nan,
            }
        )

    no_state_paths = pd.concat(no_state_frames, ignore_index=True)
    fertility_only_paths = pd.concat(fertility_only_frames, ignore_index=True)
    political_only_paths = pd.concat(political_only_frames, ignore_index=True)
    joint_paths = pd.concat(joint_frames, ignore_index=True)
    fixed_points = pd.DataFrame(fixed_rows)
    comparisons = build_comparison_table(
        joint_paths,
        no_state_paths,
        fertility_only_paths,
        political_only_paths,
        stationary,
        checkpoints,
        horizon,
    )

    stem = f"annual_full_re_stationary_transition_joint_states_T{horizon}"
    fixed_points.to_csv(BUILD / f"{stem}_fixed_points.csv", index=False)
    no_state_paths.to_csv(BUILD / f"{stem}_no_state_paths.csv", index=False)
    fertility_only_paths.to_csv(BUILD / f"{stem}_fertility_only_paths.csv", index=False)
    political_only_paths.to_csv(BUILD / f"{stem}_political_only_paths.csv", index=False)
    joint_paths.to_csv(BUILD / f"{stem}.csv", index=False)
    comparisons.to_csv(BUILD / f"{stem}_checkpoints.csv", index=False)
    stationary.to_csv(BUILD / f"{stem}_stationary_targets.csv", index=False)
    write_note(
        BUILD / f"{stem}.md",
        fixed_points,
        comparisons,
        stationary,
        horizon,
        float(args.fert_rho),
        float(args.fert_q_gain),
        float(args.fert_owner_gain),
        float(args.fert_mortgage_gain),
        float(args.fert_max_abs),
        float(args.pol_rho),
        float(args.pol_price_gain),
        float(args.pol_mortgage_gap_gain),
        float(args.pol_owner_gap_gain),
        float(args.theta_state_gain),
        float(args.pol_max_abs),
    )


if __name__ == "__main__":
    main()
