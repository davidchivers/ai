from __future__ import annotations

from pathlib import Path

import pandas as pd

from build_annual_snapshot_state_transition import (
    BUILD,
    CHECKPOINTS,
    INPUT_SUMMARY,
    Scenario,
    load_initial_cross_section,
    simulate_scenario,
)


OUTPUT_STEM = "annual_snapshot_state_transition_conservative_selected_regimes"
T = 80


def build_scenarios() -> list[Scenario]:
    center = 0.18
    width = 0.04
    mid_age_scale = 0.80
    qualification = 0.25
    light_family_help = 0.15
    return [
        Scenario(
            "drift_baseline",
            1.05,
            0.0,
            0.0,
            0,
            0,
            False,
        ),
        Scenario(
            "drift_targeted_help_to_buy_conservative",
            1.05,
            0.0,
            qualification,
            0,
            0,
            True,
            support_center=center,
            support_width=width,
            mid_age_scale=mid_age_scale,
        ),
        Scenario(
            "drift_targeted_help_to_buy_plus_light_family_help",
            1.05,
            light_family_help,
            qualification,
            0,
            0,
            True,
            support_center=center,
            support_width=width,
            mid_age_scale=mid_age_scale,
        ),
    ]


def summarize(frames: list[pd.DataFrame]) -> pd.DataFrame:
    combined = pd.concat(frames, ignore_index=True)
    baseline = combined.loc[combined["scenario"] == "drift_baseline"].set_index("t")
    rows: list[dict[str, float | str | int]] = []
    for scenario, frame in combined.groupby("scenario", sort=False):
        for row in frame.itertuples(index=False):
            base = baseline.loc[row.t]
            young_mortgage_ratio = (
                float(row.young_mortgaged_owner_share_25_34)
                / max(float(row.young_owner_share_25_34), 1.0e-12)
            )
            mid_mortgage_ratio = (
                float(row.mortgaged_owner_share_35_44)
                / max(float(row.owner_share_35_44), 1.0e-12)
            )
            rows.append(
                {
                    "scenario": scenario,
                    "t": int(row.t),
                    "young_owner_share_25_34": float(row.young_owner_share_25_34),
                    "young_mortgaged_owner_share_25_34": float(
                        row.young_mortgaged_owner_share_25_34
                    ),
                    "young_mortgage_share_among_owners": young_mortgage_ratio,
                    "young_renter_with_debt_share_25_34": float(
                        row.young_renter_with_debt_share_25_34
                    ),
                    "owner_share_35_44": float(row.owner_share_35_44),
                    "mortgaged_owner_share_35_44": float(row.mortgaged_owner_share_35_44),
                    "mortgage_share_among_owners_35_44": mid_mortgage_ratio,
                    "young_owner_gap_vs_drift": float(row.young_owner_share_25_34)
                    - float(base["young_owner_share_25_34"]),
                    "young_mortgage_gap_vs_drift": float(
                        row.young_mortgaged_owner_share_25_34
                    )
                    - float(base["young_mortgaged_owner_share_25_34"]),
                    "owner_35_44_gap_vs_drift": float(row.owner_share_35_44)
                    - float(base["owner_share_35_44"]),
                    "mortgage_35_44_gap_vs_drift": float(row.mortgaged_owner_share_35_44)
                    - float(base["mortgaged_owner_share_35_44"]),
                }
            )
    summary = pd.DataFrame.from_records(rows)
    return summary.loc[summary["t"].isin(CHECKPOINTS)].copy()


def write_note(path: Path, summary: pd.DataFrame) -> None:
    scenarios = list(summary["scenario"].drop_duplicates())
    key_rows = summary.loc[summary["t"].isin([1, 2, 5, 10, 20])]
    top = key_rows.loc[key_rows["scenario"] != "drift_baseline"]
    peaks = (
        top.groupby("scenario", as_index=False)[
            [
                "young_mortgage_gap_vs_drift",
                "young_owner_gap_vs_drift",
                "mortgage_35_44_gap_vs_drift",
                "owner_35_44_gap_vs_drift",
            ]
        ]
        .max()
    )
    lines = [
        "# Annual conservative selected transition regimes",
        "",
        "This note tightens the selected annual transition rule rather than reopening the mechanism search.",
        "Help-to-buy remains the main channel; family help is trimmed to a light augmentation.",
        "",
        "## Frozen calibration",
        "",
        "- threshold center: `0.18`",
        "- threshold width: `0.04`",
        "- age-35-44 scale: `0.80`",
        "- qualification weight: `0.25`",
        "- family deposit-help weight: `0.15` when active",
        "- all support is standing, not temporary",
        "",
        "## Scenarios",
        "",
        "- `drift_baseline`: permanent `+5%` price path, no support",
        "- `drift_targeted_help_to_buy_conservative`: permanent `+5%` price path, standing targeted qualification only",
        "- `drift_targeted_help_to_buy_plus_light_family_help`: permanent `+5%` price path, standing targeted qualification plus light family deposit help",
        "",
        "## Peak gains vs drift baseline",
        "",
        "| Scenario | Peak young mortgage gain | Peak young owner gain | Peak 35-44 mortgage gain | Peak 35-44 owner gain |",
        "|---|---:|---:|---:|---:|",
    ]
    for row in peaks.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.young_mortgage_gap_vs_drift:.3f}` | "
            f"`{row.young_owner_gap_vs_drift:.3f}` | `{row.mortgage_35_44_gap_vs_drift:.3f}` | "
            f"`{row.owner_35_44_gap_vs_drift:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints",
            "",
            "| Scenario | t | Young owner 25-34 | Young mortgaged-owner 25-34 | Young mortgage share among owners | Owner 35-44 | Mortgaged-owner 35-44 | 35-44 mortgage share among owners | Young mortgage gap vs drift | Young owner gap vs drift |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )
    for scenario in scenarios:
        rows = summary.loc[summary["scenario"] == scenario]
        for row in rows.itertuples(index=False):
            lines.append(
                f"| `{row.scenario}` | `{row.t}` | `{row.young_owner_share_25_34:.3f}` | "
                f"`{row.young_mortgaged_owner_share_25_34:.3f}` | "
                f"`{row.young_mortgage_share_among_owners:.3f}` | `{row.owner_share_35_44:.3f}` | "
                f"`{row.mortgaged_owner_share_35_44:.3f}` | "
                f"`{row.mortgage_share_among_owners_35_44:.3f}` | "
                f"`{row.young_mortgage_gap_vs_drift:.3f}` | `{row.young_owner_gap_vs_drift:.3f}` |"
            )

    lines.extend(
        [
            "",
            "## Read",
            "",
            "- Tightening the rule works mainly by trimming family help, not by removing the qualification channel.",
            "- Help-to-buy stays the main driver of young mortgaged-owner gains.",
            "- The lighter family-help layer still amplifies the mortgage effect, but with less ownership overshoot than the earlier selected-regime comparison.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")
    summary = load_initial_cross_section(INPUT_SUMMARY)
    frames = [simulate_scenario(summary, scenario=scenario, T=T) for scenario in build_scenarios()]
    raw = pd.concat(frames, ignore_index=True)
    out_summary = summarize(frames)
    raw.to_csv(BUILD / f"{OUTPUT_STEM}.csv", index=False)
    out_summary.to_csv(BUILD / f"{OUTPUT_STEM}_summary.csv", index=False)
    write_note(BUILD / f"{OUTPUT_STEM}.md", out_summary)


if __name__ == "__main__":
    main()
