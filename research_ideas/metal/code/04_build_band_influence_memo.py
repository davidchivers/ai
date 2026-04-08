from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = PROJECT_ROOT / "data" / "processed"
DATA_DIR = PROJECT_ROOT / "data"

HITS_PATH = OUTPUT_DIR / "blockbuster_album_country_hits_core.csv"
OUTCOME_PANEL_PATH = OUTPUT_DIR / "metal_archives_all_metal_country_year_panel.csv"
SEED_PATH = DATA_DIR / "blockbuster_album_seed.csv"

EVENT_OUTPUT_PATH = OUTPUT_DIR / "blockbuster_band_influence_event_windows.csv"
RANKING_OUTPUT_PATH = OUTPUT_DIR / "blockbuster_band_influence_ranking.csv"
EVENT_STUDY_OUTPUT_PATH = OUTPUT_DIR / "blockbuster_band_influence_event_study.csv"
MEMO_OUTPUT_PATH = OUTPUT_DIR / "blockbuster_band_influence_memo.md"

PRE_WINDOW_YEARS = 3
POST_WINDOW_YEARS = 3
RESIDUAL_FIT_START_YEAR = 1993
RESIDUAL_FIT_END_YEAR = 2022
EVENT_STUDY_RELATIVE_YEARS = list(range(-PRE_WINDOW_YEARS, POST_WINDOW_YEARS))

OUTCOME_COLUMNS = {
    "all_metal": "bands_formed_all_metal_ct",
    "unsigned": "bands_formed_all_metal_unsigned_ct",
    "signed": "bands_formed_all_metal_signed_ct",
}
RESIDUAL_COLUMNS = {short_name: f"{short_name}_fe_resid" for short_name in OUTCOME_COLUMNS}

EVENT_DEFINITIONS = {
    "first_presence_by_band_market": {
        "label": "First visible band-market success",
        "short_label": "presence",
        "rule_text": "first recovered chart-presence or certification signal by band-market",
    },
    "first_certification_by_band_market": {
        "label": "First certification by band-market",
        "short_label": "certification",
        "rule_text": "first gold-or-higher certification by band-market",
    },
    "first_top10_by_band_market": {
        "label": "First top-10 by band-market",
        "short_label": "top10",
        "rule_text": "first recovered top-10 album-chart hit by band-market",
    },
}


def scalar_or_na(value: object) -> object:
    if value is None or pd.isna(value):
        return pd.NA
    return float(value)


def pct_text(value: object) -> str:
    if value is None or pd.isna(value):
        return "NA"
    return f"{float(value) * 100:.1f}%"


def gap_text(value: object) -> str:
    if value is None or pd.isna(value):
        return "NA"
    return f"{float(value):+.1f}"


def round_table_columns(frame: pd.DataFrame, columns: list[str]) -> pd.DataFrame:
    table = frame.copy()
    for column in columns:
        if column in table.columns:
            table[column] = table[column].astype(float).round(1)
    return table


