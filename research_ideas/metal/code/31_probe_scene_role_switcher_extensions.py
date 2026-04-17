from __future__ import annotations

import csv
import re
from collections import defaultdict
from pathlib import Path

import numpy as np
import pandas as pd
from linearmodels.panel import PanelOLS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
EDGE_PATH = SCENE_DIR / "full_musician_band_edges.csv"
SNAPSHOT_PATH = SCENE_DIR / "city_year_network_snapshots.csv"
EMERGENCE_PATH = SCENE_DIR / "city_genre_first_appearance.csv"
BAND_PATH = PROJECT_ROOT / "data" / "processed" / "metal_archives_all_metal_band_clean.csv"

FEATURE_PATH = SCENE_DIR / "city_year_scene_role_switcher_features.csv"
CRITICAL_MASS_PATH = SCENE_DIR / "scene_role_switcher_critical_mass.csv"
RESULTS_PATH = SCENE_DIR / "scene_role_switcher_extension_results.csv"
SUMMARY_PATH = SCENE_DIR / "scene_role_switcher_extension_summary.md"

ROLE_CATEGORIES = ["guitar", "drums", "bass", "vocals", "keyboards"]
MAX_YEAR = 2022
ROLLING_YEARS = 5

GUITAR_PATTERN = re.compile(r"guitar")
DRUM_PATTERN = re.compile(r"drum|percussion")
BASS_PATTERN = re.compile(r"\bbass\b")
VOCAL_PATTERN = re.compile(r"vocal")
KEYBOARD_PATTERN = re.compile(r"keyboard|synth|piano|organ")


def normalize_city_country(city: str, country: str) -> str:
    city = (city or "").strip()
    country = (country or "").strip()
    if not city:
        return ""
    return f"{city}, {country}" if country else city


def safe_int(value: object) -> int | None:
    if value is None or (isinstance(value, float) and np.isnan(value)):
        return None
    text = str(value).strip()
    if not text:
        return None
    try:
        return int(float(text))
    except ValueError:
        return None


def zscore(series: pd.Series) -> pd.Series:
    std = series.std(ddof=0)
    if pd.isna(std) or std == 0:
        return pd.Series(0.0, index=series.index)
    return (series - series.mean()) / std


def classify_roles(role_text: str) -> tuple[str, ...]:
    text = (role_text or "").lower()
    roles: list[str] = []
    if GUITAR_PATTERN.search(text):
        roles.append("guitar")
    if DRUM_PATTERN.search(text):
        roles.append("drums")
    if BASS_PATTERN.search(text):
        roles.append("bass")
    if VOCAL_PATTERN.search(text):
        roles.append("vocals")
    if KEYBOARD_PATTERN.search(text):
        roles.append("keyboards")
    return tuple(sorted(set(roles)))


def load_snapshots() -> tuple[pd.DataFrame, dict[int, list[str]], set[str]]:
    snapshots = pd.read_csv(SNAPSHOT_PATH)
    snapshots["snapshot_year"] = pd.to_numeric(snapshots["snapshot_year"], errors="coerce").astype(int)
    snapshots["n_active_bands"] = pd.to_numeric(snapshots["n_active_bands"], errors="coerce")
    snapshots["n_nontrivial_communities"] = pd.to_numeric(
        snapshots["n_nontrivial_communities"], errors="coerce"
    )
    city_years_by_emit_year: dict[int, list[str]] = defaultdict(list)
    for row in snapshots[["city_country", "snapshot_year"]].itertuples(index=False):
        city_years_by_emit_year[int(row.snapshot_year)].append(str(row.city_country))
    eligible_cities = set(snapshots["city_country"].dropna().unique())
    return snapshots, city_years_by_emit_year, eligible_cities


