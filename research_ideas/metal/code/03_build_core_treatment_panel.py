from __future__ import annotations

import re
import time
import unicodedata
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable
from urllib.parse import quote, urljoin

import pandas as pd
import requests
from bs4 import BeautifulSoup, Tag


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data"
OUTPUT_DIR = DATA_DIR / "processed"

SEED_PATH = DATA_DIR / "blockbuster_album_seed.csv"
OUTCOME_PANEL_PATH = OUTPUT_DIR / "metal_archives_all_metal_country_year_panel.csv"
AUS_MANUAL_PATH = DATA_DIR / "blockbuster_album_country_hits_aus_manual.csv"
USA_MANUAL_PATH = DATA_DIR / "blockbuster_album_country_hits_usa_manual.csv"
DEU_MANUAL_PATH = DATA_DIR / "blockbuster_album_country_hits_deu_manual.csv"
BRA_MANUAL_PATH = DATA_DIR / "blockbuster_album_country_hits_bra_manual.csv"
FIN_MANUAL_PATH = DATA_DIR / "blockbuster_album_country_hits_fin_manual.csv"
SWE_MANUAL_PATH = DATA_DIR / "blockbuster_album_country_hits_swe_manual.csv"
FRA_MANUAL_PATH = DATA_DIR / "blockbuster_album_country_hits_fra_manual.csv"
NOR_MANUAL_PATH = DATA_DIR / "blockbuster_album_country_hits_nor_manual.csv"

OUTPUT_HITS_PATH = OUTPUT_DIR / "blockbuster_album_country_hits_core.csv"
OUTPUT_PANEL_PATH = OUTPUT_DIR / "blockbuster_country_year_hit_panel.csv"
OUTPUT_SUMMARY_PATH = OUTPUT_DIR / "blockbuster_country_year_hit_summary.md"

SEED_METADATA_COLUMNS = [
    "seed_album_id",
    "artist_countryiso3code",
    "artist_country_name",
    "artist_language_code",
    "artist_language_name",
    "seed_inclusion_rule",
]
HIT_COLUMNS = [
    "seed_album_id",
    "artist_name",
    "album_title",
    "market_code",
    "country_name",
    "source_name",
    "source_url",
    "chart_name",
    "chart_type",
    "observation_date",
    "entry_date",
    "peak_position",
    "weeks_on_chart",
    "top10_flag",
    "no1_flag",
    "certification_level",
    "certification_date",
    "hit_year",
    "hit_weight",
    "manual_notes",
]

OFFICIAL_CHARTS_BASE = "https://www.officialcharts.com"
FIMI_SEARCH_BASE = "https://www.fimi.it/top-of-the-music/music/?title="
ARIA_ALBUMS_CHART_ID = "f0fd3d45-3e44-4dba-a3ed-98f7690a1be3"

REQUEST_HEADERS = {"User-Agent": "Mozilla/5.0"}
REQUEST_TIMEOUT = 30
SLEEP_SECONDS = 0.25

SPACE_PATTERN = re.compile(r"\s+")
NON_ALNUM_PATTERN = re.compile(r"[^a-z0-9]+")
UK_PEAK_PATTERN = re.compile(r"Peak:\s*(\d+)", re.I)
UK_WEEKS_PATTERN = re.compile(r"Weeks:\s*(\d+)", re.I)
UK_WEEKS_NO1_PATTERN = re.compile(r"Weeks\s+No\.\s*1:\s*(\d+)", re.I)
FIMI_WEEK_PATTERN = re.compile(r"W\s*(\d{1,2})\s*-\s*(\d{4})", re.I)
FIMI_WEEKS_BUTTON_PATTERN = re.compile(r"(\d+)\s+SETTIMAN", re.I)
FIMI_CERT_COUNT_PATTERN = re.compile(r"(\d+)")


@dataclass
class ExtractionLog:
    seed_album_id: str
    market_code: str
    status: str
    detail: str


def collapse_spaces(value: str) -> str:
    return SPACE_PATTERN.sub(" ", value).strip()


def normalize_ascii(value: object) -> str:
    if value is None or pd.isna(value):
        return ""
    text = str(value).strip()
    if not text:
        return ""
    return unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")


def normalize_match_text(value: object) -> str:
    text = normalize_ascii(value).lower()
    text = NON_ALNUM_PATTERN.sub(" ", text)
    return collapse_spaces(text)


def parse_iso_date_uk(raw_value: str | None) -> str | pd.NA:
    if not raw_value:
        return pd.NA
    try:
        parsed = datetime.strptime(raw_value, "%d/%m/%Y").date()
    except ValueError:
        return pd.NA
    return parsed.isoformat()


def parse_fimi_week(raw_value: str | None) -> tuple[int, int] | None:
    if not raw_value:
        return None
    match = FIMI_WEEK_PATTERN.search(raw_value)
    if match is None:
        return None
    week = int(match.group(1))
    year = int(match.group(2))
    return year, week


def canonical_fimi_week(raw_value: str | None) -> str | pd.NA:
    parsed = parse_fimi_week(raw_value)
    if parsed is None:
        return pd.NA
    year, week = parsed
    return f"W{week:02d}-{year}"


def year_from_uk_date(raw_value: str | None) -> int | pd.NA:
    if not raw_value:
        return pd.NA
    try:
        return int(raw_value[:4])
    except (TypeError, ValueError):
        return pd.NA


def year_from_fimi_week(raw_value: str | None) -> int | pd.NA:
    parsed = parse_fimi_week(raw_value)
    if parsed is None:
        return pd.NA
    return parsed[0]


def year_from_market_timing(market_code: object, raw_value: object) -> int | pd.NA:
    market = normalize_ascii(market_code).upper()
    value = normalize_ascii(raw_value)
    if not value:
        return pd.NA
    if market == "ITA":
        return year_from_fimi_week(value)
    return year_from_uk_date(value)


