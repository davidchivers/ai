"""Generate curve-style figures for the current experiment set (Sections 7.1-7.3)."""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

plt.rcParams.update(
    {
        "font.family": "serif",
        "mathtext.fontset": "cm",
        "font.size": 11,
        "axes.titlesize": 12,
        "axes.labelsize": 11,
        "legend.fontsize": 9,
    }
)


OUT_DIR = Path(__file__).parent

SCENARIOS = [
    "Baseline",
    "Low UI\n(Endog tax)",
    "No UI\n(Endog tax)",
    "No UI\n(Fixed tax)",
]

# Values from drafts/tables/*.tex
ENTR = {
    "Low edu": [0.1457, 0.1542, 0.2481, 0.1507],
    "Mid edu": [0.1398, 0.1472, 0.2180, 0.1455],
    "High edu": [0.1618, 0.1672, 0.2018, 0.1680],
}

LABOR = {
    "Low edu": [9.7237, 9.0788, 4.5716, 9.2638],
    "Mid edu": [17.9923, 16.8165, 8.7990, 16.9940],
    "High edu": [33.5470, 31.8708, 19.1706, 31.7442],
}

TRANSITIONS = {
    "Entr -> Entr": [0.145, 0.151, 0.212, 0.151],
    "Emp -> Work": [0.740, 0.738, 0.676, 0.737],
    "Unemp -> Entr": [0.002, 0.003, 0.004, 0.002],
    "Unemp -> Work": [0.113, 0.107, 0.108, 0.110],
}


def plot_lines(series, title, ylabel, filename):
    x = list(range(len(SCENARIOS)))
    fig, ax = plt.subplots(figsize=(8.6, 4.8))
    markers = ["o", "s", "^", "D", "v", "P"]
    colors = ["#1f4e79", "#2e8b57", "#b35a1f", "#6a3d9a", "#3a3a3a", "#a63d40"]

    for i, (label, values) in enumerate(series.items()):
        ax.plot(
            x,
            values,
            marker=markers[i % len(markers)],
            color=colors[i % len(colors)],
            linewidth=2.0,
            markersize=5,
            label=label,
        )

    ax.set_xticks(x)
    ax.set_xticklabels(SCENARIOS)
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.grid(axis="y", alpha=0.25, linewidth=0.7)
    ax.legend(frameon=False, loc="best")
    fig.tight_layout()

    out_png = OUT_DIR / f"{filename}.png"
    out_pdf = OUT_DIR / f"{filename}.pdf"
    fig.savefig(out_png, dpi=350, facecolor="white")
    fig.savefig(out_pdf, facecolor="white")
    plt.close(fig)
    print(f"Wrote: {out_png}")
    print(f"Wrote: {out_pdf}")


def main():
    plot_lines(
        ENTR,
        "Entrepreneurship by Education Across Current Experiments",
        "Entrepreneurship Rate",
        "curve_entrepreneurship_by_education_current_experiments",
    )
    plot_lines(
        LABOR,
        "Labor Demand by Education Across Current Experiments",
        "Average Labor Demand (n)",
        "curve_labor_demand_by_education_current_experiments",
    )
    plot_lines(
        TRANSITIONS,
        "Key Transition Rates Across Current Experiments",
        "Transition Probability",
        "curve_transition_rates_current_experiments",
    )


if __name__ == "__main__":
    main()
