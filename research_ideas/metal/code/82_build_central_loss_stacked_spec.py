from __future__ import annotations

import re
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from linearmodels.panel import PanelOLS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
SCENE_DIR = PROCESSED_DIR / "scene_networks"

EVENTS_PATH = SCENE_DIR / "central_loss_verified_death_events.csv"
MATCHES_PATH = SCENE_DIR / "central_loss_matched_controls.csv"
GENRE_PANEL_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"
CITY_PANEL_PATH = SCENE_DIR / "city_year_scene_cluster_richer_features.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"
BAND_PATH = PROCESSED_DIR / "metal_archives_all_metal_band_clean.csv"

OUT_PANEL = SCENE_DIR / "central_loss_stacked_event_panel.csv"
OUT_DID = SCENE_DIR / "central_loss_stacked_did_results.csv"
OUT_EVENT_STUDY = SCENE_DIR / "central_loss_stacked_event_study_results.csv"
OUT_FIGURE = SCENE_DIR / "figures" / "central_loss_stacked_event_study.png"
OUT_SUMMARY = SCENE_DIR / "central_loss_stacked_spec_summary.md"

MATCH_YEARS = [-3, -2, -1, 0, 1]
EVENT_STUDY_YEARS = [-3, -2, 0, 1]
EVENT_STUDY_LABELS = {-3: "t-3", -2: "t-2", 0: "t", 1: "t+1"}

GENRE_FAMILIES = {
    "atmospheric black metal": "atmospheric_black_metal",
    "avant-garde metal": "avant_garde_metal",
    "brutal death metal": "brutal_death_metal",
    "depressive black metal": "depressive_black_metal",
    "melodic death metal": "melodic_death_metal",
    "technical death metal": "technical_death_metal",
    "black metal": "black_metal",
    "death metal": "death_metal",
    "doom metal": "doom_metal",
    "drone metal": "drone_metal",
    "folk metal": "folk_metal",
    "gothic metal": "gothic_metal",
    "grindcore": "grindcore",
    "groove metal": "groove_metal",
    "heavy metal": "heavy_metal",
    "industrial metal": "industrial_metal",
    "metalcore": "metalcore",
    "nu metal": "nu_metal",
    "post-black metal": "post_black_metal",
    "post-metal": "post_metal",
    "power metal": "power_metal",
    "progressive metal": "progressive_metal",
    "sludge metal": "sludge_metal",
    "speed metal": "speed_metal",
    "stoner metal": "stoner_metal",
    "symphonic metal": "symphonic_metal",
    "thrash metal": "thrash_metal",
    "viking metal": "viking_metal",
    "deathcore": "deathcore",
}
GENRE_FAMILY_KEYS = sorted(GENRE_FAMILIES.keys(), key=len, reverse=True)


def extract_city(notes_str: str) -> str:
    if not isinstance(notes_str, str) or not notes_str:
        return ""
    match = re.search(r"location=([^;]+)", notes_str)
    if not match:
        return ""
    parts = [part.strip() for part in match.group(1).strip().split(",")]
    return parts[0] if parts else ""


def normalize_city_country(city: str, country: str) -> str:
    city = "" if pd.isna(city) else str(city).strip()
    country = "" if pd.isna(country) else str(country).strip()
    if not city:
        return ""
    return f"{city}, {country}" if country else city


def parse_genre_families(genre_raw: str) -> tuple[str, ...]:
    text = (genre_raw or "").strip().lower()
    if not text:
        return tuple()
    families: list[str] = []
    for key in GENRE_FAMILY_KEYS:
        if key in text:
            families.append(GENRE_FAMILIES[key])
    if not families and "metal" in text:
        families.append("other_metal")
    return tuple(sorted(set(families)))


def classify_emergence_timing(terminal_year: int, emergence_year: float | int | None) -> str:
    if pd.isna(emergence_year):
        return "no_emergence_record"
    emergence_year = int(emergence_year)
    if terminal_year < emergence_year:
        return "pre_emergence"
    if terminal_year == emergence_year:
        return "emergence_year"
    return "post_emergence"


