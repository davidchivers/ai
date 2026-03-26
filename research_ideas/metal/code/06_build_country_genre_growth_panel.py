from __future__ import annotations

import re
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_band_clean.csv"
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "country_genre_analysis"

ROLLING_WINDOW = 5
EXAMPLE_COUNTRY = "BRA"
EXAMPLE_COUNTRY_NAME = "Brazil"
EXAMPLE_FAMILY = "thrash metal"
SELECTED_COUNTRY_COUNT = 5

PAREN_PATTERN = re.compile(r"\([^)]*\)")
SPACE_PATTERN = re.compile(r"\s+")
TYPE_WORDS = (
    "metal",
    "rock",
    "punk",
    "hardcore",
    "metalcore",
    "deathcore",
    "grindcore",
    "crust",
    "ambient",
    "noise",
    "industrial",
    "electronic",
    "electronica",
    "folk",
    "jazz",
    "blues",
    "pop",
)
TYPE_PATTERN = re.compile(r"(" + "|".join(re.escape(word) for word in TYPE_WORDS) + r")$", re.IGNORECASE)

BROAD_FAMILY_RULES: list[tuple[str, callable]] = [
    ("death metal", lambda token: "death" in token and "metal" in token and "deathcore" not in token),
    ("black metal", lambda token: "black" in token and "metal" in token),
    ("thrash metal", lambda token: "thrash" in token and "metal" in token),
    ("heavy metal", lambda token: "heavy" in token and "metal" in token),
    ("doom metal", lambda token: "doom" in token and "metal" in token),
    ("progressive metal", lambda token: "progressive" in token and "metal" in token),
    ("power metal", lambda token: "power" in token and "metal" in token),
    ("groove metal", lambda token: "groove" in token and "metal" in token),
    ("grindcore", lambda token: "grindcore" in token),
    ("metalcore", lambda token: "metalcore" in token),
    ("sludge metal", lambda token: "sludge" in token and "metal" in token),
    ("stoner metal", lambda token: "stoner" in token and "metal" in token),
    ("gothic metal", lambda token: "gothic" in token and "metal" in token),
    ("symphonic metal", lambda token: "symphonic" in token and "metal" in token),
    ("speed metal", lambda token: "speed" in token and "metal" in token),
    ("deathcore", lambda token: "deathcore" in token),
    ("folk metal", lambda token: "folk" in token and "metal" in token),
    ("industrial metal", lambda token: "industrial" in token and "metal" in token),
]


def clean_genre_text(value: str) -> str:
    text = PAREN_PATTERN.sub("", value)
    text = text.replace("&", "/")
    text = SPACE_PATTERN.sub(" ", text).strip(" -")
    return text.strip()


def explicit_type(segment: str) -> str | None:
    match = TYPE_PATTERN.search(segment.strip())
    return match.group(1).lower() if match is not None else None


def expand_clause(clause: str) -> list[str]:
    clause = clean_genre_text(clause)
    if not clause:
        return []
    parts = [part.strip() for part in clause.split("/") if part.strip()]
    if not parts:
        return []
    explicit_types = [explicit_type(part) for part in parts]
    default_type = next((genre_type for genre_type in reversed(explicit_types) if genre_type), "metal")
    expanded: list[str] = []
    for part, genre_type in zip(parts, explicit_types):
        token = part.lower()
        if genre_type is None:
            token = f"{token} {default_type}"
        token = SPACE_PATTERN.sub(" ", token).strip()
        expanded.append(token)
    return expanded


def expand_genre_tokens(raw_value: str) -> list[str]:
    text = clean_genre_text(raw_value)
    if not text:
        return []
    clauses = [clause.strip() for clause in re.split(r"[;,]", text) if clause.strip()]
    tokens: list[str] = []
    seen: set[str] = set()
    for clause in clauses:
        for token in expand_clause(clause):
            if token not in seen:
                seen.add(token)
                tokens.append(token)
    return tokens


def assign_broad_families(tokens: list[str]) -> list[str]:
    families: list[str] = []
    for family_name, rule in BROAD_FAMILY_RULES:
        if any(rule(token) for token in tokens):
            families.append(family_name)
    return families


