from __future__ import annotations

import argparse
from dataclasses import replace
from pathlib import Path

import numpy as np
import pandas as pd

from nimby_fertility_transition_bridge import (
    BridgeParams,
    normalize_mass_vector,
    simulate_constant_price_relaxation,
    simulate_exogenous_price_path_relaxation,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
SUMMARY_CSV = BUILD / "fertility_annual_transition_path_state_grid_mapping_summary.csv"

PRICE_RATIO = 1.05
SHOCK_START = 1
CHECKPOINTS = [0, 1, 5, 10, 20, 40, 79]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build bounded annual transition mechanism scenario comparisons."
    )
    parser.add_argument(
        "--pack",
        choices=("default", "hamilton", "deposit_help_smoke", "deposit_help_hamilton"),
        default="default",
        help="Scenario pack to run.",
    )
    parser.add_argument(
        "--output-stem",
        default="annual_transition_mechanism_scenarios",
        help="Output filename stem written into notes/build/.",
    )
    return parser.parse_args()


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


def build_price_path(
    params: BridgeParams,
    price_ratio: float = PRICE_RATIO,
    shock_start: int = SHOCK_START,
) -> np.ndarray:
    price_path = np.zeros(params.T + 1, dtype=float)
    price_path[shock_start:] = float(np.log(price_ratio))
    return price_path


def run_scenario(
    scenario: str,
    params: BridgeParams,
    template_mass: np.ndarray,
    price_ratio: float,
) -> pd.DataFrame:
    use_price_path = abs(price_ratio - 1.0) > 1.0e-12
    if use_price_path:
        frame = simulate_exogenous_price_path_relaxation(
            params=params,
            price_path=build_price_path(params, price_ratio=price_ratio),
            mode="fertility",
            initial_mass=template_mass,
        )
    else:
        frame = simulate_constant_price_relaxation(
            params=params,
            fixed_price=0.0,
            mode="fertility",
            initial_mass=template_mass,
        )
    frame = frame.copy()
    frame["scenario"] = scenario
    frame["price_ratio"] = np.exp(frame["price"])
    frame["shock_price_ratio"] = float(price_ratio)
    frame["child_housing_burden_weight"] = float(params.f_child_housing_burden_weight)
    frame["deposit_help_weight"] = float(params.deposit_help_weight)
    return frame


def build_scenario_defs(pack: str) -> list[tuple[str, BridgeParams, float]]:
    base_params = BridgeParams()

    if pack == "default":
        utility_proxy_params = replace(base_params, f_child_housing_burden_weight=1.0)
        return [
            ("baseline_template", base_params, 1.0),
            ("drift_only", base_params, 1.05),
            ("child_housing_utility_proxy", utility_proxy_params, 1.0),
            ("child_housing_utility_plus_drift", utility_proxy_params, 1.05),
        ]

    if pack == "hamilton":
        return [
            ("baseline_template", base_params, 1.0),
            ("drift_only_103", base_params, 1.03),
            ("drift_only_105", base_params, 1.05),
            ("drift_only_110", base_params, 1.10),
            ("child_housing_utility_050", replace(base_params, f_child_housing_burden_weight=0.5), 1.0),
            ("child_housing_utility_100", replace(base_params, f_child_housing_burden_weight=1.0), 1.0),
            (
                "child_housing_utility_050_plus_drift_105",
                replace(base_params, f_child_housing_burden_weight=0.5),
                1.05,
            ),
            (
                "child_housing_utility_100_plus_drift_105",
                replace(base_params, f_child_housing_burden_weight=1.0),
                1.05,
            ),
            (
                "child_housing_utility_100_plus_drift_110",
                replace(base_params, f_child_housing_burden_weight=1.0),
                1.10,
            ),
        ]

    if pack == "deposit_help_smoke":
        return [
            ("baseline_template", base_params, 1.0),
            ("deposit_help_only", replace(base_params, deposit_help_weight=0.50), 1.0),
            ("deposit_help_plus_drift_105", replace(base_params, deposit_help_weight=0.50), 1.05),
            ("deposit_help_plus_drift_110", replace(base_params, deposit_help_weight=0.50), 1.10),
        ]

    if pack == "deposit_help_hamilton":
        return [
            ("baseline_template", base_params, 1.0),
            ("drift_only_105", base_params, 1.05),
            ("deposit_help_only_025", replace(base_params, deposit_help_weight=0.25), 1.0),
            ("deposit_help_only_050", replace(base_params, deposit_help_weight=0.50), 1.0),
            ("deposit_help_plus_drift_105_025", replace(base_params, deposit_help_weight=0.25), 1.05),
            ("deposit_help_plus_drift_105_050", replace(base_params, deposit_help_weight=0.50), 1.05),
            ("deposit_help_plus_drift_110_050", replace(base_params, deposit_help_weight=0.50), 1.10),
        ]

    raise ValueError(f"Unknown scenario pack: {pack}")