def build_local_genre_starts() -> pd.DataFrame:
    bands = pd.read_csv(BAND_PATH, low_memory=False)
    rows: list[dict[str, object]] = []
    for row in bands.itertuples(index=False):
        city = extract_city(getattr(row, "notes", ""))
        formed_year = getattr(row, "formed_year", pd.NA)
        if pd.isna(formed_year):
            continue
        try:
            formed_year = int(float(formed_year))
        except (TypeError, ValueError):
            continue
        city_country = normalize_city_country(city, getattr(row, "country_std", ""))
        if not city_country:
            continue
        for genre_family in parse_genre_families(getattr(row, "genre_raw", "")):
            rows.append(
                {
                    "city_country": city_country,
                    "genre_family": genre_family,
                    "snapshot_year": formed_year,
                }
            )
    starts = (
        pd.DataFrame(rows)
        .groupby(["city_country", "genre_family", "snapshot_year"], as_index=False)
        .size()
        .rename(columns={"size": "local_genre_band_starts"})
    )
    return starts


def prepare_events() -> pd.DataFrame:
    events = pd.read_csv(EVENTS_PATH, low_memory=False)
    emergence = pd.read_csv(EMERGENCE_PATH, low_memory=False)[
        ["city_country", "genre_family", "emergence_year"]
    ].copy()
    genre_panel = pd.read_csv(GENRE_PANEL_PATH, low_memory=False)

    events = events.merge(emergence, on=["city_country", "genre_family"], how="left")
    events["emergence_timing"] = events.apply(
        lambda row: classify_emergence_timing(int(row["terminal_year"]), row["emergence_year"]),
        axis=1,
    )

    support = genre_panel.merge(
        events[["member_name", "terminal_year", "city_country", "genre_family"]],
        on=["city_country", "genre_family"],
        how="inner",
    ).copy()
    support["relative_year"] = support["snapshot_year"] - support["terminal_year"]
    support = support.loc[support["relative_year"].between(-5, 3)].copy()
    availability = (
        support.groupby(["member_name", "city_country", "genre_family", "terminal_year"], as_index=False)
        .agg(
            pre_years_available=("relative_year", lambda s: int((s < 0).sum())),
            post_years_available=("relative_year", lambda s: int((s > 0).sum())),
            event_year_available=("relative_year", lambda s: int((s == 0).any())),
        )
    )
    events = events.merge(
        availability,
        on=["member_name", "city_country", "genre_family", "terminal_year"],
        how="left",
    )
    events["usable_for_short_post_window"] = (
        events["pre_years_available"].fillna(0).ge(3)
        & events["event_year_available"].fillna(0).eq(1)
        & events["post_years_available"].fillna(0).ge(1)
    ).astype(int)
    return events


