from __future__ import annotations

import csv
import json
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_ROOT / "ops" / "data"
PUBLIC_OUTPUT = PROJECT_ROOT / "prototype" / "data" / "public-products.json"
SHOPIFY_OUTPUT = DATA_DIR / "shopify_publish_preview.json"
ADMIN_OUTPUT = PROJECT_ROOT / "prototype" / "data" / "admin-data.json"


STATE_RULES = {
    "internal_only": {"visible": False, "purchasable": False, "collection": False, "delivery": False},
    "bar_only": {"visible": False, "purchasable": False, "collection": False, "delivery": False},
    "info_only": {"visible": True, "purchasable": False, "collection": False, "delivery": False},
    "collection_only": {"visible": True, "purchasable": True, "collection": True, "delivery": False},
    "delivery_only": {"visible": True, "purchasable": True, "collection": False, "delivery": True},
    "collection_and_delivery": {"visible": True, "purchasable": True, "collection": True, "delivery": True},
}


def read_table(name: str) -> dict[str, dict[str, str]]:
    path = DATA_DIR / f"{name}.csv"
    with path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))
    return {row["internal_product_id"]: row for row in rows}


def read_rows(name: str) -> list[dict[str, str]]:
    path = DATA_DIR / f"{name}.csv"
    with path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def as_bool(value: str) -> bool:
    return str(value).strip().lower() in {"1", "true", "yes", "y"}


def as_int(value: str) -> int:
    if value == "":
        return 0
    return int(float(value))


def as_float(value: str) -> float | None:
    if value == "":
        return None
    return round(float(value), 2)


def title_state(state: str) -> str:
    labels = {
        "internal_only": "Internal only",
        "bar_only": "In bar only",
        "info_only": "Visible online, not purchasable",
        "collection_only": "Collection only",
        "delivery_only": "Local delivery only",
        "collection_and_delivery": "Collection and local delivery",
    }
    return labels[state]


def stock_message(stock_row: dict[str, str], can_purchase: bool) -> str:
    status = stock_row["stock_status"]
    bottles = as_int(stock_row["current_bottle_stock"])
    if not can_purchase and status == "bar_only":
        return "Available in the bar only"
    if not can_purchase:
        return "Shown online for discovery only"
    if status == "low_stock" and bottles > 0:
        return f"Low stock: {bottles} bottle(s) left"
    if bottles <= 0:
        return "Out of stock"
    return "In stock for the selected fulfilment options"


def region_label(catalogue_row: dict[str, str]) -> str:
    parts = [catalogue_row["sub_region_appellation"], catalogue_row["region"], catalogue_row["country"]]
    return ", ".join(part for part in parts if part)


def validate_state(publishing_row: dict[str, str], warnings: list[str]) -> None:
    state = publishing_row["publishing_state"]
    expected = STATE_RULES.get(state)
    if not expected:
        warnings.append(f"Unknown publishing state for {publishing_row['internal_product_id']}: {state}")
        return

    checks = {
        "visible": as_bool(publishing_row["visible_online"]),
        "purchasable": as_bool(publishing_row["purchasable_online"]),
        "collection": as_bool(publishing_row["collection_available"]),
        "delivery": as_bool(publishing_row["delivery_available"]),
    }
    for field, expected_value in expected.items():
        if checks[field] != expected_value:
            warnings.append(
                f"Publishing mismatch for {publishing_row['internal_product_id']}: {field}="
                f"{checks[field]} but {state} expects {expected_value}"
            )


