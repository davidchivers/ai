#!/usr/bin/env python3
"""Build a direct-CDC review of annual first-birth timing targets."""

from __future__ import annotations

import re
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
CODE = ROOT / "code"
RAW = ROOT / "data" / "raw"
BUILD = ROOT / "notes" / "build"

STATE_YEAR_PATH = RAW / "cdc_fertility_state_year.csv"
COUNTY_YEAR_PATH = RAW / "cdc_fertility_county_year.csv"
RAW_EXPORT_PATH = RAW / "cdc_wonder_first_births_state_year_export.csv"
MATLAB_CONFIG_PATH = CODE / "fertility_benchmark_config.m"

RECENT_START = 2020
RECENT_END = 2024

AGE_25_PLUS_MAP = {
    "25-29 years": "25-29",
    "30-34 years": "30-34",
    "35-39 years": "35-39",
    "40-44 years": "40-44+",
    "45-49 years": "40-44+",
    "50 years and over": "40-44+",
}
AGE_25_PLUS_ORDER = ["25-29", "30-34", "35-39", "40-44+"]


def set_style() -> None:
    plt.rcParams.update(
        {
            "font.family": "serif",
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.titleweight": "bold",
            "axes.titlesize": 11,
            "axes.labelsize": 10,
            "xtick.labelsize": 9,
            "ytick.labelsize": 9,
            "legend.fontsize": 8.5,
        }
    )


def load_numeric_csv(path: Path, columns: list[str]) -> pd.DataFrame:
    df = pd.read_csv(path, low_memory=False)
    for column in columns:
        if column in df.columns:
            df[column] = pd.to_numeric(df[column], errors="coerce")
    return df


def load_state_year_panel() -> pd.DataFrame:
    numeric = [
        "year",
        "first_births_total",
        "mean_age_first_birth",
        "share_first_birth_30_plus",
    ]
    return load_numeric_csv(STATE_YEAR_PATH, numeric)


def load_county_year_panel() -> pd.DataFrame:
    numeric = [
        "year",
        "first_births_total",
        "mean_age_first_birth",
        "share_first_birth_30_plus",
    ]
    return load_numeric_csv(COUNTY_YEAR_PATH, numeric)


def load_raw_state_year_export() -> pd.DataFrame:
    df = pd.read_csv(RAW_EXPORT_PATH, dtype=str, low_memory=False)
    df["Year"] = pd.to_numeric(df.get("Year"), errors="coerce")
    df["Births"] = pd.to_numeric(df.get("Births"), errors="coerce")
    df = df[df["Year"].notna() & df["Births"].notna()].copy()
    age_col = next(col for col in df.columns if col.startswith("Age of Mother") and not col.endswith("Code"))
    df["age_label"] = df[age_col].fillna("").astype(str).str.strip()
    return df


def build_national_series(df: pd.DataFrame) -> pd.DataFrame:
    work = df.copy()
    work["weighted_age"] = work["mean_age_first_birth"] * work["first_births_total"]
    work["weighted_share30"] = work["share_first_birth_30_plus"] * work["first_births_total"]
    out = (
        work.groupby("year", as_index=False)
        .agg(
            first_births_total=("first_births_total", "sum"),
            weighted_age=("weighted_age", "sum"),
            weighted_share30=("weighted_share30", "sum"),
        )
        .sort_values("year")
        .reset_index(drop=True)
    )
    out["mean_age_first_birth"] = out["weighted_age"] / out["first_births_total"]
    out["share_first_birth_30_plus"] = out["weighted_share30"] / out["first_births_total"]
    return out.drop(columns=["weighted_age", "weighted_share30"])


def build_validation_table(state_national: pd.DataFrame, county_national: pd.DataFrame) -> pd.DataFrame:
    comp = state_national.merge(
        county_national,
        on="year",
        suffixes=("_state", "_county"),
    )
    comp["births_gap"] = comp["first_births_total_state"] - comp["first_births_total_county"]
    comp["mean_age_gap"] = comp["mean_age_first_birth_state"] - comp["mean_age_first_birth_county"]
    comp["share30_gap"] = comp["share_first_birth_30_plus_state"] - comp["share_first_birth_30_plus_county"]
    return comp


