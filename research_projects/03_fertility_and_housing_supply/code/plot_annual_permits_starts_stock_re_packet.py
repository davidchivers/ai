from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"

INPUT = BUILD / "annual_permits_starts_stock_re_packet.csv"
FIG_PNG = BUILD / "annual_permits_starts_stock_re_packet.png"
FIG_PDF = BUILD / "annual_permits_starts_stock_re_packet.pdf"
NOTE = BUILD / "annual_permits_starts_stock_re_packet_figure_note.md"


def scenario_title(name: str) -> str:
    mapping = {
        "benchmark_d05_stock_data_3step_re": "Benchmark",
        "benchmark_d05_stock_data_5step_re": "Benchmark",
        "benchmark_d05_stock_data_20step_re": "Benchmark",
        "robustness_d05_stock_data_3step_re": "Robustness",
        "robustness_d05_stock_data_5step_re": "Robustness",
        "robustness_d05_stock_data_20step_re": "Robustness",
    }
    return mapping.get(name, name)


def main() -> None:
    if not INPUT.exists():
        raise FileNotFoundError(f"Missing packet csv: {INPUT}")

    df = pd.read_csv(INPUT)
    df = df[df["anchor_scenario"].isin(["benchmark_d05_stock_data", "robustness_d05_stock_data"])].copy()

    fig, axes = plt.subplots(2, 2, figsize=(11, 7), sharex=True)
    k_styles = {
        3: ("#1f77b4", "o"),
        5: ("#ff7f0e", "s"),
        20: ("#2ca02c", "^"),
    }
    panel_map = [
        ("benchmark_d05_stock_data", "q_gap_vs_stock_anchor", axes[0, 0], "Benchmark: price gap vs anchor"),
        ("robustness_d05_stock_data", "q_gap_vs_stock_anchor", axes[0, 1], "Robustness: price gap vs anchor"),
        ("benchmark_d05_stock_data", "young_mortgage_gap_vs_stock_anchor", axes[1, 0], "Benchmark: young mortgage gap vs anchor"),
        ("robustness_d05_stock_data", "young_mortgage_gap_vs_stock_anchor", axes[1, 1], "Robustness: young mortgage gap vs anchor"),
    ]

    for scenario, metric, ax, title in panel_map:
        panel = df[df["anchor_scenario"] == scenario]
        for k in sorted(panel["k"].unique()):
            sub = panel[panel["k"] == k].sort_values("t")
            color, marker = k_styles[int(k)]
            ax.plot(sub["t"], sub[metric], color=color, marker=marker, linewidth=2, markersize=6, label=f"k={int(k)}")
        ax.axhline(0.0, color="black", linewidth=1, alpha=0.5)
        ax.set_title(title)
        ax.set_xlabel("t")
        ax.grid(alpha=0.25)

    axes[0, 0].set_ylabel("q gap")
    axes[1, 0].set_ylabel("young mortgaged-owner gap")
    axes[0, 1].legend(frameon=False, loc="best")

    fig.suptitle("Calibrated annual RE packet: bounded horizons vs non-RE anchor", fontsize=12)
    fig.tight_layout(rect=(0, 0, 1, 0.97))
    fig.savefig(FIG_PNG, dpi=200)
    fig.savefig(FIG_PDF)
    plt.close(fig)

    note_lines = [
        "# Annual permits-starts-stock RE packet figure",
        "",
        "Files:",
        "",
        "- `annual_permits_starts_stock_re_packet.png`",
        "- `annual_permits_starts_stock_re_packet.pdf`",
        "",
        "Read:",
        "",
        "- Top row: the price premium grows with horizon, especially at `k = 20`.",
        "- Bottom row: ownership-composition gaps remain small relative to the calibrated non-RE anchor.",
        "- This is the visual reason the live hierarchy stays:",
        "  - `k = 3` main",
        "  - `k = 5` robustness",
        "  - `k = 20` appendix only",
        "",
        "- The benchmark and robustness cases tell the same qualitative story.",
    ]
    NOTE.write_text("\n".join(note_lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
