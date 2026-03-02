"""
Price Monitor — checks specific products and sitewide sales daily, emails alerts.

Setup:
  1. pip install requests beautifulsoup4
  2. Create a Gmail App Password (see SETUP.md)
  3. Copy .env.example to .env and fill in your App Password
  4. Run once manually:  python price_monitor.py
  5. Schedule with Task Scheduler (see SETUP.md)

To stop monitoring:
  Reply "STOP" to any alert email, or simply delete/rename the .env file,
  or create a file called PAUSE in this directory.
"""

import json
import os
import re
import smtplib
import sys
import time
import imaplib
import email as email_lib
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path

import requests
from bs4 import BeautifulSoup

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
STATE_FILE = SCRIPT_DIR / "price_state.json"
ENV_FILE = SCRIPT_DIR / ".env"
PAUSE_FILE = SCRIPT_DIR / "PAUSE"
LOG_FILE = SCRIPT_DIR / "monitor.log"

RECIPIENT = "davechivers123@gmail.com"

PRODUCTS = [
    {
        "name": "Tikamoon Kort Teak Small Chest of Drawers",
        "url": "https://www.tikamoon.co.uk/art-kort-solid-teak-small-chest-of-drawers-2330.html",
        "site": "tikamoon",
    },
    {
        "name": "Dreams Lucia Upholstered Bed Frame",
        "url": "https://www.dreams.co.uk/lucia-upholstered-bed-frame/p/261-00172-configurable",
        "site": "dreams",
    },
    {
        "name": "Bugaboo Butterfly 2",
        "url": "https://www.bugaboo.com/gb-en/pushchairs/bugaboo-butterfly-2/",
        "site": "bugaboo",
    },
]

# Collection pages — monitor all products listed on the page for price changes/deals
COLLECTIONS = [
    {
        "name": "Snuz Bedside Cribs",
        "url": "https://www.snuz.co.uk/collections/bedside-cribs",
        "site": "snuz",
        "filter": "snuzpod5",  # only track SnuzPod5 products
    },
]

SITE_PAGES = [
    # Tikamoon
    {"url": "https://www.tikamoon.co.uk", "site": "tikamoon", "label": "Tikamoon Homepage"},
    {"url": "https://www.tikamoon.co.uk/sale", "site": "tikamoon", "label": "Tikamoon /sale"},
    {"url": "https://www.tikamoon.co.uk/offers", "site": "tikamoon", "label": "Tikamoon /offers"},
    {"url": "https://www.tikamoon.co.uk/outlet", "site": "tikamoon", "label": "Tikamoon /outlet"},
    # Dreams
    {"url": "https://www.dreams.co.uk", "site": "dreams", "label": "Dreams Homepage"},
    {"url": "https://www.dreams.co.uk/sale", "site": "dreams", "label": "Dreams /sale"},
    {"url": "https://www.dreams.co.uk/offers", "site": "dreams", "label": "Dreams /offers"},
    {"url": "https://www.dreams.co.uk/outlet", "site": "dreams", "label": "Dreams /outlet"},
    # Bugaboo
    {"url": "https://www.bugaboo.com/gb-en/", "site": "bugaboo", "label": "Bugaboo UK Homepage"},
    {"url": "https://www.bugaboo.com/gb-en/sale/", "site": "bugaboo", "label": "Bugaboo /sale"},
    {"url": "https://www.bugaboo.com/gb-en/outlet/", "site": "bugaboo", "label": "Bugaboo /outlet"},
    # Snuz
    {"url": "https://www.snuz.co.uk", "site": "snuz", "label": "Snuz Homepage"},
    {"url": "https://www.snuz.co.uk/collections/sale", "site": "snuz", "label": "Snuz /sale"},
    {"url": "https://www.snuz.co.uk/pages/offers", "site": "snuz", "label": "Snuz /offers"},
]

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/125.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "en-GB,en;q=0.9",
}

SALE_KEYWORDS = [
    "sale", "discount", "offer", "promo", "promotion", "clearance",
    "black friday", "cyber monday", "bank holiday", "seasonal",
    "% off", "percent off", "half price", "save £", "was £", "now £",
    "voucher", "code", "coupon", "outlet", "deal", "event",
    "spring sale", "summer sale", "winter sale", "autumn sale",
    "easter", "boxing day", "january sale",
]

