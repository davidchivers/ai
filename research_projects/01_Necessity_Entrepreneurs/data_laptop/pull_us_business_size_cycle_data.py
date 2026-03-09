"""Build an annual US business-count dataset by employment size for motivation figures.

Series design:
- 0 employees: Census Nonemployer Statistics (nonemployer establishments)
- 1-4, 5-19, 20+ employees: Census Business Dynamics Statistics establishment counts
- recession flag: FRED USREC monthly indicator aggregated to annual any-recession flag

This script is intentionally isolated in data_laptop/ so it does not affect the
canonical project status workflow.
"""

from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import pandas as pd
import requests


START_YEAR = 1997
END_YEAR = 2022

OUT_DIR = Path(__file__).resolve().parent
OUT_CSV = OUT_DIR / "us_business_counts_by_size_annual.csv"
OUT_INDEXED_PNG = OUT_DIR / "us_business_counts_by_size_indexed.png"
OUT_LEVELS_PNG = OUT_DIR / "us_business_counts_by_size_levels.png"
OUT_SHARES_PNG = OUT_DIR / "us_business_counts_by_size_shares.png"
OUT_AGGREGATE_PNG = OUT_DIR / "us_business_counts_aggregate_indexed.png"
OUT_RECESSION_CSV = OUT_DIR / "recession_window_changes.csv"
OUT_RECESSION_MD = OUT_DIR / "recession_window_changes.md"
OUT_AGGREGATE_TEX = OUT_DIR / "aggregate_recession_window_changes.tex"

FRED_USREC_URL = "https://fred.stlouisfed.org/graph/fredgraph.csv?id=USREC"
BDS_URL = "https://api.census.gov/data/timeseries/bds"

SESSION = requests.Session()
SESSION.headers.update({"User-Agent": "Codex data_laptop pull"})


def fetch_json(url: str, params: dict | None = None) -> list:
    response = SESSION.get(url, params=params, timeout=60)
    response.raise_for_status()
    return response.json()


def detect_nonemp_naics_var(year: int) -> str:
    meta = fetch_json(f"https://api.census.gov/data/{year}/nonemp/variables.json")
    variables = meta["variables"]
    candidates = [
        key
        for key in variables
        if key.startswith("NAICS")
        and not key.endswith("_TTL")
        and not key.endswith("_LABEL")
        and not key.endswith("_F")
    ]
    if not candidates:
        raise RuntimeError(f"No NAICS variable found for nonemp {year}")
    return sorted(candidates, key=len)[0]


def fetch_nonemployer_counts() -> pd.DataFrame:
    rows = []
    for year in range(START_YEAR, END_YEAR + 1):
        naics_var = detect_nonemp_naics_var(year)
        data = fetch_json(
            f"https://api.census.gov/data/{year}/nonemp",
            params={
                "get": f"NESTAB,{naics_var}",
                # Older nonemp endpoints respond for national totals with `us:*`.
                "for": "us:*",
                naics_var: "00",
            },
        )
        value = int(data[1][0])
        rows.append({"year": year, "establishments_0": value})
    return pd.DataFrame(rows)


def fetch_bds_establishment_bins() -> pd.DataFrame:
    data = fetch_json(
        BDS_URL,
        params={
            "get": "YEAR,EMPSZES,EMPSZES_LABEL,ESTAB",
            "for": "us:1",
            "NAICS": "00",
            "EMPSZES": "*",
            "time": f"from {START_YEAR} to {END_YEAR}",
        },
    )
    df = pd.DataFrame(data[1:], columns=data[0])
    df = df.loc[:, ~df.columns.duplicated()].copy()
    df["YEAR"] = df["YEAR"].astype(int)
    df["ESTAB"] = df["ESTAB"].astype(int)

    # Use aggregate codes when available to minimize hand-built summation logic.
    keep_codes = {
        "212": "establishments_1_4",
        "233": "establishments_1_19",
        "220": "establishments_5_9",
        "230": "establishments_10_19",
        "250": "establishments_20_499",
        "253": "establishments_500_plus",
    }
    subset = df[df["EMPSZES"].isin(keep_codes)].copy()
    subset["series"] = subset["EMPSZES"].map(keep_codes)

    pivot = subset.pivot(index="YEAR", columns="series", values="ESTAB").reset_index()
    pivot = pivot.rename(columns={"YEAR": "year"})

    pivot["establishments_5_19"] = (
        pivot["establishments_5_9"] + pivot["establishments_10_19"]
    )
    pivot["establishments_20_plus"] = (
        pivot["establishments_20_499"] + pivot["establishments_500_plus"]
    )

    return pivot[
        [
            "year",
            "establishments_1_4",
            "establishments_5_19",
            "establishments_20_plus",
        ]
    ].sort_values("year")


