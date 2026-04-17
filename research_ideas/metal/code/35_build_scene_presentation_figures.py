from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
FIGURE_DIR = SCENE_DIR / "figures"

PREFERRED_TABLE_PATH = SCENE_DIR / "scene_cluster_preferred_mechanism_table.csv"
CRITICAL_MASS_PATH = SCENE_DIR / "scene_role_switcher_critical_mass.csv"
SUMMARY_PATH = SCENE_DIR / "scene_presentation_figures_summary.md"

PREFERRED_FIGURE_PATH = FIGURE_DIR / "scene_preferred_mechanism_coefficients.png"
CRITICAL_MASS_FIGURE_PATH = FIGURE_DIR / "scene_critical_mass_event_rates.png"

CORE_SPEC = "preferred_core_roll5_fe"

CORE_ORDER = [
    "Overall active bands",
    "Nontrivial communities",
    "Overall multi-band musicians",
    "Local spawning flow",
    "Target-genre active bands",
    "Target-genre multi-band musicians",
]

BANDS_BIN_ORDER = ["<10", "10-19", "20-39", "40+"]
SWITCHERS_BIN_ORDER = ["0-1", "2-4", "5-9", "10+"]

POSITIVE_COLOR = "#0b7285"
NEGATIVE_COLOR = "#c44536"
CONTROL_COLOR = "#6c757d"
BACKGROUND_COLOR = "#f8f5ef"
GRID_COLOR = "#d9d2c5"
BAR_COLORS = ["#dbe4e8", "#9ec5d1", "#4d96a8", "#0b7285"]


def configure_style() -> None:
    plt.rcParams.update(
        {
            "axes.facecolor": BACKGROUND_COLOR,
            "figure.facecolor": BACKGROUND_COLOR,
            "axes.edgecolor": "#3d3d3d",
            "axes.labelcolor": "#2f2f2f",
            "axes.titlesize": 13,
            "axes.titleweight": "bold",
            "font.size": 10,
            "grid.color": GRID_COLOR,
            "grid.linewidth": 0.8,
            "savefig.facecolor": BACKGROUND_COLOR,
        }
    )


def load_preferred_table() -> pd.DataFrame:
    frame = pd.read_csv(PREFERRED_TABLE_PATH)
    numeric_columns = ["coefficient", "std_error", "p_value", "n_obs", "event_count", "event_rate", "r_squared"]
    for column in numeric_columns:
        frame[column] = pd.to_numeric(frame[column], errors="coerce")
    return frame


def load_critical_mass() -> pd.DataFrame:
    frame = pd.read_csv(CRITICAL_MASS_PATH)
    for column in ["n_obs", "event_count", "event_rate"]:
        frame[column] = pd.to_numeric(frame[column], errors="coerce")
    return frame


def predictor_color(label: str) -> str:
    if label.startswith("Overall") or label == "Nontrivial communities":
        return CONTROL_COLOR
    if "share" in label.lower():
        return NEGATIVE_COLOR
    return POSITIVE_COLOR


def format_signed(value: float) -> str:
    return f"{value:+.3f}"


def build_panel_data(frame: pd.DataFrame, spec_id: str, order: list[str]) -> pd.DataFrame:
    subset = frame.loc[frame["spec_id"].eq(spec_id)].copy()
    subset["display_order"] = subset["display_label"].map({label: idx for idx, label in enumerate(order)})
    subset = subset.loc[subset["display_order"].notna()].sort_values("display_order", ascending=False)
    subset["ci_low"] = subset["coefficient"] - 1.96 * subset["std_error"]
    subset["ci_high"] = subset["coefficient"] + 1.96 * subset["std_error"]
    subset["color"] = subset["display_label"].map(predictor_color)
    return subset


