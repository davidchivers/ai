from __future__ import annotations

import re
import unicodedata
from pathlib import Path

import pandas as pd
import requests
from bs4 import BeautifulSoup


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data"
OUTPUT_DIR = DATA_DIR / "processed" / "country_genre_analysis"

CANDIDATE_POOL_PATH = DATA_DIR / "blockbuster_seed_refresh_candidate_pool.csv"

PROBE_CSV_PATH = OUTPUT_DIR / "seed_refresh_candidate_probe.csv"
PROBE_MD_PATH = OUTPUT_DIR / "seed_refresh_candidate_probe.md"

REQUEST_HEADERS = {"User-Agent": "Mozilla/5.0"}
REQUEST_TIMEOUT = 30
ARIA_ALBUMS_CHART_ID = "f0fd3d45-3e44-4dba-a3ed-98f7690a1be3"


def normalize_match_text(value: object) -> str:
    text = "" if value is None or pd.isna(value) else str(value)
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii").lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return " ".join(text.split())


def build_aria_lookup(session: requests.Session) -> dict[tuple[str, str], dict[str, object]]:
    related_dates = session.get(
        f"https://www.aria.com.au/api/charts/{ARIA_ALBUMS_CHART_ID}/related-dates",
        timeout=REQUEST_TIMEOUT,
        headers=REQUEST_HEADERS,
    ).json()

    aria_lookup: dict[tuple[str, str], dict[str, object]] = {}
    for item in related_dates:
        chart_id = item["id"]
        chart = session.get(
            f"https://www.aria.com.au/api/charts/{chart_id}",
            timeout=REQUEST_TIMEOUT,
            headers=REQUEST_HEADERS,
        ).json()
        publish_date = str(chart["publishDate"])[:10]
        for entry in chart.get("items", []):
            key = (
                normalize_match_text(entry.get("artist", "")),
                normalize_match_text(entry.get("title", "")),
            )
            current = aria_lookup.get(key)
            if current is None or publish_date < str(current["aria_first_date"]):
                aria_lookup[key] = {
                    "aria_first_date": publish_date,
                    "aria_peak": entry.get("peak", pd.NA),
                    "aria_total_weeks": entry.get("totalWeeks", pd.NA),
                }
    return aria_lookup


def probe_riaa(session: requests.Session, artist_name: str, album_title: str) -> dict[str, object]:
    response = session.get(
        "https://www.riaa.com/gold-platinum/",
        params={
            "tab_active": "default-award",
            "ar": artist_name,
            "ti": album_title,
        },
        timeout=REQUEST_TIMEOUT,
        headers=REQUEST_HEADERS,
    )
    soup = BeautifulSoup(response.text, "html.parser")
    table = soup.find("table", id="search-award-table")
    if table is None:
        return {
            "riaa_i": 0,
            "riaa_certification_date": pd.NA,
            "riaa_award_level_proxy": pd.NA,
            "riaa_source_url": response.url,
        }

    for tr in table.find_all("tr", class_="table_award_row"):
        tds = tr.find_all("td", recursive=False)
        if len(tds) < 6:
            continue
        matched_artist = " ".join(tds[1].get_text(" ", strip=True).split())
        matched_title = " ".join(tds[2].get_text(" ", strip=True).split())
        certification_date = " ".join(tds[3].get_text(" ", strip=True).split())
        fmt = " ".join(tds[5].get_text(" ", strip=True).split())

        if (
            normalize_match_text(matched_artist) == normalize_match_text(artist_name)
            and normalize_match_text(matched_title) == normalize_match_text(album_title)
            and "ALBUM" in fmt.upper()
        ):
            award_img = tds[0].find("img", class_="award")
            award_level_proxy = pd.NA
            if award_img is not None:
                award_level_proxy = award_img.get("src", "").split("/")[-1].replace("_big.png", "")
            return {
                "riaa_i": 1,
                "riaa_certification_date": certification_date,
                "riaa_award_level_proxy": award_level_proxy,
                "riaa_source_url": response.url,
            }

    return {
        "riaa_i": 0,
        "riaa_certification_date": pd.NA,
        "riaa_award_level_proxy": pd.NA,
        "riaa_source_url": response.url,
    }