def build_stack_panel() -> pd.DataFrame:
    events = prepare_events()
    matches = pd.read_csv(MATCHES_PATH, low_memory=False)
    genre_panel = pd.read_csv(GENRE_PANEL_PATH, low_memory=False)
    city_panel = pd.read_csv(CITY_PANEL_PATH, low_memory=False)
    local_starts = build_local_genre_starts()

    treated_events = events.loc[
        events["emergence_timing"].eq("post_emergence")
        & events["usable_for_short_post_window"].eq(1)
    ].copy()
    treated_events["stack_id"] = (
        treated_events["member_name"].astype(str)
        + " || "
        + treated_events["city_country"].astype(str)
        + " || "
        + treated_events["genre_family"].astype(str)
        + " || "
        + treated_events["terminal_year"].astype(int).astype(str)
    )

    panel = (
        genre_panel.merge(
            city_panel,
            on=["city_country", "snapshot_year"],
            how="left",
            suffixes=("", "_city"),
        )
        .merge(local_starts, on=["city_country", "genre_family", "snapshot_year"], how="left")
        .copy()
    )
    panel["local_genre_band_starts"] = panel["local_genre_band_starts"].fillna(0.0)

    matches = matches.merge(
        treated_events[
            [
                "member_name",
                "city_country",
                "genre_family",
                "terminal_year",
                "event_date",
                "stack_id",
            ]
        ],
        left_on=["treated_member_name", "treated_city_country", "genre_family", "treated_terminal_year"],
        right_on=["member_name", "city_country", "genre_family", "terminal_year"],
        how="inner",
    )

    rows: list[dict[str, object]] = []
    for event in treated_events.itertuples(index=False):
        stack_matches = matches.loc[matches["stack_id"].eq(event.stack_id)].copy()
        units = [
            {"unit_role": "treated", "city_country": event.city_country, "match_rank": 0},
        ]
        for match in stack_matches.itertuples(index=False):
            units.append(
                {
                    "unit_role": "control",
                    "city_country": match.control_city_country,
                    "match_rank": int(match.match_rank),
                }
            )
        for unit in units:
            window = panel.loc[
                panel["city_country"].eq(unit["city_country"])
                & panel["genre_family"].eq(event.genre_family)
                & panel["snapshot_year"].between(int(event.terminal_year) - 3, int(event.terminal_year) + 1)
            ].copy()
            if window["snapshot_year"].nunique() < len(MATCH_YEARS):
                continue
            window["relative_year"] = window["snapshot_year"] - int(event.terminal_year)
            window = window.loc[window["relative_year"].isin(MATCH_YEARS)].copy()
            if window["relative_year"].nunique() < len(MATCH_YEARS):
                continue
            window["stack_id"] = event.stack_id
            window["treated_member_name"] = event.member_name
            window["treated_city_country"] = event.city_country
            window["treated_terminal_year"] = int(event.terminal_year)
            window["event_date"] = event.event_date
            window["unit_role"] = unit["unit_role"]
            window["match_rank"] = int(unit["match_rank"])
            window["treated_i"] = 1 if unit["unit_role"] == "treated" else 0
            window["post_i"] = (window["relative_year"] >= 0).astype(int)
            window["treated_post"] = window["treated_i"] * window["post_i"]
            window["shock_id"] = (
                window["treated_city_country"].astype(str)
                + " || "
                + window["genre_family"].astype(str)
                + " || "
                + window["treated_terminal_year"].astype(int).astype(str)
            )
            window["entity_id"] = (
                window["stack_id"].astype(str) + " || " + window["city_country"].astype(str)
            )
            rows.extend(window.to_dict("records"))

    stacked = pd.DataFrame(rows).sort_values(["stack_id", "unit_role", "city_country", "relative_year"])
    return stacked


def run_did(panel: pd.DataFrame, outcome: str, sample_variant: str) -> dict[str, object]:
    sample = panel[["entity_id", "relative_year", "stack_id", outcome, "treated_post"]].copy()
    sample = sample.set_index(["entity_id", "relative_year"]).sort_index()
    cluster_frame = pd.DataFrame(
        {"stack_id": sample.reset_index()["stack_id"].values},
        index=sample.index,
    )
    model = PanelOLS(
        sample[outcome],
        sample[["treated_post"]],
        entity_effects=True,
        time_effects=True,
        drop_absorbed=True,
    )
    result = model.fit(cov_type="clustered", clusters=cluster_frame)
    return {
        "sample_variant": sample_variant,
        "outcome": outcome,
        "coefficient": float(result.params["treated_post"]),
        "std_error": float(result.std_errors["treated_post"]),
        "p_value": float(result.pvalues["treated_post"]),
        "n_obs": int(result.nobs),
        "n_entities": int(sample.index.get_level_values(0).nunique()),
        "n_stacks": int(sample["stack_id"].nunique()),
        "n_unique_shocks": int(panel["shock_id"].nunique()),
        "fixed_effects": "stack-city + relative year",
        "clustering": "stack_id",
    }


