from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
OUTPUT_DIR = PROCESSED_DIR / "country_genre_analysis"

FAMILY_PANEL_PATH = OUTPUT_DIR / "country_genre_family_year_panel.csv"
COUNTRY_YEAR_PATH = PROCESSED_DIR / "metal_archives_all_metal_country_year_panel.csv"
DEFAULT_PILOT_CASES_PATH = OUTPUT_DIR / "domestic_success_pilot_cases.csv"

DEFAULT_STATIC_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_fe_static.csv"
DEFAULT_DYNAMIC_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_fe_event_study.csv"
DEFAULT_SUMMARY_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_fe_summary.md"
DEFAULT_FIGURE_OUTPUT_PATH = OUTPUT_DIR / "domestic_success_pilot_fe_event_study.png"

SAMPLE_START_YEAR = 1990
SAMPLE_END_YEAR = 2022
EVENT_RELATIVE_YEARS = [-3, -2, 0, 1, 2]
EVENT_BASELINE_YEAR = -1
MAX_RESID_ITERS = 200
RESID_TOL = 1e-10

OUTCOME_SPECS = {
    "all": "bands_started",
    "unsigned": "bands_started_unsigned",
    "signed": "bands_started_signed",
}

CASE_SET_RULES = {
    "all_pilot_cases": lambda df: df.copy(),
    "strict_source_a_tier1": lambda df: df.loc[
        df["source_tier"].eq("source_a") & df["event_tier"].eq("tier_1")
    ].copy(),
}


def path_with_token(path: Path, token: str) -> Path:
    if not token:
        return path
    return path.with_name(f"{path.stem}_{token}{path.suffix}")


def load_inputs(pilot_cases_path: Path) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    family_panel = pd.read_csv(FAMILY_PANEL_PATH).fillna(pd.NA)
    country_year = pd.read_csv(COUNTRY_YEAR_PATH).fillna(pd.NA)
    pilot_cases = pd.read_csv(pilot_cases_path).fillna(pd.NA)

    family_panel["entry_year"] = pd.to_numeric(family_panel["entry_year"], errors="coerce").astype(int)
    for column in OUTCOME_SPECS.values():
        family_panel[column] = pd.to_numeric(family_panel[column], errors="coerce").fillna(0).astype(float)

    country_year["year"] = pd.to_numeric(country_year["year"], errors="coerce").astype(int)
    pilot_cases["domestic_success_year"] = pd.to_numeric(
        pilot_cases["domestic_success_year"], errors="coerce"
    ).astype("Int64")

    return family_panel, country_year, pilot_cases


def build_full_panel(family_panel: pd.DataFrame, country_year: pd.DataFrame) -> pd.DataFrame:
    country_year = country_year.loc[
        country_year["year"].between(SAMPLE_START_YEAR, SAMPLE_END_YEAR),
        ["countryiso3code", "country_name", "year"],
    ].drop_duplicates().copy()

    genres = (
        family_panel[["genre_family"]]
        .drop_duplicates()
        .sort_values("genre_family")
        .reset_index(drop=True)
    )
    country_year["__key"] = 1
    genres["__key"] = 1
    full_panel = country_year.merge(genres, on="__key", how="inner").drop(columns="__key")

    counts = family_panel.rename(columns={"entry_year": "year"})[
        ["countryiso3code", "country_std", "year", "genre_family", *OUTCOME_SPECS.values()]
    ].copy()

    panel = full_panel.merge(
        counts,
        on=["countryiso3code", "year", "genre_family"],
        how="left",
    )
    panel[list(OUTCOME_SPECS.values())] = panel[list(OUTCOME_SPECS.values())].fillna(0.0)

    panel["country_genre_id"] = (
        panel["countryiso3code"].astype(str) + "||" + panel["genre_family"].astype(str)
    )
    panel["country_year_id"] = (
        panel["countryiso3code"].astype(str) + "||" + panel["year"].astype(str)
    )
    panel["genre_year_id"] = panel["genre_family"].astype(str) + "||" + panel["year"].astype(str)
    return panel.sort_values(["countryiso3code", "genre_family", "year"]).reset_index(drop=True)


