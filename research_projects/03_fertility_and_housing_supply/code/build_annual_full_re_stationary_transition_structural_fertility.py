from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import (
    INPUT_SUMMARY,
    adjust_matrix,
    build_base_transition_matrices,
    load_initial_cross_section,
)
from build_annual_snapshot_state_transition_permits_stock import STATE_ORDER
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


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
DEFAULT_T = 80
DEFAULT_OPERATOR_CANDIDATE = 6
DEFAULT_TIMING_SHIFT_GAIN = 0.50
DEFAULT_FIRST_BIRTH_GAIN = 0.80
DEFAULT_CHILDLESS_ENTRY_GAIN = 0.75
DEFAULT_CHECKPOINTS = [1, 5, 10, 20, 40, 80]
STRUCTURAL_PATHS = BUILD / "fertility_annual_ownership_balance_sheet_screen_candidate_paths.csv"
STRUCTURAL_CROSSING = BUILD / "fertility_annual_ownership_balance_sheet_screen_crossing_paths.csv"


@dataclass(frozen=True)
class StructuralFertilityOperator:
    candidate_id: int
    label: str
    timing_price_grid: np.ndarray
    avg_first_birth_rate: np.ndarray
    mean_age_first_birth: np.ndarray
    share_first_birth_30_plus: np.ndarray
    childless_share_at_50: np.ndarray
    birth_price_grid: np.ndarray
    avg_birth_rate: np.ndarray

    def evaluate(self, absolute_price: float) -> dict[str, float]:
        price = max(float(absolute_price), 1.0e-6)
        return {
            "avg_birth_rate": float(edge_slope_interp(price, self.birth_price_grid, self.avg_birth_rate)),
            "avg_first_birth_rate": float(edge_slope_interp(price, self.timing_price_grid, self.avg_first_birth_rate)),
            "mean_age_first_birth": float(edge_slope_interp(price, self.timing_price_grid, self.mean_age_first_birth)),
            "share_first_birth_30_plus": float(
                edge_slope_interp(price, self.timing_price_grid, self.share_first_birth_30_plus)
            ),
            "childless_share_at_50": float(edge_slope_interp(price, self.timing_price_grid, self.childless_share_at_50)),
        }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--T", type=int, default=DEFAULT_T)
    parser.add_argument("--candidate-id", type=int, default=DEFAULT_OPERATOR_CANDIDATE)
    parser.add_argument("--timing-shift-gain", type=float, default=DEFAULT_TIMING_SHIFT_GAIN)
    parser.add_argument("--first-birth-gain", type=float, default=DEFAULT_FIRST_BIRTH_GAIN)
    parser.add_argument("--childless-entry-gain", type=float, default=DEFAULT_CHILDLESS_ENTRY_GAIN)
    return parser.parse_args()


def edge_slope_interp(x: float | np.ndarray, xs: np.ndarray, ys: np.ndarray) -> float | np.ndarray:
    x_arr = np.asarray(x, dtype=float)
    y_arr = np.interp(x_arr, xs, ys)
    if xs.size >= 2:
        left_slope = (ys[1] - ys[0]) / (xs[1] - xs[0])
        right_slope = (ys[-1] - ys[-2]) / (xs[-1] - xs[-2])
        y_arr = np.where(x_arr < xs[0], ys[0] + left_slope * (x_arr - xs[0]), y_arr)
        y_arr = np.where(x_arr > xs[-1], ys[-1] + right_slope * (x_arr - xs[-1]), y_arr)
    if np.isscalar(x):
        return float(y_arr)
    return y_arr