def fetch_recession_flags() -> pd.DataFrame:
    fred = pd.read_csv(FRED_USREC_URL, parse_dates=["observation_date"])
    fred["year"] = fred["observation_date"].dt.year
    fred = fred[(fred["year"] >= START_YEAR) & (fred["year"] <= END_YEAR)].copy()

    annual = (
        fred.groupby("year", as_index=False)
        .agg(
            recession_any=("USREC", "max"),
            recession_months=("USREC", "sum"),
            recession_share=("USREC", "mean"),
        )
        .sort_values("year")
    )
    return annual


def add_derived_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    level_cols = [
        "establishments_0",
        "establishments_1_4",
        "establishments_5_19",
        "establishments_20_plus",
    ]
    df["employer_total"] = (
        df["establishments_1_4"] + df["establishments_5_19"] + df["establishments_20_plus"]
    )
    df["establishments_all_bins"] = df[level_cols].sum(axis=1)

    derived_level_cols = level_cols + ["employer_total", "establishments_all_bins"]
    for col in derived_level_cols:
        df[f"{col}_millions"] = df[col] / 1_000_000
        base = df.loc[df["year"] == START_YEAR, col].iloc[0]
        df[f"{col}_index_{START_YEAR}"] = 100 * df[col] / base

    for col in level_cols:
        df[f"{col}_share_all_bins"] = df[col] / df["establishments_all_bins"]

    return df


def shade_recession_years(ax: plt.Axes, df: pd.DataFrame) -> None:
    for _, row in df[df["recession_any"] == 1].iterrows():
        ax.axvspan(row["year"] - 0.5, row["year"] + 0.5, color="#d9d9d9", alpha=0.35)


def set_year_axis(ax: plt.Axes) -> None:
    ticks = list(range(START_YEAR, END_YEAR + 1, 5))
    if ticks[-1] != END_YEAR:
        ticks.append(END_YEAR)
    ax.set_xlim(START_YEAR, END_YEAR)
    ax.set_xticks(ticks)
    ax.xaxis.set_major_formatter(mticker.FormatStrFormatter("%.0f"))


def write_indexed_figure(df: pd.DataFrame) -> None:
    series = [
        ("establishments_0_index_1997", "0 employees", "#1f4e79"),
        ("establishments_1_4_index_1997", "1-4 employees", "#2e8b57"),
        ("establishments_5_19_index_1997", "5-19 employees", "#b35a1f"),
        ("establishments_20_plus_index_1997", "20+ employees", "#a63d40"),
    ]

    fig, ax = plt.subplots(figsize=(9.2, 5.2))
    shade_recession_years(ax, df)

    for col, label, color in series:
        ax.plot(
            df["year"],
            df[col],
            label=label,
            color=color,
            linewidth=2.2,
        )

    ax.set_title("US business counts by employment size")
    ax.set_ylabel(f"Index ({START_YEAR}=100)")
    ax.set_xlabel("")
    ax.grid(axis="y", alpha=0.25, linewidth=0.7)
    ax.legend(frameon=False, ncol=2, loc="upper left")
    set_year_axis(ax)

    note = (
        "0 employees = Census Nonemployer Statistics; positive-employment bins = Census BDS "
        "establishment counts; shaded years include recession months from FRED USREC."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=8)
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(OUT_INDEXED_PNG, dpi=300, facecolor="white")
    plt.close(fig)