def build_scenarios(template_mass: np.ndarray, pack: str) -> list[pd.DataFrame]:
    scenario_defs = build_scenario_defs(pack)

    frames: list[pd.DataFrame] = []
    for label, params, price_ratio in scenario_defs:
        frames.append(run_scenario(label, params, template_mass, price_ratio))
    return frames


def summarize_against_baseline(frames: list[pd.DataFrame]) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    combined = pd.concat(frames, ignore_index=True)
    baseline = combined.loc[combined["scenario"] == "baseline_template"].copy()
    baseline = baseline.set_index("t")

    enriched = []
    peak_rows = []
    for scenario, frame in combined.groupby("scenario", sort=False):
        frame = frame.copy()
        if scenario == "baseline_template":
            frame["births_gap_vs_baseline"] = 0.0
            frame["fertility_gap_vs_baseline"] = 0.0
            frame["young_owner_gap_vs_baseline"] = 0.0
            frame["young_burden_gap_vs_baseline"] = 0.0
            frame["average_age_gap_vs_baseline"] = 0.0
        else:
            frame["births_gap_vs_baseline"] = frame["births"].to_numpy() - baseline.loc[frame["t"], "births"].to_numpy()
            frame["fertility_gap_vs_baseline"] = (
                frame["fertility_rate"].to_numpy() - baseline.loc[frame["t"], "fertility_rate"].to_numpy()
            )
            frame["young_owner_gap_vs_baseline"] = (
                frame["young_homeownership_proxy"].to_numpy()
                - baseline.loc[frame["t"], "young_homeownership_proxy"].to_numpy()
            )
            frame["young_burden_gap_vs_baseline"] = (
                frame["young_housing_burden_proxy"].to_numpy()
                - baseline.loc[frame["t"], "young_housing_burden_proxy"].to_numpy()
            )
            frame["average_age_gap_vs_baseline"] = (
                frame["average_age"].to_numpy() - baseline.loc[frame["t"], "average_age"].to_numpy()
            )

        births_idx = int(frame["births_gap_vs_baseline"].idxmin())
        owner_idx = int(frame["young_owner_gap_vs_baseline"].idxmin())
        burden_idx = int(frame["young_burden_gap_vs_baseline"].idxmax())
        peak_rows.append(
            {
                "scenario": scenario,
                "worst_birth_gap_t": int(frame.loc[births_idx, "t"]),
                "worst_birth_gap": float(frame.loc[births_idx, "births_gap_vs_baseline"]),
                "worst_young_owner_gap_t": int(frame.loc[owner_idx, "t"]),
                "worst_young_owner_gap": float(frame.loc[owner_idx, "young_owner_gap_vs_baseline"]),
                "peak_young_burden_gap_t": int(frame.loc[burden_idx, "t"]),
                "peak_young_burden_gap": float(frame.loc[burden_idx, "young_burden_gap_vs_baseline"]),
            }
        )
        enriched.append(frame)

    enriched_df = pd.concat(enriched, ignore_index=True)
    summary = enriched_df.loc[
        enriched_df["t"].isin(CHECKPOINTS),
        [
            "scenario",
            "t",
            "price_ratio",
            "shock_price_ratio",
            "child_housing_burden_weight",
            "deposit_help_weight",
            "births",
            "fertility_rate",
            "young_homeownership_proxy",
            "young_housing_burden_proxy",
            "average_age",
            "births_gap_vs_baseline",
            "fertility_gap_vs_baseline",
            "young_owner_gap_vs_baseline",
            "young_burden_gap_vs_baseline",
            "average_age_gap_vs_baseline",
        ],
    ].copy()
    peaks = pd.DataFrame(peak_rows)
    return enriched_df, summary, peaks


