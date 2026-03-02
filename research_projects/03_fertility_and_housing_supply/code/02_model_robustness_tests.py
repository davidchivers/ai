#!/usr/bin/env python3
"""Robustness test battery for the fertility-housing prototype model."""

from __future__ import annotations

from dataclasses import asdict, replace
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import pandas as pd

from fertility_extension_experiment import Params, simulate


PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = PROJECT_ROOT / "notes" / "build"


def metrics(df: pd.DataFrame) -> dict[str, float]:
    price_diff = df["price"].diff().abs()
    return {
        "avg_price_t10_49": float(df.loc[df["t"] >= 10, "price"].mean()),
        "avg_fertility_t10_49": float(df.loc[df["t"] >= 10, "fertility_rate"].mean()),
        "avg_births_t10_49": float(df.loc[df["t"] >= 10, "births"].mean()),
        "max_abs_price_change": float(price_diff.max(skipna=True)),
        "final_price": float(df["price"].iloc[-1]),
        "final_fertility": float(df["fertility_rate"].iloc[-1]),
    }


def count_price_direction_flips(df: pd.DataFrame) -> int:
    diff = df["price"].diff().to_numpy()
    sign = np.sign(diff[1:])
    sign_prev = np.sign(diff[:-1])
    mask = (sign != 0.0) & (sign_prev != 0.0) & (sign != sign_prev)
    return int(mask.sum())


def df_to_markdown(df: pd.DataFrame) -> str:
    cols = [str(c) for c in df.columns]
    lines = [
        "| " + " | ".join(cols) + " |",
        "| " + " | ".join(["---"] * len(cols)) + " |",
    ]
    for _, row in df.iterrows():
        vals = []
        for col in df.columns:
            v = row[col]
            if isinstance(v, (float, np.floating)):
                vals.append(f"{float(v):.6f}")
            else:
                vals.append(str(v))
        lines.append("| " + " | ".join(vals) + " |")
    return "\n".join(lines)


def run() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    baseline_summary_path = OUT_DIR / "model_experiment_summary.csv"
    baseline_summary = pd.read_csv(baseline_summary_path) if baseline_summary_path.exists() else None

    base = Params()

    damping_rows: list[dict[str, float]] = []
    for damping in [0.10, 0.25, 0.50, 0.75, 1.00]:
        df = simulate(base, damping=damping, family_supply_shift=0.0)
        row = {"damping": damping, **metrics(df), "price_direction_flips": count_price_direction_flips(df)}
        damping_rows.append(row)
    damping_df = pd.DataFrame(damping_rows)
    damping_df.to_csv(OUT_DIR / "robustness_damping_grid.csv", index=False)

    supply_rows: list[dict[str, float]] = []
    for shift in [0.00, 0.10, 0.20, 0.30]:
        df = simulate(base, damping=0.25, family_supply_shift=shift)
        row = {"family_supply_shift": shift, **metrics(df)}
        supply_rows.append(row)
    supply_df = pd.DataFrame(supply_rows)
    supply_df.to_csv(OUT_DIR / "robustness_family_supply_grid.csv", index=False)

    timing_rows: list[dict[str, float]] = []
    for shock_start in [5, 15, 25]:
        df = simulate(base, damping=0.25, family_supply_shift=0.20, shock_start=shock_start)
        row = {"shock_start": shock_start, **metrics(df)}
        timing_rows.append(row)
    timing_df = pd.DataFrame(timing_rows)
    timing_df.to_csv(OUT_DIR / "robustness_shock_timing_grid.csv", index=False)

    stress_specs = [
        ("higher_price_elasticity", {"f_price_semi_elasticity": 0.35}),
        ("lower_price_elasticity", {"f_price_semi_elasticity": 0.05}),
        ("lower_supply_elasticity", {"eps0": 0.50}),
        ("higher_supply_elasticity", {"eps0": 1.40}),
        ("older_cohort_political_weight_up", {"theta_old": 1.10}),
        ("younger_cohort_political_weight_up", {"theta_young": 0.50}),
        ("lower_baseline_fertility", {"f_level": 0.16}),
        ("higher_baseline_fertility", {"f_level": 0.30}),
    ]
    stress_rows: list[dict[str, float]] = []
    for scenario, overrides in stress_specs:
        p = replace(base, **overrides)
        df = simulate(p, damping=0.25, family_supply_shift=0.20)
        row = {"scenario": scenario, **asdict(p), **metrics(df)}
        stress_rows.append(row)
    stress_df = pd.DataFrame(stress_rows)
    stress_df.to_csv(OUT_DIR / "robustness_parameter_stress.csv", index=False)

    checks = []
    for label, df in [
        ("damping_grid", damping_df),
        ("family_supply_grid", supply_df),
        ("shock_timing_grid", timing_df),
        ("parameter_stress", stress_df),
    ]:
        checks.append((label, bool(np.isfinite(df.select_dtypes(include=[np.number]).to_numpy()).all())))

    low_damping_jump = float(damping_df.loc[damping_df["damping"] == 0.10, "max_abs_price_change"].iloc[0])
    no_damping_jump = float(damping_df.loc[damping_df["damping"] == 1.00, "max_abs_price_change"].iloc[0])
    checks.append(("low_damping_reduces_max_price_jump", low_damping_jump < no_damping_jump))

    supply0_fert = float(supply_df.loc[supply_df["family_supply_shift"] == 0.00, "avg_fertility_t10_49"].iloc[0])
    supply3_fert = float(supply_df.loc[supply_df["family_supply_shift"] == 0.30, "avg_fertility_t10_49"].iloc[0])
    checks.append(("higher_family_supply_raises_avg_fertility", supply3_fert > supply0_fert))

    checks_df = pd.DataFrame(checks, columns=["check", "passed"])
    checks_df.to_csv(OUT_DIR / "robustness_test_checks.csv", index=False)

    utc_stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        "# Full build and robustness test report",
        "",
        f"- Generated: {utc_stamp}",
        f"- Project root: `{PROJECT_ROOT}`",
        f"- Parameter baseline: `{asdict(base)}`",
        "",
        "## Build status",
        "",
        "- Baseline build artifacts present:",
        f"  - `model_experiment_no_damping.csv`: {(OUT_DIR / 'model_experiment_no_damping.csv').exists()}",
        f"  - `model_experiment_damped.csv`: {(OUT_DIR / 'model_experiment_damped.csv').exists()}",
        f"  - `model_experiment_policy.csv`: {(OUT_DIR / 'model_experiment_policy.csv').exists()}",
        f"  - `model_experiment_summary.csv`: {(OUT_DIR / 'model_experiment_summary.csv').exists()}",
        f"  - `model_experiment_paths.png`: {(OUT_DIR / 'model_experiment_paths.png').exists()}",
        "",
    ]

    if baseline_summary is not None:
        lines.extend(
            [
                "## Baseline summary (from full build)",
                "",
                df_to_markdown(baseline_summary),
                "",
            ]
        )

    lines.extend(
        [
            "## Robustness checks",
            "",
            df_to_markdown(checks_df),
            "",
            "## Damping grid",
            "",
            df_to_markdown(damping_df),
            "",
            "## Family supply shift grid",
            "",
            df_to_markdown(supply_df),
            "",
            "## Shock timing grid",
            "",
            df_to_markdown(timing_df),
            "",
            "## Parameter stress tests",
            "",
            df_to_markdown(stress_df),
            "",
        ]
    )

    (OUT_DIR / "full_build_and_robustness_report.md").write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    run()
