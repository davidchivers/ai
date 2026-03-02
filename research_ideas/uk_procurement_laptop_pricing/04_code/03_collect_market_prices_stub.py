"""Stub: collect market benchmark prices (no live retrieval).

Inputs:
- SKU list with award dates.
- benchmark source priority and date window settings.

Outputs:
- benchmark price records by sku_id and date with source tier metadata.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from typing import Dict, List


@dataclass
class MarketPriceRecord:
    sku_id: str
    date: date
    price_gbp_gross: float | None
    price_gbp_net: float | None
    retailer_or_source: str
    source_tier: str
    warranty_included: str | None
    delivery_included: bool | None


def build_benchmark_request_plan_stub(sku_dates: List[Dict]) -> List[Dict]:
    """Create source requests using hierarchy A/B/C and window rules."""
    # TODO_IMPL: deduplicate SKU-date requests and assign fallback order.
    return []


def retrieve_market_prices_stub(request: Dict) -> List[Dict]:
    """Placeholder for provider-specific retrieval logic."""
    # TODO_IMPL: implement adapters for approved data sources.
    return []


def harmonize_vat_stub(record: Dict, default_vat_rate: float = 0.20) -> Dict:
    """Compute net price when only gross is present and VAT is known/assumed."""
    gross = record.get("price_gbp_gross")
    net = record.get("price_gbp_net")
    if net is None and gross is not None:
        record["price_gbp_net"] = gross / (1.0 + default_vat_rate)
        record["vat_assumed_flag"] = True
    return record


def collect_market_prices_stub(sku_dates: List[Dict]) -> List[MarketPriceRecord]:
    """Top-level market benchmark collection stub."""
    records: list[MarketPriceRecord] = []
    for req in build_benchmark_request_plan_stub(sku_dates):
        raw = retrieve_market_prices_stub(req)
        for row in raw:
            row = harmonize_vat_stub(row)
            records.append(
                MarketPriceRecord(
                    sku_id=str(row.get("sku_id", "")),
                    date=row.get("date"),
                    price_gbp_gross=row.get("price_gbp_gross"),
                    price_gbp_net=row.get("price_gbp_net"),
                    retailer_or_source=str(row.get("retailer_or_source", "unknown")),
                    source_tier=str(row.get("source_tier", "C")),
                    warranty_included=row.get("warranty_included"),
                    delivery_included=row.get("delivery_included"),
                )
            )
    return records


if __name__ == "__main__":
    print("Stub only: configure approved benchmark sources before implementation.")