def load_inputs() -> tuple[pd.DataFrame, pd.DataFrame]:
    hits = pd.read_csv(HITS_PATH).fillna(pd.NA)
    panel = pd.read_csv(OUTCOME_PANEL_PATH).fillna(pd.NA)

    if "artist_countryiso3code" not in hits.columns or "artist_country_name" not in hits.columns:
        seed_metadata = pd.read_csv(
            SEED_PATH,
            usecols=["seed_album_id", "artist_countryiso3code", "artist_country_name"],
        ).fillna(pd.NA)
        hits = hits.merge(seed_metadata, on="seed_album_id", how="left", suffixes=("", "_seed"))
        for column in ["artist_countryiso3code", "artist_country_name"]:
            seed_column = f"{column}_seed"
            if seed_column in hits.columns:
                if column in hits.columns:
                    hits[column] = hits[column].combine_first(hits[seed_column])
                else:
                    hits[column] = hits[seed_column]
                hits = hits.drop(columns=[seed_column])

    hits["top10_flag"] = pd.to_numeric(hits["top10_flag"], errors="coerce").fillna(0).astype(int)
    hits["no1_flag"] = pd.to_numeric(hits["no1_flag"], errors="coerce").fillna(0).astype(int)
    hits["hit_year"] = pd.to_numeric(hits["hit_year"], errors="coerce").astype("Int64")
    hits["peak_position"] = pd.to_numeric(hits["peak_position"], errors="coerce")
    hits["weeks_on_chart"] = pd.to_numeric(hits["weeks_on_chart"], errors="coerce")
    hits["has_chart_signal_i"] = (
        hits["peak_position"].notna()
        | hits["weeks_on_chart"].notna()
        | hits["entry_date"].notna()
        | hits["observation_date"].notna()
    ).astype(int)
    hits["has_certification_signal_i"] = hits["certification_level"].notna().astype(int)
    hits["has_presence_signal_i"] = hits["hit_year"].notna().astype(int)

    if "home_market_i" not in hits.columns or "foreign_market_i" not in hits.columns or "market_exposure_type" not in hits.columns:
        artist_country = hits.get("artist_countryiso3code", pd.Series("", index=hits.index)).fillna("").astype(str).str.strip()
        market_code = hits.get("market_code", pd.Series("", index=hits.index)).fillna("").astype(str).str.strip()
        hits["home_market_i"] = ((artist_country != "") & (market_code != "") & (artist_country == market_code)).astype(int)
        hits["foreign_market_i"] = ((artist_country != "") & (market_code != "") & (artist_country != market_code)).astype(int)
        hits["market_exposure_type"] = "unknown_market"
        hits.loc[hits["foreign_market_i"] == 1, "market_exposure_type"] = "foreign_market"
        hits.loc[hits["home_market_i"] == 1, "market_exposure_type"] = "home_market"
    else:
        hits["home_market_i"] = pd.to_numeric(hits["home_market_i"], errors="coerce").fillna(0).astype(int)
        hits["foreign_market_i"] = pd.to_numeric(hits["foreign_market_i"], errors="coerce").fillna(0).astype(int)

    for column in OUTCOME_COLUMNS.values():
        panel[column] = pd.to_numeric(panel[column], errors="coerce").fillna(0).astype(int)
    panel["year"] = pd.to_numeric(panel["year"], errors="coerce").astype(int)

    return hits, panel


def compute_two_way_fe_residuals(panel: pd.DataFrame, outcome_column: str, residual_column: str) -> pd.DataFrame:
    fit_panel = panel.loc[
        panel["year"].between(RESIDUAL_FIT_START_YEAR, RESIDUAL_FIT_END_YEAR),
        ["countryiso3code", "year", outcome_column],
    ].copy()
    fit_panel[outcome_column] = pd.to_numeric(fit_panel[outcome_column], errors="coerce").fillna(0.0)

    intercept = pd.DataFrame({"intercept": np.ones(len(fit_panel), dtype=float)}, index=fit_panel.index)
    country_dummies = pd.get_dummies(fit_panel["countryiso3code"], prefix="country", drop_first=True, dtype=float)
    year_dummies = pd.get_dummies(fit_panel["year"], prefix="year", drop_first=True, dtype=float)
    design = pd.concat([intercept, country_dummies, year_dummies], axis=1)

    y = fit_panel[outcome_column].to_numpy(dtype=float)
    x = design.to_numpy(dtype=float)
    beta = np.linalg.lstsq(x, y, rcond=None)[0]
    fit_panel[residual_column] = y - (x @ beta)
    return fit_panel[["countryiso3code", "year", residual_column]]


def add_residualized_outcomes(panel: pd.DataFrame) -> pd.DataFrame:
    residualized = panel.copy()
    for short_name, outcome_column in OUTCOME_COLUMNS.items():
        residual_column = RESIDUAL_COLUMNS[short_name]
        residual_frame = compute_two_way_fe_residuals(
            panel=panel,
            outcome_column=outcome_column,
            residual_column=residual_column,
        )
        residualized = residualized.merge(
            residual_frame,
            on=["countryiso3code", "year"],
            how="left",
            validate="one_to_one",
        )
    return residualized