def add_case_timing(panel: pd.DataFrame, cases: pd.DataFrame) -> pd.DataFrame:
    case_timing = (
        cases.sort_values(["countryiso3code", "genre_family", "domestic_success_year", "pilot_case_id"])
        .drop_duplicates(["countryiso3code", "genre_family"], keep="first")
        .copy()
    )
    case_timing = case_timing[
        [
            "pilot_case_id",
            "countryiso3code",
            "country_name",
            "genre_family",
            "artist_name",
            "domestic_success_year",
            "source_tier",
            "event_tier",
        ]
    ].copy()
    merged = panel.merge(
        case_timing,
        on=["countryiso3code", "country_name", "genre_family"],
        how="left",
    )
    merged["domestic_success_year"] = pd.to_numeric(
        merged["domestic_success_year"], errors="coerce"
    ).astype("Int64")
    return merged


def encode_group(frame: pd.DataFrame, column: str) -> tuple[np.ndarray, np.ndarray]:
    codes, _ = pd.factorize(frame[column], sort=False)
    counts = np.bincount(codes).astype(float)
    return codes.astype(np.int64), counts


def demean_by_group(values: np.ndarray, group_codes: np.ndarray, group_counts: np.ndarray) -> np.ndarray:
    adjusted = values.copy()
    for col_index in range(adjusted.shape[1]):
        sums = np.bincount(group_codes, weights=adjusted[:, col_index], minlength=len(group_counts))
        means = sums[group_codes] / group_counts[group_codes]
        adjusted[:, col_index] = adjusted[:, col_index] - means
    return adjusted


def residualize(values: np.ndarray, group_structures: list[tuple[np.ndarray, np.ndarray]]) -> np.ndarray:
    residual = values.astype(float).copy()
    for _ in range(MAX_RESID_ITERS):
        old = residual.copy()
        for group_codes, group_counts in group_structures:
            residual = demean_by_group(residual, group_codes, group_counts)
        max_change = np.max(np.abs(residual - old))
        if max_change < RESID_TOL:
            break
    return residual


def cluster_robust_se(
    x: np.ndarray,
    residual: np.ndarray,
    cluster_codes: np.ndarray,
) -> np.ndarray:
    xpx = x.T @ x
    xpx_inv = np.linalg.inv(xpx)
    n_obs = x.shape[0]
    n_reg = x.shape[1]
    n_clusters = int(cluster_codes.max()) + 1
    meat = np.zeros((n_reg, n_reg), dtype=float)
    for cluster in range(n_clusters):
        mask = cluster_codes == cluster
        xg = x[mask, :]
        ug = residual[mask]
        xgu = xg.T @ ug
        meat += np.outer(xgu, xgu)
    correction = (n_clusters / max(n_clusters - 1, 1)) * ((n_obs - 1) / max(n_obs - n_reg, 1))
    vcov = correction * (xpx_inv @ meat @ xpx_inv)
    return np.sqrt(np.diag(vcov))


def fit_static_spec(panel: pd.DataFrame, case_set_label: str) -> pd.DataFrame:
    treated = panel["domestic_success_year"].notna()
    sample = panel.copy()
    sample["post_treatment_i"] = (
        treated & (sample["year"] >= sample["domestic_success_year"].fillna(10**9))
    ).astype(float)

    cg_codes, cg_counts = encode_group(sample, "country_genre_id")
    ct_codes, ct_counts = encode_group(sample, "country_year_id")
    gt_codes, gt_counts = encode_group(sample, "genre_year_id")
    group_structures = [(cg_codes, cg_counts), (ct_codes, ct_counts), (gt_codes, gt_counts)]

    x = sample[["post_treatment_i"]].to_numpy(dtype=float)
    x_resid = residualize(x, group_structures=group_structures)
    cluster_codes = cg_codes

    rows: list[dict[str, object]] = []
    treated_cell_ct = int(sample.loc[treated, "country_genre_id"].nunique())
    treated_obs_ct = int(sample["post_treatment_i"].sum())
    for outcome_label, outcome_column in OUTCOME_SPECS.items():
        y = sample[[outcome_column]].to_numpy(dtype=float)
        y_resid = residualize(y, group_structures=group_structures).reshape(-1)
        beta = np.linalg.lstsq(x_resid, y_resid, rcond=None)[0]
        resid = y_resid - (x_resid @ beta)
        se = cluster_robust_se(x_resid, resid, cluster_codes=cluster_codes)
        rows.append(
            {
                "case_set": case_set_label,
                "outcome": outcome_label,
                "coef_post_treatment": float(beta[0]),
                "se_cluster_country_genre": float(se[0]),
                "t_stat": float(beta[0] / se[0]) if se[0] > 0 else np.nan,
                "treated_country_genre_cells": treated_cell_ct,
                "treated_post_observations": treated_obs_ct,
                "sample_year_start": SAMPLE_START_YEAR,
                "sample_year_end": SAMPLE_END_YEAR,
            }
        )
    return pd.DataFrame(rows)


