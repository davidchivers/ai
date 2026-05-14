from __future__ import annotations

from dataclasses import dataclass
from math import exp, log
from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import (
    INPUT_SUMMARY,
    STATE_ORDER,
    Scenario,
    adjust_matrix,
    build_base_transition_matrices,
    load_initial_cross_section,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

OUTPUT_STEM = "annual_one_step_re_transition"
TERMINAL_DRIFT = 1.05
RE_WEIGHT = 0.25
T = 21
CHECKPOINTS = (0, 1, 2, 5, 20)


@dataclass(frozen=True)
class REScenario:
    name: str
    deposit_help_weight: float
    qualification_weight: float
    targeted_support: bool = True
    support_center: float = 0.18
    support_width: float = 0.04
    mid_age_scale: float = 0.80


def one_step_transition(
    summary: pd.DataFrame,
    price_ratio: float,
    deposit_help_weight: float,
    qualification_weight: float,
    targeted_support: bool,
    support_center: float,
    support_width: float,
    mid_age_scale: float,
) -> pd.DataFrame:
    base_matrices = build_base_transition_matrices()
    age_blocks = list(summary["age_block"])
    widths = (summary["age_hi"] - summary["age_lo"] + 1).to_numpy(dtype=float)
    block_masses = summary["block_mass"].to_numpy(dtype=float)
    pop = summary.loc[:, STATE_ORDER].to_numpy(dtype=float) * block_masses[:, None]
    entrant_mix = summary.loc[summary["age_block"] == "25-34", STATE_ORDER].iloc[0].to_numpy(dtype=float)

    post = np.zeros_like(pop)
    for i, age_block in enumerate(age_blocks):
        matrix = adjust_matrix(
            base_matrices[age_block],
            age_block=age_block,
            price_ratio=price_ratio,
            deposit_help_weight=deposit_help_weight,
            qualification_weight=qualification_weight,
            deposit_help_horizon=0,
            qualification_horizon=0,
            targeted_support=targeted_support,
            support_center=support_center,
            support_width=support_width,
            mid_age_scale=mid_age_scale,
            t=0,
        )
        post[i, :] = pop[i, :] @ matrix

    new_pop = np.zeros_like(pop)
    outflows = np.zeros_like(pop)
    for i in range(len(age_blocks)):
        outflows[i, :] = post[i, :] / widths[i]
        new_pop[i, :] += post[i, :] - outflows[i, :]

    for i in range(1, len(age_blocks)):
        new_pop[i, :] += outflows[i - 1, :]

    entrant_mass = float(outflows[-1, :].sum())
    new_pop[0, :] += entrant_mass * entrant_mix

    return pd.DataFrame(new_pop, columns=STATE_ORDER).assign(age_block=age_blocks, block_mass=block_masses)


def housing_pressure_index(next_pop: pd.DataFrame) -> float:
    row_25 = next_pop.loc[next_pop["age_block"] == "25-34"].iloc[0]
    row_35 = next_pop.loc[next_pop["age_block"] == "35-44"].iloc[0]
    young_mortgaged = float(row_25["owner_with_mortgage"] / row_25["block_mass"])
    young_renter_debt = float(row_25["renter_with_debt"] / row_25["block_mass"])
    owner_35_44 = float((row_35["owner_with_mortgage"] + row_35["owner_outright"]) / row_35["block_mass"])
    return young_mortgaged + young_renter_debt + 0.5 * (1.0 - owner_35_44)


def annual_checkpoint_table(frame: pd.DataFrame, scenario: str, q1: float) -> pd.DataFrame:
    sub = frame.loc[frame["t"].isin(CHECKPOINTS)].copy()
    sub.insert(0, "scenario", scenario)
    sub.insert(1, "q1_re", q1)
    return sub[
        [
            "scenario",
            "q1_re",
            "t",
            "price_ratio",
            "young_owner_share_25_34",
            "young_mortgaged_owner_share_25_34",
            "young_renter_with_debt_share_25_34",
            "young_crunch_share_25_34",
            "owner_share_35_44",
            "mortgaged_owner_share_35_44",
            "aggregate_owner_share",
            "aggregate_mortgaged_owner_share",
        ]
    ]


def simulate_custom_path(summary: pd.DataFrame, scenario: Scenario, first_step_price_ratio: float, terminal_price_ratio: float, T: int) -> pd.DataFrame:
    base_matrices = build_base_transition_matrices()
    age_blocks = list(summary["age_block"])
    widths = (summary["age_hi"] - summary["age_lo"] + 1).to_numpy(dtype=float)
    block_masses = summary["block_mass"].to_numpy(dtype=float)
    pop = summary.loc[:, STATE_ORDER].to_numpy(dtype=float) * block_masses[:, None]
    entrant_mix = summary.loc[summary["age_block"] == "25-34", STATE_ORDER].iloc[0].to_numpy(dtype=float)

    records: list[dict[str, float | str | int]] = []
    for t in range(T):
        total = float(pop.sum())
        young_idx = 0
        mid_idx = 1
        records.append(
            {
                "t": t,
                "price_ratio": (1.0 if t == 0 else (first_step_price_ratio if t == 1 else terminal_price_ratio)),
                "young_owner_share_25_34": float((pop[young_idx, 2] + pop[young_idx, 3]) / block_masses[young_idx]),
                "young_mortgaged_owner_share_25_34": float(pop[young_idx, 2] / block_masses[young_idx]),
                "young_renter_with_debt_share_25_34": float(pop[young_idx, 1] / block_masses[young_idx]),
                "young_crunch_share_25_34": float((pop[young_idx, 1] + pop[young_idx, 2]) / block_masses[young_idx]),
                "owner_share_35_44": float((pop[mid_idx, 2] + pop[mid_idx, 3]) / block_masses[mid_idx]),
                "mortgaged_owner_share_35_44": float(pop[mid_idx, 2] / block_masses[mid_idx]),
                "aggregate_owner_share": float((pop[:, 2] + pop[:, 3]).sum() / total),
                "aggregate_mortgaged_owner_share": float(pop[:, 2].sum() / total),
            }
        )

        post = np.zeros_like(pop)
        for i, age_block in enumerate(age_blocks):
            transition_price = first_step_price_ratio if t == 0 else terminal_price_ratio
            matrix = adjust_matrix(
                base_matrices[age_block],
                age_block=age_block,
                price_ratio=transition_price,
                deposit_help_weight=scenario.deposit_help_weight,
                qualification_weight=scenario.qualification_weight,
                deposit_help_horizon=0,
                qualification_horizon=0,
                targeted_support=scenario.targeted_support,
                support_center=scenario.support_center,
                support_width=scenario.support_width,
                mid_age_scale=scenario.mid_age_scale,
                t=t,
            )
            post[i, :] = pop[i, :] @ matrix

        new_pop = np.zeros_like(pop)
        outflows = np.zeros_like(pop)
        for i in range(len(age_blocks)):
            outflows[i, :] = post[i, :] / widths[i]
            new_pop[i, :] += post[i, :] - outflows[i, :]
        for i in range(1, len(age_blocks)):
            new_pop[i, :] += outflows[i - 1, :]

        entrant_mass = float(outflows[-1, :].sum())
        new_pop[0, :] += entrant_mass * entrant_mix
        pop = new_pop

    return pd.DataFrame.from_records(records)


def solve_one_step_re(
    summary: pd.DataFrame,
    re_scenario: REScenario,
    terminal_price_ratio: float,
    slope: float,
    pressure_anchor: float,
    re_weight: float,
) -> tuple[float, float]:
    q = terminal_price_ratio
    for _ in range(200):
        next_pop = one_step_transition(
            summary,
            price_ratio=q,
            deposit_help_weight=re_scenario.deposit_help_weight,
            qualification_weight=re_scenario.qualification_weight,
            targeted_support=re_scenario.targeted_support,
            support_center=re_scenario.support_center,
            support_width=re_scenario.support_width,
            mid_age_scale=re_scenario.mid_age_scale,
        )
        pressure = housing_pressure_index(next_pop)
        implied_q = exp(log(terminal_price_ratio) + re_weight * slope * (pressure - pressure_anchor))
        updated_q = 0.5 * q + 0.5 * implied_q
        if abs(updated_q - q) < 1.0e-10:
            q = updated_q
            break
        q = updated_q
    next_pop = one_step_transition(
        summary,
        price_ratio=q,
        deposit_help_weight=re_scenario.deposit_help_weight,
        qualification_weight=re_scenario.qualification_weight,
        targeted_support=re_scenario.targeted_support,
        support_center=re_scenario.support_center,
        support_width=re_scenario.support_width,
        mid_age_scale=re_scenario.mid_age_scale,
    )
    return q, housing_pressure_index(next_pop)


def main() -> None:
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")

    summary = load_initial_cross_section(INPUT_SUMMARY)

    pressure_no_shock = housing_pressure_index(
        one_step_transition(
            summary,
            price_ratio=1.0,
            deposit_help_weight=0.0,
            qualification_weight=0.0,
            targeted_support=True,
            support_center=0.18,
            support_width=0.04,
            mid_age_scale=0.80,
        )
    )
    pressure_anchor = housing_pressure_index(
        one_step_transition(
            summary,
            price_ratio=TERMINAL_DRIFT,
            deposit_help_weight=0.0,
            qualification_weight=0.0,
            targeted_support=True,
            support_center=0.18,
            support_width=0.04,
            mid_age_scale=0.80,
        )
    )
    slope = log(TERMINAL_DRIFT) / (pressure_anchor - pressure_no_shock)

    re_cases = [
        REScenario("baseline_one_step_re", 0.0, 0.0),
        REScenario("benchmark_one_step_re", 0.15, 0.25),
        REScenario("robustness_one_step_re", 0.30, 0.40),
    ]

    path_frames: list[pd.DataFrame] = []
    fixed_point_rows: list[dict[str, float | str]] = []
    base_path = simulate_custom_path(
        summary,
        Scenario("drift_baseline_anchor", TERMINAL_DRIFT, 0.0, 0.0, 0, 0, True, support_center=0.18, support_width=0.04, mid_age_scale=0.80),
        first_step_price_ratio=TERMINAL_DRIFT,
        terminal_price_ratio=TERMINAL_DRIFT,
        T=T,
    )
    base_check = annual_checkpoint_table(base_path, "drift_anchor", TERMINAL_DRIFT)
    path_frames.append(base_check)

    for case in re_cases:
        q1, pressure = solve_one_step_re(
            summary,
            case,
            terminal_price_ratio=TERMINAL_DRIFT,
            slope=slope,
            pressure_anchor=pressure_anchor,
            re_weight=RE_WEIGHT,
        )
        fixed_point_rows.append(
            {
                "scenario": case.name,
                "q1_re": q1,
                "pressure_index": pressure,
            }
        )
        path = simulate_custom_path(
            summary,
            Scenario(
                case.name,
                TERMINAL_DRIFT,
                case.deposit_help_weight,
                case.qualification_weight,
                0,
                0,
                case.targeted_support,
                support_center=case.support_center,
                support_width=case.support_width,
                mid_age_scale=case.mid_age_scale,
            ),
            first_step_price_ratio=q1,
            terminal_price_ratio=TERMINAL_DRIFT,
            T=T,
        )
        path_frames.append(annual_checkpoint_table(path, case.name, q1))

    paths = pd.concat(path_frames, ignore_index=True)
    base = paths.loc[paths["scenario"] == "drift_anchor"].set_index("t")
    paths["young_owner_gap_vs_drift_anchor"] = paths.apply(
        lambda r: float(r["young_owner_share_25_34"] - base.loc[int(r["t"]), "young_owner_share_25_34"]),
        axis=1,
    )
    paths["young_mortgage_gap_vs_drift_anchor"] = paths.apply(
        lambda r: float(r["young_mortgaged_owner_share_25_34"] - base.loc[int(r["t"]), "young_mortgaged_owner_share_25_34"]),
        axis=1,
    )

    fixed_points = pd.DataFrame.from_records(fixed_point_rows)
    fixed_points.to_csv(BUILD / f"{OUTPUT_STEM}_fixed_points.csv", index=False)
    paths.to_csv(BUILD / f"{OUTPUT_STEM}.csv", index=False)

    lines = [
        "# Annual one-step RE transition",
        "",
        "This note implements the first bounded RE pass on the annual transition object.",
        "The object solved here is not full rational expectations over the entire annual path. It is one-step-ahead RE with a terminal drift rule.",
        "",
        "## Setup",
        "",
        "- time-zero object: observed annual age-by-state snapshot",
        "- terminal rule after `t = 1`: revert to permanent `+5%` annual drift",
        "- RE object: solve only for the next-period price ratio `q_1 / q_0`",
        "- scenarios:",
        "  - `baseline_one_step_re`",
        "  - `benchmark_one_step_re`: qualification `0.25`, family help `0.15`",
        "  - `robustness_one_step_re`: qualification `0.40`, family help `0.30`",
        "",
        "## Reduced-form price fixed point",
        "",
        "- pressure index used for the one-step fixed point:",
        "  - young mortgaged-owner share `25-34`",
        "  - plus young renter-with-debt share `25-34`",
        "  - plus `0.5 * (1 - owner share 35-44)`",
        "- calibration anchor:",
        f"  - no-shock baseline pressure: `{pressure_no_shock:.3f}`",
        f"  - drift-anchor baseline pressure: `{pressure_anchor:.3f}`",
        f"  - terminal drift ratio: `{TERMINAL_DRIFT:.3f}`",
        f"  - one-step RE weight: `{RE_WEIGHT:.2f}`",
        "",
        "## Solved next-period prices",
        "",
        "| Scenario | Solved q1/q0 | Pressure index |",
        "|---|---:|---:|",
    ]
    for row in fixed_points.itertuples(index=False):
        lines.append(f"| `{row.scenario}` | `{row.q1_re:.3f}` | `{row.pressure_index:.3f}` |")

    lines.extend(
        [
            "",
            "## Checkpoints",
            "",
            "| Scenario | t | Price ratio | Young owner 25-34 | Young mortgaged-owner 25-34 | Owner 35-44 | Young owner gap vs drift-anchor | Young mortgage gap vs drift-anchor |",
            "|---|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for row in paths.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | {int(row.t)} | `{row.price_ratio:.3f}` | `{row.young_owner_share_25_34:.3f}` | "
            f"`{row.young_mortgaged_owner_share_25_34:.3f}` | `{row.owner_share_35_44:.3f}` | "
            f"`{row.young_owner_gap_vs_drift_anchor:.3f}` | `{row.young_mortgage_gap_vs_drift_anchor:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- The bounded RE layer is feasible on the annual transition object.",
            "- In this reduced-form implementation, the support regimes lower the solved next-period price relative to the pure drift anchor because they ease the young housing-pressure index immediately.",
            "- That means one-step RE acts as a partial offset to the support regimes rather than an amplifier.",
            "- The annual benchmark and robustness cases still improve young mortgaged ownership relative to the drift-anchor path, but less than they do under purely exogenous next-period drift.",
            "- This is exactly why the next bounded RE branch should stay small: one-step first, then perhaps two-step, before any full path fixed point.",
        ]
    )

    (BUILD / f"{OUTPUT_STEM}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
