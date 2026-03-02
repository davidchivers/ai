# schema market prices

## benchmark hierarchy
- `A`: manufacturer list price at date `t` (preferred)
- `B`: business/enterprise channel price at date `t`
- `C`: major UK retail public price at date `t` (fallback)

Always store which source tier generated the final benchmark.

## table: `market_prices`
- `sku_id` (string)
- `sku_descriptor` (string)
- `date` (date)
- `price_gbp_gross` (float, nullable)
- `price_gbp_net` (float, nullable)
- `vat_rate_used` (float, nullable)
- `retailer_or_source` (string)
- `source_tier` (enum: `A`, `B`, `C`)
- `warranty_included` (string/years, nullable)
- `delivery_included` (bool, nullable)
- `stock_status` (string, nullable)
- `notes` (string, nullable)

## comparability field
- `comparable_to_public` (bool): set to `1` only if warranty/service content is judged aligned to public line item.

## matching window metadata
- `days_from_award` (int)
- `within_primary_window` (bool; primary window e.g. +/- 14 days)

## TODO
- TODO_DATA: decide archival source capture method and licensing constraints.
- TODO_RULES: pre-register tie-break rules when multiple prices exist on same date.
