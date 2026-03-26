from __future__ import annotations

import re
from collections import Counter, defaultdict
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_band_clean.csv"
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "genre_analysis"

TOP_N_FAMILIES = 6
ROLLING_WINDOW = 5

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
    bands = pd.read_csv(INPUT_PATH, usecols=["genre_raw", "entry_year"], dtype={"genre_raw": "string"})
    bands["entry_year"] = pd.to_numeric(bands["entry_year"], errors="coerce").astype("Int64")
    return bands


def build_genre_cache(raw_values: pd.Series) -> tuple[dict[str, list[str]], dict[str, list[str]]]:
    token_cache: dict[str, list[str]] = {}
    family_cache: dict[str, list[str]] = {}
    for raw_value in raw_values.dropna().drop_duplicates():
        raw_text = str(raw_value)
        tokens = expand_genre_tokens(raw_text)
        token_cache[raw_text] = tokens
        family_cache[raw_text] = assign_broad_families(tokens)
    return token_cache, family_cache


def build_atomic_tag_counts(raw_counts: pd.Series, token_cache: dict[str, list[str]]) -> pd.DataFrame:
    counts: Counter[str] = Counter()
    for raw_text, band_count in raw_counts.items():
        for token in token_cache.get(str(raw_text), []):
            counts[token] += int(band_count)
    table = (
        pd.DataFrame({"atomic_genre_tag": list(counts.keys()), "band_count": list(counts.values())})
        .sort_values(["band_count", "atomic_genre_tag"], ascending=[False, True])
        .reset_index(drop=True)
    )
    return table


def build_family_counts(
    raw_counts_all: pd.Series,
    raw_counts_usable_years: pd.Series,
    family_cache: dict[str, list[str]],
) -> pd.DataFrame:
    counts_all: Counter[str] = Counter()
    counts_usable_years: Counter[str] = Counter()
    for raw_text, band_count in raw_counts_all.items():
        for family in family_cache.get(str(raw_text), []):
            counts_all[family] += int(band_count)
    for raw_text, band_count in raw_counts_usable_years.items():
        for family in family_cache.get(str(raw_text), []):
            counts_usable_years[family] += int(band_count)
    families = sorted(set(counts_all) | set(counts_usable_years))
    table = pd.DataFrame(
        {
            "genre_family": families,
            "bands_total": [counts_all.get(family, 0) for family in families],
            "bands_with_usable_entry_year": [counts_usable_years.get(family, 0) for family in families],
        }
    )
    return table.sort_values(
        ["bands_with_usable_entry_year", "bands_total", "genre_family"],
        ascending=[False, False, True],
    ).reset_index(drop=True)


def build_yearly_family_counts(
    grouped_counts: pd.DataFrame,
    family_cache: dict[str, list[str]],
) -> pd.DataFrame:
    records: list[dict[str, int | str]] = []
    for row in grouped_counts.itertuples(index=False):
        families = family_cache.get(str(row.genre_raw), [])
        for family in families:
            records.append(
                {
                    "genre_family": family,
                    "entry_year": int(row.entry_year),
                    "bands_started": int(row.band_count),
                }
            )
    yearly = (
        pd.DataFrame(records)
        .groupby(["genre_family", "entry_year"], as_index=False)["bands_started"]
        .sum()
        .sort_values(["genre_family", "entry_year"])
        .reset_index(drop=True)
    )
    yearly["bands_started_rolling_5yr"] = (
        yearly.groupby("genre_family")["bands_started"]
        .transform(lambda series: series.rolling(window=ROLLING_WINDOW, min_periods=1).mean())
        .round(2)
    )
    return yearly