def load_structural_fertility_operator(candidate_id: int) -> StructuralFertilityOperator:
    if not STRUCTURAL_PATHS.exists():
        raise FileNotFoundError(f"Missing structural-fertility path table: {STRUCTURAL_PATHS}")
    if not STRUCTURAL_CROSSING.exists():
        raise FileNotFoundError(f"Missing structural-fertility crossing table: {STRUCTURAL_CROSSING}")

    timing = pd.read_csv(STRUCTURAL_PATHS)
    timing = timing.loc[timing["candidate_id"] == candidate_id].sort_values("a_price").reset_index(drop=True)
    if timing.empty:
        raise ValueError(f"No structural-fertility timing rows found for candidate_id={candidate_id}.")

    wide = pd.read_csv(STRUCTURAL_CROSSING)
    wide = wide.loc[wide["candidate_id"] == candidate_id].sort_values("a_price").reset_index(drop=True)
    if wide.empty:
        wide = timing.loc[:, ["a_price", "avg_birth_rate"]].copy()

    return StructuralFertilityOperator(
        candidate_id=candidate_id,
        label=str(timing.loc[0, "label"]),
        timing_price_grid=timing["a_price"].to_numpy(dtype=float),
        avg_first_birth_rate=timing["avg_first_birth_rate"].to_numpy(dtype=float),
        mean_age_first_birth=timing["mean_age_first_birth"].to_numpy(dtype=float),
        share_first_birth_30_plus=timing["share_first_birth_30_plus"].to_numpy(dtype=float),
        childless_share_at_50=timing["childless_share_at_50"].to_numpy(dtype=float),
        birth_price_grid=wide["a_price"].to_numpy(dtype=float),
        avg_birth_rate=wide["avg_birth_rate"].to_numpy(dtype=float),
    )


def rescale_purchase_rows(matrix: np.ndarray, purchase_scale: float) -> np.ndarray:
    adjusted = np.array(matrix, copy=True)
    for row_idx in (0, 1):
        purchase_mass = float(adjusted[row_idx, 2] + adjusted[row_idx, 3])
        if purchase_mass <= 0.0:
            continue

        target_purchase = float(np.clip(purchase_mass * purchase_scale, 0.0, 0.95))
        scale = target_purchase / purchase_mass
        adjusted[row_idx, 2] *= scale
        adjusted[row_idx, 3] *= scale

        other_nonpurchase = float(adjusted[row_idx, :].sum() - adjusted[row_idx, row_idx] - adjusted[row_idx, 2] - adjusted[row_idx, 3])
        adjusted[row_idx, row_idx] = max(1.0e-9, 1.0 - other_nonpurchase - adjusted[row_idx, 2] - adjusted[row_idx, 3])
        adjusted[row_idx, :] = adjusted[row_idx, :] / adjusted[row_idx, :].sum()
    return adjusted


def tilt_entrant_mix(entrant_mix: np.ndarray, entrant_owner_scale: float) -> np.ndarray:
    mix = np.array(entrant_mix, copy=True)
    owner_share = float(mix[2] + mix[3])
    renter_share = float(mix[0] + mix[1])
    if owner_share <= 0.0 or renter_share <= 0.0:
        return mix / max(mix.sum(), 1.0e-9)

    target_owner_share = float(np.clip(owner_share * entrant_owner_scale, 0.02, 0.95))
    target_renter_share = 1.0 - target_owner_share
    mix[2:4] *= target_owner_share / owner_share
    mix[0:2] *= target_renter_share / renter_share
    mix /= max(mix.sum(), 1.0e-9)
    return mix


def structural_micro_adjustments(
    fertility_t: dict[str, float],
    anchor_eval: dict[str, float],
    timing_shift_gain: float,
    first_birth_gain: float,
    childless_entry_gain: float,
) -> dict[str, float]:
    anchor_first_birth_rate = max(float(anchor_eval["avg_first_birth_rate"]), 1.0e-6)
    first_birth_gap = float(fertility_t["avg_first_birth_rate"] / anchor_first_birth_rate - 1.0)
    delay_pressure = float(
        0.75 * (fertility_t["share_first_birth_30_plus"] - anchor_eval["share_first_birth_30_plus"])
        + 0.10 * (fertility_t["mean_age_first_birth"] - anchor_eval["mean_age_first_birth"])
    )
    childless_gap = float(fertility_t["childless_share_at_50"] - anchor_eval["childless_share_at_50"])

    young_purchase_scale = float(
        np.clip(1.0 + first_birth_gain * first_birth_gap - timing_shift_gain * delay_pressure, 0.60, 1.35)
    )
    mid_purchase_scale = float(
        np.clip(1.0 - 0.50 * first_birth_gain * first_birth_gap + 0.75 * timing_shift_gain * delay_pressure, 0.70, 1.35)
    )
    entrant_owner_scale = float(
        np.clip(1.0 - childless_entry_gain * (childless_gap + 0.50 * delay_pressure), 0.70, 1.30)
    )

    return {
        "first_birth_gap": first_birth_gap,
        "delay_pressure": delay_pressure,
        "childless_gap": childless_gap,
        "young_purchase_scale": young_purchase_scale,
        "mid_purchase_scale": mid_purchase_scale,
        "entrant_owner_scale": entrant_owner_scale,
    }


