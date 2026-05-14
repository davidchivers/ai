from __future__ import annotations

import argparse
from dataclasses import replace
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from nimby_fertility_transition_bridge import BridgeParams, simulate_baby_boom, summarize_transition


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"
DEFAULT_STEM = "nimby_vs_fertility_smoothed_political_path_trial"


def set_style() -> None:
    plt.rcParams.update(
        {
            "font.family": "serif",
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.titleweight": "bold",
            "axes.titlesize": 10.5,
            "axes.labelsize": 9.5,
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
            "legend.fontsize": 8.5,
        }
    )


def total_variation(values: pd.Series) -> float:
    return float(np.abs(np.diff(values.to_numpy(dtype=float))).sum())


def run_trial(smooth_rho: float, boom_amp: float) -> tuple[pd.DataFrame, pd.DataFrame]:
    baseline = BridgeParams()
    smoothed = replace(baseline, theta_path_rho=float(smooth_rho))
    summary_rows: list[dict[str, float | str]] = []
    path_rows: list[pd.DataFrame] = []

    for model in ("fertility", "old_proxy"):
        raw_base = simulate_baby_boom(baseline, mode=model, boom_amp=0.0)
        raw_shock = simulate_baby_boom(baseline, mode=model, boom_amp=boom_amp)
        smooth_base = simulate_baby_boom(smoothed, mode=model, boom_amp=0.0)
        smooth_shock = simulate_baby_boom(smoothed, mode=model, boom_amp=boom_amp)

        raw_summary = summarize_transition(raw_base, raw_shock)
        smooth_summary = summarize_transition(smooth_base, smooth_shock)

        raw_label = "raw_theta_path"
        smooth_label = f"smoothed_theta_path_rho_{smooth_rho:.2f}"

        for variant, params, base_df, shock_df, metrics in (
            (raw_label, baseline, raw_base, raw_shock, raw_summary),
            (smooth_label, smoothed, smooth_base, smooth_shock, smooth_summary),
        ):
            summary_rows.append(
                {
                    "model": model,
                    "variant": variant,
                    "theta_path_rho": float(params.theta_path_rho),
                    "boom_amp": float(boom_amp),
                    "theta_peak": float(shock_df["theta"].max()),
                    "theta_total_variation": total_variation(shock_df["theta"]),
                    "price_total_variation": total_variation(shock_df["price"]),
                    "theta_gap_vs_raw_max_abs": float(
                        np.max(np.abs(shock_df["theta"].to_numpy(dtype=float) - raw_shock["theta"].to_numpy(dtype=float)))
                    ),
                    "price_gap_vs_raw_max_abs": float(
                        np.max(np.abs(shock_df["price"].to_numpy(dtype=float) - raw_shock["price"].to_numpy(dtype=float)))
                    ),
                    **metrics,
                }
            )

            frame = shock_df.loc[:, ["t", "price", "theta", "fertility_rate", "young_share", "old_share"]].copy()
            frame["model"] = model
            frame["variant"] = variant
            frame["theta_path_rho"] = float(params.theta_path_rho)
            path_rows.append(frame)

    return pd.DataFrame(summary_rows), pd.concat(path_rows, ignore_index=True)


def write_note(summary: pd.DataFrame, stem: str, smooth_rho: float, boom_amp: float) -> None:
    lines = [
        "# Smoothed political-path trial for the fertility bridge",
        "",
        "This is a dormant diagnostic trial, not a promoted live branch.",
        "It asks whether adding inertia to the bridge-level political-tightness path `theta_t`",
        "helps smooth the fertility transition object in the same spirit as the smoother political",
        "path experiments that improved the NIMBY workflow.",
        "",
        "## Trial design",
        "",
        f"- raw bridge path: `theta_path_rho = 0.00`",
        f"- smoothed bridge path: `theta_path_rho = {smooth_rho:.2f}`",
        f"- baby-boom shock amplitude: `{boom_amp:.2f}`",
        "- modes checked:",
        "  - `fertility`",
        "  - `old_proxy`",
        "",
        "## Read this note as",
        "",
        "- a workflow trial that is ready to run later",
        "- not evidence that the smoothed path is the right structural object",
        "- and not a replacement for the annual full-RE political-state branch",
        "",
        "## Summary table",
        "",
        "| Model | Variant | Theta TV | Price TV | Peak theta | Max |price gap vs raw| | Post-price response | Peak-price response |",
        "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]

    for row in summary.sort_values(["model", "theta_path_rho"]).itertuples(index=False):
        lines.append(
            f"| `{row.model}` | `{row.variant}` | `{row.theta_total_variation:.4f}` | `{row.price_total_variation:.4f}` | "
            f"`{row.theta_peak:.4f}` | `{row.price_gap_vs_raw_max_abs:.4f}` | "
            f"`{row.post_price_response:.4f}` | `{row.peak_price_response:.4f}` |"
        )

    lines.extend(
        [
            "",
            "## Promotion rule",
            "",
            "- only promote this trial if the smoothed path clearly reduces `theta` roughness without creating a worse price distortion",
            "- if it only smooths the bridge cosmetically, leave it as a diagnostic and keep the annual political-state branch as the main upgrade path",
        ]
    )

    (BUILD / f"{stem}.md").write_text("\n".join(lines), encoding="utf-8")


def plot_paths(paths: pd.DataFrame, stem: str, smooth_rho: float) -> None:
    fig, axes = plt.subplots(2, 2, figsize=(12.0, 7.0), constrained_layout=True, sharex=True)
    colors = {
        "raw_theta_path": "#111111",
        f"smoothed_theta_path_rho_{smooth_rho:.2f}": "#b24c2a",
    }

    for col, model in enumerate(("fertility", "old_proxy")):
        subset = paths[paths["model"] == model]
        ax_theta = axes[0, col]
        ax_price = axes[1, col]

        for variant, frame in subset.groupby("variant", sort=False):
            frame = frame.sort_values("t")
            ax_theta.plot(frame["t"], frame["theta"], lw=2.0, color=colors.get(variant, "#555555"), label=variant)
            ax_price.plot(frame["t"], frame["price"], lw=2.0, color=colors.get(variant, "#555555"), label=variant)

        ax_theta.set_title(f"{model.replace('_', ' ').title()}: theta path")
        ax_theta.set_ylabel("Theta")
        ax_theta.legend(frameon=False, loc="best")

        ax_price.set_title(f"{model.replace('_', ' ').title()}: price path")
        ax_price.set_xlabel("t")
        ax_price.set_ylabel("Price")
        ax_price.legend(frameon=False, loc="best")

    fig.suptitle("Dormant fertility-bridge trial: smoothed political path", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / f"{stem}.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / f"{stem}.pdf", bbox_inches="tight")
    plt.close(fig)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--smooth-rho", type=float, default=0.65)
    parser.add_argument("--boom-amp", type=float, default=0.10)
    parser.add_argument("--stem", type=str, default=DEFAULT_STEM)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    set_style()
    summary, paths = run_trial(args.smooth_rho, args.boom_amp)
    summary.to_csv(BUILD / f"{args.stem}.csv", index=False)
    paths.to_csv(BUILD / f"{args.stem}_paths.csv", index=False)
    write_note(summary, args.stem, args.smooth_rho, args.boom_amp)
    plot_paths(paths, args.stem, args.smooth_rho)


if __name__ == "__main__":
    main()
