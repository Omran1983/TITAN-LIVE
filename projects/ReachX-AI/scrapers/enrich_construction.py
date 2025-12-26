import os
import re
from typing import Dict, List, Tuple

from supabase import create_client, Client

# Prefer RX_*; fall back to REACHX_*; URL hard-coded; key must come from env.
SUPABASE_URL = (
    os.getenv("RX_SUPABASE_URL")
    or os.getenv("REACHX_SUPABASE_URL")
    or "https://abkprecmhitqmmlzxfad.supabase.co"
)
SUPABASE_KEY = (
    os.getenv("RX_SUPABASE_SERVICE_KEY")
    or os.getenv("REACHX_SUPABASE_SERVICE_KEY")
    or ""
)

if not SUPABASE_KEY:
    raise RuntimeError("Missing Supabase service key for construction enrichment.")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


def log(msg: str) -> None:
    print(f"[enrich_construction] {msg}")


def fetch_all() -> List[Dict]:
    """
    Fetch all rows from reachx_construction_companies using supabase-py 2.x.
    """
    log("Fetching records for enrichment…")
    res = supabase.table("reachx_construction_companies").select("*").execute()

    rows = getattr(res, "data", None)
    if rows is None:
        log("WARNING: response has no .data attribute or is None, treating as empty.")
        return []

    if not isinstance(rows, list):
        log(f"WARNING: .data is not a list (got: {type(rows)}), treating as empty.")
        return []

    return rows


EMAIL_REGEX = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
URL_REGEX = re.compile(
    r"(https?://[^\s]+|www\.[^\s]+|[A-Za-z0-9.-]+\.[A-Za-z]{2,})",
    re.IGNORECASE,
)


def extract_email_and_website(text: str) -> Tuple[str, str]:
    """
    Very rough extraction of first email + website-like string from text.
    """
    if not text:
        return "", ""

    email_match = EMAIL_REGEX.search(text)
    email = email_match.group(0) if email_match else ""

    website = ""
    for m in URL_REGEX.finditer(text):
        candidate = m.group(0)
        # skip pure emails accidentally caught
        if "@" in candidate:
            continue
        website = candidate
        break

    # Normalise website to https://...
    if website and not website.lower().startswith(("http://", "https://")):
        website = "https://" + website

    return email, website


def build_enriched_records(rows: List[Dict]) -> List[Dict]:
    """
    Build list of records to upsert (id + updated email/website).
    Only include records where we actually add something new.
    """
    updates: List[Dict] = []

    for row in rows:
        rid = row.get("id")
        if rid is None:
            continue

        current_email = (row.get("email") or "").strip()
        current_website = (row.get("website") or "").strip()

        # If both already present, skip
        if current_email and current_website:
            continue

        # Build a blob of text to search in
        parts = [
            str(row.get("company_name") or ""),
            str(row.get("name") or ""),
            str(row.get("contact_phone") or ""),
            str(row.get("address") or ""),
            str(row.get("raw_data") or ""),
        ]
        blob = " ".join(parts)

        email, website = extract_email_and_website(blob)

        # Only update if we actually found something new
        new_email = email if email and not current_email else current_email
        new_website = website if website and not current_website else current_website

        if new_email != current_email or new_website != current_website:
            updates.append(
                {
                    "id": rid,
                    "email": new_email,
                    "website": new_website,
                }
            )

    return updates


def apply_updates(updates: List[Dict]) -> None:
    if not updates:
        log("No records to update (no new email/website found).")
        return

    batch_size = 100
    for i in range(0, len(updates), batch_size):
        chunk = updates[i : i + batch_size]
        log(f"Upserting enrichment batch {i // batch_size + 1} (size={len(chunk)})…")
        supabase.table("reachx_construction_companies").upsert(chunk).execute()


def main():
    companies = fetch_all()
    log(f"Fetched {len(companies)} rows for enrichment.")

    if not companies:
        log("No companies found, skipping enrichment.")
        return

    updates = build_enriched_records(companies)
    log(f"Enrichment will update {len(updates)} records.")
    apply_updates(updates)
    log("Enrichment complete.")


if __name__ == "__main__":
    main()
