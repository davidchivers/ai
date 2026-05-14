from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from build_annual_snapshot_state_transition import (
    BUILD,
    INPUT_SUMMARY,
    Scenario,
    adjust_matrix,
    build_base_transition_matrices,
    deposit_age_weight,
    deposit_time_scale,
    load_initial_cross_section,
    near_threshold_weight,
    qualification_age_weight,
    qualification_time_scale,
    simulate_scenario,
)


OUTPUT_STEM = "annual_snapshot_state_transition_takeup_calibration"
T = 80
CHECK_T = (5, 20)
HELP_TO_BUY_TARGET = (0.30, 0.40)
FAMILY_HELP_TARGET = (0.20, 0.30)


def build_scenarios() -> list[Scenario]:
    scenarios: list[Scenario] = []
    for qualification in (0.25, 0.30, 0.35, 0.40, 0.45):
        for family_help in (0.00, 0.10, 0.15, 0.20, 0.25, 0.30):
            label = f"cal_q{qualification:.2f}_fh{family_help:.2f}"
            scenarios.append(
                Scenario(
                    label,
                    1.05,
                    family_help,
                    qualification,
                    0,
                    0,
                    True,
                    support_center=0.18,
                    support_width=0.04,
                    mid_age_scale=0.80,
                )
            )
    return scenarios


def band_miss(value: float, lo: float, hi: float) -> float:
    if value < lo:
        return lo - value
    if value > hi:
        return value - hi
    return 0.0


def simulate_takeup(summary: pd.DataFrame, scenario: Scenario, T_takeup: int = 5) -> dict[str, float]:
    base_matrices = build_base_transition_matrices()
    age_blocks = list(summary["age_block"])
    widths = (summary["age_hi"] - summary["age_lo"] + 1).to_numpy(dtype=float)
    block_masses = summary["block_mass"].to_numpy(dtype=float)

    pop = summary.loc[:, ("renter_no_debt", "renter_with_debt", "owner_with_mortgage", "owner_outright")].to_numpy(dtype=float)
    pop = pop * block_masses[:, None]
    entrant_mix = summary.loc[
        summary["age_block"] == "25-34",
        ("renter_no_debt", "renter_with_debt", "owner_with_mortgage", "owner_outright"),
    ].iloc[0].to_numpy(dtype=float)

    total_purchase_flow = 0.0
    help_to_buy_flow = 0.0
    family_help_flow = 0.0
    young_purchase_flow = 0.0
    mid_purchase_flow = 0.0

    for t in range(T_takeup):
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

            if age_block not in ("25-34", "35-44"):
                continue

            age_is_mid = age_block == "35-44"
            for row_idx in (0, 1):
                row_mass = float(pop[i, row_idx])
                purchase_prob = float(matrix[row_idx, 2] + matrix[row_idx, 3])
                purchase_flow = row_mass * purchase_prob
                if purchase_flow <= 0.0:
                    continue

                original_purchase = float(base_matrices[age_block][row_idx, 2] + base_matrices[age_block][row_idx, 3])
                support_weight = (
                    near_threshold_weight(original_purchase, scenario.support_center, scenario.support_width)
                    if scenario.targeted_support
                    else 1.0
                )
                qual_strength = (
                    scenario.qualification_weight
                    * qualification_time_scale(t, scenario.qualification_horizon)
                    * qualification_age_weight(age_block, scenario.mid_age_scale)
                    * support_weight
                    * (1.0 if row_idx == 1 else 0.5)
                )
                deposit_strength = (
                    scenario.deposit_help_weight
                    * deposit_time_scale(t, scenario.deposit_help_horizon)
                    * deposit_age_weight(age_block, scenario.mid_age_scale)
                    * support_weight
                )

                qual_strength = float(np.clip(qual_strength, 0.0, 1.0))
                deposit_strength = float(np.clip(deposit_strength, 0.0, 1.0))

                total_purchase_flow += purchase_flow
                help_to_buy_flow += purchase_flow * qual_strength
                family_help_flow += purchase_flow * deposit_strength
                if age_is_mid:
                    mid_purchase_flow += purchase_flow
                else:
                    young_purchase_flow += purchase_flow

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

    return {
        "avg_help_to_buy_incidence_first5": help_to_buy_flow / max(total_purchase_flow, 1.0e-12),
        "avg_family_help_incidence_first5": family_help_flow / max(total_purchase_flow, 1.0e-12),
        "young_purchase_flow_first5": young_purchase_flow,
        "mid_purchase_flow_first5": mid_purchase_flow,
        "total_purchase_flow_first5": total_purchase_flow,
    }


