from __future__ import annotations

from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data"
PROCESSED_DIR = DATA_DIR / "processed"
OUTPUT_DIR = PROCESSED_DIR / "country_genre_analysis"

SOURCE_MATRIX_PATH = DATA_DIR / "source_matrix.csv"
SEED_PATH = DATA_DIR / "blockbuster_album_seed.csv"
CORE_HITS_PATH = PROCESSED_DIR / "blockbuster_album_country_hits_core.csv"
OUTCOME_PANEL_PATH = PROCESSED_DIR / "metal_archives_all_metal_country_year_panel.csv"

OUTPUT_CSV_PATH = OUTPUT_DIR / "language_spillover_market_priority.csv"
OUTPUT_MD_PATH = OUTPUT_DIR / "language_spillover_market_priority.md"

MARKET_LANGUAGE_MAP = {
    "AUS": ("eng", "English"),
    "BRA": ("por", "Portuguese"),
    "DEU": ("deu", "German"),
    "FRA": ("fra", "French"),
    "GBR": ("eng", "English"),
    "ITA": ("ita", "Italian"),
    "SWE": ("swe", "Swedish"),
    "USA": ("eng", "English"),
}

AUTOMATION_DIFFICULTY_SCORE = {
    "low": 3,
    "medium": 2,
    "high": 1,
}


def classify_priority_tier(row: pd.Series) -> str:
    if row["already_in_core_panel_i"] == 1:
        return "already_built_reference"
    if row["same_language_foreign_seed_count"] >= 8 and row["automation_difficulty_score"] >= 2:
        return "next_best_extension"
    if row["same_language_foreign_seed_count"] >= 8:
        return "high_value_but_source_costly"
    if row["same_language_foreign_seed_count"] >= 1:
        return "secondary_extension"
    return "low_yield_for_current_seed"


def build_priority_note(row: pd.Series) -> str:
    market = str(row["market_code"])
    if row["priority_tier"] == "already_built_reference":
        return "Already in the core treatment panel; use as a reference market rather than the next extension."
    if market == "AUS":
        return "Best next same-language extension under the current English-heavy seed: official ARIA path plus solid outcome depth."
    if market == "USA":
        return "Large outcome market and strong English-language fit, but the currently audited official path is certification-led rather than chart-led."
    if row["priority_tier"] == "low_yield_for_current_seed":
        return "Current seed has little same-language foreign potential here; this market only rises if the seed adds more local-language breakthrough acts."
    return "Viable later extension, but not the highest-yield next move for the current language-spillover design."


