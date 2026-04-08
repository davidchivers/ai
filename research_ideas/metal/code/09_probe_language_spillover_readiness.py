from __future__ import annotations

import re
import unicodedata
from pathlib import Path

import pandas as pd
import requests
from bs4 import BeautifulSoup


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data"
PROCESSED_DIR = DATA_DIR / "processed"
OUTPUT_DIR = PROCESSED_DIR / "country_genre_analysis"

SEED_PATH = DATA_DIR / "blockbuster_album_seed.csv"

AUS_OVERLAP_PATH = OUTPUT_DIR / "australia_aria_seed_overlap.csv"
USA_PROBE_PATH = OUTPUT_DIR / "usa_riaa_seed_probe.csv"
READINESS_PATH = OUTPUT_DIR / "language_spillover_build_readiness.md"

REQUEST_HEADERS = {"User-Agent": "Mozilla/5.0"}
REQUEST_TIMEOUT = 30
ARIA_ALBUMS_CHART_ID = "f0fd3d45-3e44-4dba-a3ed-98f7690a1be3"


def normalize_match_text(value: object) -> str:
    text = "" if value is None or pd.isna(value) else str(value)
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii").lower()
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return " ".join(text.split())


def fetch_australia_overlap(seed: pd.DataFrame, session: requests.Session) -> tuple[pd.DataFrame, str]:
    related_dates_url = f"https://www.aria.com.au/api/charts/{ARIA_ALBUMS_CHART_ID}/related-dates"
    related_dates = session.get(related_dates_url, timeout=REQUEST_TIMEOUT, headers=REQUEST_HEADERS).json()
    earliest_publish_date = min(item["publishDate"][:10] for item in related_dates)
    earliest_year = int(earliest_publish_date[:4])

    overlap = seed.loc[seed["release_year"] >= earliest_year].copy()
    overlap["source_market_code"] = "AUS"
    overlap["source_name"] = "ARIA"
    overlap["history_start_date"] = earliest_publish_date
    overlap["source_note"] = (
        "Official ARIA albums-chart JSON history is currently recoverable only from the earliest "
        "public related-date returned by the live site."
    )
    return overlap, earliest_publish_date


def parse_riaa_probe(seed: pd.DataFrame, session: requests.Session) -> pd.DataFrame:
    rows: list[dict[str, object]] = []
    for _, seed_row in seed.iterrows():
        response = session.get(
            "https://www.riaa.com/gold-platinum/",
            params={
                "tab_active": "default-award",
                "ar": seed_row["artist_name"],
                "ti": seed_row["album_title"],
            },
            timeout=REQUEST_TIMEOUT,
            headers=REQUEST_HEADERS,
        )
        soup = BeautifulSoup(response.text, "html.parser")
        table = soup.find("table", id="search-award-table")
        if table is None:
            rows.append(
                {
                    "seed_album_id": seed_row["seed_album_id"],
                    "artist_name": seed_row["artist_name"],
                    "album_title": seed_row["album_title"],
                    "usa_match_i": 0,
                    "matched_artist": "",
                    "matched_title": "",
                    "certification_date": "",
                    "label": "",
                    "format": "",
                    "award_level_proxy": "",
                    "source_url": response.url,
                    "source_note": "No RIAA award table returned for the exact artist-title query.",
                }
            )
            continue

        matches: list[dict[str, object]] = []
        for tr in table.find_all("tr", class_="table_award_row"):
            tds = tr.find_all("td", recursive=False)
            if len(tds) < 6:
                continue
            matched_artist = " ".join(tds[1].get_text(" ", strip=True).split())
            matched_title = " ".join(tds[2].get_text(" ", strip=True).split())
            certification_date = " ".join(tds[3].get_text(" ", strip=True).split())
            label = " ".join(tds[4].get_text(" ", strip=True).split())
            fmt = " ".join(tds[5].get_text(" ", strip=True).split())
            award_img = tds[0].find("img", class_="award")
            award_level_proxy = ""
            if award_img is not None:
                award_level_proxy = award_img.get("src", "").split("/")[-1].replace("_big.png", "")

            if (
                normalize_match_text(matched_artist) == normalize_match_text(seed_row["artist_name"])
                and normalize_match_text(matched_title) == normalize_match_text(seed_row["album_title"])
                and "ALBUM" in fmt.upper()
            ):
                matches.append(
                    {
                        "matched_artist": matched_artist,
                        "matched_title": matched_title,
                        "certification_date": certification_date,
                        "label": label,
                        "format": fmt.replace(" MORE DETAILS", "").strip(),
                        "award_level_proxy": award_level_proxy,
                    }
                )

        if matches:
            first_match = matches[0]
            rows.append(
                {
                    "seed_album_id": seed_row["seed_album_id"],
                    "artist_name": seed_row["artist_name"],
                    "album_title": seed_row["album_title"],
                    "usa_match_i": 1,
                    "matched_artist": first_match["matched_artist"],
                    "matched_title": first_match["matched_title"],
                    "certification_date": first_match["certification_date"],
                    "label": first_match["label"],
                    "format": first_match["format"],
                    "award_level_proxy": first_match["award_level_proxy"],
                    "source_url": response.url,
                    "source_note": "Exact artist-title album certification match recovered from the public RIAA search table.",
                }
            )
        else:
            rows.append(
                {
                    "seed_album_id": seed_row["seed_album_id"],
                    "artist_name": seed_row["artist_name"],
                    "album_title": seed_row["album_title"],
                    "usa_match_i": 0,
                    "matched_artist": "",
                    "matched_title": "",
                    "certification_date": "",
                    "label": "",
                    "format": "",
                    "award_level_proxy": "",
                    "source_url": response.url,
                    "source_note": "No exact album-format artist-title certification match in the public RIAA table.",
                }
            )
    return pd.DataFrame(rows)


