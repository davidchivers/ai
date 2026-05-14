from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
BUILD = PROJECT_ROOT / "notes" / "build"


def set_style() -> None:
    plt.rcParams.update(
        {
            "font.family": "serif",
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.titleweight": "bold",
            "axes.titlesize": 12,
            "axes.labelsize": 10,
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
            "legend.fontsize": 9,
        }
    )


def load_summary(path: Path) -> dict[str, float]:
    out: dict[str, float] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        out[key.strip()] = float(value.strip())
    return out


def main() -> None:
    set_style()

    age_profile = pd.read_csv(BUILD / "annual_homeownership_model_age_profile.csv")
    binned_profile = pd.read_csv(BUILD / "annual_homeownership_model_binned_profile.csv")
    acs_targets = pd.read_csv(BUILD / "acs_homeownership_age_target_recent_pool.csv")
    summary = load_summary(BUILD / "annual_homeownership_model_profile_summary.txt")

    fig, ax = plt.subplots(figsize=(9.5, 5.8))

    target_colors = {
        "support_homeownership": "#d7e9f7",
        "validation_homeownership": "#ececec",
    }

    for row in acs_targets.itertuples(index=False):
        bin_start = int(row.target_name.split("_")[2])
        bin_end = int(row.target_name.split("_")[3])
        ax.axvspan(bin_start, bin_end + 1, color=target_colors[row.role], alpha=0.45, lw=0)
        ax.fill_between(
            [bin_start, bin_end + 1],
            [row.lower, row.lower],
            [row.upper, row.upper],
            color="#9ecae1" if row.role == "support_homeownership" else "#d0d0d0",
            alpha=0.35,
            lw=0,
        )
        ax.hlines(row.reference, bin_start, bin_end + 1, color="#355c7d", lw=2.2)

    ax.plot(
        age_profile["age"],
        age_profile["baseline_owner_share"],
        color="#1f1f1f",
        lw=2.0,
        label="Annual anchor smooth profile",
    )
    ax.plot(
        age_profile["age"],
        age_profile["drift_owner_share"],
        color="#b24c2a",
        lw=2.2,
        label="Best drift candidate smooth profile",
    )

    bin_mid = 0.5 * (binned_profile["bin_start"] + binned_profile["bin_end"])
    ax.scatter(
        bin_mid,
        binned_profile["baseline_bin_share"],
        color="#1f1f1f",
        s=32,
        zorder=5,
        label="Annual anchor binned to ACS groups",
    )
    ax.scatter(
        bin_mid,
        binned_profile["drift_bin_share"],
        color="#b24c2a",
        s=34,
        marker="s",
        zorder=5,
        label="Best drift candidate binned to ACS groups",
    )

    ax.set_xlim(25, 75)
    ax.set_ylim(0.2, 0.9)
    ax.set_xlabel("Age")
    ax.set_ylabel("Owner share")
    ax.set_title("Annual model homeownership profile vs. ACS age bins")
    ax.legend(frameon=False, loc="lower right")

    fig.savefig(BUILD / "annual_homeownership_model_data_comparison.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "annual_homeownership_model_data_comparison.pdf", bbox_inches="tight")
    plt.close(fig)

    note = BUILD / "annual_homeownership_model_data_comparison.md"
    with note.open("w", encoding="utf-8") as handle:
        handle.write("# Annual homeownership model-data comparison\n\n")
        handle.write(
            "This figure overlays the smooth annual-model owner-share profile with pooled ACS `B25007` bins.\n"
            "The shaded horizontal ranges are deliberately loose target bands.\n\n"
        )
        handle.write("## Strictness\n\n")
        handle.write("- ACS object: age of householder, not female age\n")
        handle.write("- scored support bins: `25-34`, `35-44`, `45-54`\n")
        handle.write("- validation-only bins: `55-64`, `65-74`\n")
        handle.write("- interpretation: diagnostic shape comparison, not a knife-edge calibration target\n\n")
        handle.write("## Model lines\n\n")
        handle.write(f"- annual anchor eval vote: `{summary['baseline_vote']:.3f}`\n")
        handle.write(
            f"- best drift candidate eval vote: `{summary['drift_vote']:.3f}` "
            f"with drift weight `{summary['drift_weight']:.2f}` and future price factor `{summary['future_price_factor']:.2f}`\n"
        )
        handle.write("- circles/squares show the model collapsed back into the same ACS bins\n")


if __name__ == "__main__":
    main()