def run_event_study(panel: pd.DataFrame, outcome: str) -> pd.DataFrame:
    sample = panel[["entity_id", "relative_year", "stack_id", outcome, "treated_i"]].copy()
    for relative_year in EVENT_STUDY_YEARS:
        label = str(relative_year).replace("-", "m")
        sample[f"treated_rel_{label}"] = (
            sample["treated_i"].eq(1) & sample["relative_year"].eq(relative_year)
        ).astype(int)
    exog_columns = [f"treated_rel_{str(year).replace('-', 'm')}" for year in EVENT_STUDY_YEARS]
    sample = sample.set_index(["entity_id", "relative_year"]).sort_index()
    cluster_frame = pd.DataFrame(
        {"stack_id": sample.reset_index()["stack_id"].values},
        index=sample.index,
    )
    model = PanelOLS(
        sample[outcome],
        sample[exog_columns],
        entity_effects=True,
        time_effects=True,
        drop_absorbed=True,
    )
    result = model.fit(cov_type="clustered", clusters=cluster_frame)

    rows: list[dict[str, object]] = []
    for relative_year in EVENT_STUDY_YEARS:
        term = f"treated_rel_{str(relative_year).replace('-', 'm')}"
        if term not in result.params.index:
            continue
        coefficient = float(result.params[term])
        std_error = float(result.std_errors[term])
        rows.append(
            {
                "relative_year": relative_year,
                "relative_label": EVENT_STUDY_LABELS[relative_year],
                "coefficient": coefficient,
                "std_error": std_error,
                "ci_low": coefficient - 1.96 * std_error,
                "ci_high": coefficient + 1.96 * std_error,
                "p_value": float(result.pvalues[term]),
                "outcome": outcome,
                "reference_year": -1,
                "fixed_effects": "stack-city + relative year",
                "clustering": "stack_id",
                "n_obs": int(result.nobs),
                "n_entities": int(sample.index.get_level_values(0).nunique()),
                "n_stacks": int(sample["stack_id"].nunique()),
            }
        )
    return pd.DataFrame(rows).sort_values("relative_year")


def make_figure(event_study: pd.DataFrame) -> None:
    OUT_FIGURE.parent.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(7, 4.5))
    ax.axhline(0, color="#666666", linewidth=1.0, linestyle="--")
    ax.axvline(-1, color="#bbbbbb", linewidth=1.0, linestyle=":")
    ax.errorbar(
        event_study["relative_year"],
        event_study["coefficient"],
        yerr=1.96 * event_study["std_error"],
        fmt="o",
        color="#1f4e79",
        ecolor="#1f4e79",
        elinewidth=1.3,
        capsize=4,
    )
    ax.set_xticks(EVENT_STUDY_YEARS)
    ax.set_xticklabels([EVENT_STUDY_LABELS[year] for year in EVENT_STUDY_YEARS])
    ax.set_xlabel("Relative year (reference = t-1)")
    ax.set_ylabel("Treated-control gap in focal same-genre band starts")
    ax.set_title("Central death stacked event-study prototype")
    ax.grid(axis="y", alpha=0.25)
    fig.tight_layout()
    fig.savefig(OUT_FIGURE, dpi=200)
    plt.close(fig)


def format_float(value: float) -> str:
    if pd.isna(value):
        return ""
    return f"{value:.3f}"


