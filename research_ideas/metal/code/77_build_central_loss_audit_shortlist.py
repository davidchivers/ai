from __future__ import annotations

import argparse
import unicodedata
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = PROJECT_ROOT / "data" / "processed" / "scene_networks"
EDGE_PATH = SCENE_DIR / "full_musician_band_edges.csv"
PANEL_PATH = SCENE_DIR / "city_genre_scene_cluster_richer_features.csv"

OUT_ALL_ROWS = "central_loss_candidate_cells.csv"
OUT_SHORTLIST = "central_loss_audit_shortlist.csv"
OUT_SUMMARY = "central_loss_audit_summary.md"

GENRE_FAMILIES = {
    "atmospheric black metal": "atmospheric_black_metal",
    "avant-garde metal": "avant_garde_metal",
    "brutal death metal": "brutal_death_metal",
    "technical death metal": "technical_death_metal",
    "melodic death metal": "melodic_death_metal",
    "depressive black metal": "depressive_black_metal",
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
GENRE_KEYS = sorted(GENRE_FAMILIES, key=len, reverse=True)


def normalize_text(value: object) -> str:
    if value is None:
        return ""
    text = unicodedata.normalize("NFKD", str(value))
    ascii_text = text.encode("ascii", "ignore").decode("ascii")
    return " ".join(ascii_text.split())


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a shortlist of candidate central-musician loss events for manual audit."
    )
    parser.add_argument("--terminal-year-max", type=int, default=2022)
    parser.add_argument("--min-total-bands", type=int, default=3)
    parser.add_argument("--min-local-bands", type=int, default=2)
    parser.add_argument("--min-genre-active-bands", type=int, default=5)
    parser.add_argument("--max-scene-gap", type=int, default=2)
    parser.add_argument("--top-n", type=int, default=100)
    parser.add_argument(
        "--allow-blank-last",
        action="store_true",
        help="Keep musicians even if some band rows have missing last_year_in_band.",
    )
    parser.add_argument(
        "--require-no-current-membership",
        action="store_true",
        help="Drop musicians with any row marked current_member=1.",
    )
    parser.add_argument(
        "--output-suffix",
        type=str,
        default="",
        help="Optional suffix appended before the output file extensions.",
    )
    return parser.parse_args()


def parse_genre_families(genre_raw: object) -> list[str]:
    text = str(genre_raw).lower()
    families: list[str] = []
    for key in GENRE_KEYS:
        if key in text:
            families.append(GENRE_FAMILIES[key])
    return sorted(set(families))


def load_edges() -> pd.DataFrame:
    usecols = [
        "band_id",
        "member_id",
        "member_name",
        "current_member",
        "first_year_in_band",
        "last_year_in_band",
        "band_name",
        "country",
        "city",
        "genre_raw",
    ]
    edges = pd.read_csv(EDGE_PATH, usecols=usecols, low_memory=False)
    for col in ["member_name", "band_name", "country", "city", "genre_raw"]:
        edges[col] = edges[col].map(normalize_text)
    edges["member_id"] = pd.to_numeric(edges["member_id"], errors="coerce")
    edges["band_id"] = pd.to_numeric(edges["band_id"], errors="coerce")
    edges["first_year_in_band"] = pd.to_numeric(edges["first_year_in_band"], errors="coerce")
    edges["last_year_in_band"] = pd.to_numeric(edges["last_year_in_band"], errors="coerce")
    edges["current_member"] = pd.to_numeric(edges["current_member"], errors="coerce").fillna(0)
    edges = edges.dropna(subset=["member_id", "band_id"]).copy()
    edges["member_id"] = edges["member_id"].astype(int)
    edges["band_id"] = edges["band_id"].astype(int)
    return edges


def build_terminal_candidates(edges: pd.DataFrame, args: argparse.Namespace) -> pd.DataFrame:
    member_panel = (
        edges.groupby("member_id", as_index=False)
        .agg(
            member_name=("member_name", "first"),
            total_bands=("band_id", "nunique"),
            any_blank_last=("last_year_in_band", lambda s: s.isna().any()),
            any_current_membership=("current_member", lambda s: (s == 1).any()),
            terminal_year=("last_year_in_band", "max"),
        )
    )
    mask = (
        member_panel["terminal_year"].notna()
        & member_panel["total_bands"].ge(args.min_total_bands)
        & member_panel["terminal_year"].le(args.terminal_year_max)
    )
    if not args.allow_blank_last:
        mask &= ~member_panel["any_blank_last"]
    if args.require_no_current_membership:
        mask &= ~member_panel["any_current_membership"]
    member_panel = member_panel.loc[mask].copy()
    member_panel["terminal_year"] = member_panel["terminal_year"].astype(int)
    return member_panel