PROMO_CODE_PATTERN = re.compile(
    r"""(?:code|voucher|coupon|promo)[:\s]+["']?([A-Z0-9]{3,20})["']?""",
    re.IGNORECASE,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def log(msg: str):
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def load_env():
    """Load .env file into os.environ."""
    if not ENV_FILE.exists():
        return
    for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip())


def load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    return {"products": {}, "collections": {}, "sites": {}, "last_run": None}


def save_state(state: dict):
    state["last_run"] = datetime.now().isoformat()
    STATE_FILE.write_text(json.dumps(state, indent=2, ensure_ascii=False), encoding="utf-8")


def fetch(url: str, timeout: int = 20) -> requests.Response | None:
    try:
        r = requests.get(url, headers=HEADERS, timeout=timeout, allow_redirects=True)
        r.raise_for_status()
        return r
    except requests.RequestException as e:
        log(f"  WARN: failed to fetch {url}: {e}")
        return None


def extract_price(soup: BeautifulSoup, site: str) -> dict:
    """Return {"current": float|None, "was": float|None, "badge": str|None}."""
    result = {"current": None, "was": None, "badge": None}
    text = soup.get_text(" ", strip=True)

    if site == "tikamoon":
        # Tikamoon uses <span class="current-price"> or similar
        for sel in [".current-price", ".price", "[itemprop='price']", ".product-price"]:
            el = soup.select_one(sel)
            if el:
                m = re.search(r"£([\d,]+\.?\d*)", el.get_text())
                if m:
                    result["current"] = float(m.group(1).replace(",", ""))
                    break
        # Check for was price
        for sel in [".old-price", ".was-price", ".regular-price", "del", "s"]:
            el = soup.select_one(sel)
            if el:
                m = re.search(r"£([\d,]+\.?\d*)", el.get_text())
                if m:
                    result["was"] = float(m.group(1).replace(",", ""))
                    break

    elif site == "dreams":
        # Dreams uses structured price blocks
        for sel in [".price--current", ".product-price__now", ".price", "[data-price]", "[itemprop='price']"]:
            el = soup.select_one(sel)
            if el:
                price_val = el.get("content") or el.get("data-price") or el.get_text()
                m = re.search(r"£?([\d,]+\.?\d*)", str(price_val))
                if m:
                    result["current"] = float(m.group(1).replace(",", ""))
                    break
        for sel in [".price--was", ".product-price__was", ".was-price", "del", "s"]:
            el = soup.select_one(sel)
            if el:
                m = re.search(r"£([\d,]+\.?\d*)", el.get_text())
                if m:
                    result["was"] = float(m.group(1).replace(",", ""))
                    break

    elif site == "bugaboo":
        # Bugaboo uses structured product pricing
        for sel in [".product-price__sales", ".price--current", ".product-price", "[itemprop='price']", ".price"]:
            el = soup.select_one(sel)
            if el:
                price_val = el.get("content") or el.get_text()
                m = re.search(r"£([\d,]+\.?\d*)", str(price_val))
                if m:
                    result["current"] = float(m.group(1).replace(",", ""))
                    break
        for sel in [".product-price__strike", ".price--was", ".was-price", "del", "s"]:
            el = soup.select_one(sel)
            if el:
                m = re.search(r"£([\d,]+\.?\d*)", el.get_text())
                if m:
                    result["was"] = float(m.group(1).replace(",", ""))
                    break

    elif site == "snuz":
        # Snuz is a Shopify store — uses standard Shopify price markup
        for sel in [".price--sale .price-item--sale", ".price .price-item", ".product__price", "[itemprop='price']", ".price"]:
            el = soup.select_one(sel)
            if el:
                m = re.search(r"£([\d,]+\.?\d*)", el.get_text())
                if m:
                    result["current"] = float(m.group(1).replace(",", ""))
                    break
        for sel in [".price--sale .price-item--regular", ".price s", ".compare-at-price", "del", "s"]:
            el = soup.select_one(sel)
            if el:
                m = re.search(r"£([\d,]+\.?\d*)", el.get_text())
                if m:
                    result["was"] = float(m.group(1).replace(",", ""))
                    break

    # Fallback: regex scan full page for £ prices
    if result["current"] is None:
        prices = re.findall(r"£([\d,]+\.?\d*)", text)
        if prices:
            floats = [float(p.replace(",", "")) for p in prices]
            # Filter out tiny/huge values that are unlikely product prices
            plausible = [p for p in floats if 10 < p < 50000]
            if plausible:
                result["current"] = min(plausible)

    # Discount badge
    badge_el = soup.select_one(".badge, .discount, .sale-badge, .promo-badge, .savings")
    if badge_el:
        result["badge"] = badge_el.get_text(strip=True)

    return result