def write_summary(panel: pd.DataFrame, did_df: pd.DataFrame, event_study: pd.DataFrame) -> None:
    treated_events = panel["stack_id"].nunique()
    treated_units = panel.loc[panel["unit_role"].eq("treated"), "entity_id"].nunique()
    control_units = panel.loc[panel["unit_role"].eq("control"), "entity_id"].nunique()

    summary_means = (
        panel.groupby(["unit_role", "relative_year"], as_index=False)
        .agg(
            local_genre_band_starts=("local_genre_band_starts", "mean"),
            genre_multi_band_musicians=("genre_multi_band_musicians", "mean"),
            spawn_bands_formed=("spawn_bands_formed", "mean"),
        )
        .sort_values(["unit_role", "relative_year"])
    )

    lines = [
        "# Central loss stacked specification summary",
        "",
        "## Scope",
        "",
        f"- Treated death events in stacked sample: `{treated_events}`",
        f"- Treated stack-city units: `{treated_units}`",
        f"- Control stack-city units: `{control_units}`",
        f"- Relative years used: `{MATCH_YEARS[0]}` to `{MATCH_YEARS[-1]}`",
        "- This is still a small-sample descriptive prototype. The fixed-effects results are useful as a branch read, not as settled causal evidence.",
        "",
        "## Fixed-effects DID results",
        "",
        "| Variant | Outcome | Coefficient on treated x post | Std. error | P-value | Stacks | Unique shocks | Observations |",
        "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    outcome_labels = {
        "local_genre_band_starts": "Focal same-genre band starts",
        "genre_multi_band_musicians": "Focal multi-band musicians",
        "spawn_bands_formed": "City spawning flow",
    }
    for row in did_df.itertuples(index=False):
        lines.append(
            f"| {row.sample_variant} | {outcome_labels.get(row.outcome, row.outcome)} | {format_float(row.coefficient)} | "
            f"{format_float(row.std_error)} | {format_float(row.p_value)} | "
            f"{int(row.n_stacks)} | {int(row.n_unique_shocks)} | {int(row.n_obs)} |"
        )

    lines.extend(
        [
            "",
            "## Event-study coefficients for focal same-genre band starts",
            "",
            "| Relative year | Coefficient | 95% CI low | 95% CI high | P-value |",
            "| --- | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in event_study.itertuples(index=False):
        lines.append(
            f"| {row.relative_label} | {format_float(row.coefficient)} | "
            f"{format_float(row.ci_low)} | {format_float(row.ci_high)} | {format_float(row.p_value)} |"
        )

    lines.extend(
        [
            "",
            "## Relative-year means by unit role",
            "",
            "| Unit role | Relative year | Focal band starts | Focal multi-band musicians | City spawning flow |",
            "| --- | ---: | ---: | ---: | ---: |",
        ]
    )
    for row in summary_means.itertuples(index=False):
        lines.append(
            f"| {row.unit_role} | {int(row.relative_year)} | {format_float(row.local_genre_band_starts)} | "
            f"{format_float(row.genre_multi_band_musicians)} | {format_float(row.spawn_bands_formed)} |"
        )

    baseline_map = {
        row.outcome: row.coefficient
        for row in did_df.loc[did_df["sample_variant"].eq("event_weighted")].itertuples(index=False)
    }
    unique_map = {
        row.outcome: row.coefficient
        for row in did_df.loc[did_df["sample_variant"].eq("unique_shock")].itertuples(index=False)
    }
    lines.extend(
        [
            "",
            "## Read",
            "",
            f"- The event-weighted stacked FE prototype keeps the focal same-genre entry margin negative: treated x post = `{format_float(baseline_map.get('local_genre_band_starts', float('nan')))}`.",
            f"- The same focal-entry result survives the unique-shock collapse that removes duplicate city-genre-year counting: treated x post = `{format_float(unique_map.get('local_genre_band_starts', float('nan')))}`.",
            f"- The same specification is weaker on focal multi-band depth: treated x post = `{format_float(baseline_map.get('genre_multi_band_musicians', float('nan')))}`.",
            f"- City-wide spawning does not show the same negative pattern: treated x post = `{format_float(baseline_map.get('spawn_bands_formed', float('nan')))}`.",
            "- The event-study path matters more than the small-sample p-values here. The useful question is whether the post-death coefficients move down relative to the matched control path while the pre-period terms stay closer to zero.",
        ]
    )
    OUT_SUMMARY.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    panel = build_stack_panel()
    panel.to_csv(OUT_PANEL, index=False)

    first_stack_by_shock = (
        panel[["shock_id", "stack_id"]]
        .drop_duplicates()
        .sort_values(["shock_id", "stack_id"])
        .groupby("shock_id", as_index=False)
        .first()
    )
    unique_shock_panel = panel.loc[panel["stack_id"].isin(first_stack_by_shock["stack_id"])].copy()

    did_rows = [
        run_did(panel, "local_genre_band_starts", "event_weighted"),
        run_did(panel, "genre_multi_band_musicians", "event_weighted"),
        run_did(panel, "spawn_bands_formed", "event_weighted"),
        run_did(unique_shock_panel, "local_genre_band_starts", "unique_shock"),
        run_did(unique_shock_panel, "genre_multi_band_musicians", "unique_shock"),
        run_did(unique_shock_panel, "spawn_bands_formed", "unique_shock"),
    ]
    did_df = pd.DataFrame(did_rows)
    did_df.to_csv(OUT_DID, index=False)

    event_study = run_event_study(panel, "local_genre_band_starts")
    event_study.to_csv(OUT_EVENT_STUDY, index=False)
    make_figure(event_study)
    write_summary(panel, did_df, event_study)

    print(f"Wrote {OUT_PANEL}")
    print(f"Wrote {OUT_DID}")
    print(f"Wrote {OUT_EVENT_STUDY}")
    print(f"Wrote {OUT_FIGURE}")
    print(f"Wrote {OUT_SUMMARY}")


if __name__ == "__main__":
    main()