def build_records() -> tuple[list[dict[str, object]], list[dict[str, object]], list[str]]:
    catalogue = read_table("catalogue")
    pricing = read_table("pricing")
    stock = read_table("stock")
    media = read_table("media")
    publishing = read_table("publishing")

    warnings: list[str] = []
    public_records: list[dict[str, object]] = []
    shopify_preview: list[dict[str, object]] = []

    for product_id, pub in publishing.items():
        validate_state(pub, warnings)
        if product_id not in catalogue or product_id not in pricing or product_id not in stock or product_id not in media:
            warnings.append(f"Missing linked row for {product_id}")
            continue

        cat = catalogue[product_id]
        price = pricing[product_id]
        stock_row = stock[product_id]
        media_row = media[product_id]

        visible_online = as_bool(pub["visible_online"])
        purchasable_online = as_bool(pub["purchasable_online"])
        publish_online_eligibility = as_bool(stock_row["publish_online_eligibility"])
        current_stock = as_int(stock_row["current_bottle_stock"])
        can_purchase = purchasable_online and publish_online_eligibility and current_stock > 0

        merged = {
            "id": product_id,
            "sku": cat["sku"],
            "handle": pub["slug"],
            "title": pub["website_title"],
            "wineName": cat["wine_name"],
            "producer": cat["producer"],
            "cuvee": cat["cuvee"],
            "vintage": cat["vintage"],
            "country": cat["country"],
            "region": cat["region"],
            "regionLabel": region_label(cat),
            "grapes": cat["grapes"],
            "styleType": cat["wine_style_type"],
            "stillOrSparkling": cat["still_or_sparkling"],
            "bottleSize": cat["bottle_size"],
            "abv": cat["abv"],
            "supplier": cat["supplier"],
            "category": pub["public_category"],
            "shortDescription": pub["public_short_description"],
            "tastingNotes": pub["public_tasting_notes"],
            "danielNote": pub["public_daniel_recommends_note"],
            "privateStaffNote": pub["private_staff_note"],
            "featured": as_bool(pub["featured_flag"]),
            "visibleOnline": visible_online,
            "purchasableOnline": can_purchase,
            "collectionAvailable": can_purchase and as_bool(pub["collection_available"]),
            "deliveryAvailable": can_purchase and as_bool(pub["delivery_available"]),
            "publishingState": pub["publishing_state"],
            "publishingLabel": title_state(pub["publishing_state"]),
            "currentBottleStock": current_stock,
            "stockStatus": stock_row["stock_status"],
            "stockMessage": stock_message(stock_row, can_purchase),
            "activeInBar": as_bool(stock_row["active_in_bar"]),
            "availableByGlass": as_bool(stock_row["available_by_glass"]),
            "openBottleInService": as_bool(stock_row["open_bottle_in_service"]),
            "bottleRetailPrice": as_float(price["bottle_retail_price"]),
            "takeoutPrice": as_float(price["takeout_price"]) or as_float(price["bottle_retail_price"]),
            "byTheGlassPrice": as_float(price["by_the_glass_price"]),
            "carafePrice": as_float(price["carafe_price"]),
            "promotionalPrice": as_float(price["promotional_price"]),
            "mainImageUrl": media_row["main_image_url"],
            "altText": media_row["alt_text"],
            "seoTitle": pub["seo_title"],
            "seoDescription": pub["seo_description"],
            "sortOrder": as_int(pub["sort_order"]),
        }

        if visible_online:
            public_records.append(merged)

        if can_purchase:
            shopify_preview.append(
                {
                    "handle": pub["slug"],
                    "title": pub["website_title"],
                    "status": "active",
                    "product_type": pub["public_category"],
                    "price": merged["takeoutPrice"],
                    "compare_at_price": merged["bottleRetailPrice"],
                    "inventory_quantity": current_stock,
                    "fulfilment": {
                        "collection": merged["collectionAvailable"],
                        "local_delivery": merged["deliveryAvailable"],
                    },
                    "metafields": {
                        "custom.public_tasting_notes": pub["public_tasting_notes"],
                        "custom.daniel_recommends": pub["public_daniel_recommends_note"],
                        "custom.available_by_glass": merged["availableByGlass"],
                        "custom.local_delivery_only": merged["deliveryAvailable"] and not merged["collectionAvailable"],
                    },
                    "tags": [
                        f"country:{cat['country']}",
                        f"region:{cat['region']}",
                        f"state:{pub['publishing_state']}",
                        f"style:{cat['wine_style_type']}",
                    ],
                }
            )

    public_records.sort(key=lambda record: int(record["sortOrder"]))
    shopify_preview.sort(key=lambda record: record["handle"])
    return public_records, shopify_preview, warnings


def main() -> None:
    public_records, shopify_preview, warnings = build_records()
    admin_snapshot = {
        "overview": {
            "public_products": len(public_records),
            "shopify_publish_ready": len(shopify_preview),
            "bar_active_wines": sum(1 for row in read_rows("stock") if as_bool(row["active_in_bar"])),
            "by_glass_wines": sum(1 for row in read_rows("stock") if as_bool(row["available_by_glass"])),
        },
        "tables": {
            "catalogue": read_rows("catalogue"),
            "pricing": read_rows("pricing"),
            "stock": read_rows("stock"),
            "media": read_rows("media"),
            "publishing": read_rows("publishing"),
            "stock_movements": read_rows("stock_movements"),
        },
    }
    PUBLIC_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    PUBLIC_OUTPUT.write_text(json.dumps(public_records, indent=2), encoding="utf-8")
    SHOPIFY_OUTPUT.write_text(json.dumps(shopify_preview, indent=2), encoding="utf-8")
    ADMIN_OUTPUT.write_text(json.dumps(admin_snapshot, indent=2), encoding="utf-8")

    print(f"Wrote {len(public_records)} public product records to {PUBLIC_OUTPUT}")
    print(f"Wrote {len(shopify_preview)} Shopify preview records to {SHOPIFY_OUTPUT}")
    print(f"Wrote admin snapshot to {ADMIN_OUTPUT}")
    if warnings:
        print("Warnings:")
        for warning in warnings:
            print(f" - {warning}")


if __name__ == "__main__":
    main()