def detect_sitewide_sales(soup: BeautifulSoup, url: str) -> list[dict]:
    """Scan a page for sale banners, promo codes, event sales."""
    findings = []
    text_lower = soup.get_text(" ", strip=True).lower()

    # Check banner areas
    banner_selectors = [
        "header", ".banner", ".promo-banner", ".hero", ".announcement",
        ".site-banner", ".top-bar", ".notification", ".alert",
        ".sale-banner", ".promotion", ".offers-banner",
        "[class*='banner']", "[class*='promo']", "[class*='sale']",
        "[id*='banner']", "[id*='promo']", "[id*='sale']",
    ]
    banner_texts = set()
    for sel in banner_selectors:
        for el in soup.select(sel):
            t = el.get_text(" ", strip=True)
            if len(t) > 5 and len(t) < 500:
                banner_texts.add(t)

    for bt in banner_texts:
        bt_lower = bt.lower()
        for kw in SALE_KEYWORDS:
            if kw in bt_lower:
                findings.append({
                    "type": "banner",
                    "text": bt[:300],
                    "keyword": kw,
                    "url": url,
                })
                break

    # Promo codes anywhere on page
    full_text = soup.get_text(" ", strip=True)
    for m in PROMO_CODE_PATTERN.finditer(full_text):
        findings.append({
            "type": "promo_code",
            "code": m.group(1),
            "context": full_text[max(0, m.start()-40):m.end()+40].strip(),
            "url": url,
        })

    return findings


def scrape_collection_products(url: str, site: str, name_filter: str = None) -> list[dict]:
    """Scrape a collection/category page and return a list of products with prices."""
    products = []

    if site == "snuz":
        # Snuz is Shopify — use the JSON API (HTML is JS-rendered and empty)
        json_url = url.rstrip("/") + "/products.json"
        r = fetch(json_url)
        if not r:
            return []
        try:
            data = r.json()
        except Exception:
            log(f"  WARN: could not parse JSON from {json_url}")
            return []
        for p in data.get("products", []):
            name = p.get("title", "Unknown")
            handle = p.get("handle", "")
            if name_filter and name_filter.lower() not in name.lower():
                continue
            link = f"https://www.snuz.co.uk/products/{handle}" if handle else url

            # Variants — take the first available variant's price
            variants = p.get("variants", [])
            price = None
            was_price = None
            for v in variants:
                if v.get("available", True):
                    try:
                        price = float(v.get("price", "0"))
                    except (ValueError, TypeError):
                        pass
                    cp = v.get("compare_at_price")
                    if cp:
                        try:
                            was_price = float(cp)
                        except (ValueError, TypeError):
                            pass
                    break
            # Fallback to first variant
            if price is None and variants:
                try:
                    price = float(variants[0].get("price", "0"))
                except (ValueError, TypeError):
                    pass

            if price is not None:
                products.append({
                    "name": name,
                    "url": link,
                    "price": price,
                    "was": was_price,
                })

    return products


def check_page_exists(url: str) -> bool:
    """Return True if page returns 200 (not 404/redirect-to-home)."""
    try:
        r = requests.get(url, headers=HEADERS, timeout=15, allow_redirects=False)
        return r.status_code == 200
    except requests.RequestException:
        return False


