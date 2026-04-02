# Crush architecture

## 1. Recommended version-1 architecture

### Summary

Use:

- **Shopify** as the live storefront and checkout
- **Airtable** as the master operating layer for wines
- a **small sync script / automation layer** to publish selected records into Shopify
- a **duplicate Shopify theme** to implement the redesigned information architecture safely before switching live

### Why this fits Crush

Crush is not a standard national bottle shop. The live site and copy indicate a hybrid model:

- in-person wine bar activity matters
- the online range is curated and narrower than the full in-bar range
- collection and local delivery are core fulfilment modes
- events, gift vouchers, hampers, and private hire are already commercially important

So the right model is:

**Structured internal catalogue -> controlled publishing layer -> Shopify storefront**

not:

**every stocked bottle automatically becomes a Shopify product**

### Version-1 stack

| Layer | Recommended tool | Role |
|---|---|---|
| Storefront | Shopify | Theme, cart, checkout, simple content pages, vouchers, tickets |
| Master wine admin | Airtable | Linked tables for catalogue, pricing, stock, media, publishing |
| Sync layer | Small script or no-code automation | Push selected products/metafields into Shopify |
| Media source | Shopify media library plus controlled filenames | Product imagery and approved assets |
| Internal stock notes | Airtable stock + stock movement log | Lightweight operational control |

### Version-1 operating principle

One wine can be:

- in stock internally
- active in the bar
- available by the glass
- visible online
- not purchasable online
- collection only
- local-delivery eligible

Those states must be controlled independently.

## 2. Proposed schema for the core admin tables

The version-1 schema in `ops/data/` follows the structure below.

### Catalogue

Purpose: what the wine is.

Core fields:

- `internal_product_id`
- `sku`
- `wine_name`
- `producer`
- `cuvee`
- `vintage`
- `country`
- `region`
- `sub_region_appellation`
- `grapes`
- `wine_style_type`
- `still_or_sparkling`
- `bottle_size`
- `abv`
- `supplier`
- `supplier_sku`
- `internal_classification_tags`
- `producer_location_text`
- `latitude`
- `longitude`

### Pricing

Purpose: what it costs and sells for.

Core fields:

- `internal_product_id`
- `cost_price`
- `bottle_retail_price`
- `takeout_price`
- `by_the_glass_price`
- `carafe_price`
- `margin_percent`
- `vat_rate`
- `promotional_price`

### Stock

Purpose: current operational state.

Core fields:

- `internal_product_id`
- `current_bottle_stock`
- `units_on_order`
- `reorder_threshold`
- `stock_status`
- `active_in_bar`
- `available_by_glass`
- `open_bottle_in_service`
- `publish_online_eligibility`
- `stock_admin_notes`

### Media

Purpose: image and asset control.

Core fields:

- `internal_product_id`
- `main_image_filename`
- `main_image_url`
- `secondary_images`
- `alt_text`
- `label_image_status`
- `media_approval_status`

### Publishing

Purpose: what the website shows.

Core fields:

- `internal_product_id`
- `website_title`
- `public_short_description`
- `public_tasting_notes`
- `public_category`
- `featured_flag`
- `collection_available`
- `delivery_available`
- `visible_online`
- `purchasable_online`
- `sort_order`
- `slug`
- `seo_title`
- `seo_description`
- `publishing_state`
- `public_daniel_recommends_note`
- `private_staff_note`

### Optional stock movement log

Purpose: simple traceability without full ERP complexity.

Core fields:

- `occurred_at`
- `internal_product_id`
- `movement_type`
- `quantity_change`
- `source_reason`
- `note`

## 3. Publishing model

Recommended explicit publishing states:

| State | Visible online | Purchasable | Collection | Local delivery | Use case |
|---|---|---|---|---|---|
| `internal_only` | No | No | No | No | Internal record only |
| `bar_only` | No | No | No | No | In bar, not shown publicly |
| `info_only` | Yes | No | No | No | Storytelling / discovery listing |
| `collection_only` | Yes | Yes | Yes | No | Pickup-only bottle |
| `delivery_only` | Yes | Yes | No | Yes | Local-route bottle |
| `collection_and_delivery` | Yes | Yes | Yes | Yes | Flexible take-home product |

### Important rule

`publishing_state` should be a deliberate editor choice, not only a derived stock outcome.

Stock can block purchase, but it should not silently decide brand or merchandising policy.

## 4. Stock model for a hybrid wine bar + shop

### Version-1 recommendation

Track stock at **bottle level** only.

Do not attempt granular glass-level ecommerce depletion in version 1.

### Operational logic

