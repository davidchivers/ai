from pathlib import Path

import pandas as pd


YEAR_START = 1995
YEAR_END = 2022
CORE_MARKETS = {
    "USA": "United States",
    "GBR": "United Kingdom",
    "DEU": "Germany",
    "ITA": "Italy",
    "SWE": "Sweden",
    "AUS": "Australia",
}
WINDOW_RADIUS = 3


def load_band_data(band_path: Path) -> pd.DataFrame:
    bands = pd.read_csv(band_path)
    bands = bands.loc[bands["countryiso3code"].notna() & bands["entry_year"].notna()].copy()
    bands["entry_year"] = bands["entry_year"].astype(int)
    bands = bands.loc[(bands["entry_year"] >= YEAR_START) & (bands["entry_year"] <= YEAR_END)].copy()
    bands["strict_main"] = (bands["subgenre_flag_main"].fillna(0) == 1).astype(int)
    # "broad family" keeps the strict sample and adds the broad technical-family matches.
    bands["broad_family"] = (
        (bands["subgenre_flag_main"].fillna(0) == 1)
        | (bands["subgenre_flag_broad"].fillna(0) == 1)
    ).astype(int)
    return bands


def build_country_rankings(bands: pd.DataFrame) -> pd.DataFrame:
    ranking_frames = []
    for scope in ["strict_main", "broad_family"]:
        totals = (
            bands.groupby(["countryiso3code", "country_std"], as_index=False)[scope]
            .sum()
            .rename(columns={"country_std": "country_name", scope: "bands_total"})
            .sort_values("bands_total", ascending=False)
            .reset_index(drop=True)
        )
        totals["scope"] = scope
        totals["rank_all_countries"] = totals.index + 1
        ranking_frames.append(totals)
    return pd.concat(ranking_frames, ignore_index=True)


def build_core_country_year_panel(bands: pd.DataFrame) -> pd.DataFrame:
    scope_year = (
        bands.loc[bands["countryiso3code"].isin(CORE_MARKETS)]
        .groupby(["countryiso3code", "entry_year"], as_index=False)[["strict_main", "broad_family"]]
        .sum()
        .rename(columns={"entry_year": "year"})
    )
    grid = pd.MultiIndex.from_product(
        [CORE_MARKETS.keys(), range(YEAR_START, YEAR_END + 1)],
        names=["countryiso3code", "year"],
    ).to_frame(index=False)
    panel = grid.merge(scope_year, on=["countryiso3code", "year"], how="left").fillna(0)
    panel["country_name"] = panel["countryiso3code"].map(CORE_MARKETS)
    panel["strict_main"] = panel["strict_main"].astype(int)
    panel["broad_family"] = panel["broad_family"].astype(int)
    return panel[
        [
            "countryiso3code",
            "country_name",
            "year",
            "strict_main",
            "broad_family",
        ]
    ]


def build_core_country_summary(panel: pd.DataFrame, rankings: pd.DataFrame) -> pd.DataFrame:
    rows = []
    for code, country_name in CORE_MARKETS.items():
        country_panel = panel.loc[panel["countryiso3code"] == code].copy()
        for scope in ["strict_main", "broad_family"]:
            yearly = country_panel[scope]
            nonzero_years = int((yearly > 0).sum())
            scope_rank = rankings.loc[
                (rankings["scope"] == scope) & (rankings["countryiso3code"] == code),
                "rank_all_countries",
            ]
            rows.append(
                {
                    "countryiso3code": code,
                    "country_name": country_name,
                    "scope": scope,
                    "bands_total_1995_2022": int(yearly.sum()),
                    "years_nonzero_1995_2022": nonzero_years,
                    "share_nonzero_years_1995_2022": round(nonzero_years / len(country_panel), 3),
                    "avg_per_year_1995_2022": round(float(yearly.mean()), 3),
                    "avg_per_nonzero_year": round(float(yearly.loc[yearly > 0].mean()), 3)
                    if nonzero_years
                    else 0.0,
                    "peak_year": int(country_panel.loc[yearly.idxmax(), "year"]),
                    "peak_count": int(yearly.max()),
                    "rank_all_countries_1995_2022": int(scope_rank.iloc[0]) if not scope_rank.empty else pd.NA,
                }
            )
    summary = pd.DataFrame(rows)
    strict = summary.loc[summary["scope"] == "strict_main", ["countryiso3code", "bands_total_1995_2022"]].rename(
        columns={"bands_total_1995_2022": "strict_total_1995_2022"}
    )
    broad = summary.loc[
        summary["scope"] == "broad_family", ["countryiso3code", "bands_total_1995_2022"]
    ].rename(columns={"bands_total_1995_2022": "broad_total_1995_2022"})
    ratios = strict.merge(broad, on="countryiso3code", how="inner")
    ratios["broad_to_strict_total_ratio"] = ratios["broad_total_1995_2022"] / ratios["strict_total_1995_2022"]
    summary = summary.merge(
        ratios[["countryiso3code", "broad_to_strict_total_ratio"]],
        on="countryiso3code",
        how="left",
    )
    summary["broad_to_strict_total_ratio"] = summary["broad_to_strict_total_ratio"].round(3)
    return summary