def add_event_priority(hits: pd.DataFrame, event_definition: str) -> pd.DataFrame:
    prioritized = hits.copy()
    if event_definition == "first_presence_by_band_market":
        prioritized["definition_priority"] = np.select(
            [
                prioritized["top10_flag"] == 1,
                prioritized["has_chart_signal_i"] == 1,
                prioritized["has_certification_signal_i"] == 1,
            ],
            [0, 1, 2],
            default=3,
        )
    elif event_definition == "first_certification_by_band_market":
        prioritized["definition_priority"] = np.where(prioritized["certification_date"].notna(), 0, 1)
    elif event_definition == "first_top10_by_band_market":
        prioritized["definition_priority"] = np.where(prioritized["no1_flag"] == 1, 0, 1)
    else:
        prioritized["definition_priority"] = 9
    return prioritized


def filter_hits_for_definition(hits: pd.DataFrame, event_definition: str) -> pd.DataFrame:
    if event_definition == "first_presence_by_band_market":
        filtered = hits.loc[hits["has_presence_signal_i"] == 1].copy()
    elif event_definition == "first_certification_by_band_market":
        filtered = hits.loc[(hits["has_presence_signal_i"] == 1) & (hits["has_certification_signal_i"] == 1)].copy()
    elif event_definition == "first_top10_by_band_market":
        filtered = hits.loc[(hits["has_presence_signal_i"] == 1) & (hits["top10_flag"] == 1)].copy()
    else:
        filtered = pd.DataFrame(columns=hits.columns)

    if filtered.empty:
        return filtered

    filtered = add_event_priority(filtered, event_definition=event_definition)
    filtered = filtered.sort_values(
        ["artist_name", "market_code", "hit_year", "definition_priority", "album_title"],
        ascending=[True, True, True, True, True],
    ).reset_index(drop=True)
    filtered["same_market_year_event_ct"] = filtered.groupby(["market_code", "hit_year"])["seed_album_id"].transform("count")
    return filtered