def fetch_soup(session: requests.Session, url: str) -> BeautifulSoup:
    last_error: requests.RequestException | None = None
    for attempt in range(3):
        try:
            response = session.get(url, timeout=REQUEST_TIMEOUT, headers=REQUEST_HEADERS)
            response.raise_for_status()
            time.sleep(SLEEP_SECONDS)
            return BeautifulSoup(response.text, "html.parser")
        except requests.RequestException as exc:
            last_error = exc
            time.sleep(SLEEP_SECONDS * (attempt + 1))
    if last_error is not None:
        raise last_error
    raise RuntimeError(f"Failed to fetch {url}")


def first_or_na(values: Iterable[object]) -> object | pd.NA:
    for value in values:
        if value is not None and value is not pd.NA and not pd.isna(value):
            return value
    return pd.NA


def int_or_na(value: object) -> int | pd.NA:
    if value is None or value is pd.NA or pd.isna(value):
        return pd.NA
    try:
        return int(value)
    except (TypeError, ValueError):
        return pd.NA


def build_aria_lookup(session: requests.Session) -> dict[tuple[str, str], dict[str, object]]:
    related_dates_url = f"https://www.aria.com.au/api/charts/{ARIA_ALBUMS_CHART_ID}/related-dates"
    related_dates_response = session.get(related_dates_url, timeout=REQUEST_TIMEOUT, headers=REQUEST_HEADERS)
    related_dates_response.raise_for_status()
    related_dates = related_dates_response.json()
    time.sleep(SLEEP_SECONDS)

    aria_lookup: dict[tuple[str, str], dict[str, object]] = {}
    for item in related_dates:
        chart_id = item["id"]
        chart_url = f"https://www.aria.com.au/api/charts/{chart_id}"
        chart_response = session.get(chart_url, timeout=REQUEST_TIMEOUT, headers=REQUEST_HEADERS)
        chart_response.raise_for_status()
        chart = chart_response.json()
        time.sleep(SLEEP_SECONDS)

        publish_date = str(chart.get("publishDate", ""))[:10]
        if not publish_date:
            continue

        for entry in chart.get("items", []):
            key = (
                normalize_match_text(entry.get("artist", "")),
                normalize_match_text(entry.get("title", "")),
            )
            if not key[0] or not key[1]:
                continue

            peak_position = int_or_na(entry.get("peak"))
            total_weeks = int_or_na(entry.get("totalWeeks"))
            current = aria_lookup.get(key)
            if current is None:
                aria_lookup[key] = {
                    "entry_date": publish_date,
                    "observation_date": publish_date,
                    "peak_position": peak_position,
                    "weeks_on_chart": total_weeks,
                    "source_url": chart_url,
                }
                continue

            if publish_date < str(current["entry_date"]):
                current["entry_date"] = publish_date
                current["observation_date"] = publish_date
                current["source_url"] = chart_url
            if peak_position is not pd.NA:
                current_peak = current.get("peak_position", pd.NA)
                if current_peak is pd.NA or pd.isna(current_peak) or int(peak_position) < int(current_peak):
                    current["peak_position"] = peak_position
            if total_weeks is not pd.NA:
                current_weeks = current.get("weeks_on_chart", pd.NA)
                if current_weeks is pd.NA or pd.isna(current_weeks) or int(total_weeks) > int(current_weeks):
                    current["weeks_on_chart"] = total_weeks

    return aria_lookup


def build_aus_row(
    seed_row: pd.Series,
    aria_lookup: dict[tuple[str, str], dict[str, object]],
) -> tuple[dict[str, object] | None, ExtractionLog]:
    key = (
        normalize_match_text(seed_row["artist_name"]),
        normalize_match_text(seed_row["album_title"]),
    )
    match = aria_lookup.get(key)
    if match is None:
        return None, ExtractionLog(
            str(seed_row["seed_album_id"]),
            "AUS",
            "not_found",
            "No exact ARIA albums-chart match inside the current public API history window.",
        )

    peak_position = match["peak_position"]
    top10_flag = 1 if peak_position is not pd.NA and not pd.isna(peak_position) and int(peak_position) <= 10 else 0
    no1_flag = 1 if peak_position is not pd.NA and not pd.isna(peak_position) and int(peak_position) == 1 else 0
    entry_date = match["entry_date"]
    row = {
        "seed_album_id": seed_row["seed_album_id"],
        "artist_name": seed_row["artist_name"],
        "album_title": seed_row["album_title"],
        "market_code": "AUS",
        "country_name": "Australia",
        "source_name": "ARIA",
        "source_url": match["source_url"],
        "chart_name": "ARIA Albums Chart",
        "chart_type": "albums",
        "observation_date": match["observation_date"],
        "entry_date": entry_date,
        "peak_position": peak_position,
        "weeks_on_chart": match["weeks_on_chart"],
        "top10_flag": top10_flag,
        "no1_flag": no1_flag,
        "certification_level": pd.NA,
        "certification_date": pd.NA,
        "hit_year": year_from_uk_date(entry_date),
        "hit_weight": pd.NA,
        "manual_notes": (
            "Exact artist and title match in the official ARIA albums-chart API; entry_date is the "
            "earliest public chart publish date, peak_position is the best observed peak across "
            "public chart snapshots, and weeks_on_chart is the maximum observed cumulative run."
        ),
    }
    return row, ExtractionLog(str(seed_row["seed_album_id"]), "AUS", "ok", "Australia chart evidence recovered.")