def write_note(path: Path, summary: pd.DataFrame, peaks: pd.DataFrame) -> None:
    def rows_for(scenario: str) -> pd.DataFrame:
        return summary.loc[summary["scenario"] == scenario].copy()

    scenarios = list(summary["scenario"].drop_duplicates())
    scenario_meta = (
        summary.loc[:, ["scenario", "shock_price_ratio", "child_housing_burden_weight", "deposit_help_weight"]]
        .drop_duplicates()
        .set_index("scenario")
    )

    def describe_scenario(scenario: str) -> str:
        row = scenario_meta.loc[scenario]
        parts: list[str] = []
        if float(row["shock_price_ratio"]) > 1.0 + 1.0e-12:
            parts.append(
                f"permanent +{(float(row['shock_price_ratio']) - 1.0) * 100:.0f}% price path from `t = {SHOCK_START}`"
            )
        else:
            parts.append("fixed prices")
        if float(row["child_housing_burden_weight"]) > 1.0e-12:
            parts.append(
                "reduced-form child-housing burden weight "
                f"`{float(row['child_housing_burden_weight']):.2f}`"
            )
        else:
            parts.append("no extra child-housing utility proxy")
        if float(row["deposit_help_weight"]) > 1.0e-12:
            parts.append(
                "reduced-form deposit-help weight "
                f"`{float(row['deposit_help_weight']):.2f}`"
            )
        else:
            parts.append("no extra deposit-help proxy")
        return "; ".join(parts)

    lines = [
        "# Annual transition mechanism scenarios",
        "",
        "This is a bounded transition comparison built on the annual `t = 0` cross section.",
        "It does not solve a new transition equilibrium. It compares a few reduced-form mechanism paths off the same starting point.",
        "",
        "## Scenarios",
        "",
        "The scenarios below all start from the same annual `t = 0` cross section.",
        "",
    ]

    for scenario in scenarios:
        lines.append(f"- `{scenario}`: {describe_scenario(scenario)}")

    lines.extend(
        [
            "",
            "## Interpretation guardrail",
            "",
            "- Any child-housing utility scenario is a reduced-form proxy, not a literal translation of the MATLAB utility function.",
            "- Any deposit-help scenario is a reduced-form short-run owner-entry proxy, not a structural parental-transfer model.",
            "- It should be read as: tighter child-housing burden feeds more strongly into fertility decisions during the transition.",
            "",
            "## Peak crunch points",
            "",
            "| Scenario | Worst births gap t | Worst births gap | Worst young-owner gap t | Worst young-owner gap | Peak young-burden gap t | Peak young-burden gap |",
            "|---|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for row in peaks.itertuples(index=False):
        lines.append(
            f"| `{row.scenario}` | `{row.worst_birth_gap_t}` | `{row.worst_birth_gap:.4f}` | "
            f"`{row.worst_young_owner_gap_t}` | `{row.worst_young_owner_gap:.4f}` | "
            f"`{row.peak_young_burden_gap_t}` | `{row.peak_young_burden_gap:.4f}` |"
        )

    lines.extend(
        [
            "",
            "## Checkpoints",
            "",
            "| Scenario | t | Price ratio | Births | Young owner proxy | Young burden proxy | Births gap vs baseline | Young-owner gap vs baseline | Young-burden gap vs baseline |",
            "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
        ]
    )

    for scenario in scenarios:
        for row in rows_for(scenario).itertuples(index=False):
            lines.append(
                f"| `{row.scenario}` | `{int(row.t)}` | `{row.price_ratio:.3f}` | `{row.births:.4f}` | "
                f"`{row.young_homeownership_proxy:.3f}` | `{row.young_housing_burden_proxy:.3f}` | "
                f"`{row.births_gap_vs_baseline:.4f}` | `{row.young_owner_gap_vs_baseline:.3f}` | `{row.young_burden_gap_vs_baseline:.3f}` |"
            )

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    if not SUMMARY_CSV.exists():
        raise FileNotFoundError(f"Missing {SUMMARY_CSV}. Run the transition-path state-grid mapping first.")

    template_mass = load_transition_template_mass()
    frames = build_scenarios(template_mass, pack=args.pack)
    full_path, summary, peaks = summarize_against_baseline(frames)

    full_path.to_csv(BUILD / f"{args.output_stem}.csv", index=False)
    summary.to_csv(BUILD / f"{args.output_stem}_summary.csv", index=False)
    peaks.to_csv(BUILD / f"{args.output_stem}_peaks.csv", index=False)
    write_note(BUILD / f"{args.output_stem}.md", summary, peaks)


if __name__ == "__main__":
    main()
