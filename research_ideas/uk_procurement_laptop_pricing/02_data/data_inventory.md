# data inventory

Goal: construct an analysis panel with observation unit `(sku i, contract j, award date t, buyer b)`.

## procurement-side collection plan (UK)
1. Query Contracts Finder award notices in laptop-relevant CPV categories (including broad IT hardware classes such as `30200000` family where applicable) and keywords: `laptop`, `notebook`, `RM6098`, `technology products`.
2. Extend to Find a Tender records for high-value/regulated notices where available.
3. For each notice, capture and store:
   - buyer name and type,
   - award/start/end dates,
   - total value and estimation flags,
   - procurement route/procedure text,
   - framework identifiers and lot references,
   - bidder count if published,
   - all attachment URLs and downloaded files.
4. Parse attachments to recover line items with SKU text, quantity, and unit price where possible.

## key practical constraint
Many notices report only total contract values. Per-unit price extraction usually requires attachment parsing (pricing schedules, spreadsheets, or PDFs).

## market-side collection plan
Collect benchmark prices by SKU and date from prioritized sources:
- A: manufacturer list price archives,
- B: business/enterprise channel prices,
- C: major UK retail public prices as fallback.
Record source hierarchy and comparability decisions for every matched SKU-date observation.

## explicit TODOs
- TODO_DATA: final CPV code list and keyword strategy.
- TODO_DATA: define attachment storage and naming convention.
- TODO_DATA: identify feasible archival market-price providers.
- TODO_QA: build parse-audit sample to estimate extraction error rates.