def build_pilot_event_windows(panel: pd.DataFrame, pilot_hits: pd.DataFrame) -> pd.DataFrame:
    pilot_hits = pilot_hits.copy()
    pilot_hits["hit_year"] = pilot_hits["hit_year"].astype(int)
    rows = []
    for hit in pilot_hits.itertuples(index=False):
        country_panel = panel.loc[panel["countryiso3code"] == hit.market_code].copy()
        for relative_year in range(-WINDOW_RADIUS, WINDOW_RADIUS + 1):
            calendar_year = hit.hit_year + relative_year
            match = country_panel.loc[country_panel["year"] == calendar_year]
            strict_value = int(match["strict_main"].iloc[0]) if not match.empty else 0
            broad_value = int(match["broad_family"].iloc[0]) if not match.empty else 0
            rows.append(
                {
                    "seed_album_id": hit.seed_album_id,
                    "artist_name": hit.artist_name,
                    "album_title": hit.album_title,
                    "market_code": hit.market_code,
                    "country_name": hit.country_name,
                    "hit_year": hit.hit_year,
                    "relative_year": relative_year,
                    "calendar_year": calendar_year,
                    "strict_main_bands": strict_value,
                    "broad_family_bands": broad_value,
                }
            )
    return pd.DataFrame(rows)


