from __future__ import annotations

from pathlib import Path

import pandas as pd

from build_annual_snapshot_state_transition import INPUT_SUMMARY, Scenario, load_initial_cross_section, simulate_scenario
from build_annual_snapshot_state_transition_takeup_calibration import simulate_takeup


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
TABLES = ROOT / "drafts" / "tables"

OUTPUT_STEM = "annual_transition_calibration_targets"


def build_cases() -> dict[str, Scenario]:
    common = dict(
        price_ratio=1.05,
        deposit_help_horizon=0,
        qualification_horizon=0,
        targeted_support=True,
        support_center=0.18,
        support_width=0.04,
        mid_age_scale=0.80,
    )
    return {
        "drift_baseline": Scenario("drift_baseline", 1.05, 0.0, 0.0, 0, 0, False),
        "benchmark": Scenario("benchmark", deposit_help_weight=0.15, qualification_weight=0.25, **common),
        "robustness": Scenario("robustness", deposit_help_weight=0.30, qualification_weight=0.40, **common),
    }


def fmt(x: float) -> str:
    return f"{x:.3f}"


def build_table(summary: pd.DataFrame) -> pd.DataFrame:
    cases = build_cases()
    frames = {name: simulate_scenario(summary, sc, T=80).set_index("t") for name, sc in cases.items()}
    takeup = {name: simulate_takeup(summary, sc, T_takeup=5) for name, sc in cases.items() if name != "drift_baseline"}

    rows: list[dict[str, str]] = []

    def add(group: str, moment: str, target_or_role: str, t: int | None = None, var: str | None = None) -> None:
        row = {"group": group, "moment": moment, "target_or_role": target_or_role}
        if var is not None and t is not None:
            for case_name, frame in frames.items():
                row[case_name] = fmt(float(frame.loc[t, var]))
        rows.append(row)

    add("Snapshot matched by construction", "Owner share 25-34 at t=0", "0.407 observed t=0 snapshot", 0, "young_owner_share_25_34")
    add(
        "Snapshot matched by construction",
        "Mortgaged-owner share 25-34 at t=0",
        "0.306 observed t=0 snapshot",
        0,
        "young_mortgaged_owner_share_25_34",
    )
    add("Snapshot matched by construction", "Owner share 35-44 at t=0", "0.605 observed t=0 snapshot", 0, "owner_share_35_44")
    add(
        "Snapshot matched by construction",
        "Mortgaged-owner share 35-44 at t=0",
        "0.523 observed t=0 snapshot",
        0,
        "mortgaged_owner_share_35_44",
    )

    rows.append(
        {
            "group": "External incidence targets",
            "moment": "Help-to-buy incidence over first 5 years",
            "target_or_role": "0.30-0.40 external first-time buyer help-to-buy band",
            "drift_baseline": "--",
            "benchmark": fmt(takeup["benchmark"]["avg_help_to_buy_incidence_first5"]),
            "robustness": fmt(takeup["robustness"]["avg_help_to_buy_incidence_first5"]),
        }
    )
    rows.append(
        {
            "group": "External incidence targets",
            "moment": "Family-help incidence over first 5 years",
            "target_or_role": "0.20-0.30 external first-time buyer family-help band",
            "drift_baseline": "--",
            "benchmark": fmt(takeup["benchmark"]["avg_family_help_incidence_first5"]),
            "robustness": fmt(takeup["robustness"]["avg_family_help_incidence_first5"]),
        }
    )

    add("Main annual calibration window", "Owner share 25-34 at t=5", "short-run annual transition discipline", 5, "young_owner_share_25_34")
    add(
        "Main annual calibration window",
        "Mortgaged-owner share 25-34 at t=5",
        "short-run annual transition discipline",
        5,
        "young_mortgaged_owner_share_25_34",
    )
    add("Main annual calibration window", "Owner share 35-44 at t=5", "short-run annual transition discipline", 5, "owner_share_35_44")
    add(
        "Main annual calibration window",
        "Mortgaged-owner share 35-44 at t=5",
        "short-run annual transition discipline",
        5,
        "mortgaged_owner_share_35_44",
    )

    add("Persistence check only", "Owner share 25-34 at t=20", "persistence check, not main fitting target", 20, "young_owner_share_25_34")
    add(
        "Persistence check only",
        "Mortgaged-owner share 25-34 at t=20",
        "persistence check, not main fitting target",
        20,
        "young_mortgaged_owner_share_25_34",
    )
    add("Persistence check only", "Owner share 35-44 at t=20", "persistence check, not main fitting target", 20, "owner_share_35_44")
    add(
        "Persistence check only",
        "Mortgaged-owner share 35-44 at t=20",
        "persistence check, not main fitting target",
        20,
        "mortgaged_owner_share_35_44",
    )

    return pd.DataFrame(rows)


