"""Stub: parse procurement attachments into line items.

Inputs:
- notice metadata with attachment URLs or local file paths.
- local attachment folder (PDF/XLSX/DOCX).

Outputs:
- line-item table with sku_text_raw, quantity, unit_price_gbp, bundle flags.
- parse diagnostics and confidence scores.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List


@dataclass
class LineItemRecord:
    notice_id: str
    line_item_id: str
    sku_text_raw: str
    quantity: float | None
    unit_price_gbp: float | None
    warranty_years: float | None
    service_bundle_flags: dict
    parse_confidence: float


def extract_text_from_pdf_stub(path: Path) -> str:
    """Placeholder for PDF text extraction pipeline."""
    # TODO_IMPL: combine OCR fallback + table extraction for scanned schedules.
    return ""


def parse_line_items_from_text_stub(text: str) -> List[Dict]:
    """Placeholder for regex/table parsing of quantity, price, and SKU text."""
    # TODO_IMPL: detect tabular structures and currency/unit patterns.
    return []


def classify_bundle_flags_stub(sku_text: str) -> Dict[str, bool]:
    """Heuristic classifier for bundled services in line descriptions."""
    keywords = {
        "imaging": "image" in sku_text.lower(),
        "security": "security" in sku_text.lower(),
        "deployment": "deploy" in sku_text.lower(),
        "support": "support" in sku_text.lower(),
        "warranty": "warranty" in sku_text.lower(),
    }
    return keywords


def parse_attachment_stub(notice_id: str, path: Path) -> List[LineItemRecord]:
    """End-to-end placeholder parser for one attachment file."""
    text = extract_text_from_pdf_stub(path)
    rows = parse_line_items_from_text_stub(text)

    out: list[LineItemRecord] = []
    for idx, row in enumerate(rows, start=1):
        sku = str(row.get("sku_text_raw", "")).strip()
        out.append(
            LineItemRecord(
                notice_id=notice_id,
                line_item_id=f"{notice_id}_{idx}",
                sku_text_raw=sku,
                quantity=row.get("quantity"),
                unit_price_gbp=row.get("unit_price_gbp"),
                warranty_years=row.get("warranty_years"),
                service_bundle_flags=classify_bundle_flags_stub(sku),
                parse_confidence=float(row.get("parse_confidence", 0.0)),
            )
        )
    return out


if __name__ == "__main__":
    print("Stub only: implement parser against a validated attachment sample.")