def add_coefficient_panel(ax: plt.Axes, subset: pd.DataFrame, title: str) -> None:
    y_positions = np.arange(subset.shape[0])
    ax.axvline(0.0, color="#444444", linewidth=1.2, zorder=1)
    ax.grid(axis="x", linestyle="--", alpha=0.8)
    ax.grid(axis="y", visible=False)

    for y_value, row in zip(y_positions, subset.itertuples(index=False)):
        ax.errorbar(
            row.coefficient,
            y_value,
            xerr=1.96 * row.std_error,
            fmt="o",
            markersize=7,
            color=row.color,
            ecolor=row.color,
            elinewidth=2,
            capsize=3,
            zorder=3,
        )
        text_x = row.ci_high + 0.002 if row.coefficient >= 0 else row.ci_low - 0.002
        ha = "left" if row.coefficient >= 0 else "right"
        ax.text(
            text_x,
            y_value,
            format_signed(row.coefficient),
            va="center",
            ha=ha,
            fontsize=9,
            color="#2f2f2f",
        )

    ax.set_yticks(y_positions)
    ax.set_yticklabels(subset["display_label"])
    ax.set_title(title)
    ax.set_xlabel("Coefficient")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)


def plot_preferred_mechanism_coefficients(frame: pd.DataFrame) -> dict[str, float]:
    FIGURE_DIR.mkdir(parents=True, exist_ok=True)

    core = build_panel_data(frame, CORE_SPEC, CORE_ORDER)
    max_abs = max(
        float(core["ci_high"].abs().max()),
        float(core["ci_low"].abs().max()),
    )
    x_limit = max_abs * 1.25

    fig, ax = plt.subplots(1, 1, figsize=(9.2, 7.3))
    add_coefficient_panel(ax, core, "Exact-year FE headline scene mechanisms")
    ax.set_xlim(-x_limit, x_limit)

    core_meta = core.iloc[0]
    fig.suptitle(
        "Scene emergence tracks local spawning and target-genre depth",
        fontsize=15,
        fontweight="bold",
        y=0.98,
    )
    fig.text(
        0.5,
        0.025,
        (
            "Exact-year fixed effects with city-clustered standard errors.\n"
            f"{int(core_meta['n_obs']):,} city-genre-years and {int(core_meta['event_count']):,} emergence events. "
            "Core mechanism terms only."
        ),
        ha="center",
        fontsize=8.5,
        color="#3d3d3d",
        linespacing=1.25,
    )
    fig.tight_layout(rect=(0.02, 0.10, 0.98, 0.94))
    fig.savefig(PREFERRED_FIGURE_PATH, dpi=220)
    plt.close(fig)

    return {
        "core_r2": float(core_meta["r_squared"]),
        "n_obs": float(core_meta["n_obs"]),
        "event_count": float(core_meta["event_count"]),
    }


def add_bar_labels(ax: plt.Axes, values: pd.Series) -> None:
    for idx, value in enumerate(values):
        ax.text(
            idx,
            float(value) + 0.001,
            f"{value * 100:.1f}%",
            ha="center",
            va="bottom",
            fontsize=9,
            color="#2f2f2f",
        )


