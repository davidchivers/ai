from __future__ import annotations

import re
import sqlite3
import unicodedata
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
WORKSPACE_ROOT = PROJECT_ROOT.parents[1]

INPUT_DB = (
    WORKSPACE_ROOT
    / "research_ideas"
    / "learning_by_viewing"
    / "music"
    / "data"
    / "strategy_8_music_pilot"
    / "raw"
    / "metal_archives"
    / "metal-archives.db"
)
TREATMENT_PANEL_PATH = (
    WORKSPACE_ROOT
    / "research_ideas"
    / "learning_by_viewing"
    / "music"
    / "data"
    / "strategy_8_music_pilot"
    / "processed"
    / "country_year_treatment_panel.csv"
)
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed"

YEAR_PATTERN = re.compile(r"\b(?:19|20)\d{2}\b")
SPACE_PATTERN = re.compile(r"\s+")
PUNCT_PATTERN = re.compile(r"[^a-z0-9]+")
SOURCE_ID_PATTERN = re.compile(r"/bands/[^/]+/(\d+)")

CORE_MARKETS = {
    "USA": "United States",
    "GBR": "United Kingdom",
    "DEU": "Germany",
    "ITA": "Italy",
    "SWE": "Sweden",
    "AUS": "Australia",
}

COUNTRY_ALIASES = {
    "bosnia and herzegovina": "Bosnia and Herzegovina",
    "cape verde": "Cabo Verde",
    "czech republic": "Czechia",
    "democratic republic of the congo": "Congo, Dem. Rep.",
    "egypt": "Egypt, Arab Rep.",
    "hong kong": "Hong Kong SAR, China",
    "iran": "Iran, Islamic Rep.",
    "kyrgyzstan": "Kyrgyz Republic",
    "laos": "Lao PDR",
    "micronesia": "Micronesia, Fed. Sts.",
    "moldova": "Moldova",
    "north korea": "Korea, Dem. People's Rep.",
    "puerto rico": "Puerto Rico (US)",
    "korea, south": "Korea, Rep.",
    "russia": "Russian Federation",
    "slovakia": "Slovak Republic",
    "slovak republic": "Slovak Republic",
    "south korea": "Korea, Rep.",
    "syria": "Syrian Arab Republic",
    "taiwan": "Taiwan, China",
    "brunei": "Brunei Darussalam",
    "east timor": "Timor-Leste",
    "turkey": "Turkiye",
    "u.k.": "United Kingdom",
    "uk": "United Kingdom",
    "u.s.": "United States",
    "u.s.a.": "United States",
    "usa": "United States",
    "venezuela": "Venezuela, RB",
    "vietnam": "Viet Nam",
}


def collapse_spaces(value: str) -> str:
    return SPACE_PATTERN.sub(" ", value).strip()


def clean_text(value: object) -> str | pd.NA:
    if value is None or pd.isna(value):
        return pd.NA
    text = collapse_spaces(str(value))
    return text if text else pd.NA


def normalize_ascii(value: object) -> str:
    if value is None or pd.isna(value):
        return ""
    text = str(value).strip()
    if not text:
        return ""
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")


def normalize_band_name(value: object) -> str:
    text = normalize_ascii(value).lower()
    text = PUNCT_PATTERN.sub(" ", text)
    return collapse_spaces(text)


def parse_year(value: object) -> int | pd.NA:
    text = normalize_ascii(value)
    if not text:
        return pd.NA
    if text.isdigit() and len(text) == 4:
        year = int(text)
        return year if 1900 <= year <= 2026 else pd.NA
    matches = sorted(set(YEAR_PATTERN.findall(text)))
    if len(matches) != 1:
        return pd.NA
    year = int(matches[0])
    return year if 1900 <= year <= 2026 else pd.NA


def derive_unsigned(value: object) -> int | pd.NA:
    text = normalize_ascii(value).lower()
    if not text:
        return pd.NA
    if "unsigned" in text or "independent" in text:
        return 1
    return 0


def build_country_lookup(treatment_panel: pd.DataFrame) -> dict[str, tuple[str, str]]:
    lookup: dict[str, tuple[str, str]] = {}
    countries = treatment_panel[["country_name", "countryiso3code"]].drop_duplicates()
    for row in countries.itertuples(index=False):
        lookup[str(row.country_name).casefold()] = (str(row.country_name), str(row.countryiso3code))
    return lookup


def standardize_country(
    raw_value: object,
    country_lookup: dict[str, tuple[str, str]],
) -> tuple[str | pd.NA, str | pd.NA, str | pd.NA]:
    candidate = normalize_ascii(raw_value)
    if not candidate:
        return pd.NA, pd.NA, pd.NA
    alias_target = COUNTRY_ALIASES.get(candidate.casefold(), candidate)
    match = country_lookup.get(alias_target.casefold())
    if match is None:
        return pd.NA, pd.NA, pd.NA
    match_source = "direct_country_name"
    if alias_target.casefold() != candidate.casefold():
        match_source = f"alias:{candidate}"
    return match[0], match[1], match_source


