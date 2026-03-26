from __future__ import annotations

from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CORE_PATH = PROJECT_ROOT / "data" / "processed" / "blockbuster_album_country_hits_core.csv"
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed" / "country_genre_analysis"

MARKET_LANGUAGE_MAP = {
    "BRA": ("por", "Portuguese"),
    "DEU": ("deu", "German"),
    "FIN": ("fin", "Finnish"),
    "FRA": ("fra", "French"),
    "GBR": ("eng", "English"),
    "ITA": ("ita", "Italian"),
    "NOR": ("nor", "Norwegian"),
    "SWE": ("swe", "Swedish"),
    "USA": ("eng", "English"),
}


def classify_row(row: pd.Series) -> str:
    if str(row.get("market_exposure_type", "")) == "home_market":
        return "domestic_success"

    artist_language_code = str(row.get("artist_language_code", "")).strip().lower()
    market_language_code = str(row.get("market_language_code", "")).strip().lower()

    if artist_language_code == "mul":
        return "multiple_language_foreign"
    if not artist_language_code or not market_language_code:
        return "language_unknown_foreign"
    if artist_language_code == market_language_code:
        return "same_language_foreign"
    return "different_language_foreign"


def write_summary(preview: pd.DataFrame, summary_by_class: pd.DataFrame) -> None:
    lines: list[str] = []
    lines.append("# Spillover coding preview")
    lines.append("")
    lines.append("This file applies a first-pass language-based spillover rule to the existing")
    lines.append("`blockbuster_album_country_hits_core.csv` treatment rows.")
    lines.append("")
    lines.append("## Coding rule")
    lines.append("")
    lines.append("- `domestic_success`: artist home country equals market country")
    lines.append("- `same_language_foreign`: foreign artist and artist language matches market language")
    lines.append("- `different_language_foreign`: foreign artist and artist language differs from market language")
    lines.append("- `multiple_language_foreign`: foreign artist coded as `mul`")
    lines.append("")
    lines.append("Current market-language map used in this preview:")
    lines.append("")
    lines.append("| market | language code | language |")
    lines.append("|:--|:--|:--|")
    for market_code, (language_code, language_name) in sorted(MARKET_LANGUAGE_MAP.items()):
        lines.append(f"| {market_code} | {language_code} | {language_name} |")
    lines.append("")
    lines.append("## Current counts in the core treatment build")
    lines.append("")
    lines.append(summary_by_class.to_markdown(index=False))
    lines.append("")
    lines.append("## Practical read")
    lines.append("")
    lines.append("- The rule is implementable with the current core panel because artist language is already coded in the seed.")
    lines.append("- The current four-market panel still has thin same-language foreign variation.")
    lines.append("- In practice, most same-language foreign rows currently come from English-language foreign acts hitting the UK.")
    lines.append("- Germany, Italy, and Brazil currently contribute mostly different-language foreign exposure under this rule.")
    lines.append("- That means language spillovers are conceptually sharp, but the current market set is not yet ideal for estimating them well.")
    lines.append("")
    lines.append("## Preview file")
    lines.append("")
    lines.append("- `foreign_spillover_coding_preview.csv`")
    (OUTPUT_DIR / "foreign_spillover_coding_summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    core = pd.read_csv(CORE_PATH)
    core["market_code"] = core["market_code"].astype(str).str.upper()
    core["market_language_code"] = core["market_code"].map(lambda code: MARKET_LANGUAGE_MAP.get(code, ("", ""))[0])
    core["market_language_name"] = core["market_code"].map(lambda code: MARKET_LANGUAGE_MAP.get(code, ("", ""))[1])
    core["spillover_class"] = core.apply(classify_row, axis=1)

    preview_columns = [
        "artist_name",
        "album_title",
        "artist_countryiso3code",
        "artist_country_name",
        "artist_language_code",
        "artist_language_name",
        "market_code",
        "country_name",
        "market_language_code",
        "market_language_name",
        "market_exposure_type",
        "spillover_class",
        "hit_year",
    ]
    preview = core[preview_columns].copy()
    preview = preview.sort_values(
        ["spillover_class", "market_code", "hit_year", "artist_name", "album_title"],
        ascending=[True, True, True, True, True],
    ).reset_index(drop=True)

    summary_by_class = (
        preview.groupby("spillover_class", as_index=False)
        .size()
        .rename(columns={"size": "row_count"})
        .sort_values(["row_count", "spillover_class"], ascending=[False, True])
        .reset_index(drop=True)
    )

    preview.to_csv(OUTPUT_DIR / "foreign_spillover_coding_preview.csv", index=False)
    summary_by_class.to_csv(OUTPUT_DIR / "foreign_spillover_coding_counts.csv", index=False)
    pd.DataFrame(
        [
            {
                "market_code": market_code,
                "market_language_code": language_code,
                "market_language_name": language_name,
            }
            for market_code, (language_code, language_name) in sorted(MARKET_LANGUAGE_MAP.items())
        ]
    ).to_csv(OUTPUT_DIR / "pilot_market_language_reference.csv", index=False)
    write_summary(preview, summary_by_class)


if __name__ == "__main__":
    main()