def load_unsigned_map() -> dict[str, int | None]:
    bands = pd.read_csv(BAND_PATH, usecols=["source_id_primary", "unsigned_i"])
    bands["source_id_primary"] = bands["source_id_primary"].astype(str)
    unsigned_map: dict[str, int | None] = {}
    for row in bands.itertuples(index=False):
        if pd.isna(row.source_id_primary):
            continue
        if pd.isna(row.unsigned_i):
            unsigned_map[str(row.source_id_primary)] = None
        else:
            unsigned_map[str(row.source_id_primary)] = int(row.unsigned_i)
    return unsigned_map


def build_city_year_features(
    city_years_by_emit_year: dict[int, list[str]],
    eligible_cities: set[str],
    unsigned_map: dict[str, int | None],
) -> pd.DataFrame:
    events_by_year: dict[int, list[tuple[str, str, str, tuple[str, ...], int | None, int]]] = defaultdict(list)
    min_year = min(city_years_by_emit_year.keys())
    max_year = max(city_years_by_emit_year.keys())

    with EDGE_PATH.open("r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            city_country = normalize_city_country(row.get("city", ""), row.get("country", ""))
            if city_country not in eligible_cities:
                continue

            musician_id = (row.get("member_id") or "").strip() or (row.get("member_name") or "").strip()
            band_id = (row.get("band_id") or "").strip()
            if not musician_id or not band_id:
                continue

            start_year = safe_int(row.get("first_year_in_band")) or safe_int(row.get("formed_year"))
            if start_year is None:
                continue
            end_year = safe_int(row.get("last_year_in_band")) or max_year
            if end_year < min_year or start_year > max_year:
                continue
            start_year = max(start_year, min_year)
            end_year = min(end_year, max_year)
            if end_year < start_year:
                continue

            role_tuple = classify_roles(row.get("role", ""))
            unsigned_i = unsigned_map.get(band_id)

            events_by_year[start_year].append((city_country, musician_id, band_id, role_tuple, unsigned_i, 1))
            if end_year + 1 <= max_year:
                events_by_year[end_year + 1].append(
                    (city_country, musician_id, band_id, role_tuple, unsigned_i, -1)
                )

    city_states: dict[str, dict[str, object]] = {}
    feature_rows: list[dict[str, object]] = []

    for year in range(min_year, max_year + 1):
        for city_country, musician_id, band_id, role_tuple, unsigned_i, delta in events_by_year.get(year, []):
            state = city_states.setdefault(
                city_country,
                {
                    "band_edge_counts": {},
                    "active_unsigned_bands_proxy": 0,
                    "active_signed_bands_proxy": 0,
                    "active_unknown_bands_proxy": 0,
                    "musicians": {},
                    "active_musicians": 0,
                    "multi_band_musicians": 0,
                    "active_role_counts": {role: 0 for role in ROLE_CATEGORIES},
                    "multi_band_role_counts": {role: 0 for role in ROLE_CATEGORIES},
                },
            )

            band_counts: dict[str, int] = state["band_edge_counts"]  # type: ignore[assignment]
            old_band_ct = band_counts.get(band_id, 0)
            new_band_ct = old_band_ct + delta
            if new_band_ct < 0:
                new_band_ct = 0
            if old_band_ct == 0 and new_band_ct > 0:
                if unsigned_i == 1:
                    state["active_unsigned_bands_proxy"] = int(state["active_unsigned_bands_proxy"]) + 1
                elif unsigned_i == 0:
                    state["active_signed_bands_proxy"] = int(state["active_signed_bands_proxy"]) + 1
                else:
                    state["active_unknown_bands_proxy"] = int(state["active_unknown_bands_proxy"]) + 1
            elif old_band_ct > 0 and new_band_ct == 0:
                if unsigned_i == 1:
                    state["active_unsigned_bands_proxy"] = int(state["active_unsigned_bands_proxy"]) - 1
                elif unsigned_i == 0:
                    state["active_signed_bands_proxy"] = int(state["active_signed_bands_proxy"]) - 1
                else:
                    state["active_unknown_bands_proxy"] = int(state["active_unknown_bands_proxy"]) - 1

            if new_band_ct == 0:
                band_counts.pop(band_id, None)
            else:
                band_counts[band_id] = new_band_ct

            musicians: dict[str, dict[str, object]] = state["musicians"]  # type: ignore[assignment]
            musician_state = musicians.setdefault(
                musician_id,
                {"bands": set(), "role_counts": {role: 0 for role in ROLE_CATEGORIES}},
            )
            bands: set[str] = musician_state["bands"]  # type: ignore[assignment]
            role_counts: dict[str, int] = musician_state["role_counts"]  # type: ignore[assignment]

            old_n_bands = len(bands)
            old_active = old_n_bands > 0
            old_multi = old_n_bands >= 2
            old_active_flags = {role: role_counts[role] > 0 for role in ROLE_CATEGORIES}
            old_multi_flags = {role: old_multi and old_active_flags[role] for role in ROLE_CATEGORIES}

            if delta == 1:
                bands.add(band_id)
                for role in role_tuple:
                    role_counts[role] += 1
            else:
                bands.discard(band_id)
                for role in role_tuple:
                    role_counts[role] = max(0, role_counts[role] - 1)

            new_n_bands = len(bands)
            new_active = new_n_bands > 0
            new_multi = new_n_bands >= 2
            new_active_flags = {role: role_counts[role] > 0 for role in ROLE_CATEGORIES}
            new_multi_flags = {role: new_multi and new_active_flags[role] for role in ROLE_CATEGORIES}

            if not old_active and new_active:
                state["active_musicians"] = int(state["active_musicians"]) + 1
            elif old_active and not new_active:
                state["active_musicians"] = int(state["active_musicians"]) - 1

            if not old_multi and new_multi:
                state["multi_band_musicians"] = int(state["multi_band_musicians"]) + 1
            elif old_multi and not new_multi:
                state["multi_band_musicians"] = int(state["multi_band_musicians"]) - 1

            active_role_counts: dict[str, int] = state["active_role_counts"]  # type: ignore[assignment]
            multi_band_role_counts: dict[str, int] = state["multi_band_role_counts"]  # type: ignore[assignment]
            for role in ROLE_CATEGORIES:
                if not old_active_flags[role] and new_active_flags[role]:
                    active_role_counts[role] += 1
                elif old_active_flags[role] and not new_active_flags[role]:
                    active_role_counts[role] -= 1

                if not old_multi_flags[role] and new_multi_flags[role]:
                    multi_band_role_counts[role] += 1
                elif old_multi_flags[role] and not new_multi_flags[role]:
                    multi_band_role_counts[role] -= 1

            if not new_active:
                musicians.pop(musician_id, None)

        for city_country in city_years_by_emit_year.get(year, []):
            state = city_states.get(city_country)
            if state is None:
                continue

            active_musicians = int(state["active_musicians"])
            multi_band_musicians = int(state["multi_band_musicians"])
            active_unsigned = int(state["active_unsigned_bands_proxy"])
            active_signed = int(state["active_signed_bands_proxy"])
            known_label_bands = active_unsigned + active_signed

            row: dict[str, object] = {
                "city_country": city_country,
                "snapshot_year": year,
                "n_active_musicians_roleproxy": active_musicians,
                "n_multi_band_musicians": multi_band_musicians,
                "multi_band_share": (
                    multi_band_musicians / active_musicians if active_musicians > 0 else 0.0
                ),
                "active_unsigned_bands_current_proxy": active_unsigned,
                "active_signed_bands_current_proxy": active_signed,
                "unsigned_band_share_current_proxy": (
                    active_unsigned / known_label_bands if known_label_bands > 0 else np.nan
                ),
            }
            active_role_counts = state["active_role_counts"]  # type: ignore[assignment]
            multi_band_role_counts = state["multi_band_role_counts"]  # type: ignore[assignment]
            for role in ROLE_CATEGORIES:
                role_active_ct = int(active_role_counts[role])
                role_multi_ct = int(multi_band_role_counts[role])
                row[f"n_active_{role}_musicians"] = role_active_ct
                row[f"n_multi_band_{role}_musicians"] = role_multi_ct
                row[f"active_{role}_share"] = role_active_ct / active_musicians if active_musicians > 0 else 0.0
                row[f"multi_band_{role}_share_of_all"] = (
                    role_multi_ct / active_musicians if active_musicians > 0 else 0.0
                )
                row[f"multi_band_{role}_share_of_switchers"] = (
                    role_multi_ct / multi_band_musicians if multi_band_musicians > 0 else 0.0
                )
            feature_rows.append(row)

    features = pd.DataFrame(feature_rows)
    features.sort_values(["city_country", "snapshot_year"]).to_csv(FEATURE_PATH, index=False)
    return features


def build_panel(features: pd.DataFrame, snapshots: pd.DataFrame) -> pd.DataFrame:
    emergence = pd.read_csv(EMERGENCE_PATH)
    for column in ["first_band_year", "emergence_year"]:
        emergence[column] = pd.to_numeric(emergence[column], errors="coerce")

    merged_city_year = snapshots[
        ["city_country", "snapshot_year", "n_active_bands", "n_nontrivial_communities"]
    ].merge(features, on=["city_country", "snapshot_year"], how="left")
    genre_families = sorted(emergence["genre_family"].dropna().unique())

    base_panel = (
        merged_city_year[["city_country", "snapshot_year"]]
        .drop_duplicates()
        .assign(__key=1)
        .merge(pd.DataFrame({"genre_family": genre_families, "__key": 1}), on="__key", how="inner")
        .drop(columns="__key")
    )
    panel = base_panel.merge(
        emergence[["city_country", "genre_family", "first_band_year", "emergence_year"]],
        on=["city_country", "genre_family"],
        how="left",
    ).merge(merged_city_year, on=["city_country", "snapshot_year"], how="left")

    panel["emerge_this_year"] = (
        panel["emergence_year"].notna() & panel["emergence_year"].eq(panel["snapshot_year"])
    ).astype(int)
    panel = panel.loc[
        panel["first_band_year"].notna()
        & (panel["snapshot_year"] >= panel["first_band_year"])
        & (panel["emergence_year"].isna() | (panel["snapshot_year"] <= panel["emergence_year"]))
    ].copy()

    roll_cols = [
        "n_active_bands",
        "n_nontrivial_communities",
        "n_multi_band_musicians",
        "multi_band_share",
        "unsigned_band_share_current_proxy",
    ]
    for role in ROLE_CATEGORIES:
        roll_cols.append(f"multi_band_{role}_share_of_switchers")

    panel = panel.sort_values(["city_country", "snapshot_year"]).copy()
    panel["log_active_bands"] = np.log1p(panel["n_active_bands"])
    panel["log_multi_band_musicians"] = np.log1p(panel["n_multi_band_musicians"])
    for column in roll_cols + ["log_active_bands", "log_multi_band_musicians"]:
        panel[f"roll{ROLLING_YEARS}_{column}"] = panel.groupby("city_country")[column].transform(
            lambda s: s.shift(1).rolling(ROLLING_YEARS, min_periods=max(2, ROLLING_YEARS - 1)).mean()
        )
    return panel


def build_critical_mass_table(panel: pd.DataFrame) -> pd.DataFrame:
    base = panel.loc[panel[f"roll{ROLLING_YEARS}_multi_band_share"].notna()].copy()
    base["bands_bin"] = pd.cut(
        base["n_active_bands"],
        bins=[-np.inf, 9, 19, 39, np.inf],
        labels=["<10", "10-19", "20-39", "40+"],
    )
    base["switchers_bin"] = pd.cut(
        base["n_multi_band_musicians"],
        bins=[-np.inf, 1, 4, 9, np.inf],
        labels=["0-1", "2-4", "5-9", "10+"],
    )

    rows = []
    for variable in ["bands_bin", "switchers_bin"]:
        grouped = (
            base.groupby(variable, observed=False)["emerge_this_year"]
            .agg(["count", "sum", "mean"])
            .reset_index()
        )
        grouped.columns = ["bucket", "n_obs", "event_count", "event_rate"]
        grouped["table"] = variable
        rows.append(grouped)
    critical_mass = pd.concat(rows, ignore_index=True)
    critical_mass.to_csv(CRITICAL_MASS_PATH, index=False)
    return critical_mass


def fit_panel_spec(
    panel: pd.DataFrame,
    spec_id: str,
    extra_predictors: list[str],
    spec_note: str,
) -> tuple[pd.DataFrame, dict[str, object]]:
    base_predictors = [
        f"roll{ROLLING_YEARS}_log_active_bands",
        f"roll{ROLLING_YEARS}_n_nontrivial_communities",
        f"roll{ROLLING_YEARS}_multi_band_share",
    ]
    needed = base_predictors + extra_predictors
    sample = panel.loc[panel[f"roll{ROLLING_YEARS}_multi_band_share"].notna()].copy()
    for predictor in extra_predictors:
        sample = sample.loc[sample[predictor].notna()].copy()

    for predictor in needed:
        sample[f"z_{predictor}"] = zscore(sample[predictor])

    exog_cols = [f"z_{predictor}" for predictor in needed]
    sample["cell_id"] = sample["city_country"].astype(str) + " || " + sample["genre_family"].astype(str)
    sample = sample.set_index(["cell_id", "snapshot_year"]).sort_index()
    cluster_frame = pd.DataFrame(
        {"city_cluster": sample.reset_index()["cell_id"].str.split(" \\|\\| ").str[0].values},
        index=sample.index,
    )

    result = PanelOLS(
        sample["emerge_this_year"],
        sample[exog_cols],
        entity_effects=True,
        time_effects=True,
        drop_absorbed=True,
    ).fit(cov_type="clustered", clusters=cluster_frame)

    rows = []
    for predictor in needed:
        z_name = f"z_{predictor}"
        rows.append(
            {
                "spec_id": spec_id,
                "predictor": z_name,
                "coefficient": float(result.params[z_name]),
                "std_error": float(result.std_errors[z_name]),
                "p_value": float(result.pvalues[z_name]),
                "n_obs": int(result.nobs),
                "event_count": int(sample["emerge_this_year"].sum()),
                "event_rate": float(sample["emerge_this_year"].mean()),
                "fixed_effects": "city-genre + year",
                "clustering": "city",
                "spec_note": spec_note,
            }
        )

    metadata = {
        "spec_id": spec_id,
        "title": spec_note,
        "n_obs": int(result.nobs),
        "event_count": int(sample["emerge_this_year"].sum()),
        "event_rate": float(sample["emerge_this_year"].mean()),
        "r_squared": float(result.rsquared),
    }
    return pd.DataFrame(rows), metadata


def significance_stars(p_value: float) -> str:
    if p_value < 0.01:
        return "***"
    if p_value < 0.05:
        return "**"
    if p_value < 0.10:
        return "*"
    return ""


def write_summary(
    critical_mass: pd.DataFrame,
    results: pd.DataFrame,
    metadata_rows: list[dict[str, object]],
) -> None:
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        handle.write("# Scene Role, Switcher, and Signed-Proxy Extensions\n\n")
        handle.write(
            "This file extends the scene-cluster regression toward three mechanism questions: "
            "role composition, switcher critical mass, and a rough signed-versus-unsigned proxy.\n\n"
        )
        handle.write("## Measurement Notes\n\n")
        handle.write(
            "- Role measures are built from the member-role edge file and classify musicians into "
            "`guitar`, `drums`, `bass`, `vocals`, and `keyboards` whenever the role string contains "
            "that instrument family.\n"
        )
        handle.write(
            "- `n_multi_band_musicians` is a city-year count of active local musicians holding `2+` "
            "active local bands in that year.\n"
        )
        handle.write(
            "- Signed versus unsigned is only a **current-label proxy** from "
            "`metal_archives_all_metal_band_clean.csv`, not a historical contract-year measure. "
            "Any signed/unsigned read below should be treated as exploratory.\n\n"
        )

        handle.write("## Critical Mass Tables\n\n")
        for table_name, label in [
            ("bands_bin", "Active band stock"),
            ("switchers_bin", "Multi-band musicians"),
        ]:
            subset = critical_mass.loc[critical_mass["table"].eq(table_name)].copy()
            handle.write(f"### {label}\n\n")
            handle.write("| Bucket | N | Events | Event rate |\n")
            handle.write("|--------|---|--------|------------|\n")
            for _, row in subset.iterrows():
                handle.write(
                    f"| {row['bucket']} | {int(row['n_obs'])} | {int(row['event_count'])} | "
                    f"{row['event_rate']:.4f} |\n"
                )
            handle.write("\n")

        handle.write("## FE Extension Specs\n\n")
        handle.write("| Spec | N | Events | Event rate | R-squared |\n")
        handle.write("|------|---|--------|------------|-----------|\n")
        for meta in metadata_rows:
            handle.write(
                f"| {meta['title']} | {meta['n_obs']} | {meta['event_count']} | "
                f"{meta['event_rate']:.4f} | {meta['r_squared']:.4f} |\n"
            )

        for meta in metadata_rows:
            subset = results.loc[results["spec_id"].eq(meta["spec_id"])].copy()
            handle.write(f"\n### {meta['title']}\n\n")
            handle.write("| Predictor | Coef | SE | P-value |\n")
            handle.write("|-----------|------|----|---------|\n")
            for _, row in subset.iterrows():
                coef = f"{row['coefficient']:.4f}{significance_stars(float(row['p_value']))}"
                handle.write(
                    f"| {row['predictor']} | {coef} | {row['std_error']:.4f} | "
                    f"{row['p_value']:.4f} |\n"
                )

        handle.write("\n## Current Read\n\n")

        def coef(spec_id: str, predictor: str) -> float:
            return float(
                results.loc[
                    results["spec_id"].eq(spec_id) & results["predictor"].eq(predictor), "coefficient"
                ].iloc[0]
            )

        def pval(spec_id: str, predictor: str) -> float:
            return float(
                results.loc[
                    results["spec_id"].eq(spec_id) & results["predictor"].eq(predictor), "p_value"
                ].iloc[0]
            )

        switcher_spec = "switcher_intensity_fe"
        unsigned_spec = "unsigned_proxy_fe"

        role_specs = {
            role: f"role_{role}_fe" for role in ROLE_CATEGORIES
        }
        role_signal = sorted(
            [
                (
                    role,
                    abs(coef(spec_id, f"z_roll{ROLLING_YEARS}_multi_band_{role}_share_of_switchers")),
                    coef(spec_id, f"z_roll{ROLLING_YEARS}_multi_band_{role}_share_of_switchers"),
                    pval(spec_id, f"z_roll{ROLLING_YEARS}_multi_band_{role}_share_of_switchers"),
                )
                for role, spec_id in role_specs.items()
            ],
            key=lambda item: item[1],
            reverse=True,
        )
        top_role = role_signal[0]

        bands_mass = critical_mass.loc[
            critical_mass["table"].eq("bands_bin"), ["bucket", "event_rate"]
        ].copy()
        switcher_mass = critical_mass.loc[
            critical_mass["table"].eq("switchers_bin"), ["bucket", "event_rate"]
        ].copy()
        bands_text = "; ".join(
            f"{row.bucket}: {row.event_rate:.4f}" for row in bands_mass.itertuples(index=False)
        )
        switcher_text = "; ".join(
            f"{row.bucket}: {row.event_rate:.4f}" for row in switcher_mass.itertuples(index=False)
        )

        handle.write(
            f"- Critical mass looks real descriptively. Exact-year emergence rates rise with active band "
            f"stock (`{bands_text}`) and with multi-band musician counts (`{switcher_text}`).\n"
        )
        handle.write(
            f"- In the FE switcher spec, the baseline scene terms stay positive and the switcher-intensity "
            f"term `z_roll{ROLLING_YEARS}_multi_band_share = "
            f"{coef(switcher_spec, f'z_roll{ROLLING_YEARS}_multi_band_share'):.4f}` "
            f"(p = {pval(switcher_spec, f'z_roll{ROLLING_YEARS}_multi_band_share'):.4f}).\n"
        )
        handle.write(
            f"- The count-based switcher test is more informative than the share-based one. Once "
            f"overall size and community variety are controlled, "
            f"`z_roll{ROLLING_YEARS}_log_multi_band_musicians = "
            f"{coef('switcher_count_fe', f'z_roll{ROLLING_YEARS}_log_multi_band_musicians'):.4f}` "
            f"(p = {pval('switcher_count_fe', f'z_roll{ROLLING_YEARS}_log_multi_band_musicians'):.4f}), "
            f"while `z_roll{ROLLING_YEARS}_multi_band_share = "
            f"{coef('switcher_count_fe', f'z_roll{ROLLING_YEARS}_multi_band_share'):.4f}` "
            f"(p = {pval('switcher_count_fe', f'z_roll{ROLLING_YEARS}_multi_band_share'):.4f}). "
            "So absolute switcher mass matters more than switchers as a scene share.\n"
        )
        handle.write(
            f"- The strongest role-composition signal in this pass is `{top_role[0]}` among switchers, "
            f"with coefficient `{top_role[2]:.4f}` and p-value `{top_role[3]:.4f}`. This is the first "
            f"place to look if we want a role-specific creativity story.\n"
        )
        handle.write(
            f"- The signed/unsigned extension is only a current-label proxy. Its coefficient is "
            f"`{coef(unsigned_spec, f'z_roll{ROLLING_YEARS}_unsigned_band_share_current_proxy'):.4f}` "
            f"(p = {pval(unsigned_spec, f'z_roll{ROLLING_YEARS}_unsigned_band_share_current_proxy'):.4f}), "
            "so it should be read as a rough scene-composition correlate rather than a historical label effect.\n"
        )


def main() -> None:
    snapshots, city_years_by_emit_year, eligible_cities = load_snapshots()
    unsigned_map = load_unsigned_map()
    features = build_city_year_features(city_years_by_emit_year, eligible_cities, unsigned_map)
    panel = build_panel(features, snapshots)
    critical_mass = build_critical_mass_table(panel)

    result_frames: list[pd.DataFrame] = []
    metadata_rows: list[dict[str, object]] = []

    specs = [
        (
            "switcher_intensity_fe",
            [],
            "Exact-year FE with switcher intensity baseline",
        ),
        (
            "switcher_count_fe",
            [f"roll{ROLLING_YEARS}_log_multi_band_musicians"],
            "Exact-year FE with switcher count baseline",
        ),
        (
            "unsigned_proxy_fe",
            [f"roll{ROLLING_YEARS}_unsigned_band_share_current_proxy"],
            "Exact-year FE with current-label unsigned-share proxy",
        ),
    ]
    for role in ROLE_CATEGORIES:
        specs.append(
            (
                f"role_{role}_fe",
                [f"roll{ROLLING_YEARS}_multi_band_{role}_share_of_switchers"],
                f"Exact-year FE with {role} share among switchers",
            )
        )

    for spec_id, extra_predictors, note in specs:
        result_frame, meta = fit_panel_spec(panel, spec_id, extra_predictors, note)
        result_frames.append(result_frame)
        metadata_rows.append(meta)

    results = pd.concat(result_frames, ignore_index=True)
    results.to_csv(RESULTS_PATH, index=False)
    write_summary(critical_mass, results, metadata_rows)

    print(f"Wrote {FEATURE_PATH}")
    print(f"Wrote {CRITICAL_MASS_PATH}")
    print(f"Wrote {RESULTS_PATH}")
    print(f"Wrote {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
