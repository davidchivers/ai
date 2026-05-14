from __future__ import annotations

from pathlib import Path

import pandas as pd

from build_annual_snapshot_state_transition import INPUT_SUMMARY, Scenario, load_initial_cross_section, simulate_scenario


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

OUTPUT_STEM = "annual_transition_calibrated_experiments"
T = 80
DRIFT_GRID = (1.02, 1.05, 1.08)
CHECK_T = (2, 5, 20)


def build_scenarios() -> list[Scenario]:
    scenarios: list[Scenario] = []
    for drift in DRIFT_GRID:
        suffix = f"{int(round((drift - 1.0) * 100)):02d}"
        scenarios.append(Scenario(f"baseline_d{suffix}", drift, 0.0, 0.0, 0, 0, False))
        scenarios.append(
            Scenario(
                f"benchmark_d{suffix}",
                drift,
                0.15,
                0.25,
                0,
                0,
                True,
                support_center=0.18,
                support_width=0.04,
                mid_age_scale=0.80,
            )
        )
        scenarios.append(
            Scenario(
                f"robustness_d{suffix}",
                drift,
                0.30,
                0.40,
                0,
                0,
                True,
                support_center=0.18,
                support_width=0.04,
                mid_age_scale=0.80,
            )
        )
    return scenarios


def scenario_role(name: str) -> str:
    return name.split("_", 1)[0]


def scenario_drift(name: str) -> str:
    return name.split("_d", 1)[1]


def build_summary(summary: pd.DataFrame) -> pd.DataFrame:
    scenarios = build_scenarios()
    frames = {sc.name: simulate_scenario(summary, sc, T=T).set_index("t") for sc in scenarios}

    rows: list[dict[str, str | float | int]] = []
    for drift in {scenario_drift(sc.name) for sc in scenarios}:
        base = frames[f"baseline_d{drift}"]
        for sc in scenarios:
            if scenario_drift(sc.name) != drift:
                continue
            frame = frames[sc.name]
            for t in CHECK_T:
                f = frame.loc[t]
                b = base.loc[t]
                rows.append(
                    {
                        "scenario": sc.name,
                        "role": scenario_role(sc.name),
                        "drift_pct": int(drift),
                        "t": int(t),
                        "young_owner_25_34": float(f["young_owner_share_25_34"]),
                        "young_mortgaged_owner_25_34": float(f["young_mortgaged_owner_share_25_34"]),
                        "owner_35_44": float(f["owner_share_35_44"]),
                        "mortgaged_owner_35_44": float(f["mortgaged_owner_share_35_44"]),
                        "young_owner_gap_vs_baseline": float(f["young_owner_share_25_34"] - b["young_owner_share_25_34"]),
                        "young_mortgage_gap_vs_baseline": float(
                            f["young_mortgaged_owner_share_25_34"] - b["young_mortgaged_owner_share_25_34"]
                        ),
                        "owner_35_44_gap_vs_baseline": float(f["owner_share_35_44"] - b["owner_share_35_44"]),
                        "mortgage_35_44_gap_vs_baseline": float(
                            f["mortgaged_owner_share_35_44"] - b["mortgaged_owner_share_35_44"]
                        ),
                    }
                )
    table = pd.DataFrame(rows)
    table = table.sort_values(["drift_pct", "role", "t"]).reset_index(drop=True)
    return table


def write_note(path: Path, table: pd.DataFrame) -> None:
    lines = [
        "# Annual calibrated transition experiments",
        "",
        "This note runs a small annual transition experiment grid off the frozen annual calibration pack.",
        "It mirrors the logic of the `5-year` sensitivity exercises, but stays inside the annual transition branch.",
        "",
        "## Design",
        "",
        "- roles:",
        "  - `baseline`: drift only",
        "  - `benchmark`: conservative support regime",
        "  - `robustness`: data-leaning support regime",
        "- drift grid:",
        "  - `+2%`",
        "  - `+5%`",
        "  - `+8%`",
        "- checkpoints:",
        "  - `t = 2` early crunch",
        "  - `t = 5` main annual calibration window",
        "  - `t = 20` persistence check",
        "",
    ]
    for drift in sorted(table["drift_pct"].unique()):
        lines.extend(
            [
                f"## Drift `{drift}%`",
                "",
                "| Role | t | Young owner 25-34 | Young mortgaged-owner 25-34 | Owner 35-44 | Mortgaged-owner 35-44 | Young owner gap vs baseline | Young mortgage gap vs baseline |",
                "|---|---:|---:|---:|---:|---:|---:|---:|",
            ]
        )
        sub = table.loc[table["drift_pct"] == drift]
        for row in sub.itertuples(index=False):
            lines.append(
                f"| `{row.role}` | {row.t} | {row.young_owner_25_34:.3f} | {row.young_mortgaged_owner_25_34:.3f} | "
                f"{row.owner_35_44:.3f} | {row.mortgaged_owner_35_44:.3f} | "
                f"{row.young_owner_gap_vs_baseline:.3f} | {row.young_mortgage_gap_vs_baseline:.3f} |"
            )
        lines.append("")

    lines.extend(
        [
            "## Read",
            "",
            "- This is the first bounded experiment layer to run on top of the annual transition calibration pack.",
            "- It is useful for asking whether the benchmark/robustness regimes matter only at the current drift calibration or also under milder and harsher annual housing pressure.",
            "- If this experiment grid looks stable enough, it should replace ad hoc annual mechanism screens as the live annual counterfactual layer.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")
    summary = load_initial_cross_section(INPUT_SUMMARY)
    table = build_summary(summary)
    table.to_csv(BUILD / f"{OUTPUT_STEM}.csv", index=False)
    write_note(BUILD / f"{OUTPUT_STEM}.md", table)


if __name__ == "__main__":
    main()
