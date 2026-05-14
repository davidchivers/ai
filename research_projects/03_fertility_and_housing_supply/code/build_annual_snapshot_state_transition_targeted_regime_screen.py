from __future__ import annotations

from pathlib import Path

import pandas as pd

from build_annual_snapshot_state_transition import (
    BUILD,
    INPUT_SUMMARY,
    Scenario,
    load_initial_cross_section,
    simulate_scenario,
)


OUTPUT_STEM = "annual_snapshot_state_transition_targeted_regime_screen"
T = 80
CHECK_T = (5, 20)


def build_scenarios() -> list[Scenario]:
    scenarios: list[Scenario] = [
        Scenario("drift_baseline", 1.05, 0.0, 0.0, 0, 0, False),
    ]
    for center in (0.14, 0.16, 0.18):
        for width in (0.02, 0.03, 0.04):
            for mid_age_scale in (0.8, 1.0, 1.2):
                label = (
                    f"targeted_combo_c{center:.2f}_w{width:.2f}_m{mid_age_scale:.2f}"
                )
                scenarios.append(
                    Scenario(
                        label,
                        1.05,
                        0.50,
                        0.25,
                        0,
                        0,
                        True,
                        support_center=center,
                        support_width=width,
                        mid_age_scale=mid_age_scale,
                    )
                )
    return scenarios


def ratio(num: float, den: float) -> float:
    if den <= 1.0e-12:
        return 0.0
    return num / den


def evaluate(summary: pd.DataFrame) -> pd.DataFrame:
    scenarios = build_scenarios()
    frames = {
        scenario.name: simulate_scenario(summary, scenario=scenario, T=T)
        for scenario in scenarios
    }
    baseline = frames["drift_baseline"].set_index("t")

    rows: list[dict[str, float | str]] = []
    for scenario in scenarios[1:]:
        frame = frames[scenario.name].set_index("t")

        record: dict[str, float | str] = {
            "scenario": scenario.name,
            "support_center": scenario.support_center,
            "support_width": scenario.support_width,
            "mid_age_scale": scenario.mid_age_scale,
        }

        young_mortgage_gain_sum = 0.0
        young_owner_gain_sum = 0.0
        mid_mortgage_gain_sum = 0.0
        mid_owner_gain_sum = 0.0
        young_ratio_gain_sum = 0.0
        mid_ratio_gain_sum = 0.0

        for t in CHECK_T:
            row = frame.loc[t]
            base = baseline.loc[t]

            young_mortgage_gain = float(
                row["young_mortgaged_owner_share_25_34"]
                - base["young_mortgaged_owner_share_25_34"]
            )
            young_owner_gain = float(
                row["young_owner_share_25_34"] - base["young_owner_share_25_34"]
            )
            mid_mortgage_gain = float(
                row["mortgaged_owner_share_35_44"]
                - base["mortgaged_owner_share_35_44"]
            )
            mid_owner_gain = float(
                row["owner_share_35_44"] - base["owner_share_35_44"]
            )

            young_ratio_gain = ratio(
                float(row["young_mortgaged_owner_share_25_34"]),
                float(row["young_owner_share_25_34"]),
            ) - ratio(
                float(base["young_mortgaged_owner_share_25_34"]),
                float(base["young_owner_share_25_34"]),
            )
            mid_ratio_gain = ratio(
                float(row["mortgaged_owner_share_35_44"]),
                float(row["owner_share_35_44"]),
            ) - ratio(
                float(base["mortgaged_owner_share_35_44"]),
                float(base["owner_share_35_44"]),
            )

            record[f"young_owner_{t}"] = float(row["young_owner_share_25_34"])
            record[f"young_mortgage_{t}"] = float(
                row["young_mortgaged_owner_share_25_34"]
            )
            record[f"mid_owner_{t}"] = float(row["owner_share_35_44"])
            record[f"mid_mortgage_{t}"] = float(row["mortgaged_owner_share_35_44"])
            record[f"young_owner_gain_{t}"] = young_owner_gain
            record[f"young_mortgage_gain_{t}"] = young_mortgage_gain
            record[f"mid_owner_gain_{t}"] = mid_owner_gain
            record[f"mid_mortgage_gain_{t}"] = mid_mortgage_gain
            record[f"young_ratio_gain_{t}"] = young_ratio_gain
            record[f"mid_ratio_gain_{t}"] = mid_ratio_gain

            young_mortgage_gain_sum += young_mortgage_gain
            young_owner_gain_sum += young_owner_gain
            mid_mortgage_gain_sum += mid_mortgage_gain
            mid_owner_gain_sum += mid_owner_gain
            young_ratio_gain_sum += young_ratio_gain
            mid_ratio_gain_sum += mid_ratio_gain

        n = float(len(CHECK_T))
        record["avg_young_mortgage_gain"] = young_mortgage_gain_sum / n
        record["avg_young_owner_gain"] = young_owner_gain_sum / n
        record["avg_mid_mortgage_gain"] = mid_mortgage_gain_sum / n
        record["avg_mid_owner_gain"] = mid_owner_gain_sum / n
        record["avg_young_ratio_gain"] = young_ratio_gain_sum / n
        record["avg_mid_ratio_gain"] = mid_ratio_gain_sum / n

        ownership_cost = (
            record["avg_young_owner_gain"] + 0.5 * record["avg_mid_owner_gain"]
        )
        mortgage_benefit = (
            record["avg_young_mortgage_gain"] + 0.5 * record["avg_mid_mortgage_gain"]
        )
        ratio_benefit = (
            record["avg_young_ratio_gain"] + 0.5 * record["avg_mid_ratio_gain"]
        )

        record["mortgage_efficiency"] = mortgage_benefit / max(ownership_cost, 1.0e-9)
        record["balance_score"] = ratio_benefit + 0.5 * mortgage_benefit - 0.5 * ownership_cost
        rows.append(record)

    table = pd.DataFrame.from_records(rows)
    table = table.sort_values(
        ["balance_score", "mortgage_efficiency", "avg_young_mortgage_gain"],
        ascending=[False, False, False],
    ).reset_index(drop=True)
    table.insert(0, "rank", range(1, len(table) + 1))
    return table


