from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"

EVENTS_PATH = SCENE_DIR / "external_arrival_events.csv"
MATCHES_PATH = SCENE_DIR / "external_arrival_matched_controls.csv"
WINDOWS_PATH = SCENE_DIR / "external_arrival_final_audit_event_windows.csv"

OUT_COUNTRY = SCENE_DIR / "external_arrival_leave_country_out.csv"
OUT_GENRE = SCENE_DIR / "external_arrival_leave_genre_out.csv"
OUT_GEO_CLEAN = SCENE_DIR / "external_arrival_geography_clean_sensitivity.csv"
OUT_CONCENTRATION = SCENE_DIR / "external_arrival_country_genre_concentration.csv"
OUT_TARGETS = SCENE_DIR / "external_arrival_top_event_audit_targets.csv"
OUT_SUMMARY = SCENE_DIR / "external_arrival_robustness_audit_summary.md"

STRICT_DEFINITION = "cross_country_same_genre"
BASELINE_RELATIVE_YEAR = -1
PRE_YEARS = [-5, -4, -3, -2]
POST_YEARS = [1, 2, 3]

REGION_LIKE_TOKENS = (
    " province",
    " region",
    " county",
    " state",
    " prefecture",
    " department",
    " autonomous community",
)
REGION_LIKE_EXACT = {
    "alabama",
    "alaska",
    "arizona",
    "arkansas",
    "california",
    "colorado",
    "connecticut",
    "delaware",
    "florida",
    "georgia",
    "hawaii",
    "idaho",
    "illinois",
    "indiana",
    "iowa",
    "kansas",
    "kentucky",
    "louisiana",
    "maine",
    "maryland",
    "massachusetts",
    "michigan",
    "minnesota",
    "mississippi",
    "missouri",
    "montana",
    "nebraska",
    "nevada",
    "new hampshire",
    "new jersey",
    "new mexico",
    "new york",
    "north carolina",
    "north dakota",
    "ohio",
    "oklahoma",
    "oregon",
    "pennsylvania",
    "rhode island",
    "south carolina",
    "south dakota",
    "tennessee",
    "texas",
    "utah",
    "vermont",
    "virginia",
    "washington",
    "west virginia",
    "wisconsin",
    "wyoming",
    "black forest",
    "england",
    "scotland",
    "wales",
    "northern ireland",
    "rhineland-palatinate",
    "saxony",
    "skåne",
    "south holland",
    "västra götaland",
}


def normalize_text(value: object) -> str:
    if pd.isna(value):
        return ""
    return str(value).strip()


def city_part(city_country: object) -> str:
    return normalize_text(city_country).split(",", 1)[0].strip()


def is_region_like_city(city_country: object) -> bool:
    city = city_part(city_country).lower()
    if not city or city == "n/a":
        return True
    return (
        "/" in city
        or city in REGION_LIKE_EXACT
        or any(token in f" {city}" for token in REGION_LIKE_TOKENS)
    )


def weighted_mean(frame: pd.DataFrame, value_col: str, weight_col: str) -> float:
    if frame.empty:
        return np.nan
    values = pd.to_numeric(frame[value_col], errors="coerce")
    weights = pd.to_numeric(frame[weight_col], errors="coerce")
    if weights.isna().all() or weights.fillna(0).sum() <= 0:
        weights = pd.Series(1.0 / len(frame), index=frame.index)
    else:
        weights = weights.fillna(0)
        weights = weights / weights.sum()
    return float((values.fillna(0) * weights).sum())