def update_population_with_structural_fertility(
    summary: pd.DataFrame,
    pop: np.ndarray,
    scenario,
    q_t: float,
    t: int,
    entrant_multiplier: float,
    young_purchase_scale: float,
    mid_purchase_scale: float,
    entrant_owner_scale: float,
) -> np.ndarray:
    age_blocks = list(summary["age_block"])
    widths = (summary["age_hi"] - summary["age_lo"] + 1).to_numpy(dtype=float)
    entrant_mix_base = summary.loc[summary["age_block"] == "25-34", STATE_ORDER].iloc[0].to_numpy(dtype=float)
    entrant_mix = tilt_entrant_mix(entrant_mix_base, entrant_owner_scale)
    base_matrices = build_base_transition_matrices()

    post = np.zeros_like(pop)
    for i, age_block in enumerate(age_blocks):
        matrix = adjust_matrix(
            base_matrices[age_block],
            age_block=age_block,
            price_ratio=q_t,
            deposit_help_weight=scenario.deposit_help_weight,
            qualification_weight=scenario.qualification_weight,
            deposit_help_horizon=scenario.deposit_help_horizon,
            qualification_horizon=scenario.qualification_horizon,
            targeted_support=scenario.targeted_support,
            support_center=scenario.support_center,
            support_width=scenario.support_width,
            mid_age_scale=scenario.mid_age_scale,
            t=t,
        )
        if age_block == "25-34":
            matrix = rescale_purchase_rows(matrix, young_purchase_scale)
        elif age_block == "35-44":
            matrix = rescale_purchase_rows(matrix, mid_purchase_scale)
        post[i, :] = pop[i, :] @ matrix

    new_pop = np.zeros_like(pop)
    outflows = np.zeros_like(pop)
    for i in range(len(age_blocks)):
        outflows[i, :] = post[i, :] / widths[i]
        new_pop[i, :] += post[i, :] - outflows[i, :]

    for i in range(1, len(age_blocks)):
        new_pop[i, :] += outflows[i - 1, :]

    entrant_mass = float(outflows[-1, :].sum()) * max(float(entrant_multiplier), 0.10)
    new_pop[0, :] += entrant_mass * entrant_mix
    return new_pop