def write_levels_figure(df: pd.DataFrame) -> None:
    series = [
        ("establishments_0_millions", "0 employees", "#1f4e79"),
        ("establishments_1_4_millions", "1-4 employees", "#2e8b57"),
        ("establishments_5_19_millions", "5-19 employees", "#b35a1f"),
        ("establishments_20_plus_millions", "20+ employees", "#a63d40"),
    ]

    fig, ax = plt.subplots(figsize=(9.2, 5.2))
    shade_recession_years(ax, df)

    for col, label, color in series:
        ax.plot(df["year"], df[col], label=label, color=color, linewidth=2.2)

    ax.set_title("US business counts by employment size")
    ax.set_ylabel("Establishments (millions)")
    ax.set_xlabel("")
    ax.grid(axis="y", alpha=0.25, linewidth=0.7)
    ax.legend(frameon=False, ncol=2, loc="upper left")
    set_year_axis(ax)

    note = (
        "Levels mix nonemployer establishments for 0 employees with BDS establishment counts for "
        "positive-employment bins; use mainly for visual scale comparisons."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=8)
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(OUT_LEVELS_PNG, dpi=300, facecolor="white")
    plt.close(fig)


def write_share_figure(df: pd.DataFrame) -> None:
    series = [
        ("establishments_0_share_all_bins", "0 employees", "#1f4e79"),
        ("establishments_1_4_share_all_bins", "1-4 employees", "#2e8b57"),
        ("establishments_5_19_share_all_bins", "5-19 employees", "#b35a1f"),
        ("establishments_20_plus_share_all_bins", "20+ employees", "#a63d40"),
    ]

    fig, ax = plt.subplots(figsize=(9.2, 5.2))
    shade_recession_years(ax, df)

    for col, label, color in series:
        ax.plot(df["year"], 100 * df[col], label=label, color=color, linewidth=2.2)

    ax.set_title("US business-size shares within tracked bins")
    ax.set_ylabel("Share of tracked bins (%)")
    ax.set_xlabel("")
    ax.grid(axis="y", alpha=0.25, linewidth=0.7)
    ax.legend(frameon=False, ncol=2, loc="best")
    set_year_axis(ax)

    note = (
        "Tracked-bin denominator is 0, 1-4, 5-19, and 20+ employees only; shares are useful for "
        "composition changes but do not represent the full business universe."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=8)
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(OUT_SHARES_PNG, dpi=300, facecolor="white")
    plt.close(fig)


def write_aggregate_figure(df: pd.DataFrame) -> None:
    series = [
        ("establishments_all_bins_index_1997", "All tracked bins", "#3a3a3a"),
        ("employer_total_index_1997", "Employer total", "#2e8b57"),
        ("establishments_0_index_1997", "0 employees", "#1f4e79"),
    ]

    fig, ax = plt.subplots(figsize=(9.2, 5.2))
    shade_recession_years(ax, df)

    for col, label, color in series:
        ax.plot(df["year"], df[col], label=label, color=color, linewidth=2.2)

    ax.set_title("US aggregate business counts")
    ax.set_ylabel(f"Index ({START_YEAR}=100)")
    ax.set_xlabel("")
    ax.grid(axis="y", alpha=0.25, linewidth=0.7)
    ax.legend(frameon=False, loc="upper left")
    set_year_axis(ax)

    note = (
        "All tracked bins = 0, 1-4, 5-19, and 20+ employees; employer total excludes the "
        "0-employee series."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=8)
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(OUT_AGGREGATE_PNG, dpi=300, facecolor="white")
    plt.close(fig)