def build_stack_metadata(events: pd.DataFrame, matches: pd.DataFrame) -> pd.DataFrame:
    matched = (
        matches.loc[matches["arrival_definition"].eq(STRICT_DEFINITION)]
        .groupby("stack_id", as_index=False)
        .agg(
            treated_city_country=("treated_city_country", "first"),
            treated_country=("treated_country", "first"),
            genre_family=("genre_family", "first"),
            arrival_year=("arrival_year", "first"),
            control_count=("control_city_country", "nunique"),
            control_cities=("control_city_country", lambda s: "; ".join(sorted(set(map(str, s)))[:8])),
            control_region_like_count=(
                "control_city_country",
                lambda s: sum(is_region_like_city(value) for value in sorted(set(map(str, s)))),
            ),
        )
    )
    event_cols = [
        "event_id",
        "arriving_musicians",
        "arriving_bands",
        "arriving_band_ids",
        "example_musicians",
        "example_bands",
        "prior_cumulative_bands",
        "event_year_starts",
        "emergence_within_5yr_i",
        "analysis_sample_i",
    ]
    strict_events = events.loc[
        events["arrival_definition"].eq(STRICT_DEFINITION), event_cols
    ].rename(columns={"event_id": "stack_id"})
    meta = matched.merge(strict_events, on="stack_id", how="left")
    meta["treated_region_like_i"] = meta["treated_city_country"].map(is_region_like_city).astype(int)
    meta["control_region_like_share"] = meta["control_region_like_count"] / meta[
        "control_count"
    ].replace(0, np.nan)
    return meta


def build_stack_relative_windows(windows: pd.DataFrame) -> pd.DataFrame:
    outcome = "local_genre_band_starts_own_band_excluded"
    treated = windows.loc[windows["group"].eq("treated")].copy()
    treated = treated.rename(columns={outcome: "treated_starts"})
    treated = treated[
        ["stack_id", "relative_year", "snapshot_year", "treated_starts", "own_bands_excluded"]
    ]

    controls = windows.loc[windows["group"].eq("control")].copy()
    control_rows = []
    for (stack_id, relative_year), frame in controls.groupby(["stack_id", "relative_year"]):
        control_rows.append(
            {
                "stack_id": stack_id,
                "relative_year": relative_year,
                "control_starts": weighted_mean(frame, outcome, "control_weight"),
            }
        )
    control = pd.DataFrame(control_rows)

    rel = treated.merge(control, on=["stack_id", "relative_year"], how="inner")
    rel["treated_minus_control"] = rel["treated_starts"] - rel["control_starts"]

    baseline = rel.loc[
        rel["relative_year"].eq(BASELINE_RELATIVE_YEAR),
        ["stack_id", "treated_minus_control"],
    ].rename(columns={"treated_minus_control": "baseline_treated_minus_control"})
    rel = rel.merge(baseline, on="stack_id", how="inner")
    rel["normalized_did"] = (
        rel["treated_minus_control"] - rel["baseline_treated_minus_control"]
    )
    return rel


def event_study_means(rel: pd.DataFrame, stack_ids: set[str]) -> dict[str, float]:
    sample = rel.loc[rel["stack_id"].isin(stack_ids)].copy()
    by_year = sample.groupby("relative_year")["normalized_did"].mean()
    return {
        "included_events": float(len(stack_ids)),
        "mean_normalized_pre_m5_m2": float(by_year.reindex(PRE_YEARS).mean()),
        "normalized_event_year": float(by_year.reindex([0]).mean()),
        "mean_normalized_post_p1_p3": float(by_year.reindex(POST_YEARS).mean()),
    }


def build_leave_one_out(
    rel: pd.DataFrame,
    meta: pd.DataFrame,
    *,
    column: str,
    omitted_label: str,
) -> pd.DataFrame:
    all_stacks = set(meta["stack_id"])
    rows = []
    full = event_study_means(rel, all_stacks)
    full.update({omitted_label: "NONE", "omitted_events": 0.0})
    rows.append(full)
    for value, group in meta.groupby(column):
        omitted = set(group["stack_id"])
        kept = all_stacks - omitted
        if not kept:
            continue
        row = event_study_means(rel, kept)
        row.update({omitted_label: value, "omitted_events": float(len(omitted))})
        rows.append(row)
    output = pd.DataFrame(rows)
    cols = [
        omitted_label,
        "included_events",
        "omitted_events",
        "mean_normalized_pre_m5_m2",
        "normalized_event_year",
        "mean_normalized_post_p1_p3",
    ]
    return output[cols].sort_values(["mean_normalized_post_p1_p3", omitted_label])