def evaluate(summary: pd.DataFrame) -> pd.DataFrame:
    scenarios = build_scenarios()
    baseline = simulate_scenario(
        summary,
        Scenario(
            "drift_baseline",
            1.05,
            0.0,
            0.0,
            0,
            0,
            False,
        ),
        T=T,
    ).set_index("t")

    rows: list[dict[str, float | str]] = []
    for scenario in scenarios:
        frame = simulate_scenario(summary, scenario, T=T).set_index("t")
        takeup = simulate_takeup(summary, scenario, T_takeup=5)

        row: dict[str, float | str] = {
            "scenario": scenario.name,
            "qualification_weight": scenario.qualification_weight,
            "family_help_weight": scenario.deposit_help_weight,
            "avg_help_to_buy_incidence_first5": takeup["avg_help_to_buy_incidence_first5"],
            "avg_family_help_incidence_first5": takeup["avg_family_help_incidence_first5"],
            "young_purchase_flow_first5": takeup["young_purchase_flow_first5"],
            "mid_purchase_flow_first5": takeup["mid_purchase_flow_first5"],
            "total_purchase_flow_first5": takeup["total_purchase_flow_first5"],
        }

        young_mortgage_gain = 0.0
        young_owner_gain = 0.0
        mid_mortgage_gain = 0.0
        mid_owner_gain = 0.0
        for t in CHECK_T:
            f = frame.loc[t]
            b = baseline.loc[t]
            yg = float(f["young_mortgaged_owner_share_25_34"] - b["young_mortgaged_owner_share_25_34"])
            yo = float(f["young_owner_share_25_34"] - b["young_owner_share_25_34"])
            mg = float(f["mortgaged_owner_share_35_44"] - b["mortgaged_owner_share_35_44"])
            mo = float(f["owner_share_35_44"] - b["owner_share_35_44"])
            row[f"young_mortgage_gain_{t}"] = yg
            row[f"young_owner_gain_{t}"] = yo
            row[f"mid_mortgage_gain_{t}"] = mg
            row[f"mid_owner_gain_{t}"] = mo
            young_mortgage_gain += yg
            young_owner_gain += yo
            mid_mortgage_gain += mg
            mid_owner_gain += mo

        row["avg_young_mortgage_gain"] = young_mortgage_gain / len(CHECK_T)
        row["avg_young_owner_gain"] = young_owner_gain / len(CHECK_T)
        row["avg_mid_mortgage_gain"] = mid_mortgage_gain / len(CHECK_T)
        row["avg_mid_owner_gain"] = mid_owner_gain / len(CHECK_T)

        row["help_to_buy_band_miss"] = band_miss(
            row["avg_help_to_buy_incidence_first5"], HELP_TO_BUY_TARGET[0], HELP_TO_BUY_TARGET[1]
        )
        row["family_help_band_miss"] = band_miss(
            row["avg_family_help_incidence_first5"], FAMILY_HELP_TARGET[0], FAMILY_HELP_TARGET[1]
        )

        row["calibration_score"] = (
            row["avg_young_mortgage_gain"]
            + 0.5 * row["avg_mid_mortgage_gain"]
            - 0.9 * row["avg_young_owner_gain"]
            - 0.6 * row["avg_mid_owner_gain"]
            - 2.0 * row["help_to_buy_band_miss"]
            - 2.0 * row["family_help_band_miss"]
        )
        rows.append(row)

    table = pd.DataFrame.from_records(rows)
    table = table.sort_values(
        [
            "calibration_score",
            "help_to_buy_band_miss",
            "family_help_band_miss",
            "avg_young_mortgage_gain",
        ],
        ascending=[False, True, True, False],
    ).reset_index(drop=True)
    table.insert(0, "rank", range(1, len(table) + 1))
    return table