def build_recommendation(row: pd.Series) -> int:
    return int(bool(row["aria_i"] or row["riaa_i"]))


def write_summary(probe: pd.DataFrame) -> None:
    recommended = probe.loc[probe["recommended_add_i"] == 1].copy()
    rejected = probe.loc[probe["recommended_add_i"] == 0].copy()

    lines: list[str] = []
    lines.append("# Seed refresh candidate probe")
    lines.append("")
    lines.append("This file probes the candidate seed-refresh pool against the two public-source paths")
    lines.append("that currently matter most for the language-spillover extension:")
    lines.append("")
    lines.append("- ARIA albums-chart history from the live public chart API")
    lines.append("- RIAA public Gold & Platinum search pages")
    lines.append("")
    lines.append("## Recommended additions")
    lines.append("")
    if recommended.empty:
        lines.append("- None.")
    else:
        for _, row in recommended.iterrows():
            source_flags: list[str] = []
            if row["aria_i"] == 1:
                source_flags.append(f"ARIA `{row['aria_first_date']}` peak `{row['aria_peak']}`")
            if row["riaa_i"] == 1:
                source_flags.append(f"RIAA `{row['riaa_certification_date']}`")
            lines.append(
                f"- `{row['artist_name']} - {row['album_title']}` (`{int(row['release_year'])}`): "
                + "; ".join(source_flags)
            )
    lines.append("")
    lines.append("## Rejected or deferred candidates")
    lines.append("")
    if rejected.empty:
        lines.append("- None.")
    else:
        for _, row in rejected.iterrows():
            lines.append(
                f"- `{row['artist_name']} - {row['album_title']}` (`{int(row['release_year'])}`): "
                "no exact ARIA or RIAA overlap recovered in the current public-source probe."
            )
    lines.append("")
    lines.append("## Full table")
    lines.append("")
    lines.append(
        probe[
            [
                "artist_name",
                "album_title",
                "release_year",
                "aria_i",
                "aria_first_date",
                "aria_peak",
                "riaa_i",
                "riaa_certification_date",
                "recommended_add_i",
            ]
        ].to_markdown(index=False)
    )
    lines.append("")
    PROBE_MD_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    candidates = pd.read_csv(CANDIDATE_POOL_PATH)
    session = requests.Session()

    aria_lookup = build_aria_lookup(session)
    aria_rows: list[dict[str, object]] = []
    for _, row in candidates.iterrows():
        aria_match = aria_lookup.get(
            (
                normalize_match_text(row["artist_name"]),
                normalize_match_text(row["album_title"]),
            )
        )
        aria_rows.append(
            {
                "aria_i": 1 if aria_match is not None else 0,
                "aria_first_date": aria_match["aria_first_date"] if aria_match else pd.NA,
                "aria_peak": aria_match["aria_peak"] if aria_match else pd.NA,
                "aria_total_weeks": aria_match["aria_total_weeks"] if aria_match else pd.NA,
            }
        )

    probe = pd.concat([candidates.reset_index(drop=True), pd.DataFrame(aria_rows)], axis=1)

    riaa_rows = [
        probe_riaa(session, str(row["artist_name"]), str(row["album_title"]))
        for _, row in probe.iterrows()
    ]
    probe = pd.concat([probe.reset_index(drop=True), pd.DataFrame(riaa_rows)], axis=1)
    probe["recommended_add_i"] = probe.apply(build_recommendation, axis=1)

    probe.to_csv(PROBE_CSV_PATH, index=False)
    write_summary(probe)


if __name__ == "__main__":
    main()