def fit_dynamic_spec(panel: pd.DataFrame, case_set_label: str) -> pd.DataFrame:
    sample = panel.copy()
    sample["event_time"] = sample["year"] - sample["domestic_success_year"].astype("float64")

    for rel_year in EVENT_RELATIVE_YEARS:
        sample[f"event_time_{rel_year}"] = (
            sample["domestic_success_year"].notna() & sample["event_time"].eq(float(rel_year))
        ).astype(float)

    cg_codes, cg_counts = encode_group(sample, "country_genre_id")
    ct_codes, ct_counts = encode_group(sample, "country_year_id")
    gt_codes, gt_counts = encode_group(sample, "genre_year_id")
    group_structures = [(cg_codes, cg_counts), (ct_codes, ct_counts), (gt_codes, gt_counts)]
    cluster_codes = cg_codes

    regressor_columns = [f"event_time_{rel_year}" for rel_year in EVENT_RELATIVE_YEARS]
    x = sample[regressor_columns].to_numpy(dtype=float)
    x_resid = residualize(x, group_structures=group_structures)

    rows: list[dict[str, object]] = []
    treated_cell_ct = int(sample.loc[sample["domestic_success_year"].notna(), "country_genre_id"].nunique())
    for outcome_label, outcome_column in OUTCOME_SPECS.items():
        y = sample[[outcome_column]].to_numpy(dtype=float)
        y_resid = residualize(y, group_structures=group_structures).reshape(-1)
        beta = np.linalg.lstsq(x_resid, y_resid, rcond=None)[0]
        resid = y_resid - (x_resid @ beta)
        se = cluster_robust_se(x_resid, resid, cluster_codes=cluster_codes)

        for idx, rel_year in enumerate(EVENT_RELATIVE_YEARS):
            rows.append(
                {
                    "case_set": case_set_label,
                    "outcome": outcome_label,
                    "relative_year": rel_year,
                    "omitted_baseline_year": EVENT_BASELINE_YEAR,
                    "coef_event_time": float(beta[idx]),
                    "se_cluster_country_genre": float(se[idx]),
                    "t_stat": float(beta[idx] / se[idx]) if se[idx] > 0 else np.nan,
                    "treated_country_genre_cells": treated_cell_ct,
                }
            )
    return pd.DataFrame(rows)


def build_case_sets(panel: pd.DataFrame, pilot_cases: pd.DataFrame) -> dict[str, pd.DataFrame]:
    case_sets: dict[str, pd.DataFrame] = {}
    for label, rule in CASE_SET_RULES.items():
        selected_cases = rule(pilot_cases).copy()
        case_sets[label] = add_case_timing(panel=panel, cases=selected_cases)
    return case_sets


def plot_dynamic(dynamic_results: pd.DataFrame, figure_output_path: Path) -> None:
    case_set_order = ["all_pilot_cases", "strict_source_a_tier1"]
    outcome_order = ["all", "unsigned", "signed"]
    label_map = {
        "all_pilot_cases": "All pilot cases",
        "strict_source_a_tier1": "Strict Source A / Tier 1 subset",
        "all": "All",
        "unsigned": "Unsigned",
        "signed": "Signed",
    }
    color_map = {"all": "#0b7285", "unsigned": "#e67700", "signed": "#5c940d"}

    fig, axes = plt.subplots(1, 2, figsize=(13, 5), sharey=True)
    for ax, case_set in zip(axes, case_set_order):
        subset = dynamic_results.loc[dynamic_results["case_set"].eq(case_set)].copy()
        for outcome in outcome_order:
            outcome_subset = subset.loc[subset["outcome"].eq(outcome)].copy()
            ax.plot(
                outcome_subset["relative_year"],
                outcome_subset["coef_event_time"],
                marker="o",
                linewidth=2.0,
                color=color_map[outcome],
                label=label_map[outcome],
            )
        ax.axvline(-1, color="black", linewidth=0.8, alpha=0.35, linestyle="--")
        ax.axvline(0, color="black", linewidth=0.8, alpha=0.35)
        ax.axhline(0, color="black", linewidth=0.8, alpha=0.25)
        ax.set_title(label_map[case_set], fontsize=12, weight="bold")
        ax.set_xlabel("Years relative to domestic success")
        ax.grid(alpha=0.25, linewidth=0.6)
    axes[0].set_ylabel("Residualized genre-band starts per country-genre-year")
    axes[1].legend(frameon=False)
    note = (
        "Three-way FE event study with country-genre, country-year, and genre-year structure.\n"
        "Coefficients are relative to event time -1 and should be read as pilot-scale diagnostics, not final estimates."
    )
    fig.text(0.01, 0.01, note, ha="left", va="bottom", fontsize=9)
    fig.tight_layout(rect=(0, 0.07, 1, 1))
    fig.savefig(figure_output_path, dpi=200)
    plt.close(fig)