def extract_uk_search_candidate(
    session: requests.Session,
    album_title: str,
    artist_name: str,
) -> dict[str, object] | None:
    search_url = f"{OFFICIAL_CHARTS_BASE}/search/albums/{quote(album_title)}/"
    soup = fetch_soup(session, search_url)
    target_title = normalize_match_text(album_title)
    target_artist = normalize_match_text(artist_name)

    candidates: list[dict[str, object]] = []
    for title_anchor in soup.select('a.chart-name[href*="/albums/"]'):
        block = title_anchor.find_parent("p")
        if block is None:
            continue
        artist_anchor = block.find("a", class_="chart-artist")
        candidate_title = normalize_match_text(title_anchor.get_text(" ", strip=True))
        candidate_artist = normalize_match_text(artist_anchor.get_text(" ", strip=True) if artist_anchor else "")
        if candidate_title != target_title or candidate_artist != target_artist:
            continue

        stats_div = block.find_next_sibling("div", class_="stats")
        stats_text = stats_div.get_text(" ", strip=True) if stats_div is not None else ""
        peak_match = UK_PEAK_PATTERN.search(stats_text)
        weeks_match = UK_WEEKS_PATTERN.search(stats_text)
        weeks_no1_match = UK_WEEKS_NO1_PATTERN.search(stats_text)
        if peak_match is None or weeks_match is None:
            continue

        candidates.append(
            {
                "source_url": urljoin(OFFICIAL_CHARTS_BASE, title_anchor["href"]),
                "peak_position": int(peak_match.group(1)),
                "weeks_on_chart": int(weeks_match.group(1)),
                "weeks_no1": int(weeks_no1_match.group(1)) if weeks_no1_match else 0,
                "search_url": search_url,
            }
        )

    if not candidates:
        return None
    return candidates[0]


def extract_uk_first_chart_date(
    session: requests.Session,
    album_url: str,
    expected_peak: int,
) -> str | pd.NA:
    soup = fetch_soup(session, album_url)

    for item_list in soup.select("ul.item-details"):
        info: dict[str, str] = {}
        for item in item_list.find_all("li", recursive=False):
            spans = item.find_all("span", recursive=False)
            if len(spans) < 2:
                continue
            label = collapse_spaces(spans[0].get_text(" ", strip=True))
            value = collapse_spaces(spans[1].get_text(" ", strip=True))
            info[label] = value

        first_chart_date = parse_iso_date_uk(info.get("First Chart Date"))
        if first_chart_date is pd.NA:
            continue
        try:
            peak_position = int(info.get("Peak position", ""))
        except ValueError:
            peak_position = None
        if peak_position == expected_peak:
            return first_chart_date
    for item_list in soup.select("ul.item-details"):
        info: dict[str, str] = {}
        for item in item_list.find_all("li", recursive=False):
            spans = item.find_all("span", recursive=False)
            if len(spans) < 2:
                continue
            label = collapse_spaces(spans[0].get_text(" ", strip=True))
            value = collapse_spaces(spans[1].get_text(" ", strip=True))
            info[label] = value
        first_chart_date = parse_iso_date_uk(info.get("First Chart Date"))
        if first_chart_date is not pd.NA:
            return first_chart_date
    return pd.NA


def build_uk_row(
    session: requests.Session,
    seed_row: pd.Series,
) -> tuple[dict[str, object] | None, ExtractionLog]:
    candidate = extract_uk_search_candidate(
        session=session,
        album_title=str(seed_row["album_title"]),
        artist_name=str(seed_row["artist_name"]),
    )
    if candidate is None:
        return None, ExtractionLog(str(seed_row["seed_album_id"]), "GBR", "not_found", "No exact UK chart match with peak/weeks found.")

    entry_date = extract_uk_first_chart_date(
        session=session,
        album_url=str(candidate["source_url"]),
        expected_peak=int(candidate["peak_position"]),
    )
    if entry_date is pd.NA:
        return None, ExtractionLog(str(seed_row["seed_album_id"]), "GBR", "blocked", "UK chart page matched but first chart date was not recoverable.")

    peak_position = int(candidate["peak_position"])
    row = {
        "seed_album_id": seed_row["seed_album_id"],
        "artist_name": seed_row["artist_name"],
        "album_title": seed_row["album_title"],
        "market_code": "GBR",
        "country_name": "United Kingdom",
        "source_name": "Official Charts",
        "source_url": candidate["source_url"],
        "chart_name": "Official Albums Chart",
        "chart_type": "albums",
        "observation_date": entry_date,
        "entry_date": entry_date,
        "peak_position": peak_position,
        "weeks_on_chart": int(candidate["weeks_on_chart"]),
        "top10_flag": 1 if peak_position <= 10 else 0,
        "no1_flag": 1 if peak_position == 1 or int(candidate["weeks_no1"]) > 0 else 0,
        "certification_level": pd.NA,
        "certification_date": pd.NA,
        "hit_year": year_from_uk_date(entry_date),
        "hit_weight": pd.NA,
        "manual_notes": (
            "Exact title and artist match on Official Charts search; peak and weeks come from the "
            "search result card, and first chart date comes from the matched album page."
        ),
    }
    return row, ExtractionLog(str(seed_row["seed_album_id"]), "GBR", "ok", "UK chart evidence recovered.")


def parse_fimi_chart_table(table: Tag) -> dict[str, object] | None:
    row = next((candidate for candidate in table.find_all("tr") if candidate.find_all("td")), None)
    if row is None:
        return None
    cells = [collapse_spaces(cell.get_text(" ", strip=True)) for cell in row.find_all("td")]
    if len(cells) != 5:
        return None
    category, label, peak_raw, entry_position_raw, date_raw = cells
    try:
        peak_position = int(peak_raw)
    except ValueError:
        return None
    try:
        entry_position = int(entry_position_raw)
    except ValueError:
        entry_position = pd.NA
    return {
        "category": category,
        "label": label,
        "peak_position": peak_position,
        "entry_position": entry_position,
        "date_raw": date_raw,
        "date_canonical": canonical_fimi_week(date_raw),
    }


