"""Build a CPS self-employment companion series from official FRED/BLS-backed data.

Series:
- LNU02027714: self-employed, unincorporated
- LNU02048984: self-employed, incorporated
- LNU02000000: employment level, 16 years and over
- USREC: recession indicator

All outputs remain in data_laptop/ and do not touch canonical project status files.
"""

from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import pandas as pd


START_YEAR = 2000
END_YEAR = 2022
OUT_DIR = Path(__file__).resolve().parent

OUT_MONTHLY_CSV = OUT_DIR / "us_self_employment_rates_monthly.csv"
OUT_ANNUAL_CSV = OUT_DIR / "us_self_employment_rates_annual.csv"
OUT_PNG = OUT_DIR / "us_self_employment_rates_annual.png"
OUT_MD = OUT_DIR / "self_employment_recession_windows.md"

FRED_URL = (
    "https://fred.stlouisfed.org/graph/fredgraph.csv?"
    "id=LNU02027714,LNU02048984,LNU02000000,USREC"
)


def load_monthly() -> pd.DataFrame:
    df = pd.read_csv(FRED_URL, parse_dates=["observation_date"])
    df = df.rename(
        columns={
            "observation_date": "date",
            "LNU02027714": "unincorporated_self_employed",
            "LNU02048984": "incorporated_self_employed",
            "LNU02000000": "employment_total",
            "USREC": "recession_flag",
        }
    )
    df["year"] = df["date"].dt.year
    df["month"] = df["date"].dt.month
    df = df[(df["year"] >= START_YEAR) & (df["year"] <= END_YEAR)].copy()
    df = df.dropna(
        subset=[
            "unincorporated_self_employed",
            "incorporated_self_employed",
            "employment_total",
        ]
    )

    df["self_employed_total"] = (
        df["unincorporated_self_employed"] + df["incorporated_self_employed"]
    )
    df["rate_unincorporated"] = (
        100 * df["unincorporated_self_employed"] / df["employment_total"]
    )
    df["rate_incorporated"] = 100 * df["incorporated_self_employed"] / df["employment_total"]
    df["rate_total"] = 100 * df["self_employed_total"] / df["employment_total"]

    return df


def annualize(monthly: pd.DataFrame) -> pd.DataFrame:
    annual = (
        monthly.groupby("year", as_index=False)
        .agg(
            unincorporated_self_employed=("unincorporated_self_employed", "mean"),
            incorporated_self_employed=("incorporated_self_employed", "mean"),
            self_employed_total=("self_employed_total", "mean"),
            employment_total=("employment_total", "mean"),
            rate_unincorporated=("rate_unincorporated", "mean"),
            rate_incorporated=("rate_incorporated", "mean"),
            rate_total=("rate_total", "mean"),
            recession_any=("recession_flag", "max"),
            recession_months=("recession_flag", "sum"),
        )
        .sort_values("year")
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
        ("rate_total", "Total self-employment", "#1f4e79"),
        ("rate_unincorporated", "Unincorporated", "#b35a1f"),
        ("rate_incorporated", "Incorporated", "#2e8b57"),
    ]
    for col, label, color in series:
        ax.plot(annual["year"], annual[col], label=label, color=color, linewidth=2.2)

    ax.set_title("US self-employment rates")
    ax.set_ylabel("Share of employment (%)")
    ax.set_xlabel("")
    ax.grid(axis="y", alpha=0.25, linewidth=0.7)
    ax.legend(frameon=False, loc="best")
    set_year_axis(ax)

    note = (
        "Annual averages of monthly CPS-based employment levels from FRED/BLS; shaded years "
        "include recession months from USREC."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=8)
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(OUT_PNG, dpi=300, facecolor="white")
    plt.close(fig)


def write_summary(annual: pd.DataFrame) -> None:
    windows = [
        ("2000-2002 recession window", 2000, 2002),
        ("2007-2010 Great Recession window", 2007, 2010),
        ("2019-2022 pandemic window", 2019, 2022),
    ]
    series = [
        ("rate_total", "Total self-employment"),
        ("rate_unincorporated", "Unincorporated"),
        ("rate_incorporated", "Incorporated"),
    ]

    annual = annual.set_index("year")
    lines = [
        "# Self-employment recession windows",
        "",
        "Annual-average CPS self-employment rates from the person-level companion series.",
        "",
    ]
    for label, start, end in windows:
        lines.append(f"## {label}")
        lines.append("")
        for col, display in series:
            start_val = annual.loc[start, col]
            end_val = annual.loc[end, col]
            lines.append(
                f"- `{display}`: {start_val:.2f}% -> {end_val:.2f}% "
                f"({end_val - start_val:+.2f} percentage points)"
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