def build_markdown_summary(
    output_path: Path,
    panel: pd.DataFrame,
    summary: pd.DataFrame,
    rankings: pd.DataFrame,
    pilot_windows: pd.DataFrame,
) -> None:
    all_totals = []
    for scope in ["strict_main", "broad_family"]:
        total_bands = int(panel[scope].sum())
        nonzero_cells = int((panel[scope] > 0).sum())
        all_totals.append(
            {
                "scope": scope,
                "core_bands_total": total_bands,
                "core_nonzero_country_years": nonzero_cells,
                "core_nonzero_share": round(nonzero_cells / len(panel), 3),
            }
        )
    all_totals_df = pd.DataFrame(all_totals)

    strict_total = int(
        rankings.loc[rankings["scope"] == "strict_main", "bands_total"].sum()
    )
    broad_total = int(
        rankings.loc[rankings["scope"] == "broad_family", "bands_total"].sum()
    )
    core_strict_total = int(all_totals_df.loc[all_totals_df["scope"] == "strict_main", "core_bands_total"].iloc[0])
    core_broad_total = int(all_totals_df.loc[all_totals_df["scope"] == "broad_family", "core_bands_total"].iloc[0])

    strict_summary = summary.loc[summary["scope"] == "strict_main"].copy()
    broad_summary = summary.loc[summary["scope"] == "broad_family"].copy()
    core_summary_table = strict_summary[
        [
            "countryiso3code",
            "country_name",
            "bands_total_1995_2022",
            "years_nonzero_1995_2022",
            "peak_year",
            "peak_count",
            "rank_all_countries_1995_2022",
        ]
    ].rename(
        columns={
            "bands_total_1995_2022": "strict_total",
            "years_nonzero_1995_2022": "strict_nonzero_years",
            "peak_year": "strict_peak_year",
            "peak_count": "strict_peak_count",
            "rank_all_countries_1995_2022": "strict_rank",
        }
    )
    core_summary_table = core_summary_table.merge(
        broad_summary[
            [
                "countryiso3code",
                "bands_total_1995_2022",
                "years_nonzero_1995_2022",
                "peak_year",
                "peak_count",
                "rank_all_countries_1995_2022",
                "broad_to_strict_total_ratio",
            ]
        ].rename(
            columns={
                "bands_total_1995_2022": "broad_total",
                "years_nonzero_1995_2022": "broad_nonzero_years",
                "peak_year": "broad_peak_year",
                "peak_count": "broad_peak_count",
                "rank_all_countries_1995_2022": "broad_rank",
                "broad_to_strict_total_ratio": "broad_to_strict_ratio",
            }
        ),
        on="countryiso3code",
        how="left",
    )
    core_summary_table["broad_to_strict_ratio"] = core_summary_table["broad_to_strict_ratio"].round(3)
    core_summary_table = core_summary_table[
        [
            "countryiso3code",
            "country_name",
            "strict_total",
            "broad_total",
            "broad_to_strict_ratio",
            "strict_nonzero_years",
            "broad_nonzero_years",
            "strict_peak_year",
            "broad_peak_year",
            "strict_rank",
            "broad_rank",
        ]
    ].sort_values("broad_rank")

    top_rankings = rankings.loc[rankings["rank_all_countries"] <= 10].copy()
    top_rankings["bands_total"] = top_rankings["bands_total"].astype(int)

    pilot_window_table = (
        pilot_windows.groupby(["market_code", "country_name", "hit_year", "relative_year"], as_index=False)[
            ["strict_main_bands", "broad_family_bands"]
        ].sum()
    )

    lines = [
        "# Outcome scope exploration",
        "",
        f"Window: `{YEAR_START}-{YEAR_END}`",
        "",
        "## Headline read",
        "",
        f"- Strict technical-death sample totals `{strict_total}` matched bands across all countries and `{core_strict_total}` in the six core treatment markets.",
        f"- Broad technical-family sample totals `{broad_total}` matched bands across all countries and `{core_broad_total}` in the six core treatment markets.",
        f"- In the six core markets, non-zero country-year cells rise from `{int(all_totals_df.loc[all_totals_df['scope'] == 'strict_main', 'core_nonzero_country_years'].iloc[0])}` of `{len(panel)}` under the strict sample to `{int(all_totals_df.loc[all_totals_df['scope'] == 'broad_family', 'core_nonzero_country_years'].iloc[0])}` of `{len(panel)}` under the broad sample.",
        "- Inference: the broader technical-family outcome looks materially less sparse and may be a better fit for a blockbuster-hit design than the strict technical-death-only outcome.",
        "",
        "## Core country summary",
        "",
        core_summary_table.to_markdown(index=False),
        "",
        "## Top countries by outcome scope",
        "",
        top_rankings.to_markdown(index=False),
        "",
        "## Pilot hit windows",
        "",
        "These windows are descriptive only. They use the current four-row UK/Italy pilot treatment sample and should not be interpreted as causal evidence.",
        "",
        pilot_window_table.to_markdown(index=False),
        "",
    ]
    output_path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    workspace_root = Path(__file__).resolve().parents[3]
    project_root = workspace_root / "research_ideas" / "metal"
    output_dir = project_root / "data" / "exploration"
    output_dir.mkdir(parents=True, exist_ok=True)

    band_path = (
        workspace_root
        / "research_ideas"
        / "learning_by_viewing"
        / "music"
        / "data"
        / "strategy_8_music_pilot"
        / "processed"
        / "metal_archives_band_clean.csv"
    )
    pilot_hits_path = project_root / "data" / "blockbuster_album_country_hits_pilot_sample.csv"

    bands = load_band_data(band_path)
    rankings = build_country_rankings(bands)
    core_panel = build_core_country_year_panel(bands)
    core_summary = build_core_country_summary(core_panel, rankings)
    pilot_hits = pd.read_csv(pilot_hits_path)
    pilot_windows = build_pilot_event_windows(core_panel, pilot_hits)

    core_summary.to_csv(output_dir / "core_country_outcome_scope_summary.csv", index=False)
    core_panel.to_csv(output_dir / "core_country_outcome_scope_years.csv", index=False)
    rankings.to_csv(output_dir / "top_country_scope_rankings.csv", index=False)
    pilot_windows.to_csv(output_dir / "pilot_hit_event_windows.csv", index=False)
    build_markdown_summary(
        output_path=output_dir / "outcome_scope_summary.md",
        panel=core_panel,
        summary=core_summary,
        rankings=rankings,
        pilot_windows=pilot_windows,
    )

    print(f"Wrote exploration outputs to {output_dir}")


if __name__ == "__main__":
    main()