def build_decade_growth(yearly_family_counts: pd.DataFrame) -> pd.DataFrame:
    decade = yearly_family_counts.copy()
    decade["decade"] = (decade["entry_year"] // 10) * 10
    decade = (
        decade.groupby(["genre_family", "decade"], as_index=False)["bands_started"]
        .sum()
        .sort_values(["genre_family", "decade"])
        .reset_index(drop=True)
    )
    decade["full_decade_i"] = decade["decade"].between(1970, 2010)
    decade["pct_growth_vs_previous_decade"] = (
        decade.groupby("genre_family")["bands_started"].pct_change() * 100
    ).round(2)
    return decade


def build_headline_table(
    bands: pd.DataFrame,
    token_cache: dict[str, list[str]],
) -> pd.DataFrame:
    atomic_tags = sorted({token for tokens in token_cache.values() for token in tokens})
    headlines = [
        ("bands_total", int(len(bands))),
        ("bands_with_usable_entry_year", int(bands["entry_year"].notna().sum())),
        ("unique_raw_genre_strings", int(bands["genre_raw"].dropna().nunique())),
        ("unique_atomic_genre_tags", int(len(atomic_tags))),
    ]
    return pd.DataFrame(headlines, columns=["metric", "value"])


def write_summary(
    headline_table: pd.DataFrame,
    top_raw: pd.DataFrame,
    top_families: pd.DataFrame,
    decade_growth: pd.DataFrame,
) -> None:
    lines: list[str] = []
    metrics = dict(headline_table.itertuples(index=False, name=None))
    lines.append("# Metal Archives genre analysis")
    lines.append("")
    lines.append("This note uses the first cleaned Metallum band-level dataset:")
    lines.append("`data/processed/metal_archives_all_metal_band_clean.csv`.")
    lines.append("")
    lines.append("## Headline counts")
    lines.append("")
    lines.append(f"- Bands in cleaned snapshot: `{metrics['bands_total']}`")
    lines.append(f"- Bands with usable entry year: `{metrics['bands_with_usable_entry_year']}`")
    lines.append(f"- Distinct raw genre strings: `{metrics['unique_raw_genre_strings']}`")
    lines.append(f"- Distinct parsed atomic genre tags: `{metrics['unique_atomic_genre_tags']}`")
    lines.append("")
    lines.append("Interpretation:")
    lines.append(
        "- The raw count is the exact number of different Metal Archives genre strings in the dataset."
    )
    lines.append(
        "- The atomic-tag count comes from splitting those strings on `/`, `,`, and `;` and propagating missing suffixes such as `Metal`."
    )
    lines.append("")
    lines.append("## Largest raw genre strings")
    lines.append("")
    lines.append(top_raw.to_markdown(index=False))
    lines.append("")
    lines.append("## Largest broad genre families")
    lines.append("")
    lines.append(top_families.to_markdown(index=False))
    lines.append("")
    lines.append("## Decade growth for the plotted families")
    lines.append("")
    lines.append(
        "Only full decades are used for growth comparisons below. The 1960s and 2020s are partial windows in this snapshot."
    )
    lines.append("")
    lines.append(decade_growth.to_markdown(index=False))
    lines.append("")
    lines.append("## Outputs")
    lines.append("")
    lines.append("- `genre_headline_counts.csv`")
    lines.append("- `genre_top_raw_strings.csv`")
    lines.append("- `genre_atomic_tag_counts.csv`")
    lines.append("- `genre_family_counts.csv`")
    lines.append("- `genre_family_yearly_counts.csv`")
    lines.append("- `genre_family_decade_growth.csv`")
    lines.append("- `top_genre_families_over_time.png`")
    (OUTPUT_DIR / "genre_analysis_summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def plot_top_families(yearly_family_counts: pd.DataFrame, top_families: list[str]) -> None:
    plot_data = yearly_family_counts.loc[yearly_family_counts["genre_family"].isin(top_families)].copy()
    year_min = int(plot_data["entry_year"].min())
    year_max = int(plot_data["entry_year"].max())
    all_years = pd.Index(range(year_min, year_max + 1), name="entry_year")

    color_map = plt.get_cmap("tab10")
    fig, ax = plt.subplots(figsize=(12, 7))
    for index, family in enumerate(top_families):
        family_series = (
            plot_data.loc[plot_data["genre_family"].eq(family), ["entry_year", "bands_started"]]
            .set_index("entry_year")["bands_started"]
            .reindex(all_years, fill_value=0)
        )
        rolling = family_series.rolling(window=ROLLING_WINDOW, min_periods=1).mean()
        ax.plot(
            all_years,
            rolling,
            linewidth=2.2,
            color=color_map(index),
            label=family.title(),
        )

    ax.set_title("Broad metal genre families over time", fontsize=14, weight="bold")
    ax.set_xlabel("Band entry year")
    ax.set_ylabel(f"Band starts ({ROLLING_WINDOW}-year rolling mean)")
    ax.grid(alpha=0.25, linewidth=0.6)
    ax.legend(frameon=False, ncol=2)
    ax.set_xlim(year_min, year_max)

    note = (
        "Family membership is multi-label: a band can count in more than one broad family.\n"
        "The 2020s are a partial decade in this snapshot."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(OUTPUT_DIR / "top_genre_families_over_time.png", dpi=200)
    plt.close(fig)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    bands = load_bands()
    raw_counts_all = bands["genre_raw"].value_counts()
    usable_year_bands = bands.loc[bands["entry_year"].notna()].copy()
    raw_counts_usable_years = usable_year_bands["genre_raw"].value_counts()

    token_cache, family_cache = build_genre_cache(bands["genre_raw"])

    headline_table = build_headline_table(bands, token_cache)
    top_raw_strings = (
        raw_counts_all.rename_axis("raw_genre_string")
        .reset_index(name="band_count")
        .head(15)
    )
    atomic_tag_counts = build_atomic_tag_counts(raw_counts_all, token_cache)
    family_counts = build_family_counts(raw_counts_all, raw_counts_usable_years, family_cache)

    grouped_counts = (
        usable_year_bands.groupby(["entry_year", "genre_raw"], as_index=False)
        .size()
        .rename(columns={"size": "band_count"})
    )
    yearly_family_counts = build_yearly_family_counts(grouped_counts, family_cache)
    decade_growth = build_decade_growth(yearly_family_counts)

    top_family_names = family_counts.head(TOP_N_FAMILIES)["genre_family"].tolist()
    plotted_family_table = family_counts.loc[
        family_counts["genre_family"].isin(top_family_names),
        ["genre_family", "bands_with_usable_entry_year", "bands_total"],
    ].copy()
    plotted_family_table = plotted_family_table.sort_values(
        ["bands_with_usable_entry_year", "bands_total", "genre_family"],
        ascending=[False, False, True],
    ).reset_index(drop=True)

    decade_growth_top = decade_growth.loc[
        decade_growth["genre_family"].isin(top_family_names)
        & decade_growth["full_decade_i"]
        & decade_growth["pct_growth_vs_previous_decade"].notna(),
        ["genre_family", "decade", "bands_started", "pct_growth_vs_previous_decade"],
    ].copy()

    headline_table.to_csv(OUTPUT_DIR / "genre_headline_counts.csv", index=False)
    top_raw_strings.to_csv(OUTPUT_DIR / "genre_top_raw_strings.csv", index=False)
    atomic_tag_counts.to_csv(OUTPUT_DIR / "genre_atomic_tag_counts.csv", index=False)
    family_counts.to_csv(OUTPUT_DIR / "genre_family_counts.csv", index=False)
    yearly_family_counts.to_csv(OUTPUT_DIR / "genre_family_yearly_counts.csv", index=False)
    decade_growth.to_csv(OUTPUT_DIR / "genre_family_decade_growth.csv", index=False)

    plot_top_families(yearly_family_counts, top_family_names)
    write_summary(headline_table, top_raw_strings, plotted_family_table, decade_growth_top)


if __name__ == "__main__":
    main()