def full_path_implied_with_structural_fertility(
    summary: pd.DataFrame,
    scenario,
    params,
    q_guesses: np.ndarray,
    operator: StructuralFertilityOperator,
    absolute_price_anchor: float,
    timing_shift_gain: float,
    first_birth_gain: float,
    childless_entry_gain: float,
) -> tuple[np.ndarray, dict[str, list[float]]]:
    horizon = len(q_guesses)
    pop, arrays, refs = initial_state(summary, params, horizon)
    q_implied = np.zeros(horizon, dtype=float)
    current_q = arrays["q"][0]

    anchor_eval = operator.evaluate(absolute_price_anchor)
    anchor_birth_rate = max(anchor_eval["avg_birth_rate"], 1.0e-6)

    extras = {
        "absolute_price": [],
        "avg_birth_rate": [],
        "avg_first_birth_rate": [],
        "mean_age_first_birth": [],
        "share_first_birth_30_plus": [],
        "childless_share_at_50": [],
        "birth_multiplier": [],
        "first_birth_gap": [],
        "delay_pressure": [],
        "childless_gap": [],
        "young_purchase_scale": [],
        "mid_purchase_scale": [],
        "entrant_owner_scale": [],
        "theta": [],
        "permits": [],
        "starts": [],
        "completions": [],
        "stock": [],
        "young_mortgage": [],
    }

    for t in range(horizon):
        absolute_price_t = absolute_price_anchor * max(float(q_guesses[t]), 1.0e-6)
        fertility_t = operator.evaluate(absolute_price_t)
        birth_multiplier_t = max(fertility_t["avg_birth_rate"] / anchor_birth_rate, 0.10)
        micro_t = structural_micro_adjustments(
            fertility_t,
            anchor_eval,
            timing_shift_gain,
            first_birth_gain,
            childless_entry_gain,
        )

        metrics_t = extract_metrics(pop)
        theta_t = theta_from_metrics(metrics_t, params)
        demand_t = demand_index(metrics_t, refs, scenario.price_ratio, t, params) * birth_multiplier_t

        arrays["permits"][t + 1] = permit_update(
            arrays["permits"][t],
            theta_t,
            demand_t,
            arrays["stock"][t],
            q_guesses[t],
            params,
        )
        update_construction(arrays, t, params)

        pop = update_population_with_structural_fertility(
            summary,
            pop,
            scenario,
            q_guesses[t],
            t,
            birth_multiplier_t,
            micro_t["young_purchase_scale"],
            micro_t["mid_purchase_scale"],
            micro_t["entrant_owner_scale"],
        )
        metrics_next = extract_metrics(pop)

        next_guess = q_guesses[t] if t == horizon - 1 else q_guesses[t + 1]
        absolute_price_next = absolute_price_anchor * max(float(next_guess), 1.0e-6)
        birth_multiplier_next = max(operator.evaluate(absolute_price_next)["avg_birth_rate"] / anchor_birth_rate, 0.10)
        demand_next = demand_index(metrics_next, refs, scenario.price_ratio, t + 1, params) * birth_multiplier_next
        current_q = implied_q_next(current_q, demand_next, arrays["stock"][t + 1], params)
        q_implied[t] = current_q

        extras["absolute_price"].append(float(absolute_price_t))
        extras["avg_birth_rate"].append(float(fertility_t["avg_birth_rate"]))
        extras["avg_first_birth_rate"].append(float(fertility_t["avg_first_birth_rate"]))
        extras["mean_age_first_birth"].append(float(fertility_t["mean_age_first_birth"]))
        extras["share_first_birth_30_plus"].append(float(fertility_t["share_first_birth_30_plus"]))
        extras["childless_share_at_50"].append(float(fertility_t["childless_share_at_50"]))
        extras["birth_multiplier"].append(float(birth_multiplier_t))
        extras["first_birth_gap"].append(float(micro_t["first_birth_gap"]))
        extras["delay_pressure"].append(float(micro_t["delay_pressure"]))
        extras["childless_gap"].append(float(micro_t["childless_gap"]))
        extras["young_purchase_scale"].append(float(micro_t["young_purchase_scale"]))
        extras["mid_purchase_scale"].append(float(micro_t["mid_purchase_scale"]))
        extras["entrant_owner_scale"].append(float(micro_t["entrant_owner_scale"]))
        extras["theta"].append(float(theta_t))
        extras["permits"].append(float(arrays["permits"][t + 1]))
        extras["starts"].append(float(arrays["starts"][t + 1]))
        extras["completions"].append(float(arrays["completions"][t + 1]))
        extras["stock"].append(float(arrays["stock"][t + 1]))
        extras["young_mortgage"].append(float(metrics_next["young_mortgage_25_34"]))

    return q_implied, extras


def solve_full_path_with_structural_fertility(
    summary: pd.DataFrame,
    scenario,
    params,
    horizon: int,
    operator: StructuralFertilityOperator,
    absolute_price_anchor: float,
    timing_shift_gain: float,
    first_birth_gain: float,
    childless_entry_gain: float,
    q_init: np.ndarray | None = None,
) -> tuple[np.ndarray, dict[str, list[float]]]:
    q_guess = np.array(q_init, copy=True) if q_init is not None else np.ones(horizon, dtype=float)

    for _ in range(600):
        q_implied, extras = full_path_implied_with_structural_fertility(
            summary,
            scenario,
            params,
            q_guess,
            operator,
            absolute_price_anchor,
            timing_shift_gain,
            first_birth_gain,
            childless_entry_gain,
        )
        q_new = 0.65 * q_guess + 0.35 * q_implied
        if np.max(np.abs(q_new - q_guess)) < 1.0e-10:
            q_guess = q_new
            q_implied, extras = full_path_implied_with_structural_fertility(
                summary,
                scenario,
                params,
                q_guess,
                operator,
                absolute_price_anchor,
                timing_shift_gain,
                first_birth_gain,
                childless_entry_gain,
            )
            break
        q_guess = q_new

    return q_implied, extras