def parse_fimi_cert_level(listing_div: Tag) -> str | pd.NA:
    for node in listing_div.select("div.type.desk"):
        raw_text = collapse_spaces(node.get_text(" ", strip=True))
        if not raw_text:
            continue
        normalized = normalize_match_text(raw_text)
        if "diamante" in normalized:
            return "diamond"
        if "oro" in normalized:
            return "gold"
        if "platino" in normalized:
            count_match = FIMI_CERT_COUNT_PATTERN.search(normalized)
            if count_match:
                return f"{int(count_match.group(1))}x_platinum"
            return "platinum"
        return normalized.replace(" ", "_")
    return pd.NA


def build_ita_row(
    session: requests.Session,
    seed_row: pd.Series,
) -> tuple[dict[str, object] | None, ExtractionLog]:
    search_url = FIMI_SEARCH_BASE + quote(str(seed_row["album_title"]))
    soup = fetch_soup(session, search_url)
    target_title = normalize_match_text(seed_row["album_title"])
    target_artist = normalize_match_text(seed_row["artist_name"])

    chart_records: list[dict[str, object]] = []
    cert_records: list[dict[str, object]] = []

    listing_divs = soup.find_all(
        "div",
        class_=lambda value: value and "listingsearch" in (value if isinstance(value, str) else " ".join(value)),
    )
    for listing_div in listing_divs:
        classes = listing_div.get("class", [])
        title_node = listing_div.find("span", class_="name")
        artist_node = listing_div.find("span", class_="text")
        listing_title = normalize_match_text(title_node.get_text(" ", strip=True) if title_node else "")
        listing_artist = normalize_match_text(artist_node.get_text(" ", strip=True) if artist_node else "")
        if listing_title != target_title or listing_artist != target_artist:
            continue

        listing_id = listing_div.get("id", "")
        if not listing_id:
            continue
        table_id = "table" + listing_id.replace("listing", "")
        table = soup.find("table", id=table_id)
        if table is None:
            continue

        if "cert" in classes:
            cert_row = next((candidate for candidate in table.find_all("tr") if candidate.find_all("td")), None)
            if cert_row is None:
                continue
            cells = [collapse_spaces(cell.get_text(" ", strip=True)) for cell in cert_row.find_all("td")]
            if len(cells) != 4:
                continue
            cert_records.append(
                {
                    "category": cells[0],
                    "label": cells[1],
                    "release_date": collapse_spaces(cells[2]),
                    "certification_date": canonical_fimi_week(cells[3]),
                    "certification_level": parse_fimi_cert_level(listing_div),
                }
            )
            continue

        chart_info = parse_fimi_chart_table(table)
        if chart_info is None:
            continue
        if normalize_match_text(chart_info["category"]) != "artisti":
            continue

        button_node = listing_div.find("div", class_="button")
        button_text = collapse_spaces(button_node.get_text(" ", strip=True)) if button_node else ""
        weeks_match = FIMI_WEEKS_BUTTON_PATTERN.search(button_text)
        weeks_on_chart = int(weeks_match.group(1)) if weeks_match else pd.NA
        chart_info["weeks_on_chart"] = weeks_on_chart
        chart_records.append(chart_info)

    if not chart_records and not cert_records:
        return None, ExtractionLog(str(seed_row["seed_album_id"]), "ITA", "not_found", "No exact FIMI album/artist match with chart or certification evidence found.")

    chart_records = [record for record in chart_records if record["date_canonical"] is not pd.NA]
    chart_records.sort(key=lambda record: parse_fimi_week(str(record["date_canonical"])) or (9999, 99))
    cert_records = [record for record in cert_records if record["certification_date"] is not pd.NA]
    cert_records.sort(key=lambda record: parse_fimi_week(str(record["certification_date"])) or (9999, 99))

    entry_date = first_or_na(record["date_canonical"] for record in chart_records)
    certification_date = first_or_na(record["certification_date"] for record in cert_records)
    certification_level = first_or_na(record["certification_level"] for record in cert_records)
    peak_position = min((int(record["peak_position"]) for record in chart_records), default=None)
    weeks_on_chart = max(
        (int(record["weeks_on_chart"]) for record in chart_records if record["weeks_on_chart"] is not pd.NA),
        default=None,
    )

    top10_flag = 1 if peak_position is not None and peak_position <= 10 else 0
    no1_flag = 1 if peak_position == 1 else 0

    if top10_flag == 1 and entry_date is not pd.NA:
        hit_year = year_from_fimi_week(str(entry_date))
    elif certification_date is not pd.NA:
        hit_year = year_from_fimi_week(str(certification_date))
    elif entry_date is not pd.NA:
        hit_year = year_from_fimi_week(str(entry_date))
    else:
        hit_year = pd.NA

    if chart_records:
        chart_name = "Top of the Music Artisti"
    else:
        chart_name = "FIMI certifications"

    row = {
        "seed_album_id": seed_row["seed_album_id"],
        "artist_name": seed_row["artist_name"],
        "album_title": seed_row["album_title"],
        "market_code": "ITA",
        "country_name": "Italy",
        "source_name": "FIMI",
        "source_url": search_url,
        "chart_name": chart_name,
        "chart_type": "albums",
        "observation_date": first_or_na([entry_date, certification_date]),
        "entry_date": entry_date,
        "peak_position": peak_position if peak_position is not None else pd.NA,
        "weeks_on_chart": weeks_on_chart if weeks_on_chart is not None else pd.NA,
        "top10_flag": top10_flag,
        "no1_flag": no1_flag,
        "certification_level": certification_level,
        "certification_date": certification_date,
        "hit_year": hit_year,
        "hit_weight": pd.NA,
        "manual_notes": (
            "Exact title and artist match on the FIMI title page; chart evidence uses only the "
            "'Artisti' category, weeks_on_chart is the maximum observed run length, and "
            "certification timing comes from the certification block when present."
        ),
    }
    return row, ExtractionLog(str(seed_row["seed_album_id"]), "ITA", "ok", "Italy chart/certification evidence recovered.")


