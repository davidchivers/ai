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


OUTPUT_STEM = "annual_snapshot_state_transition_conservative_screen"
T = 80
CHECK_T = (5, 20)


def build_scenarios() -> list[Scenario]:
    scenarios: list[Scenario] = [
        Scenario("drift_baseline", 1.05, 0.0, 0.0, 0, 0, False),
    ]
    for family_help in (0.00, 0.15, 0.25, 0.35, 0.50):
        for mid_age_scale in (0.80, 1.00, 1.20):
            label = f"conservative_fh{family_help:.2f}_m{mid_age_scale:.2f}"
            scenarios.append(
                Scenario(
                    label,
                    1.05,
                    family_help,
                    0.25,
                    0,
                    0,
                    True,
                    support_center=0.18,
                    support_width=0.04,
                    mid_age_scale=mid_age_scale,
                )
            )
    return scenarios


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
        row: dict[str, float | str] = {
            "scenario": scenario.name,
            "family_help_weight": scenario.deposit_help_weight,
            "mid_age_scale": scenario.mid_age_scale,
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

        n = float(len(CHECK_T))
        row["avg_young_mortgage_gain"] = young_mortgage_gain / n
        row["avg_young_owner_gain"] = young_owner_gain / n
        row["avg_mid_mortgage_gain"] = mid_mortgage_gain / n
        row["avg_mid_owner_gain"] = mid_owner_gain / n
        # More conservative score: heavily penalize ownership overshoot.
        row["conservative_score"] = (
            row["avg_young_mortgage_gain"]
            + 0.5 * row["avg_mid_mortgage_gain"]
            - 1.2 * row["avg_young_owner_gain"]
            - 0.8 * row["avg_mid_owner_gain"]
        )
        row["mortgage_efficiency"] = (
            (row["avg_young_mortgage_gain"] + 0.5 * row["avg_mid_mortgage_gain"])
            / max(row["avg_young_owner_gain"] + 0.5 * row["avg_mid_owner_gain"], 1.0e-9)
        )
        rows.append(row)

    table = pd.DataFrame.from_records(rows)
    table = table.sort_values(
        ["conservative_score", "mortgage_efficiency", "avg_young_mortgage_gain"],
        ascending=[False, False, False],
    ).reset_index(drop=True)
    table.insert(0, "rank", range(1, len(table) + 1))
    return table


def write_note(path: Path, table: pd.DataFrame) -> None:
    best = table.iloc[0]
    top = table.head(8)
    lines = [
        "# Annual conservative transition screen",
        "",
        "This is a narrow tightening pass around the selected annual transition rule.",
        "Help-to-buy stays fixed; only family-help intensity and the 35-44 age weight move.",
        "",
        "## Fixed items",
        "",
        "- permanent `+5%` drift",
        "- targeted standing qualification weight `0.25`",
        "- support center `0.18`",
        "- support width `0.04`",
        "",
        "## Best conservative row",
        "",
        f"- label: `{best['scenario']}`",
        f"- family-help weight: `{best['family_help_weight']:.2f}`",
        f"- age-35-44 scale: `{best['mid_age_scale']:.2f}`",
        f"- avg young mortgaged-owner gain: `{best['avg_young_mortgage_gain']:.3f}`",
        f"- avg young owner gain: `{best['avg_young_owner_gain']:.3f}`",
        f"- avg 35-44 mortgaged-owner gain: `{best['avg_mid_mortgage_gain']:.3f}`",
        f"- avg 35-44 owner gain: `{best['avg_mid_owner_gain']:.3f}`",
        f"- mortgage efficiency: `{best['mortgage_efficiency']:.3f}`",
        f"- conservative score: `{best['conservative_score']:.3f}`",
        "",
        "## Top rows",
        "",
        "| Rank | Scenario | Family help | 35-44 scale | Avg young mortgage gain | Avg young owner gain | Avg 35-44 mortgage gain | Avg 35-44 owner gain | Mortgage efficiency | Conservative score |",
        "|---|---|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in top.itertuples(index=False):
        lines.append(
            f"| {row.rank} | `{row.scenario}` | {row.family_help_weight:.2f} | {row.mid_age_scale:.2f} | "
            f"{row.avg_young_mortgage_gain:.3f} | {row.avg_young_owner_gain:.3f} | "
            f"{row.avg_mid_mortgage_gain:.3f} | {row.avg_mid_owner_gain:.3f} | "
            f"{row.mortgage_efficiency:.3f} | {row.conservative_score:.3f} |"
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