def load_bands() -> pd.DataFrame:
    bands = pd.read_csv(
        INPUT_PATH,
        usecols=["countryiso3code", "country_std", "genre_raw", "entry_year", "unsigned_i"],
        dtype={"countryiso3code": "string", "country_std": "string", "genre_raw": "string"},
    )
    bands["entry_year"] = pd.to_numeric(bands["entry_year"], errors="coerce").astype("Int64")
    bands["unsigned_i"] = pd.to_numeric(bands["unsigned_i"], errors="coerce").fillna(0).astype(int)
    bands["signed_i"] = 1 - bands["unsigned_i"]
    bands = bands.loc[bands["countryiso3code"].notna() & bands["entry_year"].notna()].copy()
    return bands


def build_family_cache(raw_values: pd.Series) -> dict[str, list[str]]:
    family_cache: dict[str, list[str]] = {}
    for raw_value in raw_values.dropna().drop_duplicates():
        raw_text = str(raw_value)
        family_cache[raw_text] = assign_broad_families(expand_genre_tokens(raw_text))
    return family_cache


def build_country_genre_panel(bands: pd.DataFrame, family_cache: dict[str, list[str]]) -> pd.DataFrame:
    country_year_totals = (
        bands.groupby(["countryiso3code", "country_std", "entry_year"], as_index=False)
        .agg(
            all_metal_bands_started=("genre_raw", "size"),
            all_metal_bands_started_unsigned=("unsigned_i", "sum"),
            all_metal_bands_started_signed=("signed_i", "sum"),
        )
    )

    family_rows: list[dict[str, int | str]] = []
    grouped = (
        bands.groupby(["countryiso3code", "country_std", "entry_year", "genre_raw"], as_index=False)
        .agg(
            band_count=("genre_raw", "size"),
            band_count_unsigned=("unsigned_i", "sum"),
            band_count_signed=("signed_i", "sum"),
        )
    )
    for row in grouped.itertuples(index=False):
        for family in family_cache.get(str(row.genre_raw), []):
            family_rows.append(
                {
                    "countryiso3code": str(row.countryiso3code),
                    "country_std": str(row.country_std),
                    "entry_year": int(row.entry_year),
                    "genre_family": family,
                    "bands_started": int(row.band_count),
                    "bands_started_unsigned": int(row.band_count_unsigned),
                    "bands_started_signed": int(row.band_count_signed),
                }
            )

    family_panel = (
        pd.DataFrame(family_rows)
        .groupby(["countryiso3code", "country_std", "entry_year", "genre_family"], as_index=False)[
            ["bands_started", "bands_started_unsigned", "bands_started_signed"]
        ]
        .sum()
        .sort_values(["countryiso3code", "genre_family", "entry_year"])
        .reset_index(drop=True)
    )

    panel = family_panel.merge(
        country_year_totals,
        on=["countryiso3code", "country_std", "entry_year"],
        how="left",
        validate="many_to_one",
    )
    panel["genre_share_of_country_year"] = panel["bands_started"] / panel["all_metal_bands_started"]
    panel["genre_share_of_country_year_unsigned"] = np.where(
        panel["all_metal_bands_started_unsigned"] > 0,
        panel["bands_started_unsigned"] / panel["all_metal_bands_started_unsigned"],
        np.nan,
    )
    panel["genre_share_of_country_year_signed"] = np.where(
        panel["all_metal_bands_started_signed"] > 0,
        panel["bands_started_signed"] / panel["all_metal_bands_started_signed"],
        np.nan,
    )
    return panel


