#!/usr/bin/env python3
"""Pull first-birth timing extracts directly from CDC WONDER natality."""

from __future__ import annotations

import argparse
import io
import time
from pathlib import Path

import pandas as pd
import requests
from bs4 import BeautifulSoup


BASE_URL = "https://wonder.cdc.gov"
DEFAULT_DATASET_CODE = "D66"
DEFAULT_YEAR_START = 2007
DEFAULT_YEAR_END = 2024


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Pull a CDC WONDER natality extract grouped by geography, year, and "
            "mother's age group, filtered to first births."
        )
    )
    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Path to project root (default: parent of code/).",
    )
    parser.add_argument(
        "--dataset-code",
        default=DEFAULT_DATASET_CODE,
        help="CDC WONDER dataset code (default: D66, Natality 2007-2024).",
    )
    parser.add_argument(
        "--geography",
        choices=["county_year", "state_year"],
        default="county_year",
        help="Geography to pull (default: county_year).",
    )
    parser.add_argument(
        "--year-start",
        type=int,
        default=DEFAULT_YEAR_START,
        help=f"First year to pull (default: {DEFAULT_YEAR_START}).",
    )
    parser.add_argument(
        "--year-end",
        type=int,
        default=DEFAULT_YEAR_END,
        help=f"Last year to pull (default: {DEFAULT_YEAR_END}).",
    )
    parser.add_argument(
        "--pause-seconds",
        type=float,
        default=0.75,
        help="Pause between CDC requests in seconds (default: 0.75).",
    )
    parser.add_argument(
        "--output-path",
        type=Path,
        default=None,
        help=(
            "Output CSV path. Defaults to "
            "data/raw/cdc_wonder_first_births_export.csv under project root."
        ),
    )
    parser.add_argument(
        "--log-path",
        type=Path,
        default=None,
        help=(
            "Pull log path. Defaults to notes/build/cdc_wonder_first_birth_pull_log.md "
            "under project root."
        ),
    )
    return parser.parse_args()


def build_form_payload(form: BeautifulSoup) -> list[tuple[str, str]]:
    payload: list[tuple[str, str]] = []
    for tag in form.find_all(["input", "select", "textarea"]):
        name = tag.get("name")
        if not name:
            continue
        if tag.name == "input":
            input_type = (tag.get("type") or "text").lower()
            if input_type in {"button", "file", "image", "reset", "submit"}:
                continue
            if input_type in {"checkbox", "radio"}:
                if tag.has_attr("checked"):
                    payload.append((name, tag.get("value", "on")))
                continue
            payload.append((name, tag.get("value", "")))
            continue
        if tag.name == "select":
            options = tag.find_all("option")
            selected = [option.get("value", "") for option in options if option.has_attr("selected")]
            if not selected and options:
                selected = [options[0].get("value", "")]
            for value in selected:
                payload.append((name, value))
            continue
        payload.append((name, tag.text or ""))
    return payload


def set_payload_value(
    payload: list[tuple[str, str]], name: str, values: str | list[str] | None
) -> list[tuple[str, str]]:
    updated = [(k, v) for (k, v) in payload if k != name]
    if values is None:
        return updated
    if isinstance(values, list):
        updated.extend((name, value) for value in values)
    else:
        updated.append((name, values))
    return updated


def post_with_retry(
    session: requests.Session,
    url: str,
    data: list[tuple[str, str]] | dict[str, str],
    timeout: int,
    tries: int = 3,
) -> requests.Response:
    last_error: Exception | None = None
    for attempt in range(1, tries + 1):
        try:
            response = session.post(url, data=data, timeout=timeout)
            response.raise_for_status()
            return response
        except Exception as exc:  # pragma: no cover - network failure path
            last_error = exc
            if attempt == tries:
                break
            time.sleep(2 * attempt)
    assert last_error is not None
    raise last_error


def get_request_form(session: requests.Session, dataset_code: str) -> tuple[str, BeautifulSoup]:
    request_url = f"{BASE_URL}/controller/datarequest/{dataset_code}"
    response = post_with_retry(
        session,
        request_url,
        {"stage": "about", "action-I Agree": "I Agree"},
        timeout=120,
    )
    soup = BeautifulSoup(response.text, "html.parser")
    forms = soup.find_all("form")
    if len(forms) < 2:
        raise RuntimeError("Could not find CDC WONDER request form.")
    action = requests.compat.urljoin(response.url, forms[1].get("action"))
    return action, forms[1]