def build_summary(
    static_results: pd.DataFrame,
    dynamic_results: pd.DataFrame,
    pilot_cases: pd.DataFrame,
    run_label: str,
    static_output_path: Path,
    dynamic_output_path: Path,
    figure_output_path: Path,
) -> str:
    static_table = static_results.copy()
    for column in ["coef_post_treatment", "se_cluster_country_genre", "t_stat"]:
        static_table[column] = static_table[column].astype(float).round(3)

    dynamic_table = dynamic_results.copy()
    for column in ["coef_event_time", "se_cluster_country_genre", "t_stat"]:
        dynamic_table[column] = dynamic_table[column].astype(float).round(3)

    full_all = static_results.loc[
        static_results["case_set"].eq("all_pilot_cases") & static_results["outcome"].eq("all")
    ].iloc[0]
    full_unsigned = static_results.loc[
        static_results["case_set"].eq("all_pilot_cases") & static_results["outcome"].eq("unsigned")
    ].iloc[0]
    strict_all = static_results.loc[
        static_results["case_set"].eq("strict_source_a_tier1") & static_results["outcome"].eq("all")
    ].iloc[0]

    leads_full = dynamic_results.loc[
        dynamic_results["case_set"].eq("all_pilot_cases")
        & dynamic_results["outcome"].eq("all")
        & dynamic_results["relative_year"].isin([-3, -2])
    ].copy()
    posts_full = dynamic_results.loc[
        dynamic_results["case_set"].eq("all_pilot_cases")
        & dynamic_results["outcome"].eq("all")
        & dynamic_results["relative_year"].isin([0, 1, 2])
    ].copy()

    lines: list[str] = []
    heading = "Domestic-success pilot FE summary"
    if run_label:
        heading = f"Domestic-success {run_label} FE summary"
    lines.append(f"# {heading}")
    lines.append("")
    lines.append("## Specification")
    lines.append("")
    lines.append(
        "- Unit of observation: `country x genre_family x year`, built as a full zero-filled panel from `1990` to `2022`."
    )
    lines.append(
        "- Outcome margins: `all`, `unsigned`, and `signed` genre-family band starts."
    )
    lines.append(
        "- Fixed effects: country-genre, country-year, and genre-year."
    )
    lines.append(
        "- Main regressor: `post_domestic_success_active`, equal to one from the coded domestic-success year onward for treated country-genre cells."
    )
    lines.append(
        "- Event-study regressors: relative years `-3`, `-2`, `0`, `1`, and `2`, with `-1` omitted as the baseline year."
    )
    full_case_ct = int(pilot_cases["pilot_case_id"].nunique())
    strict_case_ct = int(
        pilot_cases.loc[
            pilot_cases["source_tier"].eq("source_a") & pilot_cases["event_tier"].eq("tier_1"),
            "pilot_case_id",
        ].nunique()
    )
    lines.append(
        f"- Case sets: full `{full_case_ct}`-case pilot and a stricter `{strict_case_ct}`-case `source_a + tier_1` subset."
    )
    lines.append("")
    lines.append("## First read")
    lines.append("")
    lines.append(
        f"- Full pilot static coefficient on `all` starts: `{full_all['coef_post_treatment']:.3f}` with clustered SE `{full_all['se_cluster_country_genre']:.3f}`."
    )
    lines.append(
        f"- Full pilot static coefficient on `unsigned` starts: `{full_unsigned['coef_post_treatment']:.3f}` with clustered SE `{full_unsigned['se_cluster_country_genre']:.3f}`."
    )
    lines.append(
        f"- Strict subset static coefficient on `all` starts: `{strict_all['coef_post_treatment']:.3f}` with clustered SE `{strict_all['se_cluster_country_genre']:.3f}`."
    )
    lines.append(
        f"- In the full pilot, average lead coefficients on `all` starts are `{leads_full['coef_event_time'].mean():.3f}` and average post coefficients are `{posts_full['coef_event_time'].mean():.3f}`."
    )
    lines.append(
        "- Practical read: if lead coefficients are already large in magnitude or the static effect flips sharply across the strict subset, the treatment file is still too heterogeneous to read causally."
    )
    lines.append("")
    lines.append("## Static FE results")
    lines.append("")
    lines.append(static_table.to_markdown(index=False))
    lines.append("")
    lines.append("## Event-study FE results")
    lines.append("")
    lines.append(dynamic_table.to_markdown(index=False))
    lines.append("")
    lines.append("## Interpretation")
    lines.append("")
    lines.append(
        "- This is the first real residualized country-genre specification in the project, but it is still built on a small and partly heterogeneous treatment file."
    )
    lines.append(
        "- The main use of this pass is diagnostic: it tells us whether the broadened pilot survives once country-year and genre-year structure are removed."
    )
    lines.append(
        "- If the strict subset behaves materially better than the full pilot, the right next move is to keep expanding with higher-confidence rows rather than polishing the weak rows."
    )
    lines.append("")
    lines.append("## Outputs")
    lines.append("")
    lines.append(f"- `{static_output_path.name}`")
    lines.append(f"- `{dynamic_output_path.name}`")
    lines.append(f"- `{figure_output_path.name}`")
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--pilot-cases-file",
        default=str(DEFAULT_PILOT_CASES_PATH),
        help="Path to the domestic-success case CSV to use",
    )
    parser.add_argument(
        "--output-token",
        default="",
        help="Optional token appended to output filenames before the extension",
    )
    args = parser.parse_args()

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    pilot_cases_path = Path(args.pilot_cases_file)
    output_token = args.output_token.strip()
    static_output_path = path_with_token(DEFAULT_STATIC_OUTPUT_PATH, output_token)
    dynamic_output_path = path_with_token(DEFAULT_DYNAMIC_OUTPUT_PATH, output_token)
    summary_output_path = path_with_token(DEFAULT_SUMMARY_OUTPUT_PATH, output_token)
    figure_output_path = path_with_token(DEFAULT_FIGURE_OUTPUT_PATH, output_token)

    family_panel, country_year, pilot_cases = load_inputs(pilot_cases_path=pilot_cases_path)
    full_panel = build_full_panel(family_panel=family_panel, country_year=country_year)
    case_sets = build_case_sets(panel=full_panel, pilot_cases=pilot_cases)

    static_frames: list[pd.DataFrame] = []
    dynamic_frames: list[pd.DataFrame] = []
    for case_set_label, panel in case_sets.items():
        static_frames.append(fit_static_spec(panel=panel, case_set_label=case_set_label))
        dynamic_frames.append(fit_dynamic_spec(panel=panel, case_set_label=case_set_label))

    static_results = pd.concat(static_frames, ignore_index=True)
    dynamic_results = pd.concat(dynamic_frames, ignore_index=True)
    summary = build_summary(
        static_results=static_results,
        dynamic_results=dynamic_results,
        pilot_cases=pilot_cases,
        run_label=output_token or "pilot",
        static_output_path=static_output_path,
        dynamic_output_path=dynamic_output_path,
        figure_output_path=figure_output_path,
    )

    static_results.to_csv(static_output_path, index=False)
    dynamic_results.to_csv(dynamic_output_path, index=False)
    summary_output_path.write_text(summary, encoding="utf-8")
    plot_dynamic(dynamic_results=dynamic_results, figure_output_path=figure_output_path)

    print(f"Full panel rows: {len(full_panel)}")
    print(f"Treated cells in full pilot: {pilot_cases[['countryiso3code', 'genre_family']].drop_duplicates().shape[0]}")
    print(f"Wrote: {static_output_path}")
    print(f"Wrote: {dynamic_output_path}")
    print(f"Wrote: {summary_output_path}")
    print(f"Wrote: {figure_output_path}")


if __name__ == "__main__":
    main()
