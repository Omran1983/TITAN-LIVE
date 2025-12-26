# File: F:\AION-ZERO\agents\import_goli_products.py
#
# Scrapes https://goli.com/pages/order and pushes products to Supabase (aogrl_ds_products).
# Requires:
#   - SUPABASE_URL
#   - SUPABASE_SERVICE_ROLE_KEY
#
# NOTE: HTML structure may change; adjust CSS selectors if needed.

import os
import re
import json
import sys
from typing import List, Dict, Any

import requests
from bs4 import BeautifulSoup


SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("ERROR: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set in environment.", file=sys.stderr)
    sys.exit(1)


GOLI_ORDER_URL = "https://goli.com/pages/order"
SUPPLIER_NAME = "Goli"


def fetch_page(url: str) -> str:
    headers = {
        "User-Agent": "Mozilla/5.0 (compatible; AOGRL-DS-Bot/1.0; +https://aogrl.com)"
    }
    resp = requests.get(url, headers=headers, timeout=20)
    resp.raise_for_status()
    return resp.text


def parse_price_to_cents(price_str: str) -> int:
    """
    Convert price string like "$19.99" or "US$19.99" to integer cents (1999).
    Returns None if it can't parse.
    """
    if not price_str:
        return None

    # Keep digits and dot
    cleaned = re.sub(r"[^0-9.]", "", price_str)
    if not cleaned:
        return None

    try:
        value = float(cleaned)
        return int(round(value * 100))
    except ValueError:
        return None


def extract_from_json_ld(soup: BeautifulSoup) -> List[Dict[str, Any]]:
    """Try to get product info from JSON-LD schema if present."""
    products = []
    scripts = soup.find_all("script", type="application/ld+json")
    for s in scripts:
        try:
            data = json.loads(s.string or "")
        except Exception:
            continue

        # Could be a list or single object
        if isinstance(data, list):
            candidates = data
        else:
            candidates = [data]

        for item in candidates:
            if not isinstance(item, dict):
                continue
            if item.get("@type") not in ("Product",):
                continue

            name = item.get("name")
            description = item.get("description", "")
            image = None
            if isinstance(item.get("image"), list):
                image = item["image"][0]
            elif isinstance(item.get("image"), str):
                image = item["image"]

            offers = item.get("offers") or {}
            if isinstance(offers, list):
                offers = offers[0] if offers else {}

            price_str = offers.get("price") or ""
            currency = offers.get("priceCurrency") or "USD"

            # price in JSON-LD is often numeric string without currency symbol
            price_cents = None
            if price_str:
                try:
                    price_cents = int(round(float(price_str) * 100))
                except ValueError:
                    price_cents = parse_price_to_cents(price_str)

            sku = item.get("sku") or item.get("productID") or name

            products.append({
                "supplier": SUPPLIER_NAME,
                "supplier_product_id": sku,
                "name": name,
                "description": description,
                "price_cents": price_cents,
                "currency": currency or "USD",
                "image_url": image,
                "source_url": GOLI_ORDER_URL,
                "extra": {
                    "json_ld": item
                }
            })

    return products


def extract_from_dom(soup: BeautifulSoup) -> List[Dict[str, Any]]:
    """
    Fallback: scrape from visible DOM.
    NOTE: You may need to tweak CSS selectors depending on Goli's markup.
    """
    products = []

    # Example: look for product cards by common classes
    product_selectors = [
        ".product-card",
        ".product-item",
        ".ProductItem",
        ".product",  # generic
    ]

    cards = []
    for sel in product_selectors:
        cards = soup.select(sel)
        if cards:
            break

    for card in cards:
        # Product name
        name_el = card.select_one(".product-title, .ProductItem__Title, .product-name, .title")
        name = name_el.get_text(strip=True) if name_el else None
        if not name:
            continue

        # Price text
        price_el = card.select_one(
            ".product-price, .Price, .ProductItem__Price, .price, [data-price]"
        )
        price_raw = price_el.get_text(strip=True) if price_el else ""
        price_cents = parse_price_to_cents(price_raw)

        # Image
        img_el = card.select_one("img")
        image_url = None
        if img_el:
            # Prefer data-src or data-original, else src
            if img_el.has_attr("data-src"):
                image_url = img_el["data-src"]
            elif img_el.has_attr("data-original"):
                image_url = img_el["data-original"]
            elif img_el.has_attr("src"):
                image_url = img_el["src"]

        # Description / extra text
        desc_el = card.select_one(".product-description, .ProductItem__Description, .description")
        description = desc_el.get_text(" ", strip=True) if desc_el else ""

        # Try to derive a "product id" from data-attributes or name
        supplier_pid = None
        for attr_name in ["data-product-id", "data-id", "data-product-handle"]:
            if card.has_attr(attr_name):
                supplier_pid = card[attr_name]
                break
        if not supplier_pid:
            supplier_pid = name

        products.append({
            "supplier": SUPPLIER_NAME,
            "supplier_product_id": supplier_pid,
            "name": name,
            "description": description,
            "price_cents": price_cents,
            "currency": "USD",
            "image_url": image_url,
            "source_url": GOLI_ORDER_URL,
            "extra": {
                "price_raw": price_raw,
            }
        })

    return products


def upsert_products(products: List[Dict[str, Any]]) -> None:
    """
    Upsert products into aogrl_ds_products using Supabase REST.
    Uses unique index on (supplier, supplier_product_id).
    """
    if not products:
        print("No products to upsert.")
        return

    endpoint = f"{SUPABASE_URL}/rest/v1/aogrl_ds_products"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
        # merge-duplicates respects unique index
    }

    # Supabase REST can accept an array of rows
    resp = requests.post(endpoint, headers=headers, data=json.dumps(products))
    if resp.status_code >= 200 and resp.status_code < 300:
        print(f"Upserted {len(products)} products into aogrl_ds_products.")
    else:
        print("ERROR posting to Supabase:", resp.status_code, resp.text, file=sys.stderr)
        resp.raise_for_status()


def main():
    print(f"[GoliImport] Fetching {GOLI_ORDER_URL} ...")
    html = fetch_page(GOLI_ORDER_URL)
    soup = BeautifulSoup(html, "html.parser")

    products = []

    # 1) Try JSON-LD
    products_ld = extract_from_json_ld(soup)
    if products_ld:
        print(f"[GoliImport] Found {len(products_ld)} products via JSON-LD.")
        products.extend(products_ld)

    # 2) Fallback to DOM scraping
    products_dom = extract_from_dom(soup)
    if products_dom:
        print(f"[GoliImport] Found {len(products_dom)} products via DOM scraping.")
        products.extend(products_dom)

    # Deduplicate by (supplier, supplier_product_id)
    deduped = {}
    for p in products:
        key = (p["supplier"], p["supplier_product_id"])
        deduped[key] = p

    final_products = list(deduped.values())
    print(f"[GoliImport] Final product count after dedupe: {len(final_products)}")

    upsert_products(final_products)


if __name__ == "__main__":
    main()