def write_note(path: Path, table: pd.DataFrame) -> None:
    lines = [
        "# Annual transition calibration targets",
        "",
        "This pack recasts the annual branch as a transition calibration object rather than a steady-state calibration object.",
        "",
        "## Calibration logic",
        "",
        "- `t = 0` age-by-tenure states are matched by construction from the observed snapshot.",
        "- `t = 1-5` is the main annual calibration window.",
        "- `t = 20` is a persistence check only, not a main fitting target.",
        "- External take-up evidence disciplines the support regime through two incidence objects:",
        "  - help-to-buy / qualification incidence among first-time buyers",
        "  - family-help incidence among first-time buyers",
        "",
        "## Cases",
        "",
        "- `drift_baseline`: no support, permanent `+5%` drift.",
        "- `benchmark`: qualification `0.25`, family help `0.15`.",
        "- `robustness`: qualification `0.40`, family help `0.30`.",
        "",
        "## Table",
        "",
        "| Group | Moment | Target or role | Drift baseline | Benchmark | Robustness |",
        "|---|---|---|---:|---:|---:|",
    ]
    for row in table.itertuples(index=False):
        lines.append(
            f"| {row.group} | {row.moment} | {row.target_or_role} | {row.drift_baseline} | {row.benchmark} | {row.robustness} |"
        )
    lines.extend(
        [
            "",
            "## Read",
            "",
            "- The benchmark case is the disciplined annual transition object.",
            "- The robustness case is the more data-facing take-up alignment case.",
            "- This is the annual calibration layer to use going forward, rather than reopening annual steady-state search.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def tex_escape(text: str) -> str:
    return (
        text.replace("\\", "\\textbackslash ")
        .replace("&", "\\&")
        .replace("%", "\\%")
        .replace("_", "\\_")
        .replace("#", "\\#")
    )


def write_tex(path: Path, table: pd.DataFrame) -> None:
    lines = [
        "\\begin{table}[htbp]",
        "\\centering",
        "\\caption{Annual transition calibration targets and frozen cases}",
        "\\label{tab:annual_transition_calibration_targets}",
        "\\begin{tabular}{p{3.2cm} p{4.0cm} p{4.6cm} c c c}",
        "\\toprule",
        "Group & Moment & Target or role & Drift baseline & Benchmark & Robustness \\\\",
        "\\midrule",
    ]
    current_group = None
    for row in table.itertuples(index=False):
        group = tex_escape(row.group)
        moment = tex_escape(row.moment)
        target = tex_escape(row.target_or_role)
        group_cell = group if row.group != current_group else ""
        current_group = row.group
        lines.append(
            f"{group_cell} & {moment} & {target} & {row.drift_baseline} & {row.benchmark} & {row.robustness} \\\\"
        )
    lines.extend(
        [
            "\\bottomrule",
            "\\end{tabular}",
            "\\end{table}",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if not INPUT_SUMMARY.exists():
        raise FileNotFoundError(f"Missing {INPUT_SUMMARY}.")
    summary = load_initial_cross_section(INPUT_SUMMARY)
    table = build_table(summary)
    BUILD.mkdir(parents=True, exist_ok=True)
    TABLES.mkdir(parents=True, exist_ok=True)
    table.to_csv(BUILD / f"{OUTPUT_STEM}.csv", index=False)
    write_note(BUILD / f"{OUTPUT_STEM}.md", table)
    write_tex(TABLES / f"{OUTPUT_STEM}.tex", table)


if __name__ == "__main__":
    main()