def build_recent_age_targets(raw_export: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    work = raw_export.copy()
    work = work[work["age_label"].isin(AGE_25_PLUS_MAP)].copy()
    work["bucket"] = work["age_label"].map(AGE_25_PLUS_MAP)

    annual_rows: list[dict[str, float | int]] = []
    for year, group in work.groupby("Year"):
        bucket_totals = group.groupby("bucket", as_index=False)["Births"].sum()
        total = float(bucket_totals["Births"].sum())
        row: dict[str, float | int] = {"year": int(year)}
        for bucket in AGE_25_PLUS_ORDER:
            births = float(bucket_totals.loc[bucket_totals["bucket"] == bucket, "Births"].sum())
            row[bucket] = births / total if total > 0 else float("nan")
        annual_rows.append(row)

    annual = pd.DataFrame(annual_rows).sort_values("year").reset_index(drop=True)
    recent = annual[annual["year"].between(RECENT_START, RECENT_END)].copy()

    pooled = (
        work[work["Year"].between(RECENT_START, RECENT_END)]
        .groupby("bucket", as_index=False)["Births"]
        .sum()
    )
    pooled["share_25_plus"] = pooled["Births"] / pooled["Births"].sum()
    pooled = pooled.set_index("bucket").reindex(AGE_25_PLUS_ORDER).reset_index()
    return annual, pooled


def load_current_code_target() -> pd.DataFrame:
    text = MATLAB_CONFIG_PATH.read_text(encoding="utf-8")
    match = re.search(
        r"cfg\.target_first_birth_age_share_25plus\s*=\s*\[([^\]]+)\];",
        text,
    )
    if match is None:
        raise ValueError("Could not parse current MATLAB first-birth timing target.")
    values = [float(x) for x in re.findall(r"-?\d+(?:\.\d+)?", match.group(1))]
    if len(values) != 4:
        raise ValueError("Expected four 25+ timing shares in MATLAB target.")
    return pd.DataFrame(
        {
            "bucket": AGE_25_PLUS_ORDER,
            "current_code_target": values,
        }
    )


def build_recommendation_table(
    national_series: pd.DataFrame,
    annual_25plus: pd.DataFrame,
    pooled_target: pd.DataFrame,
    current_target: pd.DataFrame,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    recent = national_series[national_series["year"].between(RECENT_START, RECENT_END)].copy()
    timing_rows = [
        {
            "object": "mean_age_first_birth",
            "recommended_weight": "hard",
            "recent_mean": float(recent["mean_age_first_birth"].mean()),
            "recent_sd": float(recent["mean_age_first_birth"].std()),
            "suggested_band_half_width": 2.0 * float(recent["mean_age_first_birth"].std()),
            "comment": "Direct annual timing level from fresh CDC pull; stable enough to anchor the annual model.",
        },
        {
            "object": "share_first_birth_30_plus",
            "recommended_weight": "hard",
            "recent_mean": float(recent["share_first_birth_30_plus"].mean()),
            "recent_sd": float(recent["share_first_birth_30_plus"].std()),
            "suggested_band_half_width": 2.0 * float(recent["share_first_birth_30_plus"].std()),
            "comment": "Clean annual timing share from the same CDC pull; useful as a level target with a modest tolerance band.",
        },
    ]
    timing_table = pd.DataFrame(timing_rows)

    bins = pooled_target.merge(current_target, on="bucket", how="left")
    recent_sd = (
        annual_25plus.loc[annual_25plus["year"].between(RECENT_START, RECENT_END), ["25-29", "30-34", "35-39", "40-44+"]]
        .std()
        .rename_axis("bucket")
        .reset_index(name="recent_sd")
    )
    bins = bins.merge(recent_sd, on="bucket", how="left")
    bins["gap_data_minus_code"] = bins["share_25_plus"] - bins["current_code_target"]
    bins["recommended_weight"] = "medium"
    bins["comment"] = (
        "Useful pooled timing-shape target, but grouped-age and top-coded in the highest bin, so better as a loose anchor than a knife-edge requirement."
    )
    return timing_table, bins


def plot_review(
    national_series: pd.DataFrame,
    annual_25plus: pd.DataFrame,
    pooled_bins: pd.DataFrame,
) -> None:
    set_style()
    fig, axes = plt.subplots(2, 2, figsize=(11.2, 8.8), constrained_layout=True)

    c_data = "#275d8c"
    c_alt = "#b24c2a"
    c_green = "#5d7f1f"
    c_gold = "#aa7a16"
    c_pink = "#a24376"

    ax = axes[0, 0]
    ax.plot(national_series["year"], national_series["mean_age_first_birth"], color=c_data, lw=2.4)
    ax.axhline(
        national_series.loc[national_series["year"].between(RECENT_START, RECENT_END), "mean_age_first_birth"].mean(),
        color=c_alt,
        lw=1.6,
        ls="--",
        label=f"{RECENT_START}-{RECENT_END} mean",
    )
    ax.set_title("National Mean Age At First Birth")
    ax.set_xlabel("Year")
    ax.set_ylabel("Years")
    ax.legend(frameon=False, loc="upper left")

    ax = axes[0, 1]
    ax.plot(national_series["year"], national_series["share_first_birth_30_plus"], color=c_alt, lw=2.4)
    ax.axhline(
        national_series.loc[national_series["year"].between(RECENT_START, RECENT_END), "share_first_birth_30_plus"].mean(),
        color=c_data,
        lw=1.6,
        ls="--",
        label=f"{RECENT_START}-{RECENT_END} mean",
    )
    ax.set_title("National Share Of First Births At Age 30+")
    ax.set_xlabel("Year")
    ax.set_ylabel("Share")
    ax.legend(frameon=False, loc="upper left")

    ax = axes[1, 0]
    palette = {
        "25-29": c_data,
        "30-34": c_alt,
        "35-39": c_green,
        "40-44+": c_gold,
    }
    for bucket in AGE_25_PLUS_ORDER:
        ax.plot(annual_25plus["year"], annual_25plus[bucket], lw=2.0, color=palette[bucket], label=bucket)
    ax.set_title("Within-25+ First-Birth Shares")
    ax.set_xlabel("Year")
    ax.set_ylabel("Share Within Ages 25+")
    ax.legend(frameon=False, ncol=2, loc="upper center")

    ax = axes[1, 1]
    bar_positions = range(len(AGE_25_PLUS_ORDER))
    width = 0.36
    pooled = pooled_bins.set_index("bucket").reindex(AGE_25_PLUS_ORDER)
    ax.bar(
        [x - width / 2 for x in bar_positions],
        pooled["share_25_plus"],
        width=width,
        color=c_pink,
        label=f"CDC pooled {RECENT_START}-{RECENT_END}",
    )
    ax.bar(
        [x + width / 2 for x in bar_positions],
        pooled["current_code_target"],
        width=width,
        color="#9b9b9b",
        label="Current code target",
    )
    ax.set_title("Current Code Target Versus Fresh CDC Pull")
    ax.set_xticks(list(bar_positions))
    ax.set_xticklabels(AGE_25_PLUS_ORDER)
    ax.set_ylabel("Share Within Ages 25+")
    ax.legend(frameon=False, loc="upper right")

    fig.suptitle("CDC First-Birth Timing Target Review", fontsize=14, fontweight="bold")
    fig.savefig(BUILD / "cdc_first_birth_timing_target_review.png", dpi=220, bbox_inches="tight")
    fig.savefig(BUILD / "cdc_first_birth_timing_target_review.pdf", bbox_inches="tight")
    plt.close(fig)


def write_markdown(
    national_series: pd.DataFrame,
    validation: pd.DataFrame,
    pooled_bins: pd.DataFrame,
    timing_table: pd.DataFrame,
    bin_table: pd.DataFrame,
) -> None:
    recent = national_series[national_series["year"].between(RECENT_START, RECENT_END)].copy()
    pooled = pooled_bins.set_index("bucket").reindex(AGE_25_PLUS_ORDER)
    max_abs = validation[["births_gap", "mean_age_gap", "share30_gap"]].abs().max()

    lines = [
        "# CDC first-birth timing target review",
        "",
        "This note uses a fresh direct CDC WONDER state-year pull to review which first-birth timing",
        "objects are sensible annual targets for the fertility model.",
        "",
        "## Main read",
        "",
        f"- Fresh direct pull now exists at `data/raw/cdc_wonder_first_births_state_year_export.csv`, covering `{int(national_series['year'].min())}-{int(national_series['year'].max())}`.",
        f"- The direct state-year pull is extremely close to the existing county-aggregated path: max national annual gap is `{int(max_abs['births_gap'])}` births, `{max_abs['mean_age_gap']:.4f}` years in mean age, and `{max_abs['share30_gap']:.4f}` in share age 30+.",
        f"- National mean age at first birth rises from `{national_series['mean_age_first_birth'].iloc[0]:.3f}` in `{int(national_series['year'].iloc[0])}` to `{national_series['mean_age_first_birth'].iloc[-1]:.3f}` in `{int(national_series['year'].iloc[-1])}`.",
        f"- National share of first births at age 30+ rises from `{national_series['share_first_birth_30_plus'].iloc[0]:.3f}` to `{national_series['share_first_birth_30_plus'].iloc[-1]:.3f}` over the same span.",
        f"- The pooled `{RECENT_START}-{RECENT_END}` direct CDC timing-shape target within ages 25+ is `[25-29: {pooled.loc['25-29', 'share_25_plus']:.3f}, 30-34: {pooled.loc['30-34', 'share_25_plus']:.3f}, 35-39: {pooled.loc['35-39', 'share_25_plus']:.3f}, 40-44+: {pooled.loc['40-44+', 'share_25_plus']:.3f}]`.",
        f"- That is already very close to the current code target `[0.438, 0.381, 0.152, 0.029]`, so the old pooled timing target was not badly off.",
        "",
        "## Recommendation",
        "",
        "- Use direct annual timing levels as the main annual fertility targets.",
        f"  Mean age at first birth: pooled `{RECENT_START}-{RECENT_END}` mean `{timing_table.loc[timing_table['object'] == 'mean_age_first_birth', 'recent_mean'].iloc[0]:.3f}` with a loose band of about `+/- {timing_table.loc[timing_table['object'] == 'mean_age_first_birth', 'suggested_band_half_width'].iloc[0]:.3f}`.",
        f"  Share of first births at age 30+: pooled `{RECENT_START}-{RECENT_END}` mean `{timing_table.loc[timing_table['object'] == 'share_first_birth_30_plus', 'recent_mean'].iloc[0]:.3f}` with a loose band of about `+/- {timing_table.loc[timing_table['object'] == 'share_first_birth_30_plus', 'suggested_band_half_width'].iloc[0]:.3f}`.",
        "- Keep the 25+ age-shape shares as medium-weight pooled targets, not knife-edge annual targets.",
        "- Keep age-50 parity / childlessness as a separate stock target.",
        "- Do not promote the old 5-year NIMBY vote/debt bridge objects to fertility targets.",
        "",
        "## Direct annual national series",
        "",
        "| Year | First births | Mean age first birth | Share first births 30+ |",
        "| --- | ---: | ---: | ---: |",
    ]
    for row in national_series.itertuples(index=False):
        lines.append(
            f"| {int(row.year)} | {int(row.first_births_total)} | {row.mean_age_first_birth:.3f} | {row.share_first_birth_30_plus:.3f} |"
        )

    lines.extend(
        [
            "",
            f"## Pooled {RECENT_START}-{RECENT_END} timing-shape target within ages 25+",
            "",
            "| Bucket | Direct CDC pooled share | Current code target | Gap | Recent annual sd | Recommended weight |",
            "| --- | ---: | ---: | ---: | ---: | --- |",
        ]
    )
    for row in bin_table.itertuples(index=False):
        lines.append(
            f"| {row.bucket} | {row.share_25_plus:.6f} | {row.current_code_target:.6f} | {row.gap_data_minus_code:.6f} | {row.recent_sd:.6f} | {row.recommended_weight} |"
        )

    lines.extend(
        [
            "",
            "## Interpretation",
            "",
            "The new direct CDC pull changes the target discussion less than expected.",
            "The important correction is not that the old pooled 25+ shape target was wrong.",
            "It is that the annual model should be judged mainly on direct annual timing objects,",
            "with the pooled age-shape shares kept as a looser support target.",
            "",
            "The top-bin caveat remains real: the direct pull separates `40-44`, `45-49`, and `50+`,",
            "while the recommended calibration target folds the tiny `45+` tail into the top bin.",
            "That is why the top-bin share should stay a medium-weight target rather than a hard one.",
        ]
    )

    (BUILD / "cdc_first_birth_timing_target_review.md").write_text(
        "\n".join(lines) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    BUILD.mkdir(parents=True, exist_ok=True)

    state_year = load_state_year_panel()
    county_year = load_county_year_panel()
    raw_export = load_raw_state_year_export()

    national_state = build_national_series(state_year)
    national_county = build_national_series(county_year)
    validation = build_validation_table(national_state, national_county)
    annual_recent_25plus, pooled_recent_25plus = build_recent_age_targets(raw_export)
    current_code_target = load_current_code_target()

    national_recent_25plus = annual_recent_25plus[
        annual_recent_25plus["year"].between(RECENT_START, RECENT_END)
    ].copy()
    timing_table, bin_table = build_recommendation_table(
        national_state,
        annual_recent_25plus,
        pooled_recent_25plus,
        current_code_target,
    )

    national_state.to_csv(BUILD / "cdc_first_birth_timing_target_review_annual_series.csv", index=False)
    validation.to_csv(BUILD / "cdc_first_birth_timing_target_review_validation.csv", index=False)
    annual_recent_25plus.to_csv(BUILD / "cdc_first_birth_timing_target_review_25plus_annual.csv", index=False)
    bin_table.to_csv(BUILD / "cdc_first_birth_timing_target_review_25plus_target_comparison.csv", index=False)
    timing_table.to_csv(BUILD / "cdc_first_birth_timing_target_review_target_ranking.csv", index=False)

    plot_review(national_state, annual_recent_25plus, bin_table)
    write_markdown(national_state, validation, pooled_recent_25plus, timing_table, bin_table)