def build_example_comparison(country_genre_panel: pd.DataFrame) -> pd.DataFrame:
    example = country_genre_panel.loc[
        country_genre_panel["genre_family"].eq(EXAMPLE_FAMILY),
        [
            "countryiso3code",
            "country_std",
            "entry_year",
            "bands_started",
            "all_metal_bands_started",
            "genre_share_of_country_year",
        ],
    ].copy()

    brazil = example.loc[example["countryiso3code"].eq(EXAMPLE_COUNTRY)].rename(
        columns={
            "bands_started": "brazil_genre_bands_started",
            "all_metal_bands_started": "brazil_all_metal_bands_started",
            "genre_share_of_country_year": "brazil_genre_share",
        }
    )
    rest = example.loc[example["countryiso3code"].ne(EXAMPLE_COUNTRY)].groupby("entry_year", as_index=False)[
        ["bands_started", "all_metal_bands_started"]
    ].sum()
    rest = rest.rename(
        columns={
            "bands_started": "rest_of_world_genre_bands_started",
            "all_metal_bands_started": "rest_of_world_all_metal_bands_started",
        }
    )
    rest["rest_of_world_genre_share"] = (
        rest["rest_of_world_genre_bands_started"] / rest["rest_of_world_all_metal_bands_started"]
    )

    year_min = int(example["entry_year"].min())
    year_max = int(example["entry_year"].max())
    year_frame = pd.DataFrame({"entry_year": list(range(year_min, year_max + 1))})

    comparison = year_frame.merge(
        brazil[
            [
                "entry_year",
                "brazil_genre_bands_started",
                "brazil_all_metal_bands_started",
                "brazil_genre_share",
            ]
        ],
        on="entry_year",
        how="left",
    ).merge(
        rest[
            [
                "entry_year",
                "rest_of_world_genre_bands_started",
                "rest_of_world_all_metal_bands_started",
                "rest_of_world_genre_share",
            ]
        ],
        on="entry_year",
        how="left",
    )

    fill_zero_columns = [
        "brazil_genre_bands_started",
        "brazil_all_metal_bands_started",
        "brazil_genre_share",
        "rest_of_world_genre_bands_started",
        "rest_of_world_all_metal_bands_started",
        "rest_of_world_genre_share",
    ]
    comparison[fill_zero_columns] = comparison[fill_zero_columns].fillna(0)

    comparison["brazil_genre_share_rolling_5yr"] = (
        comparison["brazil_genre_share"].rolling(window=ROLLING_WINDOW, min_periods=1).mean()
    )
    comparison["rest_of_world_genre_share_rolling_5yr"] = (
        comparison["rest_of_world_genre_share"].rolling(window=ROLLING_WINDOW, min_periods=1).mean()
    )
    comparison["share_gap_brazil_minus_rest"] = (
        comparison["brazil_genre_share"] - comparison["rest_of_world_genre_share"]
    )
    comparison["share_gap_brazil_minus_rest_rolling_5yr"] = (
        comparison["brazil_genre_share_rolling_5yr"] - comparison["rest_of_world_genre_share_rolling_5yr"]
    )
    return comparison


def build_selected_country_comparison(country_genre_panel: pd.DataFrame) -> pd.DataFrame:
    family_panel = country_genre_panel.loc[country_genre_panel["genre_family"].eq(EXAMPLE_FAMILY)].copy()
    top_countries = (
        family_panel.groupby(["countryiso3code", "country_std"], as_index=False)["bands_started"]
        .sum()
        .sort_values(["bands_started", "countryiso3code"], ascending=[False, True])
        .head(SELECTED_COUNTRY_COUNT)
        .reset_index(drop=True)
    )

    selected_codes = top_countries["countryiso3code"].tolist()
    selected = family_panel.loc[family_panel["countryiso3code"].isin(selected_codes)].copy()
    year_min = int(selected["entry_year"].min())
    year_max = int(selected["entry_year"].max())
    all_years = pd.DataFrame({"entry_year": list(range(year_min, year_max + 1))})

    country_frames: list[pd.DataFrame] = []
    for row in top_countries.itertuples(index=False):
        country_series = all_years.merge(
            selected.loc[selected["countryiso3code"].eq(row.countryiso3code), [
                "entry_year",
                "countryiso3code",
                "country_std",
                "bands_started",
                "all_metal_bands_started",
                "genre_share_of_country_year",
            ]],
            on="entry_year",
            how="left",
        )
        country_series["countryiso3code"] = country_series["countryiso3code"].fillna(str(row.countryiso3code))
        country_series["country_std"] = country_series["country_std"].fillna(str(row.country_std))
        fill_zero_columns = ["bands_started", "all_metal_bands_started", "genre_share_of_country_year"]
        country_series[fill_zero_columns] = country_series[fill_zero_columns].fillna(0)
        country_series["genre_share_rolling_5yr"] = (
            country_series["genre_share_of_country_year"].rolling(window=ROLLING_WINDOW, min_periods=1).mean()
        )
        country_frames.append(country_series)

    comparison = pd.concat(country_frames, ignore_index=True)
    return comparison