def extract_source_id(value: object) -> str | pd.NA:
    text = clean_text(value)
    if text is pd.NA:
        return pd.NA
    match = SOURCE_ID_PATTERN.search(str(text))
    return match.group(1) if match is not None else pd.NA


def build_notes(row: pd.Series) -> str | pd.NA:
    note_parts: list[str] = []
    for label, column in (
        ("location", "location"),
        ("status", "status"),
        ("lyrical_themes", "lyrical_themes"),
        ("data_retrieved", "data_retrieved"),
    ):
        value = clean_text(row.get(column))
        if value is not pd.NA:
            note_parts.append(f"{label}={value}")
    if not note_parts:
        return pd.NA
    return "; ".join(note_parts)


def load_snapshot(path: Path) -> pd.DataFrame:
    query = """
        SELECT
            band_name,
            url,
            country_of_origin,
            location,
            status,
            formed_in,
            genre,
            lyrical_themes,
            current_label,
            years_active,
            data_retrieved
        FROM band_info
    """
    with sqlite3.connect(path) as connection:
        frame = pd.read_sql_query(query, connection)
    return frame.fillna(pd.NA)


def build_clean_bands(raw_bands: pd.DataFrame, treatment_panel: pd.DataFrame) -> pd.DataFrame:
    country_lookup = build_country_lookup(treatment_panel)
    clean = pd.DataFrame()
    clean["source_name"] = "metal_archives_git_snapshot_all_metal"
    clean["source_id_primary"] = raw_bands["url"].map(extract_source_id)
    clean["band_name_raw"] = raw_bands["band_name"].map(clean_text)
    clean["band_name_clean"] = clean["band_name_raw"].map(normalize_band_name)
    clean["country_raw"] = raw_bands["country_of_origin"].map(clean_text)
    standardized = clean["country_raw"].map(lambda value: standardize_country(value, country_lookup))
    clean["country_std"] = standardized.map(lambda value: value[0])
    clean["countryiso3code"] = standardized.map(lambda value: value[1])
    clean["country_match_source"] = standardized.map(lambda value: value[2])
    clean["formed_year_raw"] = raw_bands["formed_in"].map(clean_text)
    clean["formed_year"] = clean["formed_year_raw"].map(parse_year).astype("Int64")
    clean["entry_year"] = clean["formed_year"]
    clean["entry_year_source"] = clean["entry_year"].map(
        lambda value: "formed_year_observed" if pd.notna(value) else pd.NA
    )
    clean["genre_raw"] = raw_bands["genre"].map(clean_text)
    clean["label_status_raw"] = raw_bands["current_label"].map(clean_text)
    clean["unsigned_i"] = clean["label_status_raw"].map(derive_unsigned).astype("Int64")
    clean["active_status_raw"] = raw_bands["years_active"].where(
        raw_bands["years_active"].notna(), raw_bands["status"]
    ).map(clean_text)
    clean["source_url"] = raw_bands["url"].map(clean_text)
    clean["notes"] = raw_bands.apply(build_notes, axis=1)
    ordered = [
        "source_name",
        "source_id_primary",
        "band_name_raw",
        "band_name_clean",
        "country_raw",
        "country_std",
        "countryiso3code",
        "country_match_source",
        "formed_year_raw",
        "formed_year",
        "entry_year",
        "entry_year_source",
        "genre_raw",
        "label_status_raw",
        "unsigned_i",
        "active_status_raw",
        "source_url",
        "notes",
    ]
    return clean[ordered]


def build_unmatched_country_report(clean_bands: pd.DataFrame) -> pd.DataFrame:
    unmatched = clean_bands.loc[
        clean_bands["country_raw"].notna() & clean_bands["countryiso3code"].isna(),
        ["country_raw"],
    ].copy()
    if unmatched.empty:
        return pd.DataFrame(columns=["country_raw", "row_count"])
    return (
        unmatched.groupby("country_raw", dropna=False)
        .size()
        .reset_index(name="row_count")
        .sort_values(["row_count", "country_raw"], ascending=[False, True])
        .reset_index(drop=True)
    )


def build_country_year_panel(clean_bands: pd.DataFrame, treatment_panel: pd.DataFrame) -> pd.DataFrame:
    eligible = clean_bands.loc[
        clean_bands["countryiso3code"].notna() & clean_bands["entry_year"].notna()
    ].copy()
    if not eligible.empty:
        eligible["bands_formed_all_metal_ct"] = 1
        eligible["bands_formed_all_metal_unsigned_ct"] = eligible["unsigned_i"].eq(1).fillna(False).astype(int)
        eligible["bands_formed_all_metal_signed_ct"] = eligible["unsigned_i"].eq(0).fillna(False).astype(int)
        outcomes = (
            eligible.groupby(["countryiso3code", "entry_year"], dropna=False)[
                [
                    "bands_formed_all_metal_ct",
                    "bands_formed_all_metal_unsigned_ct",
                    "bands_formed_all_metal_signed_ct",
                ]
            ]
            .sum()
            .reset_index()
            .rename(columns={"entry_year": "year"})
        )
    else:
        outcomes = pd.DataFrame(
            columns=[
                "countryiso3code",
                "year",
                "bands_formed_all_metal_ct",
                "bands_formed_all_metal_unsigned_ct",
                "bands_formed_all_metal_signed_ct",
            ]
        )

    panel = treatment_panel.merge(outcomes, on=["countryiso3code", "year"], how="left")
    for column in (
        "bands_formed_all_metal_ct",
        "bands_formed_all_metal_unsigned_ct",
        "bands_formed_all_metal_signed_ct",
    ):
        panel[column] = panel[column].fillna(0).astype(int)

    denominator = panel["bands_formed_all_metal_unsigned_ct"] + panel["bands_formed_all_metal_signed_ct"]
    panel["share_all_metal_unsigned_ct"] = pd.NA
    valid = denominator > 0
    panel.loc[valid, "share_all_metal_unsigned_ct"] = (
        panel.loc[valid, "bands_formed_all_metal_unsigned_ct"] / denominator.loc[valid]
    )
    panel["share_all_metal_unsigned_ct"] = panel["share_all_metal_unsigned_ct"].astype("Float64")
    return panel


