from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "notes" / "build"


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


def load_data() -> pd.DataFrame:
    return pd.read_csv(BUILD / "annual_transition_calibrated_experiments.csv")


def plot_paths(data: pd.DataFrame) -> None:
    drift = 5
    subset = data.loc[data["drift_pct"] == drift].copy()
    palette = {
        "baseline": "#111111",
        "benchmark": "#275d8c",
        "robustness": "#b24c2a",
    }

    fig, axes = plt.subplots(2, 2, figsize=(11.5, 7.8), constrained_layout=True)
    mapping = [
        ("young_owner_25_34", "A. Young owner share 25-34", "Share"),
        ("young_mortgaged_owner_25_34", "B. Young mortgaged-owner share 25-34", "Share"),
        ("owner_35_44", "C. Owner share 35-44", "Share"),
        ("mortgaged_owner_35_44", "D. Mortgaged-owner share 35-44", "Share"),
    ]
    for ax, (col, title, ylabel) in zip(axes.flat, mapping):
        for role, group in subset.groupby("role", sort=False):
            g = group.sort_values("t")
            ax.plot(g["t"], g[col], lw=2.2, color=palette[role], label=role.capitalize())
        ax.set_title(title)
        ax.set_xlabel("Years since snapshot")
        ax.set_ylabel(ylabel)
        ax.set_xlim(0, 20)
        if "mortgaged" in col:
            ax.set_ylim(bottom=0.15)
        else:
            ax.set_ylim(bottom=0.35)
    axes[0, 0].legend(frameon=False, loc="best")

    fig.suptitle("Annual transition benchmark paths under +5% drift", fontsize=13.5, fontweight="bold")
    fig.savefig(BUILD / "annual_transition_benchmark_paths.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "annual_transition_benchmark_paths.pdf", bbox_inches="tight")
    plt.close(fig)


def plot_sensitivity(data: pd.DataFrame) -> None:
    subset = data.loc[data["role"] != "baseline"].copy()
    subset = subset.loc[subset["t"].isin([5, 20])]
    palette = {
        "benchmark": "#275d8c",
        "robustness": "#b24c2a",
    }
    fig, axes = plt.subplots(1, 2, figsize=(10.5, 4.0), constrained_layout=True)
    mapping = [
        ("young_mortgage_gap_vs_baseline", "A. Young mortgage gain vs drift baseline"),
        ("young_owner_gap_vs_baseline", "B. Young ownership gain vs drift baseline"),
    ]
    for ax, (col, title) in zip(axes, mapping):
        for role, group in subset.groupby("role", sort=False):
            g = group.sort_values(["drift_pct", "t"])
            for t, marker in ((5, "o"), (20, "s")):
                gt = g.loc[g["t"] == t]
                ax.plot(
                    gt["drift_pct"],
                    gt[col],
                    lw=2.0,
                    marker=marker,
                    color=palette[role],
                    label=f"{role.capitalize()}, t={t}",
                )
        ax.set_title(title)
        ax.set_xlabel("Permanent drift rate (%)")
        ax.set_ylabel("Gain over drift baseline")
        ax.set_xticks([2, 5, 8])
    handles, labels = axes[0].get_legend_handles_labels()
    by_label = dict(zip(labels, handles))
    axes[0].legend(by_label.values(), by_label.keys(), frameon=False, loc="best")

    fig.suptitle("Annual transition sensitivity across drift calibrations", fontsize=13.5, fontweight="bold")
    fig.savefig(BUILD / "annual_transition_benchmark_sensitivity.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "annual_transition_benchmark_sensitivity.pdf", bbox_inches="tight")
    plt.close(fig)


def write_note(data: pd.DataFrame) -> None:
    subset = data.loc[(data["drift_pct"] == 5) & (data["t"].isin([5, 20]))].copy()
    lines = [
        "# Annual transition benchmark figures",
        "",
        "These figures are the paper-facing visual layer for the annual transition branch.",
        "",
        "## Files",
        "",
        "- `annual_transition_benchmark_paths.png` / `.pdf`",
        "- `annual_transition_benchmark_sensitivity.png` / `.pdf`",
        "",
        "## Read",
        "",
        "At the central `+5%` drift calibration:",
        "",
    ]
    for row in subset.itertuples(index=False):
        if row.role == "baseline":
            continue
        lines.append(
            f"- `{row.role}` at `t={row.t}`: young owner `{row.young_owner_25_34:.3f}`, "
            f"young mortgaged-owner `{row.young_mortgaged_owner_25_34:.3f}`, "
            f"young owner gap `{row.young_owner_gap_vs_baseline:.3f}`, "
            f"young mortgage gap `{row.young_mortgage_gap_vs_baseline:.3f}`."
        )
    lines.extend(
        [
            "",
            "The path figure should be used for the central annual benchmark comparison. The sensitivity figure shows that the ordering of benchmark and robustness survives under milder and harsher drift.",
        ]
    )
    (BUILD / "annual_transition_benchmark_figures.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    set_style()
    data = load_data()
    plot_paths(data)
    plot_sensitivity(data)
    write_note(data)


if __name__ == "__main__":
    main()