def plot_example(comparison: pd.DataFrame) -> None:
    fig, ax = plt.subplots(figsize=(12, 7))
    ax.plot(
        comparison["entry_year"],
        comparison["brazil_genre_share_rolling_5yr"] * 100,
        color="#0b7285",
        linewidth=2.4,
        label=f"{EXAMPLE_COUNTRY_NAME} {EXAMPLE_FAMILY.title()} share",
    )
    ax.plot(
        comparison["entry_year"],
        comparison["rest_of_world_genre_share_rolling_5yr"] * 100,
        color="#495057",
        linewidth=2.2,
        linestyle="--",
        label=f"Rest of world {EXAMPLE_FAMILY.title()} share",
    )
    ax.axhline(0, color="black", linewidth=0.8, alpha=0.4)
    ax.set_title(
        f"Exploratory country-genre growth: {EXAMPLE_COUNTRY_NAME} {EXAMPLE_FAMILY.title()}",
        fontsize=14,
        weight="bold",
    )
    ax.set_xlabel("Band entry year")
    ax.set_ylabel(f"{EXAMPLE_FAMILY.title()} share of all metal band starts (%)")
    ax.grid(alpha=0.25, linewidth=0.6)
    ax.legend(frameon=False)
    ax.set_xlim(int(comparison["entry_year"].min()), int(comparison["entry_year"].max()))

    note = (
        "5-year rolling mean. This is an exploratory descriptive graph built from band starts,\n"
        "not a causal event study with breakthrough timing. Family membership is multi-label."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.05, 1, 1))
    fig.savefig(OUTPUT_DIR / "brazil_thrash_metal_vs_rest_of_world_share.png", dpi=200)
    plt.close(fig)


def plot_selected_countries(comparison: pd.DataFrame) -> None:
    order = (
        comparison.groupby(["countryiso3code", "country_std"], as_index=False)["bands_started"]
        .sum()
        .sort_values(["bands_started", "countryiso3code"], ascending=[False, True])
        .reset_index(drop=True)
    )
    color_map = plt.get_cmap("tab10")
    fig, ax = plt.subplots(figsize=(12, 7))
    for index, row in enumerate(order.itertuples(index=False)):
        country_data = comparison.loc[comparison["countryiso3code"].eq(row.countryiso3code)].copy()
        linewidth = 2.8 if row.countryiso3code == EXAMPLE_COUNTRY else 2.0
        alpha = 1.0 if row.countryiso3code == EXAMPLE_COUNTRY else 0.9
        ax.plot(
            country_data["entry_year"],
            country_data["genre_share_rolling_5yr"] * 100,
            linewidth=linewidth,
            alpha=alpha,
            color=color_map(index),
            label=str(row.country_std),
        )

    ax.set_title(
        f"{EXAMPLE_FAMILY.title()} growth across selected countries",
        fontsize=14,
        weight="bold",
    )
    ax.set_xlabel("Band entry year")
    ax.set_ylabel(f"{EXAMPLE_FAMILY.title()} share of each country's metal band starts (%)")
    ax.grid(alpha=0.25, linewidth=0.6)
    ax.legend(frameon=False, ncol=2)
    ax.set_xlim(int(comparison["entry_year"].min()), int(comparison["entry_year"].max()))

    note = (
        "5-year rolling mean. Countries are the largest observed markets in this broad genre family.\n"
        "This is descriptive and uses band starts rather than curated breakthrough timing."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.05, 1, 1))
    fig.savefig(OUTPUT_DIR / "thrash_metal_selected_countries_share.png", dpi=200)
    plt.close(fig)