def write_note(path: Path, table: pd.DataFrame) -> None:
    top = table.head(8)
    best = top.iloc[0]
    lines = [
        "# Annual targeted persistent help-to-buy regime screen",
        "",
        "This is a narrow calibration screen for the standing targeted annual transition regime.",
        "It does not add a new mechanism. It only tunes the eligibility shape.",
        "",
        "## Screen design",
        "",
        "- fixed mechanism: standing qualification + standing deposit help under permanent `+5%%` drift",
        "- fixed weights: deposit help `0.50`, qualification `0.25`",
        "- tuned knobs:",
        "  - threshold center",
        "  - threshold width",
        "  - age-35-44 scale",
        "- evaluation windows: `t = 5` and `t = 20`",
        "- ranking criterion: raise mortgaged-owner shares without pushing owner shares too much",
        "",
        "## Best row",
        "",
        f"- label: `{best['scenario']}`",
        f"- threshold center: `{best['support_center']:.2f}`",
        f"- threshold width: `{best['support_width']:.2f}`",
        f"- age-35-44 scale: `{best['mid_age_scale']:.2f}`",
        f"- avg young mortgaged-owner gain: `{best['avg_young_mortgage_gain']:.3f}`",
        f"- avg young owner gain: `{best['avg_young_owner_gain']:.3f}`",
        f"- avg 35-44 mortgaged-owner gain: `{best['avg_mid_mortgage_gain']:.3f}`",
        f"- avg 35-44 owner gain: `{best['avg_mid_owner_gain']:.3f}`",
        f"- mortgage efficiency: `{best['mortgage_efficiency']:.3f}`",
        f"- balance score: `{best['balance_score']:.3f}`",
        "",
        "## Top rows",
        "",
        "| Rank | Scenario | Center | Width | 35-44 scale | Avg young mortgage gain | Avg young owner gain | Avg 35-44 mortgage gain | Avg 35-44 owner gain | Mortgage efficiency | Balance score |",
        "|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in top.itertuples(index=False):
        lines.append(
            f"| {row.rank} | `{row.scenario}` | {row.support_center:.2f} | {row.support_width:.2f} | {row.mid_age_scale:.2f} | "
            f"{row.avg_young_mortgage_gain:.3f} | {row.avg_young_owner_gain:.3f} | "
            f"{row.avg_mid_mortgage_gain:.3f} | {row.avg_mid_owner_gain:.3f} | "
            f"{row.mortgage_efficiency:.3f} | {row.balance_score:.3f} |"
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
