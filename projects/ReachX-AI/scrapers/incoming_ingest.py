import os
import csv
import sys
from pathlib import Path
from typing import List, Dict

from supabase import create_client, Client

ROOT = Path(__file__).resolve().parents[1]
RAW_CSV = ROOT / "data" / "raw" / "employers_mauritiusifc.csv"


def get_supabase_client() -> Client:
    url = (
        os.getenv("REACHX_SUPABASE_URL")
        or os.getenv("RX_SUPABASE_URL")
        or os.getenv("SUPABASE_URL")
    )
    key = (
        os.getenv("REACHX_SUPABASE_SERVICE_KEY")
        or os.getenv("REACHX_SUPABASE_SERVICE_ROLE_KEY")
        or os.getenv("RX_SUPABASE_SERVICE_KEY")
        or os.getenv("SUPABASE_SERVICE_KEY")
    )
    if not url or not key:
        raise RuntimeError(
            "Missing Supabase env. Need REACHX_SUPABASE_URL + REACHX_SUPABASE_SERVICE_KEY (or equivalents)."
        )
    return create_client(url, key)


def load_csv() -> List[Dict]:
    if not RAW_CSV.exists():
        print(f"[incoming_ingest] No CSV found at {RAW_CSV}")
        return []

    with RAW_CSV.open("r", newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"[incoming_ingest] Loaded {len(rows)} rows from {RAW_CSV}")
    return rows


def normalise(rows: List[Dict]) -> List[Dict]:
    out: List[Dict] = []
    for r in rows:
        name = (r.get("company_name") or "").strip()
        if not name:
            continue

        country = (r.get("country") or "Mauritius").strip()
        industry_csv = (r.get("industry") or "").strip()
        sector_raw = (r.get("sector_raw") or "").strip()
        sector_group = (r.get("sector_group") or "").strip()

        # final industry = grouped sector if present, else CSV industry, else fallback
        industry = sector_group or industry_csv or "Financial Services - Other"

        out.append(
            {
                "name": name,
                "employer_name": name,
                "industry": industry,
                "country": country,
                "contact_email": (r.get("email") or "").strip() or None,
                "contact_phone": (r.get("phone") or "").strip() or None,
                "website": (r.get("website") or "").strip() or None,
                "source": (r.get("source") or "mauritius_ifc_directory").strip(),
                "business_sector": sector_raw or None,   # raw text from IFC
                "sector_group": sector_group or None,    # clean grouped label
            }
        )

    print(f"[incoming_ingest] Normalised {len(out)} employer rows.")
    return out


def upsert_employers(client: Client, rows: List[Dict]):
    if not rows:
        print("[incoming_ingest] No rows to upsert.")
        return

    table_name = "reachx_employers"
    batch_size = 200
    total = 0

    for i in range(0, len(rows), batch_size):
        batch = rows[i : i + batch_size]
        res = client.table(table_name).upsert(batch, on_conflict="name").execute()
        data = res.data or []
        total += len(data)
        print(
            f"[incoming_ingest] Batch {i//batch_size + 1}: upserted {len(data)} rows (total {total})."
        )

    print(f"[incoming_ingest] Finished upserting employers: {total} rows.")


def main():
    print("=== ReachX Incoming Ingest → reachx_employers ===")
    rows = load_csv()
    normalised = normalise(rows)
    if not normalised:
        print("[incoming_ingest] Nothing to send to Supabase.")
        return 0

    client = get_supabase_client()
    upsert_employers(client, normalised)
    print("=== ReachX Incoming Ingest: DONE ===")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
