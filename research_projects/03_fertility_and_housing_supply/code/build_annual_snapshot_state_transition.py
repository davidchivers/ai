from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
INPUT_SUMMARY = BUILD / "fertility_annual_transition_path_state_grid_mapping_summary.csv"

STATE_ORDER = (
    "renter_no_debt",
    "renter_with_debt",
    "owner_with_mortgage",
    "owner_outright",
)

CHECKPOINTS = [0, 1, 2, 5, 10, 20, 40, 79]


@dataclass(frozen=True)
class Scenario:
    name: str
    price_ratio: float
    deposit_help_weight: float
    qualification_weight: float
    deposit_help_horizon: int
    qualification_horizon: int
    targeted_support: bool
    support_center: float = 0.16
    support_width: float = 0.03
    mid_age_scale: float = 1.0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build the first snapshot-forward annual transition sandbox."
    )
    parser.add_argument(
        "--output-stem",
        default="annual_snapshot_state_transition",
        help="Output filename stem in notes/build/.",
    )
    parser.add_argument(
        "--T",
        type=int,
        default=80,
        help="Number of annual periods.",
    )
    parser.add_argument(
        "--pack",
        default="default",
        choices=("default", "qualification", "hybrid", "persistent", "targeted_persistent"),
        help="Scenario pack to run.",
    )
    return parser.parse_args()


def load_initial_cross_section(path: Path) -> pd.DataFrame:
    summary = pd.read_csv(path)
    expected = {
        "age_block",
        "age_lo",
        "age_hi",
        "block_mass",
        "renter_no_debt",
        "renter_with_debt",
        "owner_with_mortgage",
        "owner_outright",
    }
    missing = expected.difference(summary.columns)
    if missing:
        raise ValueError(f"Missing required columns in {path}: {sorted(missing)}")
    return summary


def build_base_transition_matrices() -> dict[str, np.ndarray]:
    return {
        "25-34": np.array(
            [
                [0.84, 0.07, 0.08, 0.01],
                [0.05, 0.78, 0.15, 0.02],
                [0.01, 0.03, 0.87, 0.09],
                [0.00, 0.00, 0.01, 0.99],
            ],
            dtype=float,
        ),
        "35-44": np.array(
            [
                [0.86, 0.04, 0.08, 0.02],
                [0.05, 0.77, 0.14, 0.04],
                [0.01, 0.02, 0.80, 0.17],
                [0.00, 0.00, 0.01, 0.99],
            ],
            dtype=float,
        ),
        "45-54": np.array(
            [
                [0.89, 0.03, 0.06, 0.02],
                [0.05, 0.81, 0.10, 0.04],
                [0.01, 0.01, 0.72, 0.26],
                [0.00, 0.00, 0.005, 0.995],
            ],
            dtype=float,
        ),
        "55-64": np.array(
            [
                [0.91, 0.02, 0.04, 0.03],
                [0.05, 0.84, 0.07, 0.04],
                [0.01, 0.01, 0.64, 0.34],
                [0.00, 0.00, 0.003, 0.997],
            ],
            dtype=float,
        ),
        "65-80": np.array(
            [
                [0.93, 0.02, 0.02, 0.03],
                [0.04, 0.86, 0.05, 0.05],
                [0.00, 0.01, 0.58, 0.41],
                [0.00, 0.00, 0.002, 0.998],
            ],
            dtype=float,
        ),
    }


def price_penalty_by_block() -> dict[str, float]:
    return {
        "25-34": 2.5,
        "35-44": 1.8,
        "45-54": 1.0,
        "55-64": 0.5,
        "65-80": 0.2,
    }


def deposit_age_weight(age_block: str, mid_age_scale: float = 1.0) -> float:
    return {
        "25-34": 1.0,
        "35-44": 0.6 * mid_age_scale,
        "45-54": 0.15,
        "55-64": 0.0,
        "65-80": 0.0,
    }[age_block]


def deposit_time_scale(t: int, horizon: int) -> float:
    if horizon <= 0:
        return 1.0
    if t < 0 or t >= horizon:
        return 0.0
    return float((horizon - t) / horizon)


def qualification_age_weight(age_block: str, mid_age_scale: float = 1.0) -> float:
    return {
        "25-34": 1.0,
        "35-44": 0.7 * mid_age_scale,
        "45-54": 0.15,
        "55-64": 0.0,
        "65-80": 0.0,
    }[age_block]


def qualification_time_scale(t: int, horizon: int) -> float:
    if horizon <= 0:
        return 1.0
    if t < 0 or t >= horizon:
        return 0.0
    return float((horizon - t) / horizon)