def build_core_summary(panel: pd.DataFrame) -> pd.DataFrame:
    rows = []
    sample = panel.loc[(panel["year"] >= 1995) & (panel["year"] <= 2022)].copy()
    for code, name in CORE_MARKETS.items():
        country = sample.loc[sample["countryiso3code"] == code].copy()
        yearly = country["bands_formed_all_metal_ct"]
        rows.append(
            {
                "countryiso3code": code,
                "country_name": name,
                "bands_total_1995_2022": int(yearly.sum()),
                "years_nonzero_1995_2022": int((yearly > 0).sum()),
                "avg_per_year_1995_2022": round(float(yearly.mean()), 3),
                "peak_year": int(country.loc[yearly.idxmax(), "year"]) if not country.empty else pd.NA,
                "peak_count": int(yearly.max()) if not country.empty else 0,
            }
        )
    return pd.DataFrame(rows)


def build_markdown_summary(
    clean_bands: pd.DataFrame,
    unmatched: pd.DataFrame,
    panel: pd.DataFrame,
    core_summary: pd.DataFrame,
    output_path: Path,
) -> None:
    matched = clean_bands["countryiso3code"].notna().sum()
    usable_year = clean_bands["entry_year"].notna().sum()
    matched_usable = clean_bands["countryiso3code"].notna() & clean_bands["entry_year"].notna()
    panel_1995_2022 = panel.loc[(panel["year"] >= 1995) & (panel["year"] <= 2022)].copy()
    nonzero_cells = int((panel_1995_2022["bands_formed_all_metal_ct"] > 0).sum())
    top_unmatched = unmatched.head(10) if not unmatched.empty else pd.DataFrame(columns=["country_raw", "row_count"])
    lines = [
        "# All-metal outcome summary",
        "",
        "This output treats the Metal Archives snapshot as an all-metal source rather than a technical-death subset.",
        "",
        "## Headline counts",
        "",
        f"- Raw Metallum bands in snapshot: `{len(clean_bands)}`",
        f"- Matched to treatment-panel countries: `{int(matched)}`",
        f"- Usable formed years: `{int(usable_year)}`",
        f"- Matched countries with usable formed years: `{int(matched_usable.sum())}`",
        f"- Non-zero country-year cells in the all-country panel, `1995-2022`: `{nonzero_cells}`",
        "",
        "## Core markets, all metal",
        "",
        core_summary.to_markdown(index=False),
        "",
        "## Largest unmatched country strings",
        "",
        top_unmatched.to_markdown(index=False),
        "",
    ]
    output_path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    treatment_panel = pd.read_csv(TREATMENT_PANEL_PATH)
    raw_bands = load_snapshot(INPUT_DB)
    clean_bands = build_clean_bands(raw_bands, treatment_panel)
    unmatched = build_unmatched_country_report(clean_bands)
    panel = build_country_year_panel(clean_bands, treatment_panel)
    core_summary = build_core_summary(panel)

    clean_bands.to_csv(OUTPUT_DIR / "metal_archives_all_metal_band_clean.csv", index=False)
    unmatched.to_csv(OUTPUT_DIR / "metal_archives_all_metal_unmatched_countries.csv", index=False)
    panel.to_csv(OUTPUT_DIR / "metal_archives_all_metal_country_year_panel.csv", index=False)
    core_summary.to_csv(OUTPUT_DIR / "metal_archives_all_metal_core_country_summary.csv", index=False)
    build_markdown_summary(
        clean_bands=clean_bands,
        unmatched=unmatched,
        panel=panel,
        core_summary=core_summary,
        output_path=OUTPUT_DIR / "metal_archives_all_metal_summary.md",
    )

    print(f"Snapshot rows read: {len(raw_bands)}")
    print(f"Matched countries: {int(clean_bands['countryiso3code'].notna().sum())}")
    print(f"Usable formed years: {int(clean_bands['entry_year'].notna().sum())}")
    print(f"Matched and dated rows: {int((clean_bands['countryiso3code'].notna() & clean_bands['entry_year'].notna()).sum())}")
    print(f"Wrote all-metal outputs to {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