# ---------------------------------------------------------------------------
# Email
# ---------------------------------------------------------------------------
def send_email(subject: str, body_html: str):
    sender = os.environ.get("GMAIL_ADDRESS", RECIPIENT)
    password = os.environ.get("GMAIL_APP_PASSWORD", "")
    if not password:
        log("ERROR: GMAIL_APP_PASSWORD not set — cannot send email.")
        return False

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = sender
    msg["To"] = RECIPIENT
    msg["Reply-To"] = sender

    # Plain text fallback
    plain = re.sub(r"<[^>]+>", "", body_html)
    plain = re.sub(r"\n{3,}", "\n\n", plain)
    msg.attach(MIMEText(plain, "plain"))
    msg.attach(MIMEText(body_html, "html"))

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465, timeout=30) as srv:
            srv.login(sender, password)
            srv.sendmail(sender, RECIPIENT, msg.as_string())
        log(f"  Email sent: {subject}")
        return True
    except Exception as e:
        log(f"  ERROR sending email: {e}")
        return False


def check_for_stop_reply():
    """Check inbox for a reply containing STOP to pause monitoring."""
    sender = os.environ.get("GMAIL_ADDRESS", RECIPIENT)
    password = os.environ.get("GMAIL_APP_PASSWORD", "")
    if not password:
        return False
    try:
        with imaplib.IMAP4_SSL("imap.gmail.com") as mail:
            mail.login(sender, password)
            mail.select("inbox")
            # Search for recent emails with STOP in subject or body
            _, data = mail.search(None, '(SUBJECT "STOP" SINCE "' +
                                  (datetime.now().strftime("%d-%b-%Y")) + '")')
            if data[0]:
                for num in data[0].split():
                    _, msg_data = mail.fetch(num, "(RFC822)")
                    msg = email_lib.message_from_bytes(msg_data[0][1])
                    body = ""
                    if msg.is_multipart():
                        for part in msg.walk():
                            if part.get_content_type() == "text/plain":
                                body = part.get_payload(decode=True).decode(errors="replace")
                                break
                    else:
                        body = msg.get_payload(decode=True).decode(errors="replace")
                    if "STOP" in body.upper() or "STOP" in msg.get("Subject", "").upper():
                        log("STOP command received via email — pausing monitor.")
                        PAUSE_FILE.touch()
                        return True
    except Exception as e:
        log(f"  WARN: could not check inbox for STOP: {e}")
    return False