def near_threshold_weight(original_purchase: float, center: float = 0.16, width: float = 0.03) -> float:
    if width <= 0:
        return 1.0
    z = (original_purchase - center) / width
    return float(np.exp(-0.5 * z * z))


def adjust_matrix(
    base_matrix: np.ndarray,
    age_block: str,
    price_ratio: float,
    deposit_help_weight: float,
    qualification_weight: float,
    deposit_help_horizon: int,
    qualification_horizon: int,
    targeted_support: bool,
    support_center: float,
    support_width: float,
    mid_age_scale: float,
    t: int,
) -> np.ndarray:
    matrix = np.array(base_matrix, copy=True)

    log_gap = float(np.log(price_ratio))
    penalty_scale = max(0.25, 1.0 - price_penalty_by_block()[age_block] * log_gap)

    for row_idx in (0, 1):
        original_purchase = float(matrix[row_idx, 2] + matrix[row_idx, 3])
        if original_purchase <= 0.0:
            continue

        support_weight = near_threshold_weight(original_purchase, support_center, support_width) if targeted_support else 1.0
        boost_scale = 1.0 + 0.6 * deposit_help_weight * deposit_time_scale(t, deposit_help_horizon) * deposit_age_weight(age_block, mid_age_scale) * support_weight
        purchase_scale = penalty_scale * boost_scale
        target_purchase = np.clip(original_purchase * purchase_scale, 0.0, 0.95)
        if original_purchase > 0.0:
            matrix[row_idx, 2] *= target_purchase / original_purchase
            matrix[row_idx, 3] *= target_purchase / original_purchase

        qual_strength = qualification_weight * qualification_time_scale(t, qualification_horizon) * qualification_age_weight(age_block, mid_age_scale) * support_weight
        if qual_strength > 0.0:
            row_strength = qual_strength * (1.0 if row_idx == 1 else 0.5)
            stay_idx = row_idx
            shift_from_outright = min(matrix[row_idx, 3] * 0.6 * row_strength, matrix[row_idx, 3])
            extra_from_stay = min(matrix[row_idx, stay_idx] * 0.2 * row_strength, matrix[row_idx, stay_idx])
            matrix[row_idx, 2] += shift_from_outright + extra_from_stay
            matrix[row_idx, 3] -= shift_from_outright
            matrix[row_idx, stay_idx] -= extra_from_stay

        row_other = matrix[row_idx, [1 - row_idx, 1 if row_idx == 0 else 0]].sum()
        stay_prob = 1.0 - row_other - matrix[row_idx, 2] - matrix[row_idx, 3]
        matrix[row_idx, row_idx] = max(stay_prob, 1.0e-9)
        matrix[row_idx, :] = matrix[row_idx, :] / matrix[row_idx, :].sum()

    return matrix


