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
)
from build_annual_full_path_re_permits_starts_stock_calibrated import initial_state, solve_full_path, update_construction
from build_annual_full_re_stationary_transition_calibrated import (
    build_stationary_scenarios,
    simulate_stationary_re_path,
)
from build_annual_full_re_stationary_transition_endogenous_fertility import stationary_targets_extended
from build_annual_full_re_stationary_transition_political_state import political_easing_target
from build_annual_full_re_stationary_transition_structural_fertility import (
    DEFAULT_CHECKPOINTS,
    DEFAULT_CHILDLESS_ENTRY_GAIN,
    DEFAULT_FIRST_BIRTH_GAIN,
    DEFAULT_OPERATOR_CANDIDATE,
    DEFAULT_T,
    DEFAULT_TIMING_SHIFT_GAIN,
    StructuralFertilityOperator,
    load_structural_fertility_operator,
    simulate_stationary_re_path_with_structural_fertility,
    solve_full_path_with_structural_fertility,
    structural_micro_adjustments,
    update_population_with_structural_fertility,
)
from build_annual_full_re_stationary_transition_support_state import (
    DEFAULT_SUPPORT_MAX,
    DEFAULT_SUPPORT_MORTGAGE_GAP_GAIN,
    DEFAULT_SUPPORT_OWNER_GAP_GAIN,
    DEFAULT_SUPPORT_PRICE_GAIN,
    DEFAULT_SUPPORT_RHO,
    DEFAULT_THETA_SUPPORT_GAIN,
    interpolated_support_scenario,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--T", type=int, default=DEFAULT_T)
    parser.add_argument("--candidate-id", type=int, default=DEFAULT_OPERATOR_CANDIDATE)
    parser.add_argument("--support-rho", type=float, default=DEFAULT_SUPPORT_RHO, dest="support_rho")
    parser.add_argument("--support-price-gain", type=float, default=DEFAULT_SUPPORT_PRICE_GAIN, dest="support_price_gain")
    parser.add_argument(
        "--support-mortgage-gap-gain",
        type=float,
        default=DEFAULT_SUPPORT_MORTGAGE_GAP_GAIN,
        dest="support_mortgage_gap_gain",
    )
    parser.add_argument(
        "--support-owner-gap-gain",
        type=float,
        default=DEFAULT_SUPPORT_OWNER_GAP_GAIN,
        dest="support_owner_gap_gain",
    )
    parser.add_argument("--support-max", type=float, default=DEFAULT_SUPPORT_MAX, dest="support_max")
    parser.add_argument("--theta-support-gain", type=float, default=DEFAULT_THETA_SUPPORT_GAIN, dest="theta_support_gain")
    parser.add_argument("--timing-shift-gain", type=float, default=DEFAULT_TIMING_SHIFT_GAIN, dest="timing_shift_gain")
    parser.add_argument("--first-birth-gain", type=float, default=DEFAULT_FIRST_BIRTH_GAIN, dest="first_birth_gain")
    parser.add_argument("--childless-entry-gain", type=float, default=DEFAULT_CHILDLESS_ENTRY_GAIN, dest="childless_entry_gain")
    return parser.parse_args()


def support_adjusted_price_anchor(base_q_ss: float, target_q_ss: float, support_state: float) -> float:
    s = float(np.clip(support_state, 0.0, 1.0))
    return float((1.0 - s) * base_q_ss + s * target_q_ss)


def full_path_implied_with_structural_support_state(
    summary: pd.DataFrame,
    base_scenario,
    target_scenario,
    params,
    q_guesses: np.ndarray,
    operator: StructuralFertilityOperator,
    base_q_ss: float,
    target_q_ss: float,
    support_rho: float,
    support_price_gain: float,
    support_mortgage_gap_gain: float,
    support_owner_gap_gain: float,
    support_max: float,
    theta_support_gain: float,
    timing_shift_gain: float,
    first_birth_gain: float,
    childless_entry_gain: float,
) -> tuple[np.ndarray, np.ndarray, dict[str, list[float]]]:
    horizon = len(q_guesses)
    pop, arrays, refs = initial_state(summary, params, horizon)
    q_implied = np.zeros(horizon, dtype=float)
    support_state = np.zeros(horizon + 1, dtype=float)
    current_q = arrays["q"][0]

    extras = {
        "support_state": [],
        "q_anchor": [],
        "absolute_price": [],
        "avg_birth_rate": [],
        "avg_first_birth_rate": [],
        "mean_age_first_birth": [],
        "share_first_birth_30_plus": [],
        "childless_share_at_50": [],
        "birth_multiplier": [],
        "young_purchase_scale": [],
        "mid_purchase_scale": [],
        "entrant_owner_scale": [],
        "theta_base": [],
        "theta_effective": [],
        "deposit_help_weight": [],
        "qualification_weight": [],
        "permits": [],
        "starts": [],
        "completions": [],
        "stock": [],
        "young_mortgage": [],
        "owner_35_44": [],
    }

    for t in range(horizon):
        scenario_t = interpolated_support_scenario(base_scenario, target_scenario, support_state[t])
        q_anchor_t = support_adjusted_price_anchor(base_q_ss, target_q_ss, support_state[t])
        anchor_eval_t = operator.evaluate(q_anchor_t)
        absolute_price_t = q_anchor_t * max(float(q_guesses[t]), 1.0e-6)
        fertility_t = operator.evaluate(absolute_price_t)
        birth_multiplier_t = max(fertility_t["avg_birth_rate"] / max(anchor_eval_t["avg_birth_rate"], 1.0e-6), 0.10)
        micro_t = structural_micro_adjustments(
            fertility_t,
            anchor_eval_t,
            timing_shift_gain,
            first_birth_gain,
            childless_entry_gain,
        )

        metrics_t = extract_metrics(pop)
        theta_base_t = theta_from_metrics(metrics_t, params)
        theta_effective_t = float(np.clip(theta_base_t - theta_support_gain * support_state[t], 0.0, 0.95))
        demand_t = demand_index(metrics_t, refs, scenario_t.price_ratio, t, params) * birth_multiplier_t

        arrays["permits"][t + 1] = permit_update(
            arrays["permits"][t],
            theta_effective_t,
            demand_t,
            arrays["stock"][t],
            q_guesses[t],
            params,
        )
        update_construction(arrays, t, params)

        pop = update_population_with_structural_fertility(
            summary,
            pop,
            scenario_t,
            q_guesses[t],
            t,
            birth_multiplier_t,
            micro_t["young_purchase_scale"],
            micro_t["mid_purchase_scale"],
            micro_t["entrant_owner_scale"],
        )
        metrics_next = extract_metrics(pop)

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

        next_guess = q_guesses[t] if t == horizon - 1 else q_guesses[t + 1]
        scenario_next = interpolated_support_scenario(base_scenario, target_scenario, support_state[t + 1])
        q_anchor_next = support_adjusted_price_anchor(base_q_ss, target_q_ss, support_state[t + 1])
        anchor_eval_next = operator.evaluate(q_anchor_next)
        fertility_next = operator.evaluate(q_anchor_next * max(float(next_guess), 1.0e-6))
        birth_multiplier_next = max(
            fertility_next["avg_birth_rate"] / max(anchor_eval_next["avg_birth_rate"], 1.0e-6),
            0.10,
        )
        demand_next = demand_index(metrics_next, refs, scenario_next.price_ratio, t + 1, params) * birth_multiplier_next
        current_q = implied_q_next(current_q, demand_next, arrays["stock"][t + 1], params)
        q_implied[t] = current_q

        extras["support_state"].append(float(support_state[t]))
        extras["q_anchor"].append(float(q_anchor_t))
        extras["absolute_price"].append(float(absolute_price_t))
        extras["avg_birth_rate"].append(float(fertility_t["avg_birth_rate"]))
        extras["avg_first_birth_rate"].append(float(fertility_t["avg_first_birth_rate"]))
        extras["mean_age_first_birth"].append(float(fertility_t["mean_age_first_birth"]))
        extras["share_first_birth_30_plus"].append(float(fertility_t["share_first_birth_30_plus"]))
        extras["childless_share_at_50"].append(float(fertility_t["childless_share_at_50"]))
        extras["birth_multiplier"].append(float(birth_multiplier_t))
        extras["young_purchase_scale"].append(float(micro_t["young_purchase_scale"]))
        extras["mid_purchase_scale"].append(float(micro_t["mid_purchase_scale"]))
        extras["entrant_owner_scale"].append(float(micro_t["entrant_owner_scale"]))
        extras["theta_base"].append(float(theta_base_t))
        extras["theta_effective"].append(float(theta_effective_t))
        extras["deposit_help_weight"].append(float(scenario_t.deposit_help_weight))
        extras["qualification_weight"].append(float(scenario_t.qualification_weight))
        extras["permits"].append(float(arrays["permits"][t + 1]))
        extras["starts"].append(float(arrays["starts"][t + 1]))
        extras["completions"].append(float(arrays["completions"][t + 1]))
        extras["stock"].append(float(arrays["stock"][t + 1]))
        extras["young_mortgage"].append(float(metrics_next["young_mortgage_25_34"]))
        extras["owner_35_44"].append(float(metrics_next["owner_35_44"]))

    return q_implied, support_state, extras


def solve_full_path_with_structural_support_state(
    summary: pd.DataFrame,
    base_scenario,
    target_scenario,
    params,
    horizon: int,
    operator: StructuralFertilityOperator,
    base_q_ss: float,
    target_q_ss: float,
    support_rho: float,
    support_price_gain: float,
    support_mortgage_gap_gain: float,
    support_owner_gap_gain: float,
    support_max: float,
    theta_support_gain: float,
    timing_shift_gain: float,
    first_birth_gain: float,
    childless_entry_gain: float,
    q_init: np.ndarray | None = None,
) -> tuple[np.ndarray, np.ndarray, dict[str, list[float]]]:
    q_guess = np.array(q_init, copy=True) if q_init is not None else np.ones(horizon, dtype=float)

    for _ in range(700):
        q_implied, support_state, extras = full_path_implied_with_structural_support_state(
            summary,
            base_scenario,
            target_scenario,
            params,
            q_guess,
            operator,
            base_q_ss,
            target_q_ss,
            support_rho,
            support_price_gain,
            support_mortgage_gap_gain,
            support_owner_gap_gain,
            support_max,
            theta_support_gain,
            timing_shift_gain,
            first_birth_gain,
            childless_entry_gain,
        )
        q_new = 0.65 * q_guess + 0.35 * q_implied
        if np.max(np.abs(q_new - q_guess)) < 1.0e-10:
            q_guess = q_new
            q_implied, support_state, extras = full_path_implied_with_structural_support_state(
                summary,
                base_scenario,
                target_scenario,
                params,
                q_guess,
                operator,
                base_q_ss,
                target_q_ss,
                support_rho,
                support_price_gain,
                support_mortgage_gap_gain,
                support_owner_gap_gain,
                support_max,
                theta_support_gain,
                timing_shift_gain,
                first_birth_gain,
                childless_entry_gain,
            )
            break
        q_guess = q_new

    return q_implied, support_state, extras


def simulate_stationary_re_path_with_structural_support_state(
    summary: pd.DataFrame,
    base_scenario,
    target_scenario,
    params,
    q_path: np.ndarray,
    support_state: np.ndarray,
    operator: StructuralFertilityOperator,
    base_q_ss: float,
    target_q_ss: float,
    theta_support_gain: float,
    timing_shift_gain: float,
    first_birth_gain: float,
    childless_entry_gain: float,
) -> pd.DataFrame:
    horizon = len(q_path)
    pop, arrays, refs = initial_state(summary, params, horizon)
    records: list[dict[str, float | int | str]] = []

    for t in range(horizon + 1):
        scenario_t = interpolated_support_scenario(base_scenario, target_scenario, support_state[t])
        q_anchor_t = support_adjusted_price_anchor(base_q_ss, target_q_ss, support_state[t])
        anchor_eval_t = operator.evaluate(q_anchor_t)
        absolute_price_t = q_anchor_t * max(float(arrays["q"][t]), 1.0e-6)
        fertility_t = operator.evaluate(absolute_price_t)
        birth_multiplier_t = max(fertility_t["avg_birth_rate"] / max(anchor_eval_t["avg_birth_rate"], 1.0e-6), 0.10)
        micro_t = structural_micro_adjustments(
            fertility_t,
            anchor_eval_t,
            timing_shift_gain,
            first_birth_gain,
            childless_entry_gain,
        )

        metrics = extract_metrics(pop)
        theta_base_t = theta_from_metrics(metrics, params)
        theta_effective_t = float(np.clip(theta_base_t - theta_support_gain * support_state[t], 0.0, 0.95))
        demand_t = demand_index(metrics, refs, scenario_t.price_ratio, t, params) * birth_multiplier_t

        records.append(
            {
                "scenario": f"{target_scenario.name}_structural_support_state_T{horizon}_full_re_stationary",
                "t": t,
                "support_state": float(support_state[t]),
                "deposit_help_weight": float(scenario_t.deposit_help_weight),
                "qualification_weight": float(scenario_t.qualification_weight),
                "q_anchor": float(q_anchor_t),
                "q": float(arrays["q"][t]),
                "absolute_price": float(absolute_price_t),
                "avg_birth_rate": float(fertility_t["avg_birth_rate"]),
                "avg_first_birth_rate": float(fertility_t["avg_first_birth_rate"]),
                "mean_age_first_birth": float(fertility_t["mean_age_first_birth"]),
                "share_first_birth_30_plus": float(fertility_t["share_first_birth_30_plus"]),
                "childless_share_at_50": float(fertility_t["childless_share_at_50"]),
                "birth_multiplier": float(birth_multiplier_t),
                "young_purchase_scale": float(micro_t["young_purchase_scale"]),
                "mid_purchase_scale": float(micro_t["mid_purchase_scale"]),
                "entrant_owner_scale": float(micro_t["entrant_owner_scale"]),
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

        q_effective = float(q_path[t])
        arrays["permits"][t + 1] = permit_update(
            arrays["permits"][t],
            theta_effective_t,
            demand_t,
            arrays["stock"][t],
            q_effective,
            params,
        )
        update_construction(arrays, t, params)

        q_anchor_transition = support_adjusted_price_anchor(base_q_ss, target_q_ss, support_state[t])
        anchor_eval_transition = operator.evaluate(q_anchor_transition)
        fertility_transition = operator.evaluate(q_anchor_transition * max(q_effective, 1.0e-6))
        birth_multiplier_transition = max(
            fertility_transition["avg_birth_rate"] / max(anchor_eval_transition["avg_birth_rate"], 1.0e-6),
            0.10,
        )
        micro_transition = structural_micro_adjustments(
            fertility_transition,
            anchor_eval_transition,
            timing_shift_gain,
            first_birth_gain,
            childless_entry_gain,
        )
        pop = update_population_with_structural_fertility(
            summary,
            pop,
            scenario_t,
            q_effective,
            t,
            birth_multiplier_transition,
            micro_transition["young_purchase_scale"],
            micro_transition["mid_purchase_scale"],
            micro_transition["entrant_owner_scale"],
        )
        arrays["q"][t + 1] = q_effective

    return pd.DataFrame.from_records(records)


def build_fixed_point_table(paths: pd.DataFrame, horizon: int) -> pd.DataFrame:
    rows: list[dict[str, float | str]] = []
    suffix = f"_structural_support_state_T{horizon}_full_re_stationary"
    for scenario_name, frame in paths.groupby("scenario"):
        frame = frame.set_index("t")
        rows.append(
            {
                "scenario": scenario_name.replace(suffix, ""),
                "q1": float(frame.loc[1, "q"]),
                "q5": float(frame.loc[5, "q"]) if 5 in frame.index else np.nan,
                "q10": float(frame.loc[10, "q"]) if 10 in frame.index else np.nan,
                "q20": float(frame.loc[20, "q"]) if 20 in frame.index else np.nan,
                "q40": float(frame.loc[40, "q"]) if 40 in frame.index else np.nan,
                "q80": float(frame.loc[80, "q"]) if 80 in frame.index else np.nan,
                "s5": float(frame.loc[5, "support_state"]) if 5 in frame.index else np.nan,
                "s20": float(frame.loc[20, "support_state"]) if 20 in frame.index else np.nan,
                "s40": float(frame.loc[40, "support_state"]) if 40 in frame.index else np.nan,
                "s80": float(frame.loc[80, "support_state"]) if 80 in frame.index else np.nan,
                "birth_multiplier20": float(frame.loc[20, "birth_multiplier"]) if 20 in frame.index else np.nan,
                "young_purchase_scale20": float(frame.loc[20, "young_purchase_scale"]) if 20 in frame.index else np.nan,
                "entrant_owner_scale20": float(frame.loc[20, "entrant_owner_scale"]) if 20 in frame.index else np.nan,
            }
        )
    return pd.DataFrame(rows)


def build_comparison_table(
    joint_paths: pd.DataFrame,
    structural_fixed_paths: pd.DataFrame,
    fixed_target_paths: pd.DataFrame,
    checkpoints: list[int],
    horizon: int,
) -> pd.DataFrame:
    structural_map = structural_fixed_paths.set_index(["scenario", "t"])
    fixed_map = fixed_target_paths.set_index(["scenario", "t"])
    suffix = f"_structural_support_state_T{horizon}_full_re_stationary"
    rows: list[dict[str, float | int | str]] = []

    for _, row in joint_paths.loc[joint_paths["t"].isin(checkpoints)].iterrows():
        base_name = str(row["scenario"]).replace(suffix, "")
        structural_fixed = structural_map.loc[(f"{base_name}_structural_fertility_T{horizon}_full_re_stationary", int(row["t"]))]
        fixed_target = fixed_map.loc[(f"{base_name}_T{horizon}_full_re_stationary", int(row["t"]))]
        rows.append(
            {
                "scenario": row["scenario"],
                "t": int(row["t"]),
                "support_state": float(row["support_state"]),
                "deposit_help_weight": float(row["deposit_help_weight"]),
                "qualification_weight": float(row["qualification_weight"]),
                "birth_multiplier": float(row["birth_multiplier"]),
                "young_purchase_scale": float(row["young_purchase_scale"]),
                "entrant_owner_scale": float(row["entrant_owner_scale"]),
                "q": float(row["q"]),
                "q_gap_vs_structural_fixed_support_re": float(row["q"] - structural_fixed["q"]),
                "q_gap_vs_fixed_support_re": float(row["q"] - fixed_target["q"]),
                "young_mortgaged_owner_25_34": float(row["young_mortgaged_owner_25_34"]),
                "young_mortgage_gap_vs_structural_fixed_support_re": float(
                    row["young_mortgaged_owner_25_34"] - structural_fixed["young_mortgaged_owner_25_34"]
                ),
                "young_mortgage_gap_vs_fixed_support_re": float(
                    row["young_mortgaged_owner_25_34"] - fixed_target["young_mortgaged_owner_25_34"]
                ),
            }
        )
    return pd.DataFrame(rows)


def write_note(
    path: Path,
    operator: StructuralFertilityOperator,
    fixed_points: pd.DataFrame,
    comparisons: pd.DataFrame,
    horizon: int,
    support_rho: float,
    support_price_gain: float,
    support_mortgage_gap_gain: float,
    support_owner_gap_gain: float,
    support_max: float,
    theta_support_gain: float,
    timing_shift_gain: float,
    first_birth_gain: float,
    childless_entry_gain: float,
) -> None:
    lines = [
        f"# Annual full RE with structural fertility and recursive support state (T={horizon})",
        "",
        "This note combines the richer structural fertility operator with the recursive support-state object inside the stationary annual full-RE solve.",
        "",
        f"Operator source: candidate `{operator.candidate_id}` from `fertility_annual_ownership_balance_sheet_screen_*`.",
        "",
        "Object:",
        "",
        "- support state interpolates deposit help and qualification support between baseline and the target support regime",
        "- the same support state also lowers effective supply restrictiveness `theta`",
        "- structural fertility is evaluated at a support-adjusted stationary price anchor rather than through a separate reduced-form fertility state",
        "- first-birth timing and childlessness feed back through age-specific purchase transitions and entrant tenure mix",
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
        "Structural micro-channel gains:",
        "",
        f"- first-birth gain: `{first_birth_gain:.2f}`",
        f"- timing-shift gain: `{timing_shift_gain:.2f}`",
        f"- childless-entry gain: `{childless_entry_gain:.2f}`",
        "",
        "## Joint path excerpts",
        "",
        "| Scenario | q1 | q5 | q10 | q20 | q40 | q80 | s20 | s40 | s80 | Birth mult t20 | Young purchase scale t20 | Entrant owner scale t20 |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]

    for row in fixed_points.itertuples(index=False):
        q80 = f"{row.q80:.3f}" if not pd.isna(row.q80) else "nan"
        lines.append(
            f"| `{row.scenario}` | `{row.q1:.3f}` | `{row.q5:.3f}` | `{row.q10:.3f}` | `{row.q20:.3f}` | `{row.q40:.3f}` | `{q80}` | "
            f"`{row.s20:.3f}` | `{row.s40:.3f}` | `{row.s80:.3f}` | `{row.birth_multiplier20:.3f}` | "
            f"`{row.young_purchase_scale20:.3f}` | `{row.entrant_owner_scale20:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints relative to fixed-support benchmarks",
            "",
            "| Scenario | t | Support state | Deposit help | Qualification | q | q gap vs structural fixed-support RE | q gap vs fixed-support RE | Young mortgaged-owner 25-34 | Young mortgage gap vs structural fixed-support RE |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in comparisons.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.support_state:.3f}` | `{row.deposit_help_weight:.3f}` | `{row.qualification_weight:.3f}` | "
            f"`{row.q:.3f}` | `{row.q_gap_vs_structural_fixed_support_re:.3f}` | `{row.q_gap_vs_fixed_support_re:.3f}` | "
            f"`{row.young_mortgaged_owner_25_34:.3f}` | `{row.young_mortgage_gap_vs_structural_fixed_support_re:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is the cleanest current annual RE object that combines recursive policy support with structural fertility micro moments.",
            "- It is richer than the support-state object because fertility is structural rather than reduced-form.",
            "- It is richer than the structural-only object because support is forecast recursively rather than fixed at the target regime.",
            "- It is still an operator bridge rather than a literal annual household recursion because parity and children-at-home states are not yet explicit Python states.",
        ]
    )

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    horizon = int(args.T)
    checkpoints = [t for t in DEFAULT_CHECKPOINTS if t <= horizon]
    summary = load_initial_cross_section(INPUT_SUMMARY)
    params = resolve_calibrated_params(summary)
    scenarios = build_stationary_scenarios()
    stationary = stationary_targets_extended(summary, params, scenarios)
    stationary_map = stationary.set_index("scenario")
    operator = load_structural_fertility_operator(int(args.candidate_id))

    base_scenario = scenarios[0]
    base_q_ss = float(stationary_map.loc[base_scenario.name, "q_ss"])
    target_scenarios = scenarios[1:]

    fixed_target_frames: list[pd.DataFrame] = []
    structural_fixed_frames: list[pd.DataFrame] = []
    joint_frames: list[pd.DataFrame] = []

    for target_scenario in target_scenarios:
        fixed_target_q_path, _, _ = solve_full_path(summary, target_scenario, params, horizon)
        fixed_target_frames.append(simulate_stationary_re_path(summary, target_scenario, params, fixed_target_q_path))

        target_q_ss = float(stationary_map.loc[target_scenario.name, "q_ss"])
        structural_fixed_q_path, _ = solve_full_path_with_structural_fertility(
            summary,
            target_scenario,
            params,
            horizon,
            operator,
            target_q_ss,
            float(args.timing_shift_gain),
            float(args.first_birth_gain),
            float(args.childless_entry_gain),
            q_init=fixed_target_q_path,
        )
        structural_fixed_frames.append(
            simulate_stationary_re_path_with_structural_fertility(
                summary,
                target_scenario,
                params,
                structural_fixed_q_path,
                operator,
                target_q_ss,
                float(args.timing_shift_gain),
                float(args.first_birth_gain),
                float(args.childless_entry_gain),
            )
        )

        joint_q_path, support_state, _ = solve_full_path_with_structural_support_state(
            summary,
            base_scenario,
            target_scenario,
            params,
            horizon,
            operator,
            base_q_ss,
            target_q_ss,
            float(args.support_rho),
            float(args.support_price_gain),
            float(args.support_mortgage_gap_gain),
            float(args.support_owner_gap_gain),
            float(args.support_max),
            float(args.theta_support_gain),
            float(args.timing_shift_gain),
            float(args.first_birth_gain),
            float(args.childless_entry_gain),
            q_init=structural_fixed_q_path,
        )
        joint_frames.append(
            simulate_stationary_re_path_with_structural_support_state(
                summary,
                base_scenario,
                target_scenario,
                params,
                joint_q_path,
                support_state,
                operator,
                base_q_ss,
                target_q_ss,
                float(args.theta_support_gain),
                float(args.timing_shift_gain),
                float(args.first_birth_gain),
                float(args.childless_entry_gain),
            )
        )

    fixed_target_paths = pd.concat(fixed_target_frames, ignore_index=True)
    structural_fixed_paths = pd.concat(structural_fixed_frames, ignore_index=True)
    joint_paths = pd.concat(joint_frames, ignore_index=True)
    fixed_points = build_fixed_point_table(joint_paths, horizon)
    comparisons = build_comparison_table(joint_paths, structural_fixed_paths, fixed_target_paths, checkpoints, horizon)

    stem = f"annual_full_re_stationary_transition_structural_support_state_T{horizon}"
    fixed_points.to_csv(BUILD / f"{stem}_fixed_points.csv", index=False)
    fixed_target_paths.to_csv(BUILD / f"{stem}_fixed_target_paths.csv", index=False)
    structural_fixed_paths.to_csv(BUILD / f"{stem}_structural_fixed_paths.csv", index=False)
    joint_paths.to_csv(BUILD / f"{stem}.csv", index=False)
    comparisons.to_csv(BUILD / f"{stem}_checkpoints.csv", index=False)
    write_note(
        BUILD / f"{stem}.md",
        operator,
        fixed_points,
        comparisons,
        horizon,
        float(args.support_rho),
        float(args.support_price_gain),
        float(args.support_mortgage_gap_gain),
        float(args.support_owner_gap_gain),
        float(args.support_max),
        float(args.theta_support_gain),
        float(args.timing_shift_gain),
        float(args.first_birth_gain),
        float(args.childless_entry_gain),
    )


if __name__ == "__main__":
    main()