def build_event_windows(hits: pd.DataFrame, panel: pd.DataFrame) -> pd.DataFrame:
    observed_outcome_mask = panel[list(OUTCOME_COLUMNS.values())].sum(axis=1) > 0
    observed_outcome_max_year = int(panel.loc[observed_outcome_mask, "year"].max())

    rows: list[dict[str, object]] = []
    for event_definition, metadata in EVENT_DEFINITIONS.items():
        filtered_hits = filter_hits_for_definition(hits=hits, event_definition=event_definition)
        if filtered_hits.empty:
            continue

        first_hits = filtered_hits.drop_duplicates(["artist_name", "market_code"], keep="first").copy()
        first_hits["post_window_complete_i"] = (
            first_hits["hit_year"].notna() & ((first_hits["hit_year"] + POST_WINDOW_YEARS - 1) <= observed_outcome_max_year)
        ).astype(int)

        for hit in first_hits.itertuples(index=False):
            if pd.isna(hit.hit_year):
                continue

            country_panel = panel.loc[panel["countryiso3code"] == hit.market_code].copy()
            hit_year = int(hit.hit_year)
            pre_window = country_panel.loc[country_panel["year"].between(hit_year - PRE_WINDOW_YEARS, hit_year - 1)]
            post_window = country_panel.loc[country_panel["year"].between(hit_year, hit_year + POST_WINDOW_YEARS - 1)]

            row: dict[str, object] = {
                "event_definition": event_definition,
                "event_definition_label": metadata["label"],
                "event_definition_short": metadata["short_label"],
                "artist_name": hit.artist_name,
                "album_title": hit.album_title,
                "artist_countryiso3code": hit.artist_countryiso3code,
                "artist_country_name": hit.artist_country_name,
                "market_code": hit.market_code,
                "country_name": hit.country_name,
                "market_exposure_type": hit.market_exposure_type,
                "home_market_i": int(hit.home_market_i),
                "foreign_market_i": int(hit.foreign_market_i),
                "hit_year": hit_year,
                "peak_position": hit.peak_position,
                "top10_flag": int(hit.top10_flag),
                "certification_level": hit.certification_level,
                "same_market_year_event_ct": int(hit.same_market_year_event_ct),
                "post_window_complete_i": int(hit.post_window_complete_i),
                "window_pre": f"{hit_year - PRE_WINDOW_YEARS}-{hit_year - 1}",
                "window_post": f"{hit_year}-{hit_year + POST_WINDOW_YEARS - 1}",
            }

            for short_name, outcome_column in OUTCOME_COLUMNS.items():
                pre_total = int(pre_window[outcome_column].sum())
                post_total = int(post_window[outcome_column].sum())
                row[f"pre_{short_name}_ct"] = pre_total
                row[f"post_{short_name}_ct"] = post_total
                row[f"delta_{short_name}_ct"] = post_total - pre_total
                row[f"pct_{short_name}"] = ((post_total / pre_total) - 1.0) if pre_total > 0 else pd.NA

                residual_column = RESIDUAL_COLUMNS[short_name]
                pre_resid_mean = scalar_or_na(pre_window[residual_column].mean())
                post_resid_mean = scalar_or_na(post_window[residual_column].mean())
                row[f"pre_{short_name}_resid_mean"] = pre_resid_mean
                row[f"post_{short_name}_resid_mean"] = post_resid_mean
                if pre_resid_mean is pd.NA or post_resid_mean is pd.NA:
                    row[f"delta_{short_name}_resid_mean"] = pd.NA
                else:
                    row[f"delta_{short_name}_resid_mean"] = float(post_resid_mean) - float(pre_resid_mean)

            rows.append(row)

    event_windows = pd.DataFrame(rows)
    if event_windows.empty:
        return event_windows
    return event_windows.sort_values(
        ["event_definition", "post_window_complete_i", "artist_name", "market_code", "hit_year"],
        ascending=[True, False, True, True, True],
    ).reset_index(drop=True)


def summarize_ranking(frame: pd.DataFrame, group_columns: list[str]) -> pd.DataFrame:
    return (
        frame.groupby(group_columns, dropna=False)
        .agg(
            market_event_ct=("market_code", "size"),
            mean_pct_all_metal=("pct_all_metal", "mean"),
            mean_pct_unsigned=("pct_unsigned", "mean"),
            mean_delta_all_metal_ct=("delta_all_metal_ct", "mean"),
            mean_delta_unsigned_ct=("delta_unsigned_ct", "mean"),
            mean_resid_gap_all_metal=("delta_all_metal_resid_mean", "mean"),
            mean_resid_gap_unsigned=("delta_unsigned_resid_mean", "mean"),
            total_resid_gap_all_metal=("delta_all_metal_resid_mean", "sum"),
            total_resid_gap_unsigned=("delta_unsigned_resid_mean", "sum"),
            max_same_market_year_event_ct=("same_market_year_event_ct", "max"),
        )
        .reset_index()
    )


def build_band_ranking(event_windows: pd.DataFrame) -> pd.DataFrame:
    complete = event_windows.loc[event_windows["post_window_complete_i"] == 1].copy()
    if complete.empty:
        return pd.DataFrame()

    overall = summarize_ranking(complete, ["event_definition", "event_definition_label", "artist_name"])
    overall["ranking_scope"] = "overall"
    overall["market_exposure_type"] = "all_markets"

    by_exposure = summarize_ranking(
        complete,
        ["event_definition", "event_definition_label", "artist_name", "market_exposure_type"],
    )
    by_exposure["ranking_scope"] = "exposure_type"

    ranking = pd.concat([overall, by_exposure], ignore_index=True, sort=False)
    return ranking.sort_values(
        [
            "event_definition",
            "ranking_scope",
            "market_exposure_type",
            "mean_resid_gap_all_metal",
            "mean_resid_gap_unsigned",
            "market_event_ct",
            "artist_name",
        ],
        ascending=[True, True, True, False, False, False, True],
    ).reset_index(drop=True)


