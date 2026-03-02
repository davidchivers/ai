"""Stub: match procurement line items to market benchmark SKUs.

Inputs:
- public line items with raw SKU text and extracted attributes.
- market catalog records with structured SKU descriptors.

Outputs:
- matched pairs with confidence scores and comparability flags.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from difflib import SequenceMatcher
from typing import Dict, List


@dataclass
class MatchResult:
    notice_id: str
    line_item_id: str
    public_sku_text: str
    market_sku_id: str | None
    confidence_score: float
    comparable_to_public: bool
    match_notes: str


def normalize_text(text: str) -> str:
    """Normalize SKU strings for matching."""
    text = text.lower()
    text = re.sub(r"[^a-z0-9\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def similarity(a: str, b: str) -> float:
    """Simple fuzzy similarity score."""
    return SequenceMatcher(None, normalize_text(a), normalize_text(b)).ratio()


def compute_confidence_stub(public_row: Dict, market_row: Dict) -> float:
    """Combine text similarity with attribute agreement into a confidence score."""
    base = similarity(str(public_row.get("sku_text_raw", "")), str(market_row.get("sku_descriptor", "")))
    # TODO_IMPL: add structured attribute checks for CPU/RAM/storage/screen/OS/warranty.
    return float(base)


def is_comparable_stub(public_row: Dict, market_row: Dict) -> bool:
    """Check warranty/service comparability for baseline inclusion."""
    # TODO_IMPL: strict comparability checks using parsed warranty and bundle flags.
    return bool(market_row.get("comparable_to_public", False))


def match_skus_stub(public_rows: List[Dict], market_rows: List[Dict]) -> List[MatchResult]:
    """Greedy placeholder matcher.

    Pseudocode:
    1. Candidate generation by coarse filters (brand/model family).
    2. Score candidates via fuzzy + structured checks.
    3. Keep best candidate and record confidence.
    """
    out: list[MatchResult] = []
    for prow in public_rows:
        best = None
        best_score = -1.0
        for mrow in market_rows:
            score = compute_confidence_stub(prow, mrow)
            if score > best_score:
                best_score = score
                best = mrow

        out.append(
            MatchResult(
                notice_id=str(prow.get("notice_id", "")),
                line_item_id=str(prow.get("line_item_id", "")),
                public_sku_text=str(prow.get("sku_text_raw", "")),
                market_sku_id=None if best is None else str(best.get("sku_id", "")),
                confidence_score=max(best_score, 0.0),
                comparable_to_public=False if best is None else is_comparable_stub(prow, best),
                match_notes="stub_match",
            )
        )
    return out


if __name__ == "__main__":
    print("Stub only: implement strict attribute matching before analysis use.")