def build_query_payload(form: BeautifulSoup, dataset_code: str, geography: str, year: int) -> list[tuple[str, str]]:
    prefix = f"{dataset_code}."
    payload = build_form_payload(form)
    geography_group = f"{prefix}V21-level2" if geography == "county_year" else f"{prefix}V21-level1"
    overrides: dict[str, str | list[str] | None] = {
        "B_1": geography_group,
        "B_2": f"{prefix}V20",
        "B_3": f"{prefix}V38",
        "B_4": "*None*",
        "B_5": "*None*",
        "O_location": f"{prefix}V21",
        "O_age": f"{prefix}V38",
        f"V_{prefix}V20": str(year),
        f"V_{prefix}V28": "01",
        f"V_{prefix}V38": "*All*",
        "action-Send": "Send",
    }
    for name, values in overrides.items():
        payload = set_payload_value(payload, name, values)
    payload = set_payload_value(payload, f"V_{prefix}V21", None)
    return payload


def query_year(
    session: requests.Session,
    dataset_code: str,
    geography: str,
    year: int,
) -> pd.DataFrame:
    action, form = get_request_form(session, dataset_code)
    payload = build_query_payload(form, dataset_code, geography, year)
    response = post_with_retry(session, action, payload, timeout=240)
    results_soup = BeautifulSoup(response.text, "html.parser")
    results_forms = results_soup.find_all("form")
    if len(results_forms) < 2:
        raise RuntimeError(f"Could not find CDC WONDER results form for year {year}.")

    export_action = requests.compat.urljoin(response.url, results_forms[1].get("action"))
    export_payload = build_form_payload(results_forms[1])
    export_payload = set_payload_value(export_payload, "O_export-format", "csv")
    export_payload = set_payload_value(export_payload, "action-Export", "Download")

    export_response = post_with_retry(session, export_action, export_payload, timeout=240)
    if "WONDER Message" in export_response.text[:500]:
        message_soup = BeautifulSoup(export_response.text, "html.parser")
        message = message_soup.select_one(".w-sys-message .text")
        detail = message.get_text(" ", strip=True) if message else "Unknown CDC WONDER error."
        raise RuntimeError(f"CDC WONDER export failed for year {year}: {detail}")

    data = pd.read_csv(io.StringIO(export_response.text), dtype=str)
    data["pull_year"] = str(year)
    return data


def write_log(
    log_path: Path,
    dataset_code: str,
    geography: str,
    years: list[int],
    output_path: Path,
    row_count: int,
) -> None:
    lines = [
        "# CDC WONDER first-birth pull log",
        "",
        f"- Dataset code: `{dataset_code}`",
        f"- Geography: `{geography}`",
        f"- Years pulled: {years[0]} to {years[-1]}",
        "- Grouping: geography, year, mother's age group",
        "- Filter: live birth order = first birth",
        "- Measure: births",
        f"- Output: `{output_path}`",
        f"- Export rows written: {row_count}",
    ]
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    args = parse_args()
    project_root = args.project_root.resolve()
    output_path = (
        args.output_path.resolve()
        if args.output_path is not None
        else project_root / "data" / "raw" / "cdc_wonder_first_births_export.csv"
    )
    log_path = (
        args.log_path.resolve()
        if args.log_path is not None
        else project_root / "notes" / "build" / "cdc_wonder_first_birth_pull_log.md"
    )

    years = list(range(args.year_start, args.year_end + 1))
    if not years:
        raise ValueError("No years requested.")

    session = requests.Session()
    session.headers.update({"User-Agent": "Mozilla/5.0"})

    parts: list[pd.DataFrame] = []
    for year in years:
        print(f"Pulling CDC WONDER first births for {year}...")
        part = query_year(
            session=session,
            dataset_code=args.dataset_code,
            geography=args.geography,
            year=year,
        )
        print(f"  rows={len(part)}")
        parts.append(part)
        if year != years[-1]:
            time.sleep(args.pause_seconds)

    combined = pd.concat(parts, ignore_index=True)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    combined.to_csv(output_path, index=False)
    write_log(
        log_path=log_path,
        dataset_code=args.dataset_code,
        geography=args.geography,
        years=years,
        output_path=output_path,
        row_count=len(combined),
    )

    print(f"Wrote: {output_path}")
    print(f"Rows: {len(combined)}")
    print(f"Log: {log_path}")


if __name__ == "__main__":
    main()