def write_recession_change_summary(df: pd.DataFrame) -> None:
    level_cols = [
        "establishments_0",
        "establishments_1_4",
        "establishments_5_19",
        "establishments_20_plus",
        "employer_total",
        "establishments_all_bins",
    ]
    windows = [
        ("2000-2002 recession window", 2000, 2002),
        ("2007-2010 Great Recession window", 2007, 2010),
        ("2019-2022 pandemic window", 2019, 2022),
    ]

    rows = []
    indexed = df.set_index("year")
    for label, start, end in windows:
        for col in level_cols:
            start_val = indexed.loc[start, col]
            end_val = indexed.loc[end, col]
            rows.append(
                {
                    "window": label,
                    "start_year": start,
                    "end_year": end,
                    "series": col,
                    "start_value": int(start_val),
                    "end_value": int(end_val),
                    "absolute_change": int(end_val - start_val),
                    "pct_change": 100 * (end_val / start_val - 1),
                }
            )

    summary = pd.DataFrame(rows)
    summary.to_csv(OUT_RECESSION_CSV, index=False)

    display_names = {
        "establishments_0": "0 employees",
        "establishments_1_4": "1-4 employees",
        "establishments_5_19": "5-19 employees",
        "establishments_20_plus": "20+ employees",
        "employer_total": "Employer total",
        "establishments_all_bins": "All tracked bins",
    }
    lines = [
        "# Recession-window changes",
        "",
        "Annual window comparisons from the sidecar establishment-count dataset.",
        "",
    ]
    for label, start, end in windows:
        lines.append(f"## {label}")
        lines.append("")
        subset = summary[summary["window"] == label].copy()
        for _, row in subset.iterrows():
            series_name = display_names[row["series"]]
            lines.append(
                f"- `{series_name}`: {row['start_value']:,} -> {row['end_value']:,} "
                f"({row['pct_change']:.2f}%)"
            )
        lines.append("")

    OUT_RECESSION_MD.write_text("\n".join(lines), encoding="utf-8")

    tex_lines = [
        "% Auto-generated by pull_us_business_size_cycle_data.py",
        "\\begin{tabular}{llrr}",
        "\\hline",
        "Window & Series & Start value & Percent change \\\\",
        "\\hline",
    ]
    tex_windows = [
        "2007-2010 Great Recession window",
        "2019-2022 pandemic window",
    ]
    tex_series = [
        "establishments_all_bins",
        "employer_total",
        "establishments_0",
        "establishments_1_4",
        "establishments_5_19",
        "establishments_20_plus",
    ]
    for window in tex_windows:
        subset = summary[summary["window"] == window]
        for series in tex_series:
            row = subset[subset["series"] == series].iloc[0]
            tex_lines.append(
                f"{window} & {display_names[series]} & {row['start_value']:,} & {row['pct_change']:.2f}\\% \\\\"
            )
    tex_lines.extend(["\\hline", "\\end{tabular}", ""])
    OUT_AGGREGATE_TEX.write_text("\n".join(tex_lines), encoding="utf-8")


def main() -> None:
    nonemp = fetch_nonemployer_counts()
    bds = fetch_bds_establishment_bins()
    recessions = fetch_recession_flags()

    df = nonemp.merge(bds, on="year", how="inner").merge(recessions, on="year", how="inner")
    df = add_derived_columns(df)
    df.to_csv(OUT_CSV, index=False)
    write_indexed_figure(df)
    write_levels_figure(df)
    write_share_figure(df)
    write_aggregate_figure(df)
    write_recession_change_summary(df)

    print(f"Wrote {OUT_CSV}")
    print(f"Wrote {OUT_INDEXED_PNG}")
    print(f"Wrote {OUT_LEVELS_PNG}")
    print(f"Wrote {OUT_SHARES_PNG}")
    print(f"Wrote {OUT_AGGREGATE_PNG}")
    print(f"Wrote {OUT_RECESSION_CSV}")
    print(f"Wrote {OUT_RECESSION_MD}")
    print(f"Wrote {OUT_AGGREGATE_TEX}")


if __name__ == "__main__":
    main()