def load_scene_panel() -> pd.DataFrame:
    panel = pd.read_csv(
        PANEL_PATH,
        usecols=[
            "city_country",
            "snapshot_year",
            "genre_family",
            "genre_active_bands",
            "genre_active_musicians",
            "genre_multi_band_musicians",
            "genre_broker_musicians",
        ],
        low_memory=False,
    )
    panel = panel.rename(columns={"snapshot_year": "scene_reference_year"})
    panel["city_country"] = panel["city_country"].map(normalize_text)
    panel["genre_family"] = panel["genre_family"].map(normalize_text)
    panel["scene_reference_year"] = pd.to_numeric(panel["scene_reference_year"], errors="coerce")
    panel = panel.dropna(subset=["scene_reference_year"]).copy()
    panel["scene_reference_year"] = panel["scene_reference_year"].astype(int)
    return panel


def build_candidate_cells(edges: pd.DataFrame, terminal_candidates: pd.DataFrame) -> pd.DataFrame:
    active = edges.merge(
        terminal_candidates[["member_id", "terminal_year", "total_bands"]],
        on="member_id",
        how="inner",
    )
    active = active.loc[
        active["first_year_in_band"].fillna(-9999).le(active["terminal_year"])
        & active["last_year_in_band"].ge(active["terminal_year"])
    ].copy()
    active["genre_family"] = active["genre_raw"].map(parse_genre_families)
    active = active.explode("genre_family")
    active = active.dropna(subset=["genre_family"]).copy()
    active["genre_family"] = active["genre_family"].map(normalize_text)
    active["city_country"] = (
        active["city"].fillna("").astype(str).str.strip()
        + ", "
        + active["country"].fillna("").astype(str).str.strip()
    ).map(normalize_text)
    active = active.loc[
        active["city"].ne("")
        & active["country"].ne("")
        & active["genre_family"].ne("")
    ].copy()

    candidate_cells = (
        active.groupby(
            [
                "member_id",
                "member_name",
                "terminal_year",
                "total_bands",
                "city",
                "country",
                "city_country",
                "genre_family",
            ],
            as_index=False,
        )
        .agg(
            local_bands=("band_id", "nunique"),
            local_band_names=(
                "band_name",
                lambda s: " | ".join(sorted({name for name in s if name})[:8]),
            ),
        )
    )
    return candidate_cells


def add_scene_context(candidate_cells: pd.DataFrame, panel: pd.DataFrame) -> pd.DataFrame:
    group_cols = ["city_country", "genre_family"]
    candidate_cells = candidate_cells.sort_values(group_cols + ["terminal_year"]).reset_index(drop=True)
    panel = panel.sort_values(group_cols + ["scene_reference_year"]).reset_index(drop=True)
    merged_parts: list[pd.DataFrame] = []
    for key, left_group in candidate_cells.groupby(group_cols, sort=False):
        right_group = panel.loc[
            panel["city_country"].eq(key[0]) & panel["genre_family"].eq(key[1])
        ].copy()
        left_group = left_group.sort_values("terminal_year").copy()
        if right_group.empty:
            for col in [
                "scene_reference_year",
                "genre_active_bands",
                "genre_active_musicians",
                "genre_multi_band_musicians",
                "genre_broker_musicians",
            ]:
                left_group[col] = pd.NA
            merged_parts.append(left_group)
            continue
        merged_group = pd.merge_asof(
            left_group,
            right_group.drop(columns=group_cols),
            left_on="terminal_year",
            right_on="scene_reference_year",
            direction="backward",
        )
        merged_parts.append(merged_group)
    merged = pd.concat(merged_parts, ignore_index=True)
    for col in [
        "genre_active_bands",
        "genre_active_musicians",
        "genre_multi_band_musicians",
        "genre_broker_musicians",
    ]:
        merged[col] = pd.to_numeric(merged[col], errors="coerce").fillna(0)
    merged["local_band_share"] = (
        merged["local_bands"] / merged["genre_active_bands"].replace({0: pd.NA})
    ).fillna(0.0)
    merged["scene_year_gap"] = (
        merged["terminal_year"] - pd.to_numeric(merged["scene_reference_year"], errors="coerce")
    )
    merged["candidate_score"] = (
        100 * merged["local_bands"]
        + 10 * merged["total_bands"]
        + merged["genre_active_bands"]
        + 0.1 * merged["genre_multi_band_musicians"]
    )
    return merged


