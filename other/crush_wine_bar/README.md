# Crush demo

## What this is

This is a **working example** of how Crush could run its website and wine admin system more clearly.

It is built around one simple idea:

**Staff should update wines in a simple admin table, not in website code.**

The website should then show the right version of each wine:

- internal only
- visible online but not purchasable
- collection only
- local delivery only
- collection and local delivery

## If you are not technical, start here

There are **two parts** to this demo:

### 1. The customer-facing website

This is what customers would see.

Pages included:

- `index.html` = homepage
- `shop.html` = browse/shop page
- `product.html` = wine detail page
- `visit.html` = wine bar visit page
- `gather.html` = gift, events, private hire
- `admin.html` = simple explanation of how the system works

### 2. The admin/data side

This is what sits behind the website.

It is split into separate tables so staff do not have to cram everything into one giant spreadsheet row:

- `catalogue.csv` = what the wine is
- `pricing.csv` = selling and cost information
- `stock.csv` = bottle stock and bar status
- `media.csv` = images
- `publishing.csv` = what the website should show
- `stock_movements.csv` = optional stock log

## The main point

This demo is **not saying** the owner should edit HTML every day.

Normal workflow should be:

1. update the wine in Airtable or a spreadsheet-like admin
2. choose whether it is internal, visible, collection-only, delivery-only, or both
3. update stock and notes
4. sync to Shopify / website

HTML is mainly for the **design of the site**, not the everyday running of the product list.

## What to click first

If you want the easiest overview, open:

- `prototype/admin.html`

That page explains:

- what gets edited
- what should not be edited
- the day-to-day workflow
- the actual sample tables behind the site

## How to preview the website locally

If you want to open the actual demo in a browser, run:

```powershell
python -m http.server 8000 -d other/crush_wine_bar/prototype
```

Then open:

```text
http://localhost:8000
```

For the admin explanation page:

```text
http://localhost:8000/admin.html
```

## How the files work together

### Step 1. Product data is stored in separate tables

The source files are in:

- `other/crush_wine_bar/ops/data/`

### Step 2. A small script combines them

This file:

- `other/crush_wine_bar/ops/scripts/build_public_catalog.py`

reads the separate tables and creates:

- `prototype/data/public-products.json`
- `prototype/data/admin-data.json`
- `ops/data/shopify_publish_preview.json`

### Step 3. The website reads the generated output

The pages in `prototype/` use those generated JSON files to display the website and the admin explanation page.

## If this became a real version 1

The intended live setup would be:

- Shopify stays as the storefront
- Airtable becomes the simple admin system
- a sync process pushes approved wines into Shopify
- the theme is improved to match the Crush identity better

That means the owner or manager would mostly work in Airtable, not in code.

## Most important business rule

Crush is **not** a normal bottle shop.

The full bar range and the online range should be treated as different things.

That is why the publishing layer exists.

## Useful files

- `ops/architecture.md` = recommended architecture and roadmap
- `ops/owner_question_bank.md` = questions that still need owner decisions
- `prototype/admin.html` = easiest non-technical walkthrough

## Current status of this branch

This branch is an example/prototype.

It shows:

- a redesigned website direction
- a practical admin model
- a simple publishing workflow

It does **not** yet connect to a real Shopify store or Airtable base.
