from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from nimby_fertility_transition_bridge import (
    BridgeParams,
    default_mass_vector,
    normalize_mass_vector,
    simulate_constant_price_relaxation,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
SUMMARY_CSV = BUILD / "fertility_annual_transition_path_state_grid_mapping_summary.csv"


def load_transition_template_mass() -> np.ndarray:
    summary = pd.read_csv(SUMMARY_CSV)
    mass_by_block = dict(zip(summary["age_block"], summary["block_mass"]))
    mass_65_80 = float(mass_by_block["65-80"])

    # Bridge bins are 15-24, 25-34, 35-44, 45-54, 55-64, 65-74, 75-84, 85+.
    # The annual transition template starts at 25 and currently ends at 80.
    # So 15-24 and 85+ are set to zero here, and the 65-80 block is split 10/6.
    vec = np.array(
        [
            0.0,
            float(mass_by_block["25-34"]),
            float(mass_by_block["35-44"]),
            float(mass_by_block["45-54"]),
            float(mass_by_block["55-64"]),
            mass_65_80 * 10.0 / 16.0,
            mass_65_80 * 6.0 / 16.0,
            0.0,
        ],
        dtype=float,
    )
    return normalize_mass_vector(vec)


def build_mass_table(default_mass: np.ndarray, template_mass: np.ndarray, params: BridgeParams) -> pd.DataFrame:
    age_grid = np.asarray(params.age_grid, dtype=float)
    labels = [
        "15-24",
        "25-34",
        "35-44",
        "45-54",
        "55-64",
        "65-74",
        "75-84",
        "85+",
    ]
    return pd.DataFrame(
        {
            "age_bin": labels,
            "bridge_age_point": age_grid,
            "default_mass": default_mass,
            "transition_template_mass": template_mass,
            "template_minus_default": template_mass - default_mass,
        }
    )


def summarize_paths(default_path: pd.DataFrame, template_path: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    merged = default_path.merge(template_path, on="t", suffixes=("_default", "_template"))
    merged["average_age_gap"] = merged["average_age_template"] - merged["average_age_default"]
    merged["young_share_gap"] = merged["young_share_template"] - merged["young_share_default"]
    merged["old_share_gap"] = merged["old_share_template"] - merged["old_share_default"]
    merged["fertility_rate_gap"] = merged["fertility_rate_template"] - merged["fertility_rate_default"]
    merged["young_homeownership_proxy_gap"] = (
        merged["young_homeownership_proxy_template"] - merged["young_homeownership_proxy_default"]
    )
    merged["old_homeownership_proxy_gap"] = (
        merged["old_homeownership_proxy_template"] - merged["old_homeownership_proxy_default"]
    )
    gap_cols = [f"age_share_{int(age)}_template" for age in BridgeParams().age_grid]
    base_cols = [f"age_share_{int(age)}_default" for age in BridgeParams().age_grid]
    merged["age_share_l1_gap"] = np.abs(merged[gap_cols].to_numpy() - merged[base_cols].to_numpy()).sum(axis=1)

    checkpoints = merged[merged["t"].isin([0, 1, 5, 10, 20, 40, 79])].copy()
    summary = checkpoints[
        [
            "t",
            "average_age_default",
            "average_age_template",
            "average_age_gap",
            "young_share_default",
            "young_share_template",
            "young_share_gap",
            "old_share_default",
            "old_share_template",
            "old_share_gap",
            "fertility_rate_default",
            "fertility_rate_template",
            "fertility_rate_gap",
            "young_homeownership_proxy_default",
            "young_homeownership_proxy_template",
            "young_homeownership_proxy_gap",
            "old_homeownership_proxy_default",
            "old_homeownership_proxy_template",
            "old_homeownership_proxy_gap",
            "age_share_l1_gap",
        ]
    ].reset_index(drop=True)
    return merged, summary


def write_note(
    note_path: Path,
    mass_table: pd.DataFrame,
    summary_table: pd.DataFrame,
    default_mass: np.ndarray,
    template_mass: np.ndarray,
) -> None:
    initial_gap = float(summary_table.loc[summary_table["t"] == 0, "age_share_l1_gap"].iloc[0])
    gap_t20 = float(summary_table.loc[summary_table["t"] == 20, "age_share_l1_gap"].iloc[0])
    gap_t40 = float(summary_table.loc[summary_table["t"] == 40, "age_share_l1_gap"].iloc[0])
    avg_age_gap0 = float(summary_table.loc[summary_table["t"] == 0, "average_age_gap"].iloc[0])
    avg_age_gap20 = float(summary_table.loc[summary_table["t"] == 20, "average_age_gap"].iloc[0])
    young_gap0 = float(summary_table.loc[summary_table["t"] == 0, "young_share_gap"].iloc[0])
    young_gap20 = float(summary_table.loc[summary_table["t"] == 20, "young_share_gap"].iloc[0])

    lines = [
        "# Annual transition-path constant-price relaxation",
        "",
        "This is the first live transition-path experiment for the annual branch.",
        "It does one thing only: inject the new `t = 0` transition template once, hold price fixed, and let the age distribution relax endogenously.",
        "",
        "## Scope lock",
        "",
        "- fixed price path only",
        "- no price shock",
        "- no voting change",
        "- no re-estimation",
        "",
        "## Initial mass mapping",
        "",
        "- default bridge mass is the existing reduced-form transition baseline",
        "- template mass is built from the new annual `t = 0` age cross section",
        "- ages `15-24` and `85+` are set to zero because the current annual template starts at `25` and ends at `80`",
        "- the `65-80` template block is split `10/16` into `65-74` and `6/16` into `75-84`",
        "",
        "## Main read",
        "",
        f"- initial age-share L1 gap between default and template: `{initial_gap:.3f}`",
        f"- age-share L1 gap after 20 periods: `{gap_t20:.3f}`",
        f"- age-share L1 gap after 40 periods: `{gap_t40:.3f}`",
        f"- average-age gap at `t = 0`: `{avg_age_gap0:.2f}` years",
        f"- average-age gap at `t = 20`: `{avg_age_gap20:.2f}` years",
        f"- young-share gap at `t = 0`: `{young_gap0:.3f}`",
        f"- young-share gap at `t = 20`: `{young_gap20:.3f}`",
        "",
        "## Interpretation",
        "",
        "- This run tells us how much of the annual gap is just an initial cross-section effect under a fixed price path.",
        "- If the template quickly relaxes back toward the default bridge, then the `t = 0` cross section matters mainly for short-run transition dynamics.",
        "- If the gap stays large for many periods, then the young leverage problem is persistent enough that a real transition experiment is worth building next.",
        "",
        "## Initial mass table",
        "",
        "| Age bin | Default mass | Template mass | Template - default |",
        "|---|---:|---:|---:|",
    ]

    for row in mass_table.itertuples(index=False):
        lines.append(
            f"| {row.age_bin} | `{row.default_mass:.3f}` | `{row.transition_template_mass:.3f}` | `{row.template_minus_default:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Relaxation checkpoints",
            "",
            "| t | Avg age gap | Young-share gap | Old-share gap | Fertility gap | Young owner proxy gap | Age-share L1 gap |",
            "|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in summary_table.itertuples(index=False):
        lines.append(
            f"| {int(row.t)} | `{row.average_age_gap:.2f}` | `{row.young_share_gap:.3f}` | `{row.old_share_gap:.3f}` | "
            f"`{row.fertility_rate_gap:.4f}` | `{row.young_homeownership_proxy_gap:.3f}` | `{row.age_share_l1_gap:.3f}` |"
        )

    note_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if not SUMMARY_CSV.exists():
        raise FileNotFoundError(f"Missing {SUMMARY_CSV}. Run the state-grid mapping first.")

    params = BridgeParams()
    default_mass = default_mass_vector()
    template_mass = load_transition_template_mass()

    default_path = simulate_constant_price_relaxation(params, fixed_price=0.0, mode="fertility", initial_mass=default_mass)
    template_path = simulate_constant_price_relaxation(
        params, fixed_price=0.0, mode="fertility", initial_mass=template_mass
    )

    full_path, summary_table = summarize_paths(default_path, template_path)
    mass_table = build_mass_table(default_mass, template_mass, params)

    full_path.to_csv(BUILD / "annual_transition_path_constant_price_relaxation.csv", index=False)
    summary_table.to_csv(BUILD / "annual_transition_path_constant_price_relaxation_summary.csv", index=False)
    mass_table.to_csv(BUILD / "annual_transition_path_constant_price_relaxation_initial_mass.csv", index=False)
    write_note(
        BUILD / "annual_transition_path_constant_price_relaxation.md",
        mass_table,
        summary_table,
        default_mass,
        template_mass,
    )


if __name__ == "__main__":
    main()