def write_summary(priority: pd.DataFrame, seed: pd.DataFrame) -> None:
    total_seed = len(seed)
    english_seed = int((seed["artist_language_code"] == "eng").sum())
    built = priority.loc[priority["already_in_core_panel_i"] == 1].copy()
    unbuilt = priority.loc[priority["already_in_core_panel_i"] == 0].copy()

    lines: list[str] = []
    lines.append("# Language spillover market priority")
    lines.append("")
    lines.append("This file ranks the already-audited source markets by how useful they are for the")
    lines.append("`same_language_foreign` extension of the domestic-success design.")
    lines.append("")
    lines.append("## Seed language composition")
    lines.append("")
    lines.append(f"- Seed albums: `{total_seed}`")
    lines.append(f"- English-language seed albums: `{english_seed}`")
    lines.append(f"- Non-English or multiple-language seed albums: `{total_seed - english_seed}`")
    lines.append("")
    lines.append("The current seed is therefore heavily English-language. With the present seed, the")
    lines.append("same-language spillover design is mostly an English-market design unless more")
    lines.append("local-language breakthrough acts are added.")
    lines.append("")
    lines.append("## Highest-priority unbuilt markets")
    lines.append("")
    top_unbuilt = unbuilt.head(3)
    if top_unbuilt.empty:
        lines.append("- No unbuilt audited markets remain in the current source matrix.")
    else:
        for _, row in top_unbuilt.iterrows():
            lines.append(
                f"- `{row['market_code']}` `{row['country_name']}`: "
                f"`{int(row['same_language_foreign_seed_count'])}` same-language foreign seed candidates, "
                f"`{int(row['all_metal_bands_total_1995_2022'])}` all-metal bands in `1995-2022`, "
                f"`{row['automation_difficulty']}` source difficulty. {row['priority_note']}"
            )
    lines.append("")
    lines.append("## Already-built reference markets")
    lines.append("")
    top_built = built.loc[
        :, ["market_code", "country_name", "same_language_foreign_seed_count", "current_same_language_foreign_rows"]
    ]
    if top_built.empty:
        lines.append("- None.")
    else:
        for _, row in top_built.iterrows():
            lines.append(
                f"- `{row['market_code']}` `{row['country_name']}`: "
                f"`{int(row['same_language_foreign_seed_count'])}` same-language foreign seed matches, "
                f"`{int(row['current_same_language_foreign_rows'])}` currently recovered same-language foreign rows."
            )
    lines.append("")
    lines.append("## Practical read")
    lines.append("")
    if not top_unbuilt.empty:
        best_unbuilt = top_unbuilt.iloc[0]
        lines.append(
            f"- `{best_unbuilt['market_code']}` is now the cleanest unbuilt extension under the current seed."
        )
    else:
        lines.append("- No unbuilt audited markets remain in the current source matrix.")
    if (priority["market_code"] == "AUS").any() and int(priority.loc[priority["market_code"] == "AUS", "already_in_core_panel_i"].iloc[0]) == 1:
        lines.append("- `AUS` is now a built same-language reference market rather than a pending extension.")
    lines.append("- `USA` is substantively attractive but should still be treated as a certification-led or robustness-style market under the current audited source path.")
    lines.append("- `SWE`, `FRA`, `ITA`, `BRA`, and `DEU` remain low-yield language-spillover markets with the current seed because the seed does not contain enough foreign acts in those market languages.")
    lines.append("- If language spillovers remain central, the project eventually needs either more English-language destination markets or a broader seed of non-English-language flagship acts.")
    lines.append("")
    lines.append("## Full ranking")
    lines.append("")
    lines.append(
        priority[
            [
                "priority_rank",
                "market_code",
                "country_name",
                "market_language_name",
                "already_in_core_panel_i",
                "same_language_foreign_seed_count",
                "current_same_language_foreign_rows",
                "all_metal_bands_total_1995_2022",
                "automation_difficulty",
                "priority_tier",
            ]
        ].to_markdown(index=False)
    )
    lines.append("")
    OUTPUT_MD_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    source_matrix = pd.read_csv(SOURCE_MATRIX_PATH)
    seed = pd.read_csv(SEED_PATH)
    core_hits = pd.read_csv(CORE_HITS_PATH)
    outcome_panel = pd.read_csv(OUTCOME_PANEL_PATH)
    outcome_panel = outcome_panel.loc[
        (outcome_panel["year"] >= 1995) & (outcome_panel["year"] <= 2022)
    ].copy()
    outcome_depth = (
        outcome_panel.groupby(["countryiso3code", "country_name"], as_index=False)
        .agg(
            all_metal_bands_total_1995_2022=("bands_formed_all_metal_ct", "sum"),
            all_metal_years_nonzero_1995_2022=("bands_formed_all_metal_ct", lambda s: int((s > 0).sum())),
        )
        .rename(columns={"countryiso3code": "market_code"})
    )
    outcome_depth["all_metal_rank_1995_2022"] = (
        outcome_depth["all_metal_bands_total_1995_2022"].rank(method="min", ascending=False).astype(int)
    )

    source_matrix["market_code"] = source_matrix["market_code"].astype(str).str.upper()
    source_matrix["market_language_code"] = source_matrix["market_code"].map(
        lambda code: MARKET_LANGUAGE_MAP.get(code, ("", ""))[0]
    )
    source_matrix["market_language_name"] = source_matrix["market_code"].map(
        lambda code: MARKET_LANGUAGE_MAP.get(code, ("", ""))[1]
    )
    source_matrix["automation_difficulty_score"] = source_matrix["automation_difficulty"].map(
        AUTOMATION_DIFFICULTY_SCORE
    )

    seed["artist_language_code"] = seed["artist_language_code"].astype(str).str.lower()
    seed["artist_countryiso3code"] = seed["artist_countryiso3code"].astype(str).str.upper()

    core_hits["market_code"] = core_hits["market_code"].astype(str).str.upper()
    core_hits["artist_language_code"] = core_hits["artist_language_code"].astype(str).str.lower()
    core_hits["artist_countryiso3code"] = core_hits["artist_countryiso3code"].astype(str).str.upper()
    core_hits["market_language_code"] = core_hits["market_code"].map(
        lambda code: MARKET_LANGUAGE_MAP.get(code, ("", ""))[0]
    )
    core_hits["same_language_foreign_i"] = (
        (core_hits["artist_countryiso3code"] != core_hits["market_code"])
        & (core_hits["artist_language_code"] == core_hits["market_language_code"])
    ).astype(int)

    source_matrix["same_language_seed_count"] = source_matrix["market_language_code"].map(
        lambda code: int((seed["artist_language_code"] == code).sum())
    )
    source_matrix["same_language_foreign_seed_count"] = source_matrix.apply(
        lambda row: int(
            (
                (seed["artist_language_code"] == row["market_language_code"])
                & (seed["artist_countryiso3code"] != row["market_code"])
            ).sum()
        ),
        axis=1,
    )
    source_matrix["same_language_domestic_seed_count"] = source_matrix.apply(
        lambda row: int(
            (
                (seed["artist_language_code"] == row["market_language_code"])
                & (seed["artist_countryiso3code"] == row["market_code"])
            ).sum()
        ),
        axis=1,
    )

    core_market_rows = core_hits.groupby("market_code", as_index=False).size().rename(columns={"size": "current_core_rows"})
    core_same_language = (
        core_hits.groupby("market_code", as_index=False)["same_language_foreign_i"]
        .sum()
        .rename(columns={"same_language_foreign_i": "current_same_language_foreign_rows"})
    )

    source_matrix = source_matrix.loc[source_matrix["source_type"] != "commercial"].copy()

    priority = source_matrix.merge(
        outcome_depth[
            [
                "market_code",
                "all_metal_bands_total_1995_2022",
                "all_metal_years_nonzero_1995_2022",
                "all_metal_rank_1995_2022",
            ]
        ],
        on="market_code",
        how="left",
    )
    priority = priority.merge(core_market_rows, on="market_code", how="left")
    priority = priority.merge(core_same_language, on="market_code", how="left")

    fill_zero_columns = [
        "all_metal_bands_total_1995_2022",
        "all_metal_years_nonzero_1995_2022",
        "current_core_rows",
        "current_same_language_foreign_rows",
    ]
    for column in fill_zero_columns:
        priority[column] = priority[column].fillna(0).astype(int)

    priority["already_in_core_panel_i"] = (priority["current_core_rows"] > 0).astype(int)
    priority["priority_tier"] = priority.apply(classify_priority_tier, axis=1)
    priority["priority_note"] = priority.apply(build_priority_note, axis=1)

    priority = priority.sort_values(
        [
            "already_in_core_panel_i",
            "same_language_foreign_seed_count",
            "automation_difficulty_score",
            "all_metal_bands_total_1995_2022",
            "market_code",
        ],
        ascending=[True, False, False, False, True],
    ).reset_index(drop=True)
    priority["priority_rank"] = range(1, len(priority) + 1)

    priority.to_csv(OUTPUT_CSV_PATH, index=False)
    write_summary(priority, seed)


if __name__ == "__main__":
    main()