# ---------------------------------------------------------------------------
# Main monitoring logic
# ---------------------------------------------------------------------------
def run_monitor():
    load_env()

    # Check for STOP email before running
    check_for_stop_reply()

    # Check pause file
    if PAUSE_FILE.exists():
        log("PAUSED — delete the PAUSE file or run: python price_monitor.py --resume")
        return

    log("=" * 60)
    log("Price Monitor starting")

    state = load_state()
    product_alerts = []   # price drops / badges on tracked products
    collection_alerts = []  # price drops on collection items
    sitewide_alerts = []  # banners, promo codes, new pages

    # ------------------------------------------------------------------
    # 1. Specific products
    # ------------------------------------------------------------------
    for prod in PRODUCTS:
        log(f"Checking product: {prod['name']}")
        url = prod["url"]

        if url is None:
            log("  WARN: no URL configured, skipping")
            continue

        r = fetch(url)
        if not r:
            continue

        soup = BeautifulSoup(r.text, "html.parser")
        price_info = extract_price(soup, prod["site"])
        prev = state["products"].get(prod["name"], {})
        prev_price = prev.get("price")

        log(f"  Current: £{price_info['current']}  Was: £{price_info['was']}  "
            f"Previous: £{prev_price}  Badge: {price_info['badge']}")

        triggered = False

        # Price drop vs last recorded
        if price_info["current"] is not None and prev_price is not None:
            if price_info["current"] < prev_price:
                drop = prev_price - price_info["current"]
                pct = (drop / prev_price) * 100
                product_alerts.append(
                    f"<tr><td>{prod['name']}</td><td>£{prev_price:.2f}</td>"
                    f"<td><b>£{price_info['current']:.2f}</b></td>"
                    f"<td>-£{drop:.2f} ({pct:.1f}%)</td>"
                    f"<td><a href='{url}'>View</a></td></tr>"
                )
                triggered = True

        # Was/now pricing on the page itself
        if price_info["was"] is not None and price_info["current"] is not None:
            if price_info["current"] < price_info["was"]:
                drop = price_info["was"] - price_info["current"]
                pct = (drop / price_info["was"]) * 100
                product_alerts.append(
                    f"<tr><td>{prod['name']}</td><td>£{price_info['was']:.2f}</td>"
                    f"<td><b>£{price_info['current']:.2f}</b></td>"
                    f"<td>-£{drop:.2f} ({pct:.1f}%)</td>"
                    f"<td><a href='{url}'>View</a></td></tr>"
                )
                triggered = True

        # Discount badge
        if price_info["badge"]:
            prev_badge = prev.get("badge")
            if price_info["badge"] != prev_badge:
                product_alerts.append(
                    f"<tr><td>{prod['name']}</td><td colspan='3'>"
                    f"Badge: <b>{price_info['badge']}</b></td>"
                    f"<td><a href='{url}'>View</a></td></tr>"
                )
                triggered = True

        # Update state
        state["products"][prod["name"]] = {
            "price": price_info["current"],
            "was": price_info["was"],
            "badge": price_info["badge"],
            "url": url,
            "last_checked": datetime.now().isoformat(),
        }

        time.sleep(1)  # polite delay between requests

    # ------------------------------------------------------------------
    # 2. Collection pages (all products on page)
    # ------------------------------------------------------------------
    state.setdefault("collections", {})
    for coll in COLLECTIONS:
        log(f"Checking collection: {coll['name']}")
        products = scrape_collection_products(coll["url"], coll["site"], coll.get("filter"))
        prev_coll = state["collections"].get(coll["name"], {})
        log(f"  Found {len(products)} products")

        for p in products:
            prev_prod = prev_coll.get(p["name"], {})
            prev_price = prev_prod.get("price")

            # Price drop vs last recorded
            if p["price"] is not None and prev_price is not None:
                if p["price"] < prev_price:
                    drop = prev_price - p["price"]
                    pct = (drop / prev_price) * 100
                    link = p["url"] or coll["url"]
                    collection_alerts.append(
                        f"<tr><td>{p['name']}</td><td>£{prev_price:.2f}</td>"
                        f"<td><b>£{p['price']:.2f}</b></td>"
                        f"<td>-£{drop:.2f} ({pct:.1f}%)</td>"
                        f"<td><a href='{link}'>View</a></td></tr>"
                    )

            # Was/now pricing on the page
            if p["was"] is not None and p["price"] is not None and p["price"] < p["was"]:
                prev_was = prev_prod.get("was")
                # Only alert if this is new sale pricing (wasn't discounted before)
                if prev_was is None or prev_was != p["was"]:
                    drop = p["was"] - p["price"]
                    pct = (drop / p["was"]) * 100
                    link = p["url"] or coll["url"]
                    collection_alerts.append(
                        f"<tr><td>{p['name']}</td><td>£{p['was']:.2f}</td>"
                        f"<td><b>£{p['price']:.2f}</b></td>"
                        f"<td>-£{drop:.2f} ({pct:.1f}%)</td>"
                        f"<td><a href='{link}'>View</a></td></tr>"
                    )

            # Update collection state
            state["collections"].setdefault(coll["name"], {})[p["name"]] = {
                "price": p["price"],
                "was": p["was"],
                "url": p["url"],
                "last_checked": datetime.now().isoformat(),
            }

        time.sleep(1)

    # ------------------------------------------------------------------
    # 3. Sitewide deal pages
    # ------------------------------------------------------------------
    for page in SITE_PAGES:
        log(f"Checking site page: {page['label']}")
        prev_status = state["sites"].get(page["url"], {})
        was_live = prev_status.get("exists", False)

        # Check if page exists (for /sale, /offers, /outlet)
        is_subpage = any(p in page["url"] for p in ["/sale", "/offers", "/outlet"])
        if is_subpage:
            exists = check_page_exists(page["url"])
            if exists and not was_live:
                sitewide_alerts.append(
                    f"<li><b>{page['label']}</b> — new page is now live: "
                    f"<a href='{page['url']}'>{page['url']}</a></li>"
                )
            state["sites"].setdefault(page["url"], {})["exists"] = exists
            if not exists:
                log(f"  Page does not exist (404)")
                state["sites"][page["url"]]["last_checked"] = datetime.now().isoformat()
                continue

        r = fetch(page["url"])
        if not r:
            state["sites"].setdefault(page["url"], {})["last_checked"] = datetime.now().isoformat()
            continue

        soup = BeautifulSoup(r.text, "html.parser")
        findings = detect_sitewide_sales(soup, page["url"])

        # Compare to previous findings
        prev_findings_keys = set(prev_status.get("finding_keys", []))
        new_findings = []
        current_keys = []

        for f in findings:
            key = f"{f['type']}:{f.get('code', '')}:{f.get('keyword', '')}:{f.get('text', '')[:80]}"
            current_keys.append(key)
            if key not in prev_findings_keys:
                new_findings.append(f)

        for f in new_findings:
            if f["type"] == "promo_code":
                sitewide_alerts.append(
                    f"<li><b>{page['label']}</b> — Promo code: "
                    f"<code>{f['code']}</code></li>"
                )
            else:
                sitewide_alerts.append(
                    f"<li><b>{page['label']}</b> — "
                    f"{f['text'][:150]}"
                    f" <a href='{page['url']}'>View</a></li>"
                )

        state["sites"].setdefault(page["url"], {}).update({
            "exists": True,
            "finding_keys": current_keys,
            "last_checked": datetime.now().isoformat(),
        })

        time.sleep(1)

    # ------------------------------------------------------------------
    # 4. Send alert email if anything found
    # ------------------------------------------------------------------
    all_alerts = product_alerts + collection_alerts + sitewide_alerts
    if all_alerts:
        total = len(all_alerts)
        log(f"Sending alert email with {total} finding(s)")

        table_style = (
            'style="border-collapse: collapse; width: 100%; font-size: 14px;" '
            'cellpadding="6"'
        )
        th_style = 'style="text-align: left; border-bottom: 2px solid #333; padding: 6px 8px;"'
        sections = []

        # -- Product price alerts --
        if product_alerts:
            sections.append(
                f"<h3>Your Products</h3>"
                f"<table {table_style}>"
                f"<tr><th {th_style}>Product</th><th {th_style}>Was</th>"
                f"<th {th_style}>Now</th><th {th_style}>Saving</th>"
                f"<th {th_style}></th></tr>"
                + "".join(product_alerts)
                + "</table>"
            )

        # -- Collection price alerts --
        if collection_alerts:
            sections.append(
                f"<h3>Snuz SnuzPod5 Cribs</h3>"
                f"<table {table_style}>"
                f"<tr><th {th_style}>Product</th><th {th_style}>Was</th>"
                f"<th {th_style}>Now</th><th {th_style}>Saving</th>"
                f"<th {th_style}></th></tr>"
                + "".join(collection_alerts)
                + "</table>"
            )

        # -- Sitewide sales --
        if sitewide_alerts:
            # Deduplicate very similar entries
            seen = set()
            unique = []
            for item in sitewide_alerts:
                short = item[:100]
                if short not in seen:
                    seen.add(short)
                    unique.append(item)
            sections.append(
                "<h3>Sitewide Sales & Promos</h3><ul>"
                + "".join(unique)
                + "</ul>"
            )

        body = (
            '<html><body style="font-family: Arial, sans-serif; '
            'max-width: 700px; margin: auto; color: #222;">'
            f'<h2>Price Monitor — {datetime.now().strftime("%d %b %Y")}</h2>'
            + "<hr>".join(sections)
            + '<hr><p style="color: #999; font-size: 11px;">'
            "Reply <b>STOP</b> to pause these alerts.</p>"
            "</body></html>"
        )
        send_email(
            f"Price Alert: {total} deal(s) found — {datetime.now().strftime('%d %b')}",
            body,
        )
    else:
        log("No new deals found today.")

    save_state(state)
    log("Monitor complete.\n")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    if "--resume" in sys.argv:
        if PAUSE_FILE.exists():
            PAUSE_FILE.unlink()
            print("Resumed — PAUSE file removed.")
        else:
            print("Not paused — nothing to do.")
        sys.exit(0)

    if "--pause" in sys.argv:
        PAUSE_FILE.touch()
        print("Paused — monitoring will skip until resumed.")
        sys.exit(0)

    if "--status" in sys.argv:
        state = load_state()
        print(f"Last run: {state.get('last_run', 'never')}")
        print(f"Paused: {PAUSE_FILE.exists()}")
        print(f"Products tracked: {len(state.get('products', {}))}")
        for name, info in state.get("products", {}).items():
            print(f"  {name}: £{info.get('price')} (checked {info.get('last_checked', '?')})")
        sys.exit(0)

    run_monitor()
