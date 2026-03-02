"""Stub: construct analysis panel from notices, line items, and market matches.

Inputs:
- normalized notice table
- parsed line-item table
- SKU match table
- market benchmark table

Outputs:
- analysis-ready panel with price_gap and modeling covariates.
"""

from __future__ import annotations

from typing import Dict, List


def compute_price_gap_stub(public_unit_price_net: float, market_price_net: float) -> float | None:
    """Compute log price gap; return None if inputs invalid."""
    import math

    if public_unit_price_net is None or market_price_net is None:
        return None
    if public_unit_price_net <= 0 or market_price_net <= 0:
        return None
    return math.log(public_unit_price_net) - math.log(market_price_net)


def build_panel_stub(
    notices: List[Dict],
    line_items: List[Dict],
    matches: List[Dict],
    market_prices: List[Dict],
) -> List[Dict]:
    """Placeholder panel builder.

    Pseudocode:
    1. Join line items to notice metadata.
    2. Join line items to SKU matches and benchmark prices by sku_id + date window.
    3. Harmonize VAT/net prices and compute `price_gap`.
    4. Build key flags: framework/direct_award/bundle/comparability confidence tiers.
    5. Output row-level panel for econometrics.
    """
    # TODO_IMPL: replace with actual keyed joins using pandas/polars.
    panel: list[Dict] = []
    _ = (notices, line_items, matches, market_prices)
    return panel


if __name__ == "__main__":
    print("Stub only: implement joins and QA checks before creating final panel.")