def simulate_stationary_re_path_with_structural_fertility(
    summary: pd.DataFrame,
    scenario,
    params,
    q_path: np.ndarray,
    operator: StructuralFertilityOperator,
    absolute_price_anchor: float,
    timing_shift_gain: float,
    first_birth_gain: float,
    childless_entry_gain: float,
) -> pd.DataFrame:
    horizon = len(q_path)
    pop, arrays, refs = initial_state(summary, params, horizon)
    anchor_eval = operator.evaluate(absolute_price_anchor)
    anchor_birth_rate = max(anchor_eval["avg_birth_rate"], 1.0e-6)
    records: list[dict[str, float | int | str]] = []

    for t in range(horizon + 1):
        q_current = float(arrays["q"][t])
        absolute_price_t = absolute_price_anchor * max(q_current, 1.0e-6)
        fertility_t = operator.evaluate(absolute_price_t)
        birth_multiplier_t = max(fertility_t["avg_birth_rate"] / anchor_birth_rate, 0.10)
        micro_t = structural_micro_adjustments(
            fertility_t,
            anchor_eval,
            timing_shift_gain,
            first_birth_gain,
            childless_entry_gain,
        )

        metrics = extract_metrics(pop)
        theta_t = theta_from_metrics(metrics, params)
        demand_t = demand_index(metrics, refs, scenario.price_ratio, t, params) * birth_multiplier_t

        records.append(
            {
                "scenario": f"{scenario.name}_structural_fertility_T{horizon}_full_re_stationary",
                "t": t,
                "q": q_current,
                "absolute_price": float(absolute_price_t),
                "avg_birth_rate": float(fertility_t["avg_birth_rate"]),
                "avg_first_birth_rate": float(fertility_t["avg_first_birth_rate"]),
                "mean_age_first_birth": float(fertility_t["mean_age_first_birth"]),
                "share_first_birth_30_plus": float(fertility_t["share_first_birth_30_plus"]),
                "childless_share_at_50": float(fertility_t["childless_share_at_50"]),
                "birth_multiplier": float(birth_multiplier_t),
                "first_birth_gap": float(micro_t["first_birth_gap"]),
                "delay_pressure": float(micro_t["delay_pressure"]),
                "childless_gap": float(micro_t["childless_gap"]),
                "young_purchase_scale": float(micro_t["young_purchase_scale"]),
                "mid_purchase_scale": float(micro_t["mid_purchase_scale"]),
                "entrant_owner_scale": float(micro_t["entrant_owner_scale"]),
                "theta": float(theta_t),
                "permits": float(arrays["permits"][t]),
                "starts": float(arrays["starts"][t]),
                "completions": float(arrays["completions"][t]),
                "stock": float(arrays["stock"][t]),
                "young_owner_25_34": metrics["young_owner_25_34"],
                "young_mortgaged_owner_25_34": metrics["young_mortgage_25_34"],
                "owner_35_44": metrics["owner_35_44"],
                "demand_index_with_structural_fertility": float(demand_t),
            }
        )

        if t == horizon:
            break

        q_effective = float(q_path[t])
        absolute_price_transition = absolute_price_anchor * max(q_effective, 1.0e-6)
        fertility_transition = operator.evaluate(absolute_price_transition)
        birth_multiplier_transition = max(
            fertility_transition["avg_birth_rate"] / anchor_birth_rate,
            0.10,
        )
        micro_transition = structural_micro_adjustments(
            fertility_transition,
            anchor_eval,
            timing_shift_gain,
            first_birth_gain,
            childless_entry_gain,
        )
        arrays["permits"][t + 1] = permit_update(arrays["permits"][t], theta_t, demand_t, arrays["stock"][t], q_effective, params)
        update_construction(arrays, t, params)
        pop = update_population_with_structural_fertility(
            summary,
            pop,
            scenario,
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
    for scenario_name, frame in paths.groupby("scenario"):
        frame = frame.set_index("t")
        rows.append(
            {
                "scenario": scenario_name.replace(f"_structural_fertility_T{horizon}_full_re_stationary", ""),
                "q1": float(frame.loc[1, "q"]),
                "q5": float(frame.loc[5, "q"]) if 5 in frame.index else np.nan,
                "q10": float(frame.loc[10, "q"]) if 10 in frame.index else np.nan,
                "q20": float(frame.loc[20, "q"]) if 20 in frame.index else np.nan,
                "q40": float(frame.loc[40, "q"]) if 40 in frame.index else np.nan,
                "q80": float(frame.loc[80, "q"]) if 80 in frame.index else np.nan,
                "birth_multiplier5": float(frame.loc[5, "birth_multiplier"]) if 5 in frame.index else np.nan,
                "birth_multiplier20": float(frame.loc[20, "birth_multiplier"]) if 20 in frame.index else np.nan,
                "birth_multiplier40": float(frame.loc[40, "birth_multiplier"]) if 40 in frame.index else np.nan,
                "birth_multiplier80": float(frame.loc[80, "birth_multiplier"]) if 80 in frame.index else np.nan,
            }
        )
    return pd.DataFrame(rows)


def build_comparison_table(
    structural_paths: pd.DataFrame,
    no_structural_paths: pd.DataFrame,
    checkpoints: list[int],
    horizon: int,
) -> pd.DataFrame:
    no_structural_map = no_structural_paths.set_index(["scenario", "t"])
    suffix = f"_structural_fertility_T{horizon}_full_re_stationary"
    rows: list[dict[str, float | int | str]] = []

    for _, row in structural_paths.loc[structural_paths["t"].isin(checkpoints)].iterrows():
        base_name = str(row["scenario"]).replace(suffix, "")
        no_structural = no_structural_map.loc[(f"{base_name}_T{horizon}_full_re_stationary", int(row["t"]))]
        rows.append(
            {
                "scenario": row["scenario"],
                "t": int(row["t"]),
                "absolute_price": float(row["absolute_price"]),
                "avg_birth_rate": float(row["avg_birth_rate"]),
                "mean_age_first_birth": float(row["mean_age_first_birth"]),
                "share_first_birth_30_plus": float(row["share_first_birth_30_plus"]),
                "birth_multiplier": float(row["birth_multiplier"]),
                "young_purchase_scale": float(row["young_purchase_scale"]),
                "mid_purchase_scale": float(row["mid_purchase_scale"]),
                "entrant_owner_scale": float(row["entrant_owner_scale"]),
                "q": float(row["q"]),
                "q_gap_vs_no_structural_re": float(row["q"] - no_structural["q"]),
                "young_mortgaged_owner_25_34": float(row["young_mortgaged_owner_25_34"]),
                "young_mortgage_gap_vs_no_structural_re": float(
                    row["young_mortgaged_owner_25_34"] - no_structural["young_mortgaged_owner_25_34"]
                ),
            }
        )
    return pd.DataFrame(rows)


def write_note(
    path: Path,
    operator: StructuralFertilityOperator,
    stationary: pd.DataFrame,
    fixed_points: pd.DataFrame,
    comparison: pd.DataFrame,
    horizon: int,
    timing_shift_gain: float,
    first_birth_gain: float,
    childless_entry_gain: float,
) -> None:
    lines = [
        f"# Annual full RE with structural fertility operator (T={horizon})",
        "",
        "This note replaces the reduced-form fertility state with the annual structural fertility operator from the ownership / balance-sheet screen.",
        "",
        f"Operator source: candidate `{operator.candidate_id}` from `fertility_annual_ownership_balance_sheet_screen_*`.",
        "",
        "Mapping used inside the stationary annual RE solve:",
        "",
        "- each scenario uses its stationary annual `q_ss` as the absolute-price anchor",
        "- structural price is `a_price_t = q_ss * q_t`",
        "- structural annual demand multiplier is `avg_birth_rate(a_price_t) / avg_birth_rate(q_ss)`",
        "- entrant cohort mass is scaled by the same ratio, so fertility changes future young-cohort mass directly",
        "- first-birth timing moments scale `25-34` versus `35-44` purchase transitions inside the annual population law",
        "- childlessness and timing moments tilt the entrant tenure mix toward renters or owners",
        "",
        "Micro-channel gains:",
        "",
        f"- first-birth gain: `{first_birth_gain:.2f}`",
        f"- timing-shift gain: `{timing_shift_gain:.2f}`",
        f"- childless-entry gain: `{childless_entry_gain:.2f}`",
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
            "## Structural-fertility full-RE path excerpts",
            "",
            "| Scenario | q1 | q5 | q10 | q20 | q40 | q80 | Birth mult t20 | Birth mult t40 | Birth mult t80 |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for row in fixed_points.itertuples(index=False):
        q80 = f"{row.q80:.3f}" if not pd.isna(row.q80) else "nan"
        b80 = f"{row.birth_multiplier80:.3f}" if not pd.isna(row.birth_multiplier80) else "nan"
        lines.append(
            f"| `{row.scenario}` | `{row.q1:.3f}` | `{row.q5:.3f}` | `{row.q10:.3f}` | `{row.q20:.3f}` | "
            f"`{row.q40:.3f}` | `{q80}` | `{row.birth_multiplier20:.3f}` | `{row.birth_multiplier40:.3f}` | `{b80}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints relative to no-structural full RE",
            "",
            "| Scenario | t | Structural a_price | Avg birth rate | Mean age first birth | Share first births 30+ | Birth multiplier | Young purchase scale | Mid purchase scale | Entrant owner scale | q | q gap vs no-structural RE | Young mortgaged-owner 25-34 | Young mortgage gap vs no-structural RE |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for row in comparison.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {row.t} | `{row.absolute_price:.3f}` | `{row.avg_birth_rate:.3f}` | "
            f"`{row.mean_age_first_birth:.2f}` | `{row.share_first_birth_30_plus:.3f}` | `{row.birth_multiplier:.3f}` | "
            f"`{row.young_purchase_scale:.3f}` | `{row.mid_purchase_scale:.3f}` | `{row.entrant_owner_scale:.3f}` | "
            f"`{row.q:.3f}` | `{row.q_gap_vs_no_structural_re:.3f}` | `{row.young_mortgaged_owner_25_34:.3f}` | "
            f"`{row.young_mortgage_gap_vs_no_structural_re:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is the first annual full-RE transition that uses a structural fertility operator instead of an ad hoc fertility state law.",
            "- The operator now enters through birth-implied demand, age-specific purchase timing, and entrant-composition margins rather than only through an aggregate fertility multiplier.",
            "- The annual branch still does not carry explicit parity or children-at-home states in Python, so this remains a structural operator bridge rather than a literal household-state recursion.",
            "- If this object moves prices materially relative to the no-structural RE path, then the annual branch has finally crossed from reduced-form fertility RE into a genuinely structural-fertility-implied RE experiment.",
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
    timing_shift_gain = float(args.timing_shift_gain)
    first_birth_gain = float(args.first_birth_gain)
    childless_entry_gain = float(args.childless_entry_gain)

    no_structural_frames: list[pd.DataFrame] = []
    structural_frames: list[pd.DataFrame] = []

    for scenario in scenarios:
        q_path_no_structural, _, _ = solve_full_path(summary, scenario, params, horizon)
        no_structural_frames.append(simulate_stationary_re_path(summary, scenario, params, q_path_no_structural))

        price_anchor = float(stationary_map.loc[scenario.name, "q_ss"])
        q_path_structural, _ = solve_full_path_with_structural_fertility(
            summary,
            scenario,
            params,
            horizon,
            operator,
            price_anchor,
            timing_shift_gain,
            first_birth_gain,
            childless_entry_gain,
            q_init=q_path_no_structural,
        )
        structural_frames.append(
            simulate_stationary_re_path_with_structural_fertility(
                summary,
                scenario,
                params,
                q_path_structural,
                operator,
                price_anchor,
                timing_shift_gain,
                first_birth_gain,
                childless_entry_gain,
            )
        )

    no_structural_paths = pd.concat(no_structural_frames, ignore_index=True)
    structural_paths = pd.concat(structural_frames, ignore_index=True)
    fixed_points = build_fixed_point_table(structural_paths, horizon)
    comparison = build_comparison_table(structural_paths, no_structural_paths, checkpoints, horizon)

    stem = f"annual_full_re_stationary_transition_structural_fertility_T{horizon}"
    structural_paths.to_csv(BUILD / f"{stem}.csv", index=False)
    no_structural_paths.to_csv(BUILD / f"{stem}_no_structural_paths.csv", index=False)
    fixed_points.to_csv(BUILD / f"{stem}_fixed_points.csv", index=False)
    comparison.to_csv(BUILD / f"{stem}_checkpoints.csv", index=False)
    write_note(
        BUILD / f"{stem}.md",
        operator,
        stationary,
        fixed_points,
        comparison,
        horizon,
        timing_shift_gain,
        first_birth_gain,
        childless_entry_gain,
    )


if __name__ == "__main__":
    main()