def build_event_effects(rel: pd.DataFrame, meta: pd.DataFrame) -> pd.DataFrame:
    def mean_for(years: list[int]) -> pd.Series:
        return (
            rel.loc[rel["relative_year"].isin(years)]
            .groupby("stack_id")["normalized_did"]
            .mean()
        )

    effects = meta.copy()
    effects["mean_normalized_pre_m5_m2"] = effects["stack_id"].map(mean_for(PRE_YEARS))
    effects["normalized_event_year"] = effects["stack_id"].map(mean_for([0]))
    effects["mean_normalized_post_p1_p3"] = effects["stack_id"].map(mean_for(POST_YEARS))
    own_removed = (
        rel.groupby("stack_id")["own_bands_excluded"].sum().rename("own_bands_excluded_total")
    )
    effects = effects.merge(own_removed, on="stack_id", how="left")
    return effects


def build_concentration(effects: pd.DataFrame) -> pd.DataFrame:
    rows = []
    total_events = len(effects)
    for dimension, column in [
        ("country", "treated_country"),
        ("genre", "genre_family"),
    ]:
        for value, group in effects.groupby(column):
            rows.append(
                {
                    "dimension": dimension,
                    "value": value,
                    "events": len(group),
                    "event_share": len(group) / total_events,
                    "mean_normalized_pre_m5_m2": group["mean_normalized_pre_m5_m2"].mean(),
                    "normalized_event_year": group["normalized_event_year"].mean(),
                    "mean_normalized_post_p1_p3": group["mean_normalized_post_p1_p3"].mean(),
                    "share_positive_post": (
                        group["mean_normalized_post_p1_p3"].gt(0).mean()
                    ),
                    "region_like_event_share": group["treated_region_like_i"].mean(),
                }
            )
    return pd.DataFrame(rows).sort_values(["dimension", "events"], ascending=[True, False])


def build_geography_clean_sensitivity(rel: pd.DataFrame, meta: pd.DataFrame) -> pd.DataFrame:
    samples = {
        "full": meta,
        "control_count_ge3": meta.loc[meta["control_count"].ge(3)],
        "control_count_ge5": meta.loc[meta["control_count"].ge(5)],
        "drop_treated_region_like": meta.loc[meta["treated_region_like_i"].eq(0)],
        "drop_any_region_like_control": meta.loc[meta["control_region_like_count"].eq(0)],
        "drop_treated_or_control_region_like": meta.loc[
            meta["treated_region_like_i"].eq(0) & meta["control_region_like_count"].eq(0)
        ],
        "geo_clean_control_ge3": meta.loc[
            meta["treated_region_like_i"].eq(0)
            & meta["control_region_like_count"].eq(0)
            & meta["control_count"].ge(3)
        ],
        "geo_clean_control_ge5": meta.loc[
            meta["treated_region_like_i"].eq(0)
            & meta["control_region_like_count"].eq(0)
            & meta["control_count"].ge(5)
        ],
    }
    rows = []
    full_events = len(meta)
    for name, frame in samples.items():
        stack_ids = set(frame["stack_id"])
        row = event_study_means(rel, stack_ids)
        row["sample"] = name
        row["dropped_events"] = float(full_events - len(stack_ids))
        rows.append(row)
    cols = [
        "sample",
        "included_events",
        "dropped_events",
        "mean_normalized_pre_m5_m2",
        "normalized_event_year",
        "mean_normalized_post_p1_p3",
    ]
    return pd.DataFrame(rows)[cols]


def build_top_event_targets(effects: pd.DataFrame, n_each: int = 15) -> pd.DataFrame:
    cols = [
        "stack_id",
        "treated_city_country",
        "treated_country",
        "genre_family",
        "arrival_year",
        "mean_normalized_pre_m5_m2",
        "normalized_event_year",
        "mean_normalized_post_p1_p3",
        "own_bands_excluded_total",
        "treated_region_like_i",
        "arriving_musicians",
        "arriving_bands",
        "example_musicians",
        "example_bands",
        "arriving_band_ids",
        "prior_cumulative_bands",
        "event_year_starts",
        "emergence_within_5yr_i",
        "control_count",
        "control_region_like_count",
        "control_region_like_share",
        "control_cities",
    ]
    positive = effects.sort_values("mean_normalized_post_p1_p3", ascending=False).head(n_each)
    positive = positive.assign(audit_side="largest_positive")
    negative = effects.sort_values("mean_normalized_post_p1_p3", ascending=True).head(n_each)
    negative = negative.assign(audit_side="largest_negative")
    return pd.concat([positive, negative], ignore_index=True)[["audit_side", *cols]]