def write_summary(
    country_genre_panel: pd.DataFrame,
    comparison: pd.DataFrame,
    selected_country_comparison: pd.DataFrame,
) -> None:
    plotted_families = (
        country_genre_panel.groupby("genre_family", as_index=False)["bands_started"]
        .sum()
        .sort_values(["bands_started", "genre_family"], ascending=[False, True])
        .reset_index(drop=True)
    )
    brazil_example = comparison.loc[comparison["brazil_genre_bands_started"] > 0].copy()
    first_year = int(brazil_example["entry_year"].min())
    peak_count_row = comparison.loc[comparison["brazil_genre_bands_started"].idxmax()]
    peak_share_row = comparison.loc[comparison["brazil_genre_share"].idxmax()]
    peak_gap_row = comparison.loc[comparison["share_gap_brazil_minus_rest_rolling_5yr"].idxmax()]
    selected_country_names = (
        selected_country_comparison[["countryiso3code", "country_std"]]
        .drop_duplicates()
        .sort_values("countryiso3code")
    )

    lines: list[str] = []
    lines.append("# Country-genre growth prototype")
    lines.append("")
    lines.append("This file builds a reusable `country x genre_family x year` panel from")
    lines.append("`data/processed/metal_archives_all_metal_band_clean.csv`.")
    lines.append("")
    lines.append("## Why this object matters")
    lines.append("")
    lines.append(
        "- It moves the project closer to the domestic-exemplar mechanism by comparing later entry in the same genre family, not only all-metal counts."
    )
    lines.append(
        "- It lets the eventual treatment become a `country-genre breakthrough` event rather than only a country-wide metal hit."
    )
    lines.append(
        "- It makes the natural comparison `same genre elsewhere` rather than `all other metal everywhere`."
    )
    lines.append("")
    lines.append("## Current panel")
    lines.append("")
    lines.append(
        f"- Countries with usable entry-year data: `{country_genre_panel['countryiso3code'].nunique()}`"
    )
    lines.append(f"- Broad genre families currently tracked: `{country_genre_panel['genre_family'].nunique()}`")
    lines.append(f"- Country-genre-year rows: `{len(country_genre_panel)}`")
    lines.append("- Outcome margins preserved in the panel: `all`, `unsigned`, and `signed` band starts")
    lines.append("")
    lines.append("Largest broad families in the panel:")
    lines.append("")
    lines.append(plotted_families.head(10).to_markdown(index=False))
    lines.append("")
    lines.append(f"## First illustrative case: {EXAMPLE_COUNTRY_NAME} {EXAMPLE_FAMILY}")
    lines.append("")
    lines.append(
        f"- First observed {EXAMPLE_FAMILY} band starts in {EXAMPLE_COUNTRY_NAME}: `{first_year}`"
    )
    lines.append(
        f"- Peak raw {EXAMPLE_FAMILY} count in {EXAMPLE_COUNTRY_NAME}: `{int(peak_count_row['brazil_genre_bands_started'])}` bands in `{int(peak_count_row['entry_year'])}`"
    )
    lines.append(
        f"- Peak {EXAMPLE_FAMILY} share in {EXAMPLE_COUNTRY_NAME}: `{peak_share_row['brazil_genre_share'] * 100:.1f}%` of all Brazilian metal band starts in `{int(peak_share_row['entry_year'])}`"
    )
    lines.append(
        f"- Largest rolling share gap versus the rest of the world: `{peak_gap_row['share_gap_brazil_minus_rest_rolling_5yr'] * 100:.1f}` percentage points in `{int(peak_gap_row['entry_year'])}`"
    )
    lines.append("")
    lines.append("Selected-country graph includes:")
    lines.append("")
    for row in selected_country_names.itertuples(index=False):
        lines.append(f"- `{row.country_std}`")
    lines.append("")
    lines.append("Interpretation:")
    lines.append(
        "- This is only a descriptive prototype. It uses observed band-start timing, not the eventual breakthrough-event timing."
    )
    lines.append(
        "- The graph compares genre share rather than raw counts so Brazil is not mechanically penalized for being smaller than the global aggregate."
    )
    lines.append(
        "- The next research step is to replace `first observed genre entry` with `first visible domestic breakthrough in that genre-country`."
    )
    lines.append("")
    lines.append("## Outputs")
    lines.append("")
    lines.append("- `country_genre_family_year_panel.csv`")
    lines.append("- panel columns now include `bands_started_unsigned`, `bands_started_signed`, and corresponding country-year totals and shares")
    lines.append("- `brazil_thrash_vs_rest_of_world.csv`")
    lines.append("- `brazil_thrash_metal_vs_rest_of_world_share.png`")
    lines.append("- `thrash_metal_selected_countries_share.csv`")
    lines.append("- `thrash_metal_selected_countries_share.png`")
    (OUTPUT_DIR / "country_genre_growth_summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    bands = load_bands()
    family_cache = build_family_cache(bands["genre_raw"])
    country_genre_panel = build_country_genre_panel(bands, family_cache)
    comparison = build_example_comparison(country_genre_panel)
    selected_country_comparison = build_selected_country_comparison(country_genre_panel)

    country_genre_panel.to_csv(OUTPUT_DIR / "country_genre_family_year_panel.csv", index=False)
    comparison.to_csv(OUTPUT_DIR / "brazil_thrash_vs_rest_of_world.csv", index=False)
    selected_country_comparison.to_csv(OUTPUT_DIR / "thrash_metal_selected_countries_share.csv", index=False)
    plot_example(comparison)
    plot_selected_countries(selected_country_comparison)
    write_summary(country_genre_panel, comparison, selected_country_comparison)


if __name__ == "__main__":
    main()
