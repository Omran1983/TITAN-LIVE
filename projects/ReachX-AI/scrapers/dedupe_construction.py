import os
import re
from typing import Dict, List

from supabase import create_client, Client

# Try RX_* first, then REACHX_* as fallback, then hard-coded URL only
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
    raise RuntimeError("Missing Supabase service key for construction dedupe.")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


def log(msg: str) -> None:
    print(f"[dedupe_construction] {msg}")


def fetch_all() -> List[Dict]:
    """
    Fetch all rows from reachx_construction_companies using supabase-py 2.x.
    """
    log("Fetching existing records…")
    res = supabase.table("reachx_construction_companies").select("*").execute()

    # supabase-py 2.x: response has .data (list[dict]) and .model_dump_json() for raw
    rows = getattr(res, "data", None)
    if rows is None:
        log("WARNING: response has no .data attribute or is None, treating as empty.")
        return []

    if not isinstance(rows, list):
        log(f"WARNING: .data is not a list (got: {type(rows)}), treating as empty.")
        return []

    return rows


COMMON_TOKENS = {
    "ltd",
    "limited",
    "co",
    "company",
    "mauritius",
    "maurice",
    "pvt",
    "pty",
    "inc",
    "corp",
    "corporation",
}


def canonical_name(name: str) -> str:
    """
    Create a normalised key for company name.
    Lowercase, remove punctuation, strip common suffixes.
    """
    if not name:
        return ""

    n = name.lower()
    # replace non-alphanum with space
    n = re.sub(r"[^a-z0-9]+", " ", n)
    parts = [p for p in n.split() if p not in COMMON_TOKENS]
    return " ".join(parts).strip()


def dedupe(rows: List[Dict]) -> List[Dict]:
    """
    Deduplicate by canonicalised company name.
    Keep the first record as the "winner".
    """
    log("Running dedupe logic…")

    by_key: Dict[str, Dict] = {}

    for row in rows:
        raw_name = row.get("company_name") or row.get("name") or ""
        key = canonical_name(raw_name)

        if not key:
            # keep these as-is but keyed by raw id so we don't lose them
            fallback_key = f"__no_name__:{row.get('id')}"
            by_key[fallback_key] = row
            continue

        if key not in by_key:
            by_key[key] = row
        else:
            # If you want to merge phones/emails etc., do it here.
            # For now, we just keep the first record.
            pass

    log(f"Deduped from {len(rows)} → {len(by_key)} records.")
    return list(by_key.values())


def replace_table(deduped: List[Dict]) -> None:
    log("Clearing table before re-insert…")
    supabase.table("reachx_construction_companies").delete().neq("id", 0).execute()

    # remove 'id' so it uses fresh bigserial
    for rec in deduped:
        rec.pop("id", None)

    batch_size = 100
    for i in range(0, len(deduped), batch_size):
        chunk = deduped[i : i + batch_size]
        log(f"Inserting deduped batch {i // batch_size + 1} (size={len(chunk)})…")
        supabase.table("reachx_construction_companies").insert(chunk).execute()


def main():
    log("Fetching existing records…")
    companies = fetch_all()
    log(f"Fetched {len(companies)} rows.")

    if not companies:
        log("No companies found, nothing to dedupe.")
        return

    deduped = dedupe(companies)
    log(f"After dedupe: {len(deduped)} unique companies.")

    replace_table(deduped)
    log("Dedupe complete.")


if __name__ == "__main__":
    main()
