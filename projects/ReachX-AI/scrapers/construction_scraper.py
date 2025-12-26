import os
import re
import json
from typing import List, Dict

import requests
import pdfplumber
from bs4 import BeautifulSoup
from supabase import create_client, Client

# ── CONFIG ──────────────────────────────────────────────────────────────

SUPABASE_URL = os.getenv("RX_SUPABASE_URL", "https://abkprecmhitqmmlzxfad.supabase.co")
SUPABASE_KEY = os.getenv("RX_SUPABASE_SERVICE_KEY", "YOUR_SERVICE_ROLE_KEY_HERE")

CIDB_PDF_URL = (
    "https://www.cidb.mu/wp-content/uploads/2020/05/"
    "list-of-Registered-Local-Contractors-as-at-24-March-2021.pdf"
)

YELLOW_DIRECTORY_URL = "https://www.yellow.mu/category/building-contractors"

# ── INIT SUPABASE ───────────────────────────────────────────────────────

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


# ── HELPERS ─────────────────────────────────────────────────────────────

def clean_text(value: str) -> str:
    if not value:
        return ""
    # keep letters, digits, punctuation common in names/addresses
    value = re.sub(r"[^A-Za-z0-9 ,.\-/()+@]", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def log(msg: str) -> None:
    print(f"[construction_scraper] {msg}")


# ── CIDB PDF SCRAPER ────────────────────────────────────────────────────

def fetch_cidb_pdf_lines() -> List[str]:
    log("Downloading CIDB contractors PDF…")
    resp = requests.get(CIDB_PDF_URL, timeout=60)
    resp.raise_for_status()

    pdf_path = "cidb_contractors.pdf"
    with open(pdf_path, "wb") as f:
        f.write(resp.content)

    log("Extracting lines from PDF…")
    lines: List[str] = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text() or ""
            for line in text.split("\n"):
                line = line.strip()
                # crude filter: must contain letters and at least 3 digits (registration, phone, etc.)
                if re.search(r"[A-Za-z]", line) and re.search(r"\d{3}", line):
                    lines.append(line)

    log(f"CIDB PDF lines captured: {len(lines)}")
    return lines


def normalise_cidb_lines(lines: List[str]) -> List[Dict]:
    records: List[Dict] = []
    for line in lines:
        cleaned = clean_text(line)
        if not cleaned:
            continue
        # split at multiple spaces – VERY rough, but good enough for seeding
        parts = re.split(r"\s{2,}", cleaned)
        company_name = parts[0] if parts else cleaned
        records.append(
            {
                "company_name": company_name,
                "phone": None,
                "email": None,
                "website": None,
                "address": None,
                "source": "CIDB PDF",
                "raw_data": {"line": line},
            }
        )
    log(f"CIDB normalised records: {len(records)}")
    return records


# ── DIRECTORY SCRAPER (YELLOW.MU STYLE) ─────────────────────────────────

def scrape_directory(url: str) -> List[Dict]:
    log(f"Scraping directory: {url}")
    resp = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=60)
    resp.raise_for_status()

    soup = BeautifulSoup(resp.text, "html.parser")
    records: List[Dict] = []

    # This is template code – adapt selectors to the actual HTML you see.
    # Look for each listing block that has company name + contact.
    for block in soup.find_all("div", class_="listing"):
        name_el = block.find("h3") or block.find("h2") or block.find("a")
        phone_el = block.find("span", class_="phone") or block.find(
            string=re.compile(r"\+230")
        )
        addr_el = block.find("div", class_="address") or block.find(
            string=re.compile(r"Road|Street|Avenue|Mauritius", re.I)
        )

        company_name = clean_text(name_el.get_text()) if name_el else ""
        if not company_name:
            continue

        phone = clean_text(phone_el.get_text()) if hasattr(phone_el, "get_text") else (
            clean_text(phone_el) if phone_el else None
        )
        address = clean_text(addr_el.get_text()) if hasattr(addr_el, "get_text") else (
            clean_text(addr_el) if addr_el else None
        )

        records.append(
            {
                "company_name": company_name,
                "phone": phone or None,
                "email": None,
                "website": None,
                "address": address or None,
                "source": url,
                "raw_data": {},
            }
        )

    log(f"Directory records found: {len(records)}")
    return records


# ── UPSERT TO SUPABASE ──────────────────────────────────────────────────

def upsert_records(records: List[Dict]) -> None:
    if not records:
        log("No records to upsert.")
        return

    # simple insert in batches of 100
    batch_size = 100
    for i in range(0, len(records), batch_size):
        chunk = records[i : i + batch_size]
        log(f"Inserting batch {i // batch_size + 1} ({len(chunk)} records)…")
        res = supabase.table("reachx_construction_companies").insert(chunk).execute()
        if res.error:
            log(f"Supabase insert error: {res.error}")
        else:
            log("Batch inserted.")


def main():
    # 1) CIDB
    cidb_lines = fetch_cidb_pdf_lines()
    cidb_records = normalise_cidb_lines(cidb_lines)

    # 2) Directory
    directory_records = []
    try:
        directory_records = scrape_directory(YELLOW_DIRECTORY_URL)
    except Exception as e:
        log(f"Directory scrape failed (non-fatal): {e}")

    all_records = cidb_records + directory_records
    log(f"Total scraped records: {len(all_records)}")

    upsert_records(all_records)
    log("Done.")


if __name__ == "__main__":
    main()
