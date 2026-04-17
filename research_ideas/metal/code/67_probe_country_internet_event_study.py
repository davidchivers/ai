from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from linearmodels.panel import PanelOLS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INPUT_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_country_year_panel.csv"
RESULTS_PATH = PROJECT_ROOT / "data" / "processed" / "country_internet_event_study_results.csv"
SUMMARY_PATH = PROJECT_ROOT / "data" / "processed" / "country_internet_event_study_summary.md"

SAMPLE_END_YEAR = 2014
PRE_PERIODS = 5
POST_PERIODS = 5
EVENT_TIMES = [-5, -4, -3, -2, 0, 1, 2, 3, 4, 5]

EVENT_SPECS = [
    {
        "event_id": "internet_5pct",
        "value_column": "internet_ct",
        "threshold": 5.0,
        "start_year": 1995,
        "display_label": "Internet adoption reaches 5%",
    },
    {
        "event_id": "internet_20pct",
        "value_column": "internet_ct",
        "threshold": 20.0,
        "start_year": 1995,
        "display_label": "Internet adoption reaches 20%",
    },
    {
        "event_id": "broadband_5pct",
        "value_column": "fixed_broadband_ct",
        "threshold": 5.0,
        "start_year": 1999,
        "display_label": "Fixed broadband reaches 5%",
    },
]

OUTCOMES = [
    {
        "outcome_id": "log_all_metal_starts",
        "source_column": "bands_formed_all_metal_ct",
        "transform": "log1p",
        "display_label": "Log all-metal band starts",
    },
    {
        "outcome_id": "log_signed_metal_starts",
        "source_column": "bands_formed_all_metal_signed_ct",
        "transform": "log1p",
        "display_label": "Log signed band starts",
    },
    {
        "outcome_id": "share_unsigned_starts",
        "source_column": "share_all_metal_unsigned_ct",
        "transform": "level",
        "display_label": "Unsigned share of starts",
    },
]


def dummy_name(event_time: int) -> str:
    return f"event_{event_time:+d}".replace("+", "p").replace("-", "m")


def load_panel() -> pd.DataFrame:
    panel = pd.read_csv(INPUT_PATH)
    panel["year"] = pd.to_numeric(panel["year"], errors="coerce").astype(int)
    numeric_columns = [
        "internet_ct",
        "fixed_broadband_ct",
        "bands_formed_all_metal_ct",
        "bands_formed_all_metal_signed_ct",
        "share_all_metal_unsigned_ct",
    ]
    for column in numeric_columns:
        panel[column] = pd.to_numeric(panel[column], errors="coerce")
    panel["bands_formed_all_metal_ct"] = panel["bands_formed_all_metal_ct"].fillna(0.0)
    panel["bands_formed_all_metal_signed_ct"] = panel["bands_formed_all_metal_signed_ct"].fillna(0.0)
    return panel


def classify_country_events(panel: pd.DataFrame, spec: dict[str, object]) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    value_column = str(spec["value_column"])
    threshold = float(spec["threshold"])
    start_year = int(spec["start_year"])

    country_info = panel[["countryiso3code", "country_name"]].drop_duplicates()
    for row in country_info.itertuples(index=False):
        rows.append(
            {
                "countryiso3code": row.countryiso3code,
                "country_name": row.country_name,
                "event_year": np.nan,
                "event_status": "no_data",
            }
        )

    status_frame = pd.DataFrame(rows)
    status_frame = status_frame.set_index("countryiso3code")

    for countryiso3code, country_panel in panel.sort_values(["countryiso3code", "year"]).groupby("countryiso3code"):
        observed = country_panel.loc[country_panel[value_column].notna(), ["year", value_column]].copy()
        if observed.empty:
            continue
        above_threshold = observed.loc[observed[value_column] >= threshold].copy()
        if above_threshold.empty:
            status_frame.loc[countryiso3code, "event_status"] = "never_reaches_threshold"
            continue
        first_above_year = int(above_threshold["year"].min())
        prior = observed.loc[observed["year"] < first_above_year].copy()
        prior_below_exists = bool((prior[value_column] < threshold).any())
        if prior_below_exists and start_year <= first_above_year <= SAMPLE_END_YEAR:
            status_frame.loc[countryiso3code, "event_status"] = "clean_event"
            status_frame.loc[countryiso3code, "event_year"] = first_above_year
        else:
            status_frame.loc[countryiso3code, "event_status"] = "ambiguous_or_pre_sample"

    return status_frame.reset_index()


def add_outcome(sample: pd.DataFrame, outcome: dict[str, str]) -> pd.DataFrame:
    sample = sample.copy()
    source_column = outcome["source_column"]
    if outcome["transform"] == "log1p":
        sample["outcome_value"] = np.log1p(sample[source_column].fillna(0.0))
    else:
        sample["outcome_value"] = sample[source_column]
    return sample