def write_note(path: Path, table: pd.DataFrame) -> None:
    best = table.iloc[0]
    top = table.head(10)
    lines = [
        "# Annual transition take-up calibration",
        "",
        "This note converts the standing targeted annual transition rule into implied first-time-buyer assistance rates.",
        "The goal is to map reduced-form weights to data-facing take-up objects rather than leave them as free wedges.",
        "",
        "## Fixed transition rule",
        "",
        "- permanent `+5%` drift",
        "- targeted standing support",
        "- support center `0.18`",
        "- support width `0.04`",
        "- age-35-44 scale `0.80`",
        "",
        "## Data-facing calibration targets",
        "",
        f"- help-to-buy / qualification incidence among first-time buyers: `{HELP_TO_BUY_TARGET[0]:.2f}-{HELP_TO_BUY_TARGET[1]:.2f}`",
        f"- family-help incidence among first-time buyers: `{FAMILY_HELP_TARGET[0]:.2f}-{FAMILY_HELP_TARGET[1]:.2f}`",
        "",
        "Incidence is measured here as the support-weighted share of first-time-buyer purchase flow over the first five annual transition periods.",
        "",
        "## Best row on calibration score",
        "",
        f"- label: `{best['scenario']}`",
        f"- qualification weight: `{best['qualification_weight']:.2f}`",
        f"- family-help weight: `{best['family_help_weight']:.2f}`",
        f"- implied help-to-buy incidence: `{best['avg_help_to_buy_incidence_first5']:.3f}`",
        f"- implied family-help incidence: `{best['avg_family_help_incidence_first5']:.3f}`",
        f"- avg young mortgaged-owner gain: `{best['avg_young_mortgage_gain']:.3f}`",
        f"- avg young owner gain: `{best['avg_young_owner_gain']:.3f}`",
        f"- avg 35-44 mortgaged-owner gain: `{best['avg_mid_mortgage_gain']:.3f}`",
        f"- avg 35-44 owner gain: `{best['avg_mid_owner_gain']:.3f}`",
        f"- help-to-buy band miss: `{best['help_to_buy_band_miss']:.3f}`",
        f"- family-help band miss: `{best['family_help_band_miss']:.3f}`",
        f"- calibration score: `{best['calibration_score']:.3f}`",
        "",
        "## Top rows",
        "",
        "| Rank | Scenario | Qualification | Family help | Help-to-buy incidence | Family-help incidence | Avg young mortgage gain | Avg young owner gain | Avg 35-44 mortgage gain | Avg 35-44 owner gain | Help band miss | Family band miss | Calibration score |",
        "|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in top.itertuples(index=False):
        lines.append(
            f"| {row.rank} | `{row.scenario}` | {row.qualification_weight:.2f} | {row.family_help_weight:.2f} | "
            f"{row.avg_help_to_buy_incidence_first5:.3f} | {row.avg_family_help_incidence_first5:.3f} | "
            f"{row.avg_young_mortgage_gain:.3f} | {row.avg_young_owner_gain:.3f} | "
            f"{row.avg_mid_mortgage_gain:.3f} | {row.avg_mid_owner_gain:.3f} | "
            f"{row.help_to_buy_band_miss:.3f} | {row.family_help_band_miss:.3f} | {row.calibration_score:.3f} |"
        )
    lines.extend(
        [
            "",
            "## Read",
            "",
            "- This is a conversion layer, not a new mechanism search.",
            "- Qualification weight is interpreted as broad help-to-buy / underwriting support.",
            "- Family-help weight is interpreted as the narrower deposit-gift layer.",
            "- The practical question is whether the same row can keep ownership overshoot moderate while landing near the data-facing take-up ranges.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")
    summary = load_initial_cross_section(INPUT_SUMMARY)
    table = evaluate(summary)
    table.to_csv(BUILD / f"{OUTPUT_STEM}.csv", index=False)
    write_note(BUILD / f"{OUTPUT_STEM}.md", table)


if __name__ == "__main__":
    main()