def simulate_scenario(
    summary: pd.DataFrame,
    scenario: Scenario,
    T: int,
) -> pd.DataFrame:
    base_matrices = build_base_transition_matrices()
    age_blocks = list(summary["age_block"])
    widths = (summary["age_hi"] - summary["age_lo"] + 1).to_numpy(dtype=float)
    block_masses = summary["block_mass"].to_numpy(dtype=float)

    pop = summary.loc[:, STATE_ORDER].to_numpy(dtype=float) * block_masses[:, None]
    entrant_mix = summary.loc[summary["age_block"] == "25-34", STATE_ORDER].iloc[0].to_numpy(dtype=float)

    records: list[dict[str, float | str | int]] = []
    for t in range(T):
        total = float(pop.sum())
        if total <= 0.0:
            raise ValueError("Population mass vanished during snapshot transition simulation.")

        young_idx = 0
        mid_idx = 1
        old_idx = 4
        records.append(
            {
                "scenario": scenario.name,
                "t": t,
                "price_ratio": 1.0 if t == 0 else scenario.price_ratio,
                "deposit_help_weight": scenario.deposit_help_weight,
                "qualification_weight": scenario.qualification_weight,
                "deposit_help_horizon": scenario.deposit_help_horizon,
                "qualification_horizon": scenario.qualification_horizon,
                "targeted_support": int(scenario.targeted_support),
                "support_center": scenario.support_center,
                "support_width": scenario.support_width,
                "mid_age_scale": scenario.mid_age_scale,
                "young_owner_share_25_34": float((pop[young_idx, 2] + pop[young_idx, 3]) / block_masses[young_idx]),
                "young_mortgaged_owner_share_25_34": float(pop[young_idx, 2] / block_masses[young_idx]),
                "young_renter_with_debt_share_25_34": float(pop[young_idx, 1] / block_masses[young_idx]),
                "young_crunch_share_25_34": float((pop[young_idx, 1] + pop[young_idx, 2]) / block_masses[young_idx]),
                "owner_share_35_44": float((pop[mid_idx, 2] + pop[mid_idx, 3]) / block_masses[mid_idx]),
                "mortgaged_owner_share_35_44": float(pop[mid_idx, 2] / block_masses[mid_idx]),
                "owner_share_65_80": float((pop[old_idx, 2] + pop[old_idx, 3]) / block_masses[old_idx]),
                "aggregate_mortgaged_owner_share": float(pop[:, 2].sum() / total),
                "aggregate_owner_share": float((pop[:, 2] + pop[:, 3]).sum() / total),
            }
        )

        post = np.zeros_like(pop)
        for i, age_block in enumerate(age_blocks):
            matrix = adjust_matrix(
                base_matrices[age_block],
                age_block=age_block,
                price_ratio=(1.0 if t == 0 else scenario.price_ratio),
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


def summarize_against_baseline(frames: list[pd.DataFrame]) -> tuple[pd.DataFrame, pd.DataFrame]:
    combined = pd.concat(frames, ignore_index=True)
    baseline = combined.loc[combined["scenario"] == "baseline_snapshot"].set_index("t")

    enriched = []
    peak_rows: list[dict[str, float | int | str]] = []
    for scenario, frame in combined.groupby("scenario", sort=False):
        frame = frame.copy()
        if scenario == "baseline_snapshot":
            for col in (
                "young_owner_gap_vs_baseline",
                "young_mortgaged_owner_gap_vs_baseline",
                "young_renter_debt_gap_vs_baseline",
                "young_crunch_gap_vs_baseline",
                "owner_35_44_gap_vs_baseline",
            ):
                frame[col] = 0.0
        else:
            frame["young_owner_gap_vs_baseline"] = (
                frame["young_owner_share_25_34"].to_numpy()
                - baseline.loc[frame["t"], "young_owner_share_25_34"].to_numpy()
            )
            frame["young_mortgaged_owner_gap_vs_baseline"] = (
                frame["young_mortgaged_owner_share_25_34"].to_numpy()
                - baseline.loc[frame["t"], "young_mortgaged_owner_share_25_34"].to_numpy()
            )
            frame["young_renter_debt_gap_vs_baseline"] = (
                frame["young_renter_with_debt_share_25_34"].to_numpy()
                - baseline.loc[frame["t"], "young_renter_with_debt_share_25_34"].to_numpy()
            )
            frame["young_crunch_gap_vs_baseline"] = (
                frame["young_crunch_share_25_34"].to_numpy()
                - baseline.loc[frame["t"], "young_crunch_share_25_34"].to_numpy()
            )
            frame["owner_35_44_gap_vs_baseline"] = (
                frame["owner_share_35_44"].to_numpy()
                - baseline.loc[frame["t"], "owner_share_35_44"].to_numpy()
            )

        mort_idx = int(frame["young_mortgaged_owner_gap_vs_baseline"].idxmax())
        crunch_idx = int(frame["young_crunch_gap_vs_baseline"].idxmax())
        owner_idx = int(frame["young_owner_gap_vs_baseline"].idxmax())
        peak_rows.append(
            {
                "scenario": scenario,
                "peak_young_mortgage_gain_t": int(frame.loc[mort_idx, "t"]),
                "peak_young_mortgage_gain": float(frame.loc[mort_idx, "young_mortgaged_owner_gap_vs_baseline"]),
                "peak_young_owner_gain_t": int(frame.loc[owner_idx, "t"]),
                "peak_young_owner_gain": float(frame.loc[owner_idx, "young_owner_gap_vs_baseline"]),
                "peak_young_crunch_gap_t": int(frame.loc[crunch_idx, "t"]),
                "peak_young_crunch_gap": float(frame.loc[crunch_idx, "young_crunch_gap_vs_baseline"]),
            }
        )
        enriched.append(frame)

    enriched_df = pd.concat(enriched, ignore_index=True)
    peaks = pd.DataFrame.from_records(peak_rows)
    summary = enriched_df.loc[
        enriched_df["t"].isin(CHECKPOINTS),
        [
            "scenario",
            "t",
            "price_ratio",
            "deposit_help_weight",
            "qualification_weight",
            "deposit_help_horizon",
            "qualification_horizon",
            "targeted_support",
            "support_center",
            "support_width",
            "mid_age_scale",
            "young_owner_share_25_34",
            "young_mortgaged_owner_share_25_34",
            "young_renter_with_debt_share_25_34",
            "young_crunch_share_25_34",
            "owner_share_35_44",
            "mortgaged_owner_share_35_44",
            "aggregate_mortgaged_owner_share",
            "young_owner_gap_vs_baseline",
            "young_mortgaged_owner_gap_vs_baseline",
            "young_renter_debt_gap_vs_baseline",
            "young_crunch_gap_vs_baseline",
        ],
    ].copy()
    return summary, peaks


def write_note(note_path: Path, summary: pd.DataFrame, peaks: pd.DataFrame) -> None:
    scenarios = list(summary["scenario"].drop_duplicates())
    meta = (
        summary.groupby("scenario", as_index=False)
        .agg(
            {
                "price_ratio": "max",
                "deposit_help_weight": "max",
                "qualification_weight": "max",
                "deposit_help_horizon": "max",
                "qualification_horizon": "max",
                "targeted_support": "max",
                "support_center": "max",
                "support_width": "max",
                "mid_age_scale": "max",
            }
        )
        .set_index("scenario")
    )

    def describe(scenario: str) -> str:
        row = meta.loc[scenario]
        parts: list[str] = []
        if float(row["price_ratio"]) > 1.0 + 1.0e-12:
            parts.append(f"permanent +{(float(row['price_ratio']) - 1.0) * 100:.0f}% price path from `t = 1`")
        else:
            parts.append("fixed prices")
        if float(row["deposit_help_weight"]) > 1.0e-12:
            if int(row["deposit_help_horizon"]) <= 0:
                parts.append(f"standing deposit-help weight `{float(row['deposit_help_weight']):.2f}`")
            else:
                parts.append(
                    f"deposit-help weight `{float(row['deposit_help_weight']):.2f}` for `{int(row['deposit_help_horizon'])}` periods"
                )
        else:
            parts.append("no deposit help")
        if float(row["qualification_weight"]) > 1.0e-12:
            if int(row["qualification_horizon"]) <= 0:
                parts.append(f"standing qualification weight `{float(row['qualification_weight']):.2f}`")
            else:
                parts.append(
                    f"qualification weight `{float(row['qualification_weight']):.2f}` for `{int(row['qualification_horizon'])}` periods"
                )
        else:
            parts.append("no qualification boost")
        if int(row["targeted_support"]) > 0:
            parts.append(
                f"near-threshold first-time buyer targeting (center `{float(row['support_center']):.2f}`, width `{float(row['support_width']):.2f}`, age-35-44 scale `{float(row['mid_age_scale']):.2f}`)"
            )
        else:
            parts.append("broad young-buyer targeting")
        return "; ".join(parts)

    lines = [
        "# Annual snapshot-forward state transition",
        "",
        "This is the first snapshot-forward annual transition sandbox.",
        "It starts from the observed four-state age cross section and ages it forward with explicit state persistence.",
        "It is still reduced-form, but it no longer treats ownership and mortgage exposure as one-period proxy shifts.",
        "",
        "## Scenarios",
        "",
    ]
    for scenario in scenarios:
        lines.append(f"- `{scenario}`: {describe(scenario)}")

    lines.extend(
        [
            "",
            "## Guardrail",
            "",
            "- This is not a full household-solver transition path.",
            "- It does treat `owner_with_mortgage` as a persistent state that can age forward and amortize into `owner_outright`.",
            "- Entrants are recycled into `25-34` using the observed initial `25-34` mix rather than a steady-state stationary density.",
            "",
            "## Peak effects vs baseline",
            "",
            "| Scenario | Peak young mortgage gain t | Peak young mortgage gain | Peak young owner gain t | Peak young owner gain | Peak young crunch gap t | Peak young crunch gap |",
            "|---|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in peaks.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.peak_young_mortgage_gain_t}` | `{row.peak_young_mortgage_gain:.3f}` | "
            f"`{row.peak_young_owner_gain_t}` | `{row.peak_young_owner_gain:.3f}` | "
            f"`{row.peak_young_crunch_gap_t}` | `{row.peak_young_crunch_gap:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints",
            "",
            "| Scenario | t | Young owner 25-34 | Young mortgage-owner 25-34 | Young renter+debt 25-34 | Young crunch 25-34 | Owner 35-44 | Young mortgage gap vs baseline | Young crunch gap vs baseline |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for scenario in scenarios:
        rows = summary.loc[summary["scenario"] == scenario]
        for row in rows.itertuples(index=False):
            lines.append(
                f"| `{row.scenario}` | `{int(row.t)}` | `{row.young_owner_share_25_34:.3f}` | "
                f"`{row.young_mortgaged_owner_share_25_34:.3f}` | `{row.young_renter_with_debt_share_25_34:.3f}` | "
                f"`{row.young_crunch_share_25_34:.3f}` | `{row.owner_share_35_44:.3f}` | "
                f"`{row.young_mortgaged_owner_gap_vs_baseline:.3f}` | `{row.young_crunch_gap_vs_baseline:.3f}` |"
            )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- If deposit help still washes out quickly here, then the remaining annual gap is not just a missing persistent mortgage state.",
            "- If deposit help lasts longer here than in the older bridge, then the old bridge was understating state persistence in the family-formation years.",
        ]
    )

    note_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}. Run the transition-path state-grid mapping first.")

    summary = load_initial_cross_section(INPUT_SUMMARY)
    if args.pack == "default":
        scenarios = [
            Scenario("baseline_snapshot", 1.0, 0.0, 0.0, 0, 0, False),
            Scenario("deposit_help_snapshot_050", 1.0, 0.5, 0.0, 3, 0, False),
            Scenario("drift_snapshot_105", 1.05, 0.0, 0.0, 0, 0, False),
            Scenario("deposit_help_plus_drift_snapshot_105", 1.05, 0.5, 0.0, 3, 0, False),
        ]
    elif args.pack == "qualification":
        scenarios = [
            Scenario("baseline_snapshot", 1.0, 0.0, 0.0, 0, 0, False),
            Scenario("qualification_snapshot_025", 1.0, 0.0, 0.25, 0, 5, False),
            Scenario("drift_snapshot_105", 1.05, 0.0, 0.0, 0, 0, False),
            Scenario("qualification_plus_drift_snapshot_025", 1.05, 0.0, 0.25, 0, 5, False),
        ]
    elif args.pack == "hybrid":
        scenarios = [
            Scenario("baseline_snapshot", 1.0, 0.0, 0.0, 0, 0, False),
            Scenario("deposit_help_snapshot_050", 1.0, 0.5, 0.0, 3, 0, False),
            Scenario("qualification_snapshot_025", 1.0, 0.0, 0.25, 0, 5, False),
            Scenario("qualification_plus_deposit_snapshot_025_050", 1.0, 0.5, 0.25, 3, 5, False),
            Scenario("drift_snapshot_105", 1.05, 0.0, 0.0, 0, 0, False),
            Scenario("qualification_plus_deposit_plus_drift_snapshot_025_050", 1.05, 0.5, 0.25, 3, 5, False),
        ]
    elif args.pack == "persistent":
        scenarios = [
            Scenario("baseline_snapshot", 1.0, 0.0, 0.0, 0, 0, False),
            Scenario("persistent_deposit_help_snapshot_050", 1.0, 0.5, 0.0, 0, 0, False),
            Scenario("persistent_qualification_snapshot_025", 1.0, 0.0, 0.25, 0, 0, False),
            Scenario("persistent_qualification_plus_deposit_snapshot_025_050", 1.0, 0.5, 0.25, 0, 0, False),
            Scenario("drift_snapshot_105", 1.05, 0.0, 0.0, 0, 0, False),
            Scenario("persistent_qualification_plus_deposit_plus_drift_snapshot_025_050", 1.05, 0.5, 0.25, 0, 0, False),
        ]
    else:
        scenarios = [
            Scenario("baseline_snapshot", 1.0, 0.0, 0.0, 0, 0, False),
            Scenario("targeted_persistent_deposit_help_snapshot_050", 1.0, 0.5, 0.0, 0, 0, True),
            Scenario("targeted_persistent_qualification_snapshot_025", 1.0, 0.0, 0.25, 0, 0, True),
            Scenario("targeted_persistent_qualification_plus_deposit_snapshot_025_050", 1.0, 0.5, 0.25, 0, 0, True),
            Scenario("drift_snapshot_105", 1.05, 0.0, 0.0, 0, 0, False),
            Scenario("targeted_persistent_qualification_plus_deposit_plus_drift_snapshot_025_050", 1.05, 0.5, 0.25, 0, 0, True),
        ]

    frames = [simulate_scenario(summary, scenario=scenario, T=args.T) for scenario in scenarios]
    combined = pd.concat(frames, ignore_index=True)
    summary_df, peaks_df = summarize_against_baseline(frames)

    combined.to_csv(BUILD / f"{args.output_stem}.csv", index=False)
    summary_df.to_csv(BUILD / f"{args.output_stem}_summary.csv", index=False)
    peaks_df.to_csv(BUILD / f"{args.output_stem}_peaks.csv", index=False)
    write_note(BUILD / f"{args.output_stem}.md", summary_df, peaks_df)


if __name__ == "__main__":
    main()
