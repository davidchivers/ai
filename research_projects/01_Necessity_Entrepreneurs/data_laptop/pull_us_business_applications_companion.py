"""Build a business-applications flow companion from Census BFS via FRED.

Series:
- BABATOTALSAUS: Business Applications, Total for All NAICS
- BAHBATOTALSAUS: High-Propensity Business Applications, Total for All NAICS
- USREC: recession indicator
"""

from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import pandas as pd


START_YEAR = 2005
END_YEAR = 2025
OUT_DIR = Path(__file__).resolve().parent

OUT_MONTHLY_CSV = OUT_DIR / "us_business_applications_monthly.csv"
OUT_ANNUAL_CSV = OUT_DIR / "us_business_applications_annual.csv"
OUT_PNG = OUT_DIR / "us_business_applications_indexed.png"
OUT_MD = OUT_DIR / "business_applications_recession_windows.md"

FRED_URL = (
    "https://fred.stlouisfed.org/graph/fredgraph.csv?"
    "id=BABATOTALSAUS,BAHBATOTALSAUS,USREC"
)


def load_monthly() -> pd.DataFrame:
    df = pd.read_csv(FRED_URL, parse_dates=["observation_date"])
    df = df.rename(
        columns={
            "observation_date": "date",
            "BABATOTALSAUS": "applications_total",
            "BAHBATOTALSAUS": "applications_high_propensity",
            "USREC": "recession_flag",
        }
    )
    df["year"] = df["date"].dt.year
    df["month"] = df["date"].dt.month
    df = df[(df["year"] >= START_YEAR) & (df["year"] <= END_YEAR)].copy()
    df = df.dropna(subset=["applications_total", "applications_high_propensity"])
    return df


def annualize(monthly: pd.DataFrame) -> pd.DataFrame:
    annual = (
        monthly.groupby("year", as_index=False)
        .agg(
            applications_total=("applications_total", "sum"),
            applications_high_propensity=("applications_high_propensity", "sum"),
            recession_any=("recession_flag", "max"),
            recession_months=("recession_flag", "sum"),
        )
        .sort_values("year")
    )
    annual["high_propensity_share"] = (
        annual["applications_high_propensity"] / annual["applications_total"]
    )

    base_total = annual.loc[annual["year"] == START_YEAR, "applications_total"].iloc[0]
    base_hba = annual.loc[
        annual["year"] == START_YEAR, "applications_high_propensity"
    ].iloc[0]
    annual["applications_total_index_2005"] = 100 * annual["applications_total"] / base_total
    annual["applications_high_propensity_index_2005"] = (
        100 * annual["applications_high_propensity"] / base_hba
    )
    return annual


def shade_recession_years(ax: plt.Axes, annual: pd.DataFrame) -> None:
    for _, row in annual[annual["recession_any"] == 1].iterrows():
        ax.axvspan(row["year"] - 0.5, row["year"] + 0.5, color="#d9d9d9", alpha=0.35)


def set_year_axis(ax: plt.Axes) -> None:
    ticks = list(range(START_YEAR, END_YEAR + 1, 5))
    if ticks[-1] != END_YEAR:
        ticks.append(END_YEAR)
    ax.set_xlim(START_YEAR, END_YEAR)
    ax.set_xticks(ticks)
    ax.xaxis.set_major_formatter(mticker.FormatStrFormatter("%.0f"))


def write_figure(annual: pd.DataFrame) -> None:
    fig, ax = plt.subplots(figsize=(9.2, 5.2))
    shade_recession_years(ax, annual)

    series = [
        ("applications_total_index_2005", "Total applications", "#1f4e79"),
        (
            "applications_high_propensity_index_2005",
            "High-propensity applications",
            "#b35a1f",
        ),
    ]
    for col, label, color in series:
        ax.plot(annual["year"], annual[col], label=label, color=color, linewidth=2.2)

    ax.set_title("US business applications")
    ax.set_ylabel(f"Index ({START_YEAR}=100)")
    ax.set_xlabel("")
    ax.grid(axis="y", alpha=0.25, linewidth=0.7)
    ax.legend(frameon=False, loc="best")
    set_year_axis(ax)

    note = (
        "Annual sums of monthly seasonally adjusted Census Business Formation Statistics series "
        "from FRED; shaded years include recession months from USREC."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=8)
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(OUT_PNG, dpi=300, facecolor="white")
    plt.close(fig)


def write_summary(annual: pd.DataFrame) -> None:
    windows = [
        ("2007-2010 Great Recession window", 2007, 2010),
        ("2019-2022 pandemic window", 2019, 2022),
    ]
    annual = annual.set_index("year")

    lines = [
        "# Business applications recession windows",
        "",
        "Annual sums of Census Business Formation Statistics from the flow-side companion series.",
        "",
    ]
    for label, start, end in windows:
        lines.append(f"## {label}")
        lines.append("")
        total_start = annual.loc[start, "applications_total"]
        total_end = annual.loc[end, "applications_total"]
        hba_start = annual.loc[start, "applications_high_propensity"]
        hba_end = annual.loc[end, "applications_high_propensity"]
        share_start = annual.loc[start, "high_propensity_share"]
        share_end = annual.loc[end, "high_propensity_share"]

        lines.append(
            f"- `Total applications`: {int(total_start):,} -> {int(total_end):,} "
            f"({100 * (total_end / total_start - 1):+.2f}%)"
        )
        lines.append(
            f"- `High-propensity applications`: {int(hba_start):,} -> {int(hba_end):,} "
            f"({100 * (hba_end / hba_start - 1):+.2f}%)"
        )
        lines.append(
            f"- `High-propensity share`: {100 * share_start:.2f}% -> {100 * share_end:.2f}% "
            f"({100 * (share_end - share_start):+.2f} percentage points)"
        )
        lines.append("")

    OUT_MD.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    monthly = load_monthly()
    annual = annualize(monthly)

    monthly.to_csv(OUT_MONTHLY_CSV, index=False)
    annual.to_csv(OUT_ANNUAL_CSV, index=False)
    write_figure(annual)
    write_summary(annual)

    print(f"Wrote {OUT_MONTHLY_CSV}")
    print(f"Wrote {OUT_ANNUAL_CSV}")
    print(f"Wrote {OUT_PNG}")
    print(f"Wrote {OUT_MD}")


if __name__ == "__main__":
    main()