def build_estimation_sample(
    panel: pd.DataFrame,
    event_status: pd.DataFrame,
    spec: dict[str, object],
    outcome: dict[str, str],
) -> tuple[pd.DataFrame, dict[str, int]]:
    start_year = int(spec["start_year"])
    sample = panel.merge(event_status, on=["countryiso3code", "country_name"], how="left")
    sample = sample.loc[sample["year"].between(start_year, SAMPLE_END_YEAR)].copy()
    sample = sample.loc[sample["event_status"] != "ambiguous_or_pre_sample"].copy()
    sample = add_outcome(sample, outcome)
    sample = sample.loc[sample["outcome_value"].notna()].copy()
    sample["treated_i"] = sample["event_status"].eq("clean_event").astype(int)
    sample["event_time"] = sample["year"] - sample["event_year"]
    sample = sample.loc[
        sample["event_status"].eq("never_reaches_threshold")
        | sample["event_time"].between(-PRE_PERIODS, POST_PERIODS)
    ].copy()

    counts = {
        "clean_event_countries": int(event_status["event_status"].eq("clean_event").sum()),
        "control_countries": int(event_status["event_status"].eq("never_reaches_threshold").sum()),
        "dropped_ambiguous_countries": int(event_status["event_status"].eq("ambiguous_or_pre_sample").sum()),
    }
    return sample, counts


def fit_event_study(
    sample: pd.DataFrame,
    spec: dict[str, object],
    outcome: dict[str, str],
    counts: dict[str, int],
) -> pd.DataFrame:
    sample = sample.copy()
    support_counts: dict[int, int] = {}
    active_terms: list[str] = []
    for event_time in EVENT_TIMES:
        column = dummy_name(event_time)
        sample[column] = (
            sample["treated_i"].eq(1) & sample["event_time"].eq(event_time)
        ).astype(int)
        support_counts[event_time] = int(sample[column].sum())
        if support_counts[event_time] > 0:
            active_terms.append(column)

    sample = sample.set_index(["countryiso3code", "year"]).sort_index()
    clusters = pd.DataFrame(
        {"country_cluster": sample.reset_index()["countryiso3code"].values},
        index=sample.index,
    )

    result = PanelOLS(
        sample["outcome_value"],
        sample[active_terms],
        entity_effects=True,
        time_effects=True,
        drop_absorbed=True,
    ).fit(cov_type="clustered", clusters=clusters)

    rows: list[dict[str, object]] = []
    for event_time in EVENT_TIMES:
        column = dummy_name(event_time)
        rows.append(
            {
                "event_id": spec["event_id"],
                "event_label": spec["display_label"],
                "value_column": spec["value_column"],
                "threshold": spec["threshold"],
                "sample_start_year": spec["start_year"],
                "sample_end_year": SAMPLE_END_YEAR,
                "outcome_id": outcome["outcome_id"],
                "outcome_label": outcome["display_label"],
                "event_time": event_time,
                "coefficient": float(result.params.get(column, np.nan)),
                "std_error": float(result.std_errors.get(column, np.nan)),
                "p_value": float(result.pvalues.get(column, np.nan)),
                "support_count": int(support_counts[event_time]),
                "n_obs": int(result.nobs),
                "clean_event_countries": counts["clean_event_countries"],
                "control_countries": counts["control_countries"],
                "dropped_ambiguous_countries": counts["dropped_ambiguous_countries"],
                "r_squared": float(result.rsquared),
            }
        )
    return pd.DataFrame(rows)


def format_coef(results: pd.DataFrame, event_id: str, outcome_id: str, event_time: int) -> str:
    row = results.loc[
        (results["event_id"] == event_id)
        & (results["outcome_id"] == outcome_id)
        & (results["event_time"] == event_time)
    ]
    if row.empty:
        return "n/a"
    row = row.iloc[0]
    if pd.isna(row["coefficient"]):
        return "n/a"
    stars = "***" if row["p_value"] < 0.01 else "**" if row["p_value"] < 0.05 else "*" if row["p_value"] < 0.10 else ""
    return f"{row['coefficient']:.4f}{stars}"