def write_summary(aus_overlap: pd.DataFrame, aus_history_start: str, usa_probe: pd.DataFrame) -> None:
    usa_matches = usa_probe.loc[usa_probe["usa_match_i"] == 1].copy()

    lines: list[str] = []
    lines.append("# Language spillover build readiness")
    lines.append("")
    lines.append("This file converts the market-priority ranking into a practical build read for the")
    lines.append("next same-language spillover extension.")
    lines.append("")
    lines.append("## Australia")
    lines.append("")
    lines.append(
        f"- Official ARIA albums-chart JSON is reachable and machine-readable through the live chart API."
    )
    lines.append(f"- Earliest public albums-chart date currently returned by `related-dates`: `{aus_history_start}`.")
    lines.append(f"- Current seed albums with release year inside that public window: `{len(aus_overlap)}`.")
    if aus_overlap.empty:
        lines.append("- Overlap rows: none.")
    else:
        lines.append("- Overlap rows:")
        for _, row in aus_overlap.iterrows():
            lines.append(
                f"  - `{row['artist_name']} - {row['album_title']}` (`{int(row['release_year'])}`)"
            )
    lines.append("")
    lines.append("## United States")
    lines.append("")
    lines.append("- Public RIAA search pages are machine-readable enough to recover album certification rows.")
    lines.append(f"- Exact seed albums with public album-format certification matches: `{len(usa_matches)}`.")
    if usa_matches.empty:
        lines.append("- Match rows: none.")
    else:
        lines.append("- Match rows:")
        for _, row in usa_matches.iterrows():
            lines.append(
                f"  - `{row['artist_name']} - {row['album_title']}` -> `{row['certification_date']}`"
            )
    lines.append("")
    lines.append("## Practical read")
    lines.append("")
    lines.append("- Australia is no longer just a readiness case. Those ARIA-supported rows can now be built into the core treatment panel.")
    lines.append("- The current public ARIA history still starts in `2019-07-01`, so Australia should be read as a modern same-language reference market rather than a deep historical series.")
    lines.append("- The United States still has the longer public historical reach through RIAA and remains the best certification-led follow-up market.")
    lines.append("- So the next bottleneck is no longer seed-source overlap at the old scale. It is whether the project should extend outward to the United States or spend the next pass on source hardening in Brazil.")
    lines.append("")
    lines.append("## Output files")
    lines.append("")
    lines.append("- `australia_aria_seed_overlap.csv`")
    lines.append("- `usa_riaa_seed_probe.csv`")
    lines.append("")
    READINESS_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    seed = pd.read_csv(SEED_PATH)
    seed["release_year"] = pd.to_numeric(seed["release_year"], errors="coerce")

    session = requests.Session()

    aus_overlap, aus_history_start = fetch_australia_overlap(seed, session)
    usa_probe = parse_riaa_probe(seed, session)

    aus_overlap.to_csv(AUS_OVERLAP_PATH, index=False)
    usa_probe.to_csv(USA_PROBE_PATH, index=False)
    write_summary(aus_overlap, aus_history_start, usa_probe)


if __name__ == "__main__":
    main()