def fmt(value: float) -> str:
    if pd.isna(value):
        return ""
    return f"{value:.3f}"


def write_summary(
    leave_country: pd.DataFrame,
    leave_genre: pd.DataFrame,
    geo_clean: pd.DataFrame,
    concentration: pd.DataFrame,
    targets: pd.DataFrame,
) -> None:
    country_no_full = leave_country.loc[leave_country["omitted_country"].ne("NONE")]
    genre_no_full = leave_genre.loc[leave_genre["omitted_genre"].ne("NONE")]
    full = leave_country.loc[leave_country["omitted_country"].eq("NONE")].iloc[0]

    country_min = country_no_full.sort_values("mean_normalized_post_p1_p3").iloc[0]
    country_max = country_no_full.sort_values("mean_normalized_post_p1_p3").iloc[-1]
    genre_min = genre_no_full.sort_values("mean_normalized_post_p1_p3").iloc[0]
    genre_max = genre_no_full.sort_values("mean_normalized_post_p1_p3").iloc[-1]

    top_countries = concentration.loc[concentration["dimension"].eq("country")].head(8)
    top_genres = concentration.loc[concentration["dimension"].eq("genre")].head(8)

    lines = [
        "# External arrival robustness audit",
        "",
        "This memo applies concentration and audit-target checks to the strict "
        "`cross_country_same_genre` matched arrival stack after excluding each arriving "
        "musician's observed own band from treated outcomes.",
        "",
        "## Output files",
        "",
        f"- leave-country-out: `{OUT_COUNTRY.relative_to(PROJECT_ROOT)}`",
        f"- leave-genre-out: `{OUT_GENRE.relative_to(PROJECT_ROOT)}`",
        f"- geography-clean sensitivity: `{OUT_GEO_CLEAN.relative_to(PROJECT_ROOT)}`",
        f"- concentration table: `{OUT_CONCENTRATION.relative_to(PROJECT_ROOT)}`",
        f"- event audit targets: `{OUT_TARGETS.relative_to(PROJECT_ROOT)}`",
        "",
        "## Headline leave-one-out read",
        "",
        f"- Full matched stack: `{int(full['included_events'])}` events, "
        f"mean normalized pre `t=-5` to `t=-2` = `{fmt(full['mean_normalized_pre_m5_m2'])}`, "
        f"event year = `{fmt(full['normalized_event_year'])}`, "
        f"post `t=+1` to `t=+3` = `{fmt(full['mean_normalized_post_p1_p3'])}`.",
        f"- Weakest leave-country-out post read: omit `{country_min['omitted_country']}`, "
        f"`{int(country_min['included_events'])}` events, post = "
        f"`{fmt(country_min['mean_normalized_post_p1_p3'])}`.",
        f"- Strongest leave-country-out post read: omit `{country_max['omitted_country']}`, "
        f"`{int(country_max['included_events'])}` events, post = "
        f"`{fmt(country_max['mean_normalized_post_p1_p3'])}`.",
        f"- Weakest leave-genre-out post read: omit `{genre_min['omitted_genre']}`, "
        f"`{int(genre_min['included_events'])}` events, post = "
        f"`{fmt(genre_min['mean_normalized_post_p1_p3'])}`.",
        f"- Strongest leave-genre-out post read: omit `{genre_max['omitted_genre']}`, "
        f"`{int(genre_max['included_events'])}` events, post = "
        f"`{fmt(genre_max['mean_normalized_post_p1_p3'])}`.",
        "",
        "## Geography-clean sensitivity",
        "",
        "| Sample | Events | Dropped | Pre mean | Event year | Post mean |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for _, row in geo_clean.iterrows():
        lines.append(
            f"| {row['sample']} | {int(row['included_events'])} | "
            f"{int(row['dropped_events'])} | {fmt(row['mean_normalized_pre_m5_m2'])} | "
            f"{fmt(row['normalized_event_year'])} | {fmt(row['mean_normalized_post_p1_p3'])} |"
        )
    lines.extend(
        [
        "",
        "## Largest country cells",
        "",
        "| Country | Events | Share | Post mean | Positive share | Region-like share |",
        "|---|---:|---:|---:|---:|---:|",
        ]
    )
    for _, row in top_countries.iterrows():
        lines.append(
            f"| {row['value']} | {int(row['events'])} | {fmt(row['event_share'])} | "
            f"{fmt(row['mean_normalized_post_p1_p3'])} | {fmt(row['share_positive_post'])} | "
            f"{fmt(row['region_like_event_share'])} |"
        )
    lines.extend(
        [
            "",
            "## Largest genre cells",
            "",
            "| Genre | Events | Share | Post mean | Positive share | Region-like share |",
            "|---|---:|---:|---:|---:|---:|",
        ]
    )
    for _, row in top_genres.iterrows():
        lines.append(
            f"| {row['value']} | {int(row['events'])} | {fmt(row['event_share'])} | "
            f"{fmt(row['mean_normalized_post_p1_p3'])} | {fmt(row['share_positive_post'])} | "
            f"{fmt(row['region_like_event_share'])} |"
        )
    region_like_targets = int(targets["treated_region_like_i"].sum())
    region_like_control_targets = int(targets["control_region_like_count"].gt(0).sum())
    lines.extend(
        [
            "",
            "## Audit-target read",
            "",
            f"- Top-event target rows written: `{len(targets)}`.",
            f"- Region-like treated labels among those targets: `{region_like_targets}`.",
            f"- Target rows with at least one region-like control label: `{region_like_control_targets}`.",
            "- The audit target file should be used for manual inspection before promoting the "
            "branch: verify treated city labels, musician/band identities, and whether the "
            "arrival looks like a real outside-experience event rather than a database artifact.",
            "",
            "## Verdict gate",
            "",
            "The branch remains alive if the post coefficient stays positive under leave-country-out "
            "and leave-genre-out checks, and if the largest event-level positives are not mostly "
            "region labels, N/A locations, or obvious data artifacts.",
            "",
        ]
    )
    OUT_SUMMARY.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    for path in [EVENTS_PATH, MATCHES_PATH, WINDOWS_PATH]:
        if not path.exists():
            raise FileNotFoundError(path)

    events = pd.read_csv(EVENTS_PATH, low_memory=False)
    matches = pd.read_csv(MATCHES_PATH, low_memory=False)
    windows = pd.read_csv(WINDOWS_PATH, low_memory=False)

    meta = build_stack_metadata(events, matches)
    rel = build_stack_relative_windows(windows)
    rel = rel.loc[rel["stack_id"].isin(set(meta["stack_id"]))].copy()

    leave_country = build_leave_one_out(
        rel, meta, column="treated_country", omitted_label="omitted_country"
    )
    leave_genre = build_leave_one_out(
        rel, meta, column="genre_family", omitted_label="omitted_genre"
    )
    geo_clean = build_geography_clean_sensitivity(rel, meta)
    effects = build_event_effects(rel, meta)
    concentration = build_concentration(effects)
    targets = build_top_event_targets(effects)

    leave_country.to_csv(OUT_COUNTRY, index=False)
    leave_genre.to_csv(OUT_GENRE, index=False)
    geo_clean.to_csv(OUT_GEO_CLEAN, index=False)
    concentration.to_csv(OUT_CONCENTRATION, index=False)
    targets.to_csv(OUT_TARGETS, index=False)
    write_summary(leave_country, leave_genre, geo_clean, concentration, targets)
    print(f"Wrote {OUT_SUMMARY}")


if __name__ == "__main__":
    main()