def build_shortlist(merged: pd.DataFrame, args: argparse.Namespace) -> tuple[pd.DataFrame, pd.DataFrame]:
    candidate_cells = merged.loc[
        merged["local_bands"].ge(args.min_local_bands)
        & merged["genre_active_bands"].ge(args.min_genre_active_bands)
        & merged["scene_year_gap"].le(args.max_scene_gap)
    ].copy()
    candidate_cells = candidate_cells.sort_values(
        [
            "candidate_score",
            "local_bands",
            "genre_active_bands",
            "total_bands",
            "terminal_year",
            "member_name",
        ],
        ascending=[False, False, False, False, True, True],
    ).reset_index(drop=True)
    primary = (
        candidate_cells.groupby("member_id", as_index=False)
        .head(1)
        .copy()
        .reset_index(drop=True)
    )
    primary["audit_priority"] = range(1, len(primary) + 1)
    primary = primary.head(args.top_n).copy()
    primary["death_search_query"] = primary.apply(
        lambda row: (
            f"\"{row['member_name']}\" death obituary "
            f"\"{str(row['local_band_names']).split(' | ')[0]}\""
        ),
        axis=1,
    )
    primary["exit_search_query"] = primary.apply(
        lambda row: (
            f"\"{row['member_name']}\" left quit "
            f"\"{str(row['local_band_names']).split(' | ')[0]}\""
        ),
        axis=1,
    )
    return candidate_cells, primary


def write_summary(
    terminal_candidates: pd.DataFrame,
    candidate_cells: pd.DataFrame,
    shortlist: pd.DataFrame,
    args: argparse.Namespace,
    out_summary: Path,
) -> None:
    top_rows = shortlist.head(20)
    lines = [
        "# Central musician loss audit summary",
        "",
        "## Screen",
        "",
        f"- Terminal year max: `{args.terminal_year_max}`",
        f"- Minimum lifetime bands: `{args.min_total_bands}`",
        f"- Minimum local same-genre active bands at terminal year: `{args.min_local_bands}`",
        f"- Minimum scene size at terminal year (`genre_active_bands`): `{args.min_genre_active_bands}`",
        f"- Maximum lag between terminal year and matched scene snapshot: `{args.max_scene_gap}`",
        f"- Allow blank last-year rows: `{args.allow_blank_last}`",
        f"- Require no current memberships: `{args.require_no_current_membership}`",
        "",
        "## Counts",
        "",
        f"- Clean terminal musicians after lifetime-band filter: `{len(terminal_candidates):,}`",
        f"- Candidate `member x city x genre x terminal_year` cells: `{len(candidate_cells):,}`",
        f"- One-row-per-member shortlist size: `{len(shortlist):,}`",
        "",
        "## Read",
        "",
        "- This is an audit-ready shortlist, not a causal event file.",
        "- Rows survive only if the musician has fully observed terminal years across all bands.",
        "- Importance is first-pass and intentionally simple: local same-genre multi-band depth plus scene size.",
        "- Web audit is still required to classify each row as a death, a clearly permanent exit, or an ambiguous disappearance.",
        "",
        "## Top shortlist rows",
        "",
        "| Priority | Musician | Terminal year | City-country | Genre | Local bands | Lifetime bands | Scene bands | Bands |",
        "| --- | --- | ---: | --- | --- | ---: | ---: | ---: | --- |",
    ]
    for row in top_rows.itertuples(index=False):
        lines.append(
            "| {priority} | {name} | {year} | {city_country} | {genre} | {local_bands} | {total_bands} | {scene_bands} | {bands} |".format(
                priority=int(row.audit_priority),
                name=row.member_name,
                year=int(row.terminal_year),
                city_country=row.city_country,
                genre=row.genre_family,
                local_bands=int(row.local_bands),
                total_bands=int(row.total_bands),
                scene_bands=int(row.genre_active_bands),
                bands=row.local_band_names,
            )
        )
    out_summary.write_text("\n".join(lines) + "\n", encoding="utf-8")


def resolve_output_path(filename: str, suffix: str) -> Path:
    if not suffix:
        return SCENE_DIR / filename
    base = Path(filename)
    return SCENE_DIR / f"{base.stem}{suffix}{base.suffix}"


def main() -> None:
    args = parse_args()
    out_all_rows = resolve_output_path(OUT_ALL_ROWS, args.output_suffix)
    out_shortlist = resolve_output_path(OUT_SHORTLIST, args.output_suffix)
    out_summary = resolve_output_path(OUT_SUMMARY, args.output_suffix)
    edges = load_edges()
    terminal_candidates = build_terminal_candidates(edges, args)
    candidate_cells = build_candidate_cells(edges, terminal_candidates)
    scene_panel = load_scene_panel()
    candidate_cells = add_scene_context(candidate_cells, scene_panel)
    candidate_cells, shortlist = build_shortlist(candidate_cells, args)
    candidate_cells.to_csv(out_all_rows, index=False)
    shortlist.to_csv(out_shortlist, index=False)
    write_summary(terminal_candidates, candidate_cells, shortlist, args, out_summary)
    print(f"Wrote {out_all_rows}")
    print(f"Wrote {out_shortlist}")
    print(f"Wrote {out_summary}")


if __name__ == "__main__":
    main()