- `current_bottle_stock` is the core quantity
- `active_in_bar` controls whether staff are currently pouring or listing it
- `available_by_glass` controls whether the bar can surface it as a by-the-glass wine
- `open_bottle_in_service` is a lightweight operational flag, not a separate inventory bucket
- `publish_online_eligibility` is a manual commercial decision, not the same as “stock exists”

### Recommended bottle-opening rule

Use the simple approach:

- when a bottle is opened for glass service, reduce bottle stock by `1`
- record a stock movement with `movement_type = opened_for_glass`
- optionally mark `open_bottle_in_service = yes`

That is usually easier to maintain than parallel open-bottle accounting.

## 5. Website information architecture and page structure

### Primary navigation

- Home
- Shop
- Visit
- Gather & gift

### Homepage

Purpose:

- explain Crush clearly as wine bar + shop
- emphasise curation and discovery
- point users quickly to shopping or visiting

Recommended sections:

- hero with dual identity
- featured online bottles
- browse by style/category
- collection and local delivery explainer
- visit highlight
- events/private hire/gifting highlight

### Shop page

Purpose:

- browsing and filtering for the curated take-home range

Recommended filters:

- style
- country
- fulfilment mode
- active in bar
- by-the-glass informational flag

### Product page

Purpose:

- present wine information clearly
- show public notes and Daniel’s public recommendation
- make fulfilment and availability unmistakable

### Visit page

Purpose:

- give the venue equal weight with ecommerce
- present address, hours, atmosphere, and by-the-glass identity

### Gather & gift page

Purpose:

- protect tickets, gift vouchers, hampers, curated boxes, and private hire as strong commercial routes

## 6. Best version-1 platform/admin setup

### Option comparison

| Option | Strengths | Weaknesses | Verdict |
|---|---|---|---|
| Excel workbook | Familiar, offline, cheap | Weak multi-user workflow, awkward media handling, weak relational control | Too fragile for the publishing model |
| Google Sheets | Familiar, collaborative, cheap | Better than Excel, but linked-table discipline is weak and validation is limited | Acceptable fallback, not ideal |
| Airtable | Strong linked tables, views, attachments, forms, filtered workflows | Subscription cost and some learning curve | **Best version-1 choice** |
| Lightweight database/admin panel | Strong long-term base | Too much setup and maintenance for v1 | Better for v2/v3 if scale grows |
| Hybrid | Shopify + Airtable + light sync | Slightly more moving parts | **Recommended** |

### Recommendation

For a small owner-managed business that values simplicity but needs real structure:

**Use Airtable as the master admin layer and Shopify as the storefront.**

Why Airtable wins for v1:

- it handles separated tables without making staff build relational logic from scratch
- image/asset linkage is easier than in Sheets
- filtered views make “publishable today”, “low stock”, and “needs image” practical
- it is much easier to evolve toward automation than Excel or plain Sheets

### Fallback if Airtable is a non-starter

Use **Google Sheets with strict tab separation** and data validation, then migrate later.

## 7. Roadmap

### Version 2

- Shopify metafields and collection templates expanded
- postcode/radius-aware local delivery checks
- low-stock alerts
- richer by-the-glass highlights on site
- POS import or stock reconciliation
- supplier order tracking
- basic AI-assisted drafting for tasting notes and SEO copy

### Version 3

- tighter POS sync
- email parsing for supplier confirmations and invoices
- reorder suggestions
- customer segmentation and email automation
- richer map/editorial discovery features
- deeper reporting on margin, stock turn, and merchandising performance

## 8. Suggested implementation approach without breaking current operations

### Phase 1: audit and duplicate

- export current Shopify products, collections, pages, and tags
- audit how vouchers, tickets, private hire, boxes, and wines currently differ
- create a **duplicate Shopify theme** for redesign work

### Phase 2: stand up the admin model

- create the Airtable base with the five core tables
- import current online wine products first
- add a controlled `publishing_state` field
- agree one product ID / SKU convention

### Phase 3: improve Shopify data shape

- add metafields for public tasting notes, Daniel recommends note, fulfilment labels, and by-the-glass flag
- keep vouchers/tickets/private hire as simpler non-wine products if that reduces friction

### Phase 4: build the new website structure

- homepage repositioning
- improved shop filters
- clearer product templates
- new visit page
- new gather/gift page

### Phase 5: controlled migration

- move a small curated wine set first
- check fulfilment messaging, stock behaviour, and collection flow
- only then expand coverage

### Operational safety rule

Do not replace the live workflow in one move.

Start with:

- curated online wine subset
- stable fulfilment rules
- lightweight stock logging
- manual or semi-manual sync

Then automate only after staff can maintain version 1 consistently.

## Related file

See `owner_question_bank.md` for the structured question list to resolve before live implementation.