def write_summary(results: pd.DataFrame) -> None:
    spec_counts = (
        results.groupby(["event_id", "event_label"], as_index=False)[
            ["clean_event_countries", "control_countries", "dropped_ambiguous_countries"]
        ]
        .max()
    )
    spec_count_map = {
        row.event_id: row for row in spec_counts.itertuples(index=False)
    }
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Country internet threshold event-study probe\n\n")
        handle.write(
            "This probe treats country-level internet or broadband threshold crossings as descriptive "
            "events and estimates event-time paths with country and year fixed effects. It is meant "
            "to see whether broad digital adoption lines up with later changes in country-level metal "
            "entry, not to establish a clean causal effect of the internet.\n\n"
        )
        handle.write("## Event definitions\n\n")
        handle.write(
            f"- Event-study window: `{PRE_PERIODS}` years before to `{POST_PERIODS}` years after threshold crossing.\n"
        )
        handle.write(f"- Sample end year: `{SAMPLE_END_YEAR}`.\n")
        handle.write(
            "- Countries that are already above the threshold at first usable observation, or otherwise "
            "lack a clean below-to-above transition, are dropped rather than treated as controls.\n"
        )

        handle.write("\n## Event support\n\n")
        for spec in EVENT_SPECS:
            row = spec_count_map[spec["event_id"]]
            handle.write(
                f"- `{row.event_label}`: clean events = `{row.clean_event_countries}`, "
                f"never-treated controls = `{row.control_countries}`, "
                f"ambiguous or pre-sample countries dropped = `{row.dropped_ambiguous_countries}`.\n"
            )

        handle.write("\n## Headline coefficients\n\n")
        for spec in EVENT_SPECS:
            handle.write(f"### {spec['display_label']}\n\n")
            for outcome in OUTCOMES:
                handle.write(
                    f"- `{outcome['display_label']}`: "
                    f"`t=-2: {format_coef(results, spec['event_id'], outcome['outcome_id'], -2)}`, "
                    f"`t=0: {format_coef(results, spec['event_id'], outcome['outcome_id'], 0)}`, "
                    f"`t=+1: {format_coef(results, spec['event_id'], outcome['outcome_id'], 1)}`, "
                    f"`t=+3: {format_coef(results, spec['event_id'], outcome['outcome_id'], 3)}`, "
                    f"`t=+5: {format_coef(results, spec['event_id'], outcome['outcome_id'], 5)}`.\n"
                )
            handle.write("\n")

        handle.write("## Current read\n\n")
        handle.write(
            f"- The clearest positive pattern is for `{EVENT_SPECS[0]['display_label']}`. "
            f"`Log all-metal band starts` moves from "
            f"`{format_coef(results, 'internet_5pct', 'log_all_metal_starts', -2)}` at `t=-2` to "
            f"`{format_coef(results, 'internet_5pct', 'log_all_metal_starts', 1)}` at `t=+1`, "
            f"`{format_coef(results, 'internet_5pct', 'log_all_metal_starts', 3)}` at `t=+3`, and "
            f"`{format_coef(results, 'internet_5pct', 'log_all_metal_starts', 5)}` at `t=+5`.\n"
        )
        handle.write(
            f"- The signed-band outcome points in the same direction around `{EVENT_SPECS[0]['display_label']}`: "
            f"`{format_coef(results, 'internet_5pct', 'log_signed_metal_starts', 1)}` at `t=+1`, "
            f"`{format_coef(results, 'internet_5pct', 'log_signed_metal_starts', 3)}` at `t=+3`, and "
            f"`{format_coef(results, 'internet_5pct', 'log_signed_metal_starts', 5)}` at `t=+5`.\n"
        )
        handle.write(
            "- The unsigned-share outcome does not show a comparably clear pattern, so the first-pass read is "
            "more about higher entry volume than a clean shift toward unsigned or amateur production.\n"
        )
        handle.write(
            f"- Later internet saturation at `{EVENT_SPECS[1]['display_label']}` looks materially weaker than the "
            f"earlier `{EVENT_SPECS[0]['display_label']}` event. That suggests the strongest signal, if real, is tied "
            "to early adoption rather than mature internet penetration.\n"
        )
        handle.write(
            f"- The `{EVENT_SPECS[1]['display_label']}` unsigned-share path should be read with caution because it "
            "already shows a nontrivial pretrend by `t=-2`, so that margin is not a clean event-study object here.\n"
        )
        handle.write(
            f"- The `{EVENT_SPECS[2]['display_label']}` event is mostly weak or negative in this window, so the "
            "country-level broadband result is not currently reinforcing the early-internet result.\n"
        )
        handle.write(
            "- This remains a descriptive country-level probe. Country-level adoption timing is still correlated "
            "with many other changes in income, institutions, recording technology, and global music circulation.\n"
        )


def main() -> None:
    panel = load_panel()
    result_frames: list[pd.DataFrame] = []
    for spec in EVENT_SPECS:
        event_status = classify_country_events(panel, spec)
        for outcome in OUTCOMES:
            sample, counts = build_estimation_sample(panel, event_status, spec, outcome)
            result_frames.append(fit_event_study(sample, spec, outcome, counts))

    results = pd.concat(result_frames, ignore_index=True)
    results.to_csv(RESULTS_PATH, index=False)
    write_summary(results)

    print(f"Wrote {RESULTS_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