def build_event_study_rows(event_windows: pd.DataFrame, panel: pd.DataFrame) -> pd.DataFrame:
    complete = event_windows.loc[event_windows["post_window_complete_i"] == 1].copy()
    if complete.empty:
        return pd.DataFrame()

    panel_lookup = panel.set_index(["countryiso3code", "year"])
    rows: list[dict[str, object]] = []
    for event in complete.itertuples(index=False):
        for relative_year in EVENT_STUDY_RELATIVE_YEARS:
            event_year = int(event.hit_year) + relative_year
            key = (event.market_code, event_year)
            if key not in panel_lookup.index:
                continue

            panel_row = panel_lookup.loc[key]
            if isinstance(panel_row, pd.DataFrame):
                panel_row = panel_row.iloc[0]

            row: dict[str, object] = {
                "event_definition": event.event_definition,
                "event_definition_label": event.event_definition_label,
                "artist_name": event.artist_name,
                "album_title": event.album_title,
                "market_code": event.market_code,
                "country_name": event.country_name,
                "market_exposure_type": event.market_exposure_type,
                "hit_year": int(event.hit_year),
                "event_year": event_year,
                "relative_year": relative_year,
            }
            for short_name, outcome_column in OUTCOME_COLUMNS.items():
                row[f"{short_name}_ct"] = int(panel_row[outcome_column])
                row[RESIDUAL_COLUMNS[short_name]] = scalar_or_na(panel_row[RESIDUAL_COLUMNS[short_name]])
            rows.append(row)

    event_study_rows = pd.DataFrame(rows)
    if event_study_rows.empty:
        return event_study_rows
    return event_study_rows.sort_values(
        ["event_definition", "market_exposure_type", "artist_name", "market_code", "relative_year"],
        ascending=[True, True, True, True, True],
    ).reset_index(drop=True)


def summarize_event_study(event_study_rows: pd.DataFrame) -> pd.DataFrame:
    if event_study_rows.empty:
        return pd.DataFrame()

    def summarize(frame: pd.DataFrame, group_columns: list[str]) -> pd.DataFrame:
        return (
            frame.groupby(group_columns, dropna=False)
            .agg(
                event_ct=("artist_name", "size"),
                mean_all_metal_ct=("all_metal_ct", "mean"),
                mean_unsigned_ct=("unsigned_ct", "mean"),
                mean_all_metal_resid=("all_metal_fe_resid", "mean"),
                mean_unsigned_resid=("unsigned_fe_resid", "mean"),
            )
            .reset_index()
        )

    overall = summarize(event_study_rows, ["event_definition", "event_definition_label", "relative_year"])
    overall["study_scope"] = "overall"
    overall["market_exposure_type"] = "all_markets"

    by_exposure = summarize(
        event_study_rows,
        ["event_definition", "event_definition_label", "market_exposure_type", "relative_year"],
    )
    by_exposure["study_scope"] = "exposure_type"

    return pd.concat([overall, by_exposure], ignore_index=True, sort=False).sort_values(
        ["event_definition", "study_scope", "market_exposure_type", "relative_year"]
    ).reset_index(drop=True)