def plot_critical_mass(frame: pd.DataFrame) -> dict[str, float]:
    FIGURE_DIR.mkdir(parents=True, exist_ok=True)

    bands = frame.loc[frame["table"].eq("bands_bin")].copy()
    bands["order"] = bands["bucket"].map({label: idx for idx, label in enumerate(BANDS_BIN_ORDER)})
    bands = bands.sort_values("order")

    switchers = frame.loc[frame["table"].eq("switchers_bin")].copy()
    switchers["order"] = switchers["bucket"].map({label: idx for idx, label in enumerate(SWITCHERS_BIN_ORDER)})
    switchers = switchers.sort_values("order")

    y_max = max(float(bands["event_rate"].max()), float(switchers["event_rate"].max())) * 1.2
    fig, axes = plt.subplots(1, 2, figsize=(12.5, 5.8), sharey=True)

    axes[0].bar(bands["bucket"], bands["event_rate"], color=BAR_COLORS, edgecolor="#2f2f2f", linewidth=0.8)
    axes[1].bar(
        switchers["bucket"], switchers["event_rate"], color=BAR_COLORS, edgecolor="#2f2f2f", linewidth=0.8
    )

    for ax, title in zip(
        axes,
        ["A. Active local band stock", "B. Multi-band musician depth"],
        strict=True,
    ):
        ax.set_title(title)
        ax.set_ylim(0, y_max)
        ax.yaxis.set_major_formatter(mtick.PercentFormatter(xmax=1.0))
        ax.grid(axis="y", linestyle="--", alpha=0.8)
        ax.grid(axis="x", visible=False)
        ax.spines["top"].set_visible(False)
        ax.spines["right"].set_visible(False)

    axes[0].set_ylabel("Exact-year emergence rate")
    add_bar_labels(axes[0], bands["event_rate"])
    add_bar_labels(axes[1], switchers["event_rate"])

    fig.suptitle(
        "Scene emergence rises sharply once cities reach modest scale and multi-band depth",
        fontsize=14,
        fontweight="bold",
        y=0.98,
    )
    fig.text(
        0.5,
        0.03,
        (
            "Descriptive exact-year rates from the city-genre panel. "
            "Emergence is defined as the year a city reaches its fifth band in a genre family."
        ),
        ha="center",
        fontsize=9,
        color="#3d3d3d",
    )
    fig.tight_layout(rect=(0.02, 0.06, 0.98, 0.93))
    fig.savefig(CRITICAL_MASS_FIGURE_PATH, dpi=220)
    plt.close(fig)

    return {
        "bands_low": float(bands.iloc[0]["event_rate"]),
        "bands_high": float(bands.iloc[-1]["event_rate"]),
        "switchers_low": float(switchers.iloc[0]["event_rate"]),
        "switchers_high": float(switchers.iloc[-1]["event_rate"]),
    }


def write_summary(preferred_meta: dict[str, float], critical_mass_meta: dict[str, float]) -> None:
    lines = [
        "# Scene presentation figures",
        "",
        "This file records the active paper-facing figure package for the scene branch.",
        "",
        "## Generated figures",
        "",
        f"- `figures/{PREFERRED_FIGURE_PATH.name}`",
        "  - single-panel headline coefficient plot for the preferred core exact-year FE specification",
        f"  - headline core R-squared: `{preferred_meta['core_r2']:.4f}`",
        "",
        f"- `figures/{CRITICAL_MASS_FIGURE_PATH.name}`",
        "  - descriptive emergence-rate bars for active-band stock and multi-band musician depth",
        f"  - active-band bins rise from `{critical_mass_meta['bands_low'] * 100:.1f}%` to `{critical_mass_meta['bands_high'] * 100:.1f}%`",
        f"  - multi-band bins rise from `{critical_mass_meta['switchers_low'] * 100:.1f}%` to `{critical_mass_meta['switchers_high'] * 100:.1f}%`",
        "",
        "## Current read",
        "",
        "- The descriptive figure makes the critical-mass pattern visually obvious before the reader sees the regression table.",
        "- The coefficient figure now isolates the clean headline terms: local spawning flow, target-genre band stock, and target-genre multi-band depth.",
        "- Connector or broker variables are no longer part of the active main-text figure package because they do not provide a clean unconditional paper story.",
    ]
    SUMMARY_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    configure_style()
    preferred_table = load_preferred_table()
    critical_mass = load_critical_mass()
    preferred_meta = plot_preferred_mechanism_coefficients(preferred_table)
    critical_mass_meta = plot_critical_mass(critical_mass)
    write_summary(preferred_meta, critical_mass_meta)
    print(f"Wrote {PREFERRED_FIGURE_PATH}")
    print(f"Wrote {CRITICAL_MASS_FIGURE_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
