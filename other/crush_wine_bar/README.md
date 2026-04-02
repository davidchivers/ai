# Crush wine bar prototype

This folder contains a practical example redesign for **Crush**, treated as a hybrid business:

- a Durham wine bar
- a local wine shop
- a curated online Shopify storefront for selected take-home products

The branch is designed to show two things together:

1. a customer-facing website direction
2. a lightweight operating system for catalogue, pricing, stock, media, and publishing

## What is here

`prototype/`

- static multi-page storefront prototype
- homepage, shop, product detail, visit, and gather/gift pages
- renders from generated `public-products.json`

`ops/data/`

- separated source tables for:
  - catalogue
  - pricing
  - stock
  - media
  - publishing
  - stock movement log

`ops/scripts/build_public_catalog.py`

- joins the source tables
- validates publishing-state rules
- generates the public catalogue JSON used by the prototype
- generates a Shopify publish preview payload

`ops/architecture.md`

- recommended version-1 architecture
- schema design
- platform comparison
- roadmap
- implementation approach
- owner question bank

## Verified live-site observations used here

Checked from `https://crushwines.co/` on **2026-04-02**:

- storefront is Shopify-powered
- site states: `Delivery available every Monday & Tuesday (within 10 miles)`
- site positions Crush as `wine bar & shop`
- listed address: `76 North Road, Durham, DH1 4SQ`
- listed opening pattern: `Wednesday - Saturday`
- home copy says `80+ wines` are available by the glass
- home copy says the online range is a `bespoke range` for home, with collection and delivery available

These observations support the core design assumption that the **full bar range and the online range should not be treated as the same thing**.

## Recommended way to use this example

1. Regenerate the public product feed:

```powershell
python other/crush_wine_bar/ops/scripts/build_public_catalog.py
```

2. Preview the prototype locally:

```powershell
python -m http.server 8000 -d other/crush_wine_bar/prototype
```

3. Open:

`http://localhost:8000`

## Why this shape

The point is not to overbuild a new platform.

The point is to show a realistic version 1 where:

- Shopify remains the storefront
- product publishing is controlled
- stock and catalogue are separated
- collection and local delivery are explicit
- the site better reflects Crush as a wine destination, not just a generic ecommerce store
