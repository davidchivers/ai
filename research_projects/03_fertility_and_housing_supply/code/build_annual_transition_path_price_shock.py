from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from nimby_fertility_transition_bridge import (
    BridgeParams,
    default_mass_vector,
    normalize_mass_vector,
    simulate_exogenous_price_path_relaxation,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
SUMMARY_CSV = BUILD / "fertility_annual_transition_path_state_grid_mapping_summary.csv"
CONST_SUMMARY_CSV = BUILD / "annual_transition_path_constant_price_relaxation_summary.csv"

PRICE_RATIO = 1.15
SHOCK_START = 1


def load_transition_template_mass() -> np.ndarray:
    summary = pd.read_csv(SUMMARY_CSV)
    mass_by_block = dict(zip(summary["age_block"], summary["block_mass"]))
    mass_65_80 = float(mass_by_block["65-80"])
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


def build_price_path(params: BridgeParams) -> np.ndarray:
    price_path = np.zeros(params.T + 1, dtype=float)
    price_path[SHOCK_START:] = float(np.log(PRICE_RATIO))
    return price_path


def build_mass_table(default_mass: np.ndarray, template_mass: np.ndarray, params: BridgeParams) -> pd.DataFrame:
    age_grid = np.asarray(params.age_grid, dtype=float)
    labels = ["15-24", "25-34", "35-44", "45-54", "55-64", "65-74", "75-84", "85+"]
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
    merged["births_gap"] = merged["births_template"] - merged["births_default"]
    merged["young_homeownership_proxy_gap"] = (
        merged["young_homeownership_proxy_template"] - merged["young_homeownership_proxy_default"]
    )
    merged["old_homeownership_proxy_gap"] = (
        merged["old_homeownership_proxy_template"] - merged["old_homeownership_proxy_default"]
    )
    gap_cols = [f"age_share_{int(age)}_template" for age in BridgeParams().age_grid]
    base_cols = [f"age_share_{int(age)}_default" for age in BridgeParams().age_grid]
    merged["age_share_l1_gap"] = np.abs(merged[gap_cols].to_numpy() - merged[base_cols].to_numpy()).sum(axis=1)
    merged["price_ratio"] = np.exp(merged["price_default"])

    checkpoints = merged[merged["t"].isin([0, 1, 5, 10, 20, 40, 79])].copy()
    summary = checkpoints[
        [
            "t",
            "price_ratio",
            "average_age_default",
            "average_age_template",
            "average_age_gap",
            "young_share_default",
            "young_share_template",
            "young_share_gap",
            "old_share_default",
            "old_share_template",
            "old_share_gap",
            "births_default",
            "births_template",
            "births_gap",
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


def write_note(note_path: Path, mass_table: pd.DataFrame, summary_table: pd.DataFrame) -> None:
    const_summary = pd.read_csv(CONST_SUMMARY_CSV) if CONST_SUMMARY_CSV.exists() else None

    initial_gap = float(summary_table.loc[summary_table["t"] == 0, "age_share_l1_gap"].iloc[0])
    gap_t20 = float(summary_table.loc[summary_table["t"] == 20, "age_share_l1_gap"].iloc[0])
    gap_t40 = float(summary_table.loc[summary_table["t"] == 40, "age_share_l1_gap"].iloc[0])
    avg_age_gap20 = float(summary_table.loc[summary_table["t"] == 20, "average_age_gap"].iloc[0])
    young_gap20 = float(summary_table.loc[summary_table["t"] == 20, "young_share_gap"].iloc[0])
    births_gap20 = float(summary_table.loc[summary_table["t"] == 20, "births_gap"].iloc[0])

    compare_line = None
    if const_summary is not None:
        const_gap20 = float(const_summary.loc[const_summary["t"] == 20, "age_share_l1_gap"].iloc[0])
        const_gap40 = float(const_summary.loc[const_summary["t"] == 40, "age_share_l1_gap"].iloc[0])
        compare_line = (
            f"- Compared with the fixed-price run, the age-share L1 gap is `{gap_t20:.3f}` versus `{const_gap20:.3f}` at `t = 20`, "
            f"and `{gap_t40:.3f}` versus `{const_gap40:.3f}` at `t = 40`."
        )

    lines = [
        "# Annual transition-path bounded price-shock run",
        "",
        "This is the first bounded price-shock transition experiment for the annual branch.",
        "It keeps the annual `t = 0` template, imposes one exogenous price path, and leaves the voting block out of the loop.",
        "",
        "## Scope lock",
        "",
        "- one exogenous price path only",
        "- no endogenous voting feedback into price",
        "- no re-estimation",
        "- no new steady-state search",
        "",
        "## Price path",
        "",
        f"- `t = 0`: baseline price level",
        f"- `t >= {SHOCK_START}`: permanent `+15%%` price level shock",
        f"- implemented as log price path `0` then `ln({PRICE_RATIO:.2f})`",
        "",
        "## Main read",
        "",
        f"- initial age-share L1 gap between default and template: `{initial_gap:.3f}`",
        f"- age-share L1 gap after `20` periods under the price shock: `{gap_t20:.3f}`",
        f"- age-share L1 gap after `40` periods under the price shock: `{gap_t40:.3f}`",
        f"- average-age gap at `t = 20`: `{avg_age_gap20:.2f}` years",
        f"- young-share gap at `t = 20`: `{young_gap20:.3f}`",
        f"- births gap at `t = 20`: `{births_gap20:.4f}`",
    ]

    if compare_line is not None:
        lines.append(compare_line)

    lines.extend(
        [
            "",
            "## Interpretation",
            "",
            "- This asks whether the annual `t = 0` cross section stays relevant once prices jump and remain high.",
            "- If the gap still washes out fairly quickly, then the transition-path branch is mainly about short-run incidence rather than a fundamentally different long-run annual equilibrium.",
            "- If the gap remains materially larger than in the constant-price run, then the price shock is interacting with the young leverage composition in a meaningful way.",
            "",
            "## Initial mass table",
            "",
            "| Age bin | Default mass | Template mass | Template - default |",
            "|---|---:|---:|---:|",
        ]
    )

    for row in mass_table.itertuples(index=False):
        lines.append(
            f"| {row.age_bin} | `{row.default_mass:.3f}` | `{row.transition_template_mass:.3f}` | `{row.template_minus_default:.3f}` |"
        )

    lines.extend(
        [
            "",
            "## Shock-path checkpoints",
            "",
            "| t | Price ratio | Avg age gap | Young-share gap | Old-share gap | Births gap | Young owner proxy gap | Age-share L1 gap |",
            "|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in summary_table.itertuples(index=False):
        lines.append(
            f"| {int(row.t)} | `{row.price_ratio:.3f}` | `{row.average_age_gap:.2f}` | `{row.young_share_gap:.3f}` | "
            f"`{row.old_share_gap:.3f}` | `{row.births_gap:.4f}` | `{row.young_homeownership_proxy_gap:.3f}` | `{row.age_share_l1_gap:.3f}` |"
        )

    note_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    if not SUMMARY_CSV.exists():
        raise FileNotFoundError(f"Missing {SUMMARY_CSV}. Run the state-grid mapping first.")

    params = BridgeParams()
    default_mass = default_mass_vector()
    template_mass = load_transition_template_mass()
    price_path = build_price_path(params)

    default_path = simulate_exogenous_price_path_relaxation(
        params, price_path=price_path, mode="fertility", initial_mass=default_mass
    )
    template_path = simulate_exogenous_price_path_relaxation(
        params, price_path=price_path, mode="fertility", initial_mass=template_mass
    )

    full_path, summary_table = summarize_paths(default_path, template_path)
    mass_table = build_mass_table(default_mass, template_mass, params)

    full_path.to_csv(BUILD / "annual_transition_path_price_shock.csv", index=False)
    summary_table.to_csv(BUILD / "annual_transition_path_price_shock_summary.csv", index=False)
    mass_table.to_csv(BUILD / "annual_transition_path_price_shock_initial_mass.csv", index=False)
    write_note(BUILD / "annual_transition_path_price_shock.md", mass_table, summary_table)


if __name__ == "__main__":
    main()