def build_sample_summary(hits: pd.DataFrame, event_windows: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for event_definition, metadata in EVENT_DEFINITIONS.items():
        filtered_hits = filter_hits_for_definition(hits=hits, event_definition=event_definition)
        complete = event_windows.loc[
            (event_windows["event_definition"] == event_definition) & (event_windows["post_window_complete_i"] == 1)
        ].copy()
        rows.append(
            {
                "event_definition": event_definition,
                "event_definition_label": metadata["label"],
                "album_country_rows": len(filtered_hits),
                "band_market_events": int(len(event_windows.loc[event_windows["event_definition"] == event_definition])),
                "complete_windows": int(len(complete)),
                "complete_home_windows": int((complete["home_market_i"] == 1).sum()) if not complete.empty else 0,
                "complete_foreign_windows": int((complete["foreign_market_i"] == 1).sum()) if not complete.empty else 0,
                "artists_with_complete_windows": int(complete["artist_name"].nunique()) if not complete.empty else 0,
            }
        )
    return pd.DataFrame(rows)


def overall_rank_table(ranking: pd.DataFrame, event_definition: str) -> pd.DataFrame:
    subset = ranking.loc[
        (ranking["event_definition"] == event_definition) & (ranking["ranking_scope"] == "overall")
    ].copy()
    if subset.empty:
        return subset
    subset = subset[
        [
            "artist_name",
            "market_event_ct",
            "mean_resid_gap_all_metal",
            "mean_resid_gap_unsigned",
            "mean_pct_all_metal",
            "max_same_market_year_event_ct",
        ]
    ].head(5)
    subset = round_table_columns(subset, ["mean_resid_gap_all_metal", "mean_resid_gap_unsigned"])
    subset["mean_pct_all_metal"] = subset["mean_pct_all_metal"].map(pct_text)
    return subset


def top_rank_table(ranking: pd.DataFrame, event_definition: str, market_exposure_type: str) -> pd.DataFrame:
    subset = ranking.loc[
        (ranking["event_definition"] == event_definition)
        & (ranking["ranking_scope"] == "exposure_type")
        & (ranking["market_exposure_type"] == market_exposure_type)
    ].copy()
    if subset.empty:
        return subset
    subset = subset[
        [
            "artist_name",
            "market_event_ct",
            "mean_resid_gap_all_metal",
            "mean_resid_gap_unsigned",
            "mean_pct_all_metal",
        ]
    ].head(5)
    subset = round_table_columns(subset, ["mean_resid_gap_all_metal", "mean_resid_gap_unsigned"])
    subset["mean_pct_all_metal"] = subset["mean_pct_all_metal"].map(pct_text)
    return subset


def event_study_table(event_study: pd.DataFrame, event_definition: str, market_exposure_type: str) -> pd.DataFrame:
    subset = event_study.loc[
        (event_study["event_definition"] == event_definition)
        & (event_study["market_exposure_type"] == market_exposure_type)
    ].copy()
    if subset.empty:
        return subset
    subset = subset[["relative_year", "event_ct", "mean_all_metal_resid", "mean_unsigned_resid"]].copy()
    return round_table_columns(subset, ["mean_all_metal_resid", "mean_unsigned_resid"])


def strongest_case_text(frame: pd.DataFrame, label: str) -> str:
    if frame.empty:
        return f"- No complete {label} windows are available yet."

    standout = frame.sort_values(
        ["delta_all_metal_resid_mean", "delta_unsigned_resid_mean", "delta_all_metal_ct"],
        ascending=[False, False, False],
    ).iloc[0]
    return (
        f"- Strongest {label} case: `{standout['artist_name']}` in `{standout['country_name']}` "
        f"after `{standout['album_title']}` (`{standout['hit_year']}`), with a residualized gap of "
        f"`{gap_text(standout['delta_all_metal_resid_mean'])}` all-metal bands per year."
    )


def build_definition_section(
    event_definition: str,
    event_windows: pd.DataFrame,
    ranking: pd.DataFrame,
    event_study: pd.DataFrame,
) -> list[str]:
    metadata = EVENT_DEFINITIONS[event_definition]
    complete = event_windows.loc[
        (event_windows["event_definition"] == event_definition) & (event_windows["post_window_complete_i"] == 1)
    ].copy()
    overall = complete.copy()
    home = complete.loc[complete["home_market_i"] == 1].copy()
    foreign = complete.loc[complete["foreign_market_i"] == 1].copy()

    multi_market = ranking.loc[
        (ranking["event_definition"] == event_definition)
        & (ranking["ranking_scope"] == "overall")
        & (ranking["market_event_ct"] >= 2)
    ].copy()
    if not overall.empty:
        standout = overall.sort_values(
            ["delta_all_metal_resid_mean", "delta_unsigned_resid_mean", "delta_all_metal_ct"],
            ascending=[False, False, False],
        ).iloc[0]
        standout_text = (
            f"- Strongest overall case: `{standout['artist_name']}` in `{standout['country_name']}` "
            f"after `{standout['album_title']}` (`{standout['hit_year']}`), with a residualized gap of "
            f"`{gap_text(standout['delta_all_metal_resid_mean'])}` all-metal bands per year and a raw "
            f"post-minus-pre change of `{int(standout['delta_all_metal_ct'])}` bands."
        )
    else:
        standout_text = "- No complete windows are available yet."

    if not multi_market.empty:
        robust = multi_market.iloc[0]
        robust_text = (
            f"- Strongest multi-market band: `{robust['artist_name']}` with mean residual gaps of "
            f"`{gap_text(robust['mean_resid_gap_all_metal'])}` all-metal and "
            f"`{gap_text(robust['mean_resid_gap_unsigned'])}` unsigned bands per year across "
            f"`{int(robust['market_event_ct'])}` markets."
        )
    else:
        robust_text = "- No artist yet has two or more complete markets under this definition."

    bundled_events = complete.loc[complete["same_market_year_event_ct"] > 1].copy()
    overall_table = overall_rank_table(ranking=ranking, event_definition=event_definition)
    home_table = top_rank_table(ranking=ranking, event_definition=event_definition, market_exposure_type="home_market")
    foreign_table = top_rank_table(ranking=ranking, event_definition=event_definition, market_exposure_type="foreign_market")
    event_study_table_overall = event_study_table(event_study=event_study, event_definition=event_definition, market_exposure_type="all_markets")

    return [
        f"## {metadata['label']}",
        "",
        f"- Event rule: {metadata['rule_text']}.",
        f"- Complete windows: `{len(complete)}`",
        f"- Complete home-market windows: `{len(home)}`",
        f"- Complete foreign-market windows: `{len(foreign)}`",
        standout_text,
        strongest_case_text(home, label="home-market"),
        strongest_case_text(foreign, label="foreign-market"),
        robust_text,
        f"- Bundled same-country same-year events under this definition: `{len(bundled_events)}`",
        "",
        "### Top overall ranking",
        "",
        overall_table.to_markdown(index=False) if not overall_table.empty else "No complete overall windows available.",
        "",
        "### Top home-market ranking",
        "",
        home_table.to_markdown(index=False) if not home_table.empty else "No complete home-market windows available.",
        "",
        "### Top foreign-market ranking",
        "",
        foreign_table.to_markdown(index=False) if not foreign_table.empty else "No complete foreign-market windows available.",
        "",
        "### Event-study profile: all markets",
        "",
        event_study_table_overall.to_markdown(index=False) if not event_study_table_overall.empty else "No complete event-study rows available.",
        "",
    ]


def build_memo(
    hits: pd.DataFrame,
    event_windows: pd.DataFrame,
    ranking: pd.DataFrame,
    event_study: pd.DataFrame,
) -> str:
    sample_summary = build_sample_summary(hits=hits, event_windows=event_windows)
    sample_summary_table = sample_summary[
        [
            "event_definition_label",
            "album_country_rows",
            "band_market_events",
            "complete_windows",
            "complete_home_windows",
            "complete_foreign_windows",
            "artists_with_complete_windows",
        ]
    ].copy()

    definition_sections: list[str] = []
    for event_definition in EVENT_DEFINITIONS:
        definition_sections.extend(
            build_definition_section(
                event_definition=event_definition,
                event_windows=event_windows,
                ranking=ranking,
                event_study=event_study,
            )
        )

    lines = [
        "# Band influence memo",
        "",
        "## Question",
        "",
        "Which bands currently look most associated with later band-startup waves once the country baseline and common year shocks are partialled out?",
        "",
        "## Current setup",
        "",
        "- Measurement vehicle stays album-based because cross-country metal data are much better for albums than for singles.",
        "- Event object is now band-market visibility rather than only blockbuster top-10 timing.",
        f"- Outcome windows compare `{PRE_WINDOW_YEARS}` pre years with the hit year plus the next `{POST_WINDOW_YEARS - 1}` years.",
        "- Outcomes: all-metal and unsigned all-metal band starts from `metal_archives_all_metal_country_year_panel.csv`.",
        f"- Residualization: two-way fixed-effect residuals from country and year dummies fitted on all country-years `{RESIDUAL_FIT_START_YEAR}-{RESIDUAL_FIT_END_YEAR}`.",
        "- Exposure split: `home_market` means the event market matches the artist home country in the curated seed; `foreign_market` means it does not.",
        "- Current sample keeps only complete post windows based on the last observed non-zero outcome year, so recent hits without a full observed post period are excluded from the ranking.",
        "",
        "## Event definitions",
        "",
        f"- `presence`: {EVENT_DEFINITIONS['first_presence_by_band_market']['rule_text']}.",
        f"- `certification`: {EVENT_DEFINITIONS['first_certification_by_band_market']['rule_text']}.",
        f"- `top10`: {EVENT_DEFINITIONS['first_top10_by_band_market']['rule_text']}.",
        "",
        "## Sample size by definition",
        "",
        sample_summary_table.to_markdown(index=False) if not sample_summary_table.empty else "No event windows were built.",
        "",
        "## First read",
        "",
        "- The broader `presence` and `certification` definitions now let Brazil matter even when the home-market signal appears as certification rather than as a top-10 chart event.",
        "- The old `top10` definition remains useful as the conservative blockbuster margin, but it is no longer the only way a band enters the influence workflow.",
        "- The ranking is still not causal, but it is conditioned on country baselines and common year shocks before comparing post-event windows.",
        "",
    ]
    lines.extend(definition_sections)
    lines.extend(
        [
            "## Important cautions",
            "",
            "- Country scenes still differ greatly in size, so the memo keeps raw post-minus-pre counts and percentages as scale checks alongside the residualized ranking.",
            "- Same-country same-year bundled events are not separable in the current country-year panel. That is why some bands can still share identical event-window scores.",
            "- Germany currently enters from a manual official-source supplement because the official German chart site blocks scripted requests in this environment.",
            "- Brazil still enters from a mixed-source manual supplement because direct Pro-Musica retrieval is blocked in this environment.",
            "- Recent hits are mechanically under-observed until more post years accumulate, so 2022 events are omitted from complete-window rankings.",
            "",
            "## Immediate implication",
            "",
            "The project can now compare broad visibility, certification, and blockbuster margins side by side. The next gain is to decide which of those should be the main empirical object, not to keep treating top-10 albums as the only meaningful signal.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    hits, panel = load_inputs()
    panel = add_residualized_outcomes(panel=panel)
    event_windows = build_event_windows(hits=hits, panel=panel)
    ranking = build_band_ranking(event_windows=event_windows)
    event_study_rows = build_event_study_rows(event_windows=event_windows, panel=panel)
    event_study = summarize_event_study(event_study_rows=event_study_rows)
    memo = build_memo(hits=hits, event_windows=event_windows, ranking=ranking, event_study=event_study)

    event_windows.to_csv(EVENT_OUTPUT_PATH, index=False)
    ranking.to_csv(RANKING_OUTPUT_PATH, index=False)
    event_study.to_csv(EVENT_STUDY_OUTPUT_PATH, index=False)
    MEMO_OUTPUT_PATH.write_text(memo, encoding="utf-8")

    sample_summary = build_sample_summary(hits=hits, event_windows=event_windows)
    print(f"Definitions compared: {len(EVENT_DEFINITIONS)}")
    for row in sample_summary.itertuples(index=False):
        print(
            f"{row.event_definition_label}: rows={int(row.album_country_rows)}, "
            f"events={int(row.band_market_events)}, complete={int(row.complete_windows)}"
        )
    print(f"Wrote: {EVENT_OUTPUT_PATH}")
    print(f"Wrote: {RANKING_OUTPUT_PATH}")
    print(f"Wrote: {EVENT_STUDY_OUTPUT_PATH}")
    print(f"Wrote: {MEMO_OUTPUT_PATH}")


if __name__ == "__main__":
    main()
