"""Stub: collect public procurement notice metadata (no live scraping).

Inputs:
- config dict with source endpoints, search keywords, CPV filters, date range.
- optional seed list of notice IDs.

Outputs:
- pandas DataFrame-like records for notice metadata.
- optional JSONL/CSV artifact with normalized fields.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, Iterable, List


@dataclass
class NoticeRecord:
    notice_id: str
    source: str
    buyer_name: str | None
    award_date: str | None
    contract_total_value_gbp: float | None
    procedure_type: str | None
    framework_id: str | None
    attachment_urls: list[str]


def build_search_payloads(config: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Create source-specific query payloads from CPV and keyword settings."""
    # TODO_IMPL: map unified config to Contracts Finder / Find a Tender request schemas.
    return []


def fetch_notices_stub(payload: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Placeholder for API/HTML retrieval.

    Do not implement network calls until sources and legal constraints are finalized.
    """
    # TODO_IMPL: request data, handle paging, retry, and rate limits.
    return []


def normalize_notice(raw: Dict[str, Any], source: str) -> NoticeRecord:
    """Convert raw notice JSON/HTML fields to canonical NoticeRecord schema."""
    # TODO_IMPL: robust field mapping with null-safe parsing.
    return NoticeRecord(
        notice_id=str(raw.get("notice_id", "")),
        source=source,
        buyer_name=raw.get("buyer_name"),
        award_date=raw.get("award_date"),
        contract_total_value_gbp=raw.get("contract_total_value_gbp"),
        procedure_type=raw.get("procedure_type"),
        framework_id=raw.get("framework_id"),
        attachment_urls=list(raw.get("attachment_urls", [])),
    )


def collect_public_contracts(config: Dict[str, Any]) -> List[NoticeRecord]:
    """Top-level stub collection routine.

    Pseudocode:
    1. Build source-specific payloads.
    2. Iterate payloads and fetch raw notice records.
    3. Normalize to canonical schema.
    4. Deduplicate by notice_id + source.
    5. Persist outputs to intermediate storage.
    """
    all_records: list[NoticeRecord] = []
    for payload in build_search_payloads(config):
        raw_rows = fetch_notices_stub(payload)
        source = payload.get("source", "unknown")
        all_records.extend(normalize_notice(r, source) for r in raw_rows)

    # TODO_IMPL: deduplicate and persist.
    return all_records


if __name__ == "__main__":
    print("Stub only: implement data collection after source setup and approvals.")