def build_album_country_rows(seed: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    session = requests.Session()

    rows: list[dict[str, object]] = []
    logs: list[ExtractionLog] = []

    for seed_row in seed.itertuples(index=False):
        series = pd.Series(seed_row._asdict())
        try:
            uk_row, uk_log = build_uk_row(session, series)
        except requests.RequestException as exc:
            uk_row = None
            uk_log = ExtractionLog(
                str(seed_row.seed_album_id),
                "GBR",
                "blocked",
                f"UK request failed after retries: {exc.__class__.__name__}.",
            )
        try:
            ita_row, ita_log = build_ita_row(session, series)
        except requests.RequestException as exc:
            ita_row = None
            ita_log = ExtractionLog(
                str(seed_row.seed_album_id),
                "ITA",
                "blocked",
                f"Italy request failed after retries: {exc.__class__.__name__}.",
            )
        logs.extend([uk_log, ita_log])
        if uk_row is not None:
            rows.append(uk_row)
        if ita_row is not None:
            rows.append(ita_row)

    hits = pd.DataFrame(rows, columns=HIT_COLUMNS).sort_values(
        ["market_code", "hit_year", "artist_name", "album_title"],
        na_position="last",
    )
    log_frame = pd.DataFrame([log.__dict__ for log in logs]).sort_values(["market_code", "seed_album_id"])
    return hits, log_frame


def load_manual_rows(
    seed: pd.DataFrame,
    market_code: str,
    path: Path,
    success_detail: str,
    missing_detail: str,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    if not path.exists():
        empty_hits = pd.DataFrame(columns=HIT_COLUMNS)
        empty_logs = pd.DataFrame(columns=["seed_album_id", "market_code", "status", "detail"])
        return empty_hits, empty_logs

    manual_hits = pd.read_csv(path).fillna(pd.NA)
    manual_hits = manual_hits[HIT_COLUMNS].copy()

    found_ids = set(manual_hits["seed_album_id"].astype(str))
    logs: list[ExtractionLog] = []
    for seed_row in seed.itertuples(index=False):
        seed_album_id = str(seed_row.seed_album_id)
        if seed_album_id in found_ids:
            logs.append(
                ExtractionLog(
                    seed_album_id,
                    market_code,
                    "ok",
                    success_detail,
                )
            )
        else:
            logs.append(
                ExtractionLog(
                    seed_album_id,
                    market_code,
                    "not_found",
                    missing_detail,
                )
            )

    log_frame = pd.DataFrame([log.__dict__ for log in logs]).sort_values(["market_code", "seed_album_id"])
    return manual_hits.sort_values(["market_code", "hit_year", "artist_name", "album_title"]), log_frame


def annotate_hit_rows(hits: pd.DataFrame, seed: pd.DataFrame) -> pd.DataFrame:
    if hits.empty:
        return hits.copy()

    seed_metadata = seed[SEED_METADATA_COLUMNS].drop_duplicates(subset=["seed_album_id"]).copy()
    annotated = hits.merge(seed_metadata, on="seed_album_id", how="left", validate="many_to_one")

    artist_country = annotated["artist_countryiso3code"].map(normalize_ascii)
    market_code = annotated["market_code"].map(normalize_ascii)
    home_market_mask = artist_country.ne("") & market_code.ne("") & artist_country.eq(market_code)
    foreign_market_mask = artist_country.ne("") & market_code.ne("") & artist_country.ne(market_code)

    annotated["home_market_i"] = home_market_mask.astype(int)
    annotated["foreign_market_i"] = foreign_market_mask.astype(int)
    annotated["market_exposure_type"] = pd.Series("unknown_market", index=annotated.index, dtype="object")
    annotated.loc[annotated["foreign_market_i"] == 1, "market_exposure_type"] = "foreign_market"
    annotated.loc[annotated["home_market_i"] == 1, "market_exposure_type"] = "home_market"

    ordered_columns = [
        "seed_album_id",
        "artist_name",
        "album_title",
        "artist_countryiso3code",
        "artist_country_name",
        "artist_language_code",
        "artist_language_name",
        "seed_inclusion_rule",
        "market_code",
        "country_name",
        "market_exposure_type",
        "home_market_i",
        "foreign_market_i",
        "source_name",
        "source_url",
        "chart_name",
        "chart_type",
        "observation_date",
        "entry_date",
        "peak_position",
        "weeks_on_chart",
        "top10_flag",
        "no1_flag",
        "certification_level",
        "certification_date",
        "hit_year",
        "hit_weight",
        "manual_notes",
    ]
    return annotated[ordered_columns].copy()


def aggregate_panel_metric(
    frame: pd.DataFrame,
    year_column: str,
    value_column: str,
    output_column: str,
) -> pd.DataFrame:
    if frame.empty:
        return pd.DataFrame(columns=["countryiso3code", "year", output_column])
    return (
        frame.groupby(["market_code", year_column], dropna=False)[value_column]
        .sum()
        .reset_index(name=output_column)
        .rename(columns={"market_code": "countryiso3code", year_column: "year"})
    )


def resolve_event_year(row: pd.Series, date_column: str) -> int | pd.NA:
    raw_date = row.get(date_column)
    if raw_date is not None and raw_date is not pd.NA and not pd.isna(raw_date):
        inferred_year = year_from_market_timing(row.get("market_code"), raw_date)
        if inferred_year is not pd.NA:
            return inferred_year
    hit_year = row.get("hit_year")
    if hit_year is None or hit_year is pd.NA or pd.isna(hit_year):
        return pd.NA
    try:
        return int(hit_year)
    except (TypeError, ValueError):
        return pd.NA


def build_country_year_panel(hits: pd.DataFrame) -> pd.DataFrame:
    scaffold = pd.read_csv(OUTCOME_PANEL_PATH, usecols=["countryiso3code", "country_name", "year"])
    scaffold = scaffold.loc[
        scaffold["countryiso3code"].isin(["AUS", "USA", "GBR", "ITA", "DEU", "BRA", "FIN", "SWE", "FRA", "NOR"])
        & scaffold["year"].between(1995, 2022)
    ].drop_duplicates()

    chart_rows = hits.loc[
        hits["entry_date"].notna()
        | hits["top10_flag"].fillna(0).astype(int).gt(0)
        | hits["no1_flag"].fillna(0).astype(int).gt(0)
        | hits["weeks_on_chart"].notna()
    ].copy()
    if not chart_rows.empty:
        chart_rows["entry_year"] = chart_rows.apply(lambda row: resolve_event_year(row, "entry_date"), axis=1)
    else:
        chart_rows["entry_year"] = pd.Series(dtype="Int64")

    certification_rows = hits.loc[hits["certification_date"].notna() | hits["certification_level"].notna()].copy()
    if not certification_rows.empty:
        certification_rows["certification_year"] = certification_rows.apply(
            lambda row: resolve_event_year(row, "certification_date"),
            axis=1,
        )
    else:
        certification_rows["certification_year"] = pd.Series(dtype="Int64")

    if not chart_rows.empty:
        chart_rows["weeks_on_chart"] = chart_rows["weeks_on_chart"].fillna(0)
        top10_panel = aggregate_panel_metric(chart_rows, "entry_year", "top10_flag", "hit_top10_ct")
        no1_panel = aggregate_panel_metric(chart_rows, "entry_year", "no1_flag", "hit_no1_ct")
        weeks_panel = aggregate_panel_metric(chart_rows, "entry_year", "weeks_on_chart", "hit_chart_weeks_ct")
        home_top10_panel = aggregate_panel_metric(
            chart_rows.loc[chart_rows["home_market_i"] == 1],
            "entry_year",
            "top10_flag",
            "hit_home_top10_ct",
        )
        foreign_top10_panel = aggregate_panel_metric(
            chart_rows.loc[chart_rows["foreign_market_i"] == 1],
            "entry_year",
            "top10_flag",
            "hit_foreign_top10_ct",
        )
        home_no1_panel = aggregate_panel_metric(
            chart_rows.loc[chart_rows["home_market_i"] == 1],
            "entry_year",
            "no1_flag",
            "hit_home_no1_ct",
        )
        foreign_no1_panel = aggregate_panel_metric(
            chart_rows.loc[chart_rows["foreign_market_i"] == 1],
            "entry_year",
            "no1_flag",
            "hit_foreign_no1_ct",
        )
        home_weeks_panel = aggregate_panel_metric(
            chart_rows.loc[chart_rows["home_market_i"] == 1],
            "entry_year",
            "weeks_on_chart",
            "hit_home_chart_weeks_ct",
        )
        foreign_weeks_panel = aggregate_panel_metric(
            chart_rows.loc[chart_rows["foreign_market_i"] == 1],
            "entry_year",
            "weeks_on_chart",
            "hit_foreign_chart_weeks_ct",
        )
    else:
        top10_panel = pd.DataFrame(columns=["countryiso3code", "year", "hit_top10_ct"])
        no1_panel = pd.DataFrame(columns=["countryiso3code", "year", "hit_no1_ct"])
        weeks_panel = pd.DataFrame(columns=["countryiso3code", "year", "hit_chart_weeks_ct"])
        home_top10_panel = pd.DataFrame(columns=["countryiso3code", "year", "hit_home_top10_ct"])
        foreign_top10_panel = pd.DataFrame(columns=["countryiso3code", "year", "hit_foreign_top10_ct"])
        home_no1_panel = pd.DataFrame(columns=["countryiso3code", "year", "hit_home_no1_ct"])
        foreign_no1_panel = pd.DataFrame(columns=["countryiso3code", "year", "hit_foreign_no1_ct"])
        home_weeks_panel = pd.DataFrame(columns=["countryiso3code", "year", "hit_home_chart_weeks_ct"])
        foreign_weeks_panel = pd.DataFrame(columns=["countryiso3code", "year", "hit_foreign_chart_weeks_ct"])

    if not certification_rows.empty:
        certification_rows["certified_i"] = 1
        cert_panel = aggregate_panel_metric(
            certification_rows,
            "certification_year",
            "certified_i",
            "hit_certified_ct",
        )
        home_cert_panel = aggregate_panel_metric(
            certification_rows.loc[certification_rows["home_market_i"] == 1],
            "certification_year",
            "certified_i",
            "hit_home_certified_ct",
        )
        foreign_cert_panel = aggregate_panel_metric(
            certification_rows.loc[certification_rows["foreign_market_i"] == 1],
            "certification_year",
            "certified_i",
            "hit_foreign_certified_ct",
        )
    else:
        cert_panel = pd.DataFrame(columns=["countryiso3code", "year", "hit_certified_ct"])
        home_cert_panel = pd.DataFrame(columns=["countryiso3code", "year", "hit_home_certified_ct"])
        foreign_cert_panel = pd.DataFrame(columns=["countryiso3code", "year", "hit_foreign_certified_ct"])

    panel = scaffold.merge(top10_panel, on=["countryiso3code", "year"], how="left")
    panel = panel.merge(no1_panel, on=["countryiso3code", "year"], how="left")
    panel = panel.merge(weeks_panel, on=["countryiso3code", "year"], how="left")
    panel = panel.merge(cert_panel, on=["countryiso3code", "year"], how="left")
    panel = panel.merge(home_top10_panel, on=["countryiso3code", "year"], how="left")
    panel = panel.merge(foreign_top10_panel, on=["countryiso3code", "year"], how="left")
    panel = panel.merge(home_no1_panel, on=["countryiso3code", "year"], how="left")
    panel = panel.merge(foreign_no1_panel, on=["countryiso3code", "year"], how="left")
    panel = panel.merge(home_weeks_panel, on=["countryiso3code", "year"], how="left")
    panel = panel.merge(foreign_weeks_panel, on=["countryiso3code", "year"], how="left")
    panel = panel.merge(home_cert_panel, on=["countryiso3code", "year"], how="left")
    panel = panel.merge(foreign_cert_panel, on=["countryiso3code", "year"], how="left")

    for column in [
        "hit_top10_ct",
        "hit_no1_ct",
        "hit_chart_weeks_ct",
        "hit_certified_ct",
        "hit_home_top10_ct",
        "hit_foreign_top10_ct",
        "hit_home_no1_ct",
        "hit_foreign_no1_ct",
        "hit_home_chart_weeks_ct",
        "hit_foreign_chart_weeks_ct",
        "hit_home_certified_ct",
        "hit_foreign_certified_ct",
    ]:
        panel[column] = panel[column].fillna(0).astype(int)

    return panel.sort_values(["countryiso3code", "year"]).reset_index(drop=True)


def build_summary(
    seed: pd.DataFrame,
    hits: pd.DataFrame,
    logs: pd.DataFrame,
    panel: pd.DataFrame,
) -> str:
    market_counts = (
        hits.groupby(["market_code", "country_name"])
        .size()
        .reset_index(name="album_country_rows")
        .sort_values("market_code")
    )
    top10_counts = (
        hits.loc[hits["top10_flag"] == 1]
        .groupby(["market_code", "country_name"])
        .size()
        .reset_index(name="top10_rows")
        .sort_values("market_code")
    )
    exposure_counts = (
        hits.groupby("market_exposure_type")
        .size()
        .reset_index(name="album_country_rows")
        .sort_values("market_exposure_type")
    )
    top10_exposure_counts = (
        hits.loc[hits["top10_flag"] == 1]
        .groupby("market_exposure_type")
        .size()
        .reset_index(name="top10_rows")
        .sort_values("market_exposure_type")
    )
    missing = logs.loc[logs["status"] != "ok"].copy()
    missing_by_market = (
        missing.groupby(["market_code", "status"])
        .size()
        .reset_index(name="count")
        .sort_values(["market_code", "status"])
        if not missing.empty
        else pd.DataFrame(columns=["market_code", "status", "count"])
    )
    top_years = (
        panel.loc[
            (panel["hit_top10_ct"] > 0)
            | (panel["hit_chart_weeks_ct"] > 0)
            | (panel["hit_certified_ct"] > 0)
        ]
        .sort_values(["countryiso3code", "year"])
        .reset_index(drop=True)
    )

    market_names = hits[["market_code", "country_name"]].drop_duplicates().sort_values("market_code")
    if market_names.empty:
        market_text = "no markets"
    else:
        market_text = ", ".join(market_names["country_name"].tolist())
    lines = [
        "# Core treatment panel summary",
        "",
        f"This build expands the active metal seed into official-source treatment rows for {market_text}.",
        "",
        "## Headline counts",
        "",
        f"- Seed albums processed: `{len(seed)}`",
        f"- Album-country rows recovered: `{len(hits)}`",
        f"- Top-10 hit rows recovered: `{int((hits['top10_flag'] == 1).sum())}`",
        f"- Home-market top-10 rows recovered: `{int(((hits['top10_flag'] == 1) & (hits['home_market_i'] == 1)).sum())}`",
        f"- Foreign-market top-10 rows recovered: `{int(((hits['top10_flag'] == 1) & (hits['foreign_market_i'] == 1)).sum())}`",
        f"- Certification rows recovered: `{int(hits['certification_level'].notna().sum())}`",
        "",
        "## Album-country coverage by market",
        "",
        market_counts.to_markdown(index=False),
        "",
        "## Top-10 hit rows by market",
        "",
        top10_counts.to_markdown(index=False) if not top10_counts.empty else "No top-10 rows recovered.",
        "",
        "## Coverage by exposure type",
        "",
        exposure_counts.to_markdown(index=False) if not exposure_counts.empty else "No exposure rows recovered.",
        "",
        "## Top-10 rows by exposure type",
        "",
        top10_exposure_counts.to_markdown(index=False) if not top10_exposure_counts.empty else "No top-10 exposure rows recovered.",
        "",
        "## Non-match or blocked cases by market",
        "",
        missing_by_market.to_markdown(index=False) if not missing_by_market.empty else "All album-market attempts returned evidence rows.",
        "",
        "## Country-year rows with any treatment signal",
        "",
        top_years[
            [
                "countryiso3code",
                "country_name",
                "year",
                "hit_home_top10_ct",
                "hit_foreign_top10_ct",
                "hit_top10_ct",
                "hit_home_no1_ct",
                "hit_foreign_no1_ct",
                "hit_no1_ct",
                "hit_home_chart_weeks_ct",
                "hit_foreign_chart_weeks_ct",
                "hit_chart_weeks_ct",
                "hit_home_certified_ct",
                "hit_foreign_certified_ct",
                "hit_certified_ct",
            ]
        ].to_markdown(index=False)
        if not top_years.empty
        else "No country-year treatment signals were built.",
        "",
        "## Measurement note",
        "",
        "- `hit_top10_ct` and `hit_no1_ct` are assigned to the chart entry year.",
        "- `hit_chart_weeks_ct` is assigned to the chart entry year because the current core file stores album-level total chart weeks rather than full week-by-week histories.",
        "- `hit_certified_ct` is assigned to the first certification year when a certification date is observed, and otherwise falls back to the manual `hit_year` for year-only certification evidence.",
        "- Manual chart rows without a recoverable entry date fall back to the manual `hit_year`, which is acceptable for the current country-year design but should not be mistaken for a precise weekly chart date.",
        "- `home_market` means the chart market matches the artist home country in the curated seed; `foreign_market` means it does not.",
        "- Australia now enters through a manual official-source supplement built from the live ARIA albums-chart API; the public chart history currently begins in `2019-07-01`, so the market is a modern same-language extension rather than a deep historical series.",
        "- United States now enters through a manual official-source supplement built from exact public RIAA album-certification matches, so it is a certification-led market rather than a chart-led market in the current build.",
        "- Germany currently enters through a manual official-source supplement because `offiziellecharts.de` blocks scripted requests in this environment.",
        "- Brazil currently enters through a manual supplement because direct Pro-Musica retrieval is blocked in this environment; the Brazil rows mix official band or artist announcements with clearly labeled secondary sources when the official chart or certification trace is cited but not directly retrievable.",
        "",
    ]
    for row in market_counts.itertuples(index=False):
        lines.insert(7, f"- {row.country_name} rows recovered: `{int(row.album_country_rows)}`")
    return "\n".join(lines)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    seed = pd.read_csv(SEED_PATH)
    hits, logs = build_album_country_rows(seed)
    manual_market_specs = [
        (
            "AUS",
            AUS_MANUAL_PATH,
            "Australia row loaded from a manual official-source ARIA supplement built from the live chart API.",
            "No Australia row in the current ARIA supplement.",
        ),
        (
            "USA",
            USA_MANUAL_PATH,
            "United States row loaded from a manual official-source RIAA supplement built from exact public album-certification matches.",
            "No United States row in the current RIAA supplement.",
        ),
        (
            "DEU",
            DEU_MANUAL_PATH,
            "Germany row loaded from manual official-source supplement because the official site blocks scripted requests in this environment.",
            "No Germany row in the current manual official-source supplement.",
        ),
        (
            "BRA",
            BRA_MANUAL_PATH,
            "Brazil row loaded from a manual supplement because direct Pro-Musica retrieval is blocked in this environment.",
            "No Brazil row in the current manual supplement.",
        ),
        (
            "FIN",
            FIN_MANUAL_PATH,
            "Finland row loaded from a manual official-source supplement built from IFPI Finland chart pages.",
            "No Finland row in the current manual official-source supplement.",
        ),
        (
            "SWE",
            SWE_MANUAL_PATH,
            "Sweden row loaded from a manual official-source supplement built from Sverigetopplistan weekly chart pages.",
            "No Sweden row in the current manual official-source supplement.",
        ),
        (
            "FRA",
            FRA_MANUAL_PATH,
            "France row loaded from a manual official-source supplement built from SNEP weekly top-album PDFs.",
            "No France row in the current manual official-source supplement.",
        ),
        (
            "NOR",
            NOR_MANUAL_PATH,
            "Norway row loaded from a manual official-source supplement built from VG-lista weekly chart pages.",
            "No Norway row in the current manual official-source supplement.",
        ),
    ]
    manual_hits_frames = [hits]
    manual_log_frames = [logs]
    for market_code, path, success_detail, missing_detail in manual_market_specs:
        manual_hits, manual_logs = load_manual_rows(
            seed=seed,
            market_code=market_code,
            path=path,
            success_detail=success_detail,
            missing_detail=missing_detail,
        )
        manual_hits_frames.append(manual_hits)
        manual_log_frames.append(manual_logs)
    hits = pd.concat(manual_hits_frames, ignore_index=True)
    logs = pd.concat(manual_log_frames, ignore_index=True)
    hits = annotate_hit_rows(hits=hits, seed=seed)
    hits = hits.sort_values(["market_code", "hit_year", "artist_name", "album_title"], na_position="last").reset_index(drop=True)
    logs = logs.sort_values(["market_code", "seed_album_id"]).reset_index(drop=True)
    panel = build_country_year_panel(hits)

    hits.to_csv(OUTPUT_HITS_PATH, index=False)
    panel.to_csv(OUTPUT_PANEL_PATH, index=False)
    OUTPUT_SUMMARY_PATH.write_text(build_summary(seed=seed, hits=hits, logs=logs, panel=panel), encoding="utf-8")

    print(f"Seed albums processed: {len(seed)}")
    print(f"Album-country rows recovered: {len(hits)}")
    market_names = (
        hits[["market_code", "country_name"]]
        .drop_duplicates()
        .sort_values("market_code")
        .itertuples(index=False)
    )
    for row in market_names:
        print(f"{row.country_name} rows: {int((hits['market_code'] == row.market_code).sum())}")
    print(f"Top-10 rows: {int((hits['top10_flag'] == 1).sum())}")
    print(f"Home-market top-10 rows: {int(((hits['top10_flag'] == 1) & (hits['home_market_i'] == 1)).sum())}")
    print(f"Foreign-market top-10 rows: {int(((hits['top10_flag'] == 1) & (hits['foreign_market_i'] == 1)).sum())}")
    print(f"Certification rows: {int(hits['certification_level'].notna().sum())}")
    print(f"Wrote: {OUTPUT_HITS_PATH}")
    print(f"Wrote: {OUTPUT_PANEL_PATH}")
    print(f"Wrote: {OUTPUT_SUMMARY_PATH}")


if __name__ == "__main__":
    main()
