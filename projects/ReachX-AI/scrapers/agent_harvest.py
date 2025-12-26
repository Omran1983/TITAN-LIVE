import os
import csv
import time
import sys
from pathlib import Path

import requests
from bs4 import BeautifulSoup


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"
RAW_DIR.mkdir(parents=True, exist_ok=True)

OUT_CSV = RAW_DIR / "employers_mauritiusifc.csv"


def normalise_sector(raw: str) -> str:
    if not raw:
        return "Financial Services - Other"

    s = raw.lower()

    if "management compan" in s:
        return "Management Companies"
    if "fund" in s or "asset management" in s or "investment manager" in s:
        return "Funds & Asset Management"
    if "bank" in s or "banking" in s:
        return "Banking & Finance"
    if "insurance" in s:
        return "Insurance"
    if "trust" in s or "fiduciary" in s:
        return "Trust & Fiduciary"
    if "law" in s or "legal" in s or "chambers" in s:
        return "Legal Services"
    if "account" in s or "audit" in s:
        return "Accounting & Audit"
    if "consult" in s or "advisory" in s:
        return "Advisory & Consulting"
    if "fintech" in s or "payment" in s:
        return "FinTech & Payments"
    if "ict" in s or "technology" in s or "it services" in s:
        return "ICT & Digital Services"
    if "hr" in s or "recruitment" in s or "training" in s:
        return "HR & Training"

    return "Financial Services - Other"


def parse_business_directory_page(text: str):
    lines = [ln.strip() for ln in text.splitlines()]
    records = []

    i = 0
    while i < len(lines):
        if lines[i].lower() == "contact details":
            # Find company name by scanning backwards
            name_idx = None
            back = i - 1
            while back >= 0:
                candidate = lines[back].strip()
                if candidate and candidate.lower() not in ("image",):
                    name_idx = back
                    break
                back -= 1

            name = None
            if name_idx is not None:
                name = lines[name_idx].lstrip("#").strip()

            # Sector/business category lines between name and "Contact details"
            sector_lines = []
            if name_idx is not None:
                for j in range(name_idx + 1, i):
                    cand = lines[j].strip()
                    if not cand:
                        continue
                    low = cand.lower()
                    if low in ("image", "contact details"):
                        continue
                    if "@" in cand:
                        continue
                    if "http" in low or ".mu" in low or ".com" in low:
                        continue
                    if any(tok in low for tok in ("tel", "fax", "telephone", "mobile")):
                        continue
                    sector_lines.append(cand)

            # Deduplicate sector lines while preserving order
            seen_sectors = {}
            for s in sector_lines:
                seen_sectors.setdefault(s, True)
            sector_raw = ", ".join(seen_sectors.keys())
            sector_group = normalise_sector(sector_raw)

            # Email / phone / website as before
            email = lines[i + 1].strip() if i + 1 < len(lines) else ""
            phone = lines[i + 2].strip() if i + 2 < len(lines) else ""

            website = ""
            for j in range(i + 1, min(i + 8, len(lines))):
                if j >= len(lines):
                    break
                candidate = lines[j].strip()
                low = candidate.lower()
                if "http" in low or ".mu" in low or ".com" in low:
                    website = candidate
                    break

            if name and (email or phone or website):
                records.append(
                    {
                        "company_name": name,
                        # industry now = grouped sector
                        "industry": sector_group or "Financial Services - Other",
                        "country": "Mauritius",
                        "city": "",
                        "email": email,
                        "phone": phone,
                        "website": website,
                        "source": "mauritius_ifc_directory",
                        "sector_raw": sector_raw,
                        "sector_group": sector_group,
                    }
                )
        i += 1

    return records


def scrape_mauritius_ifc():
    base = "https://mauritiusifc.mu/business-directory"
    headers = {
        "User-Agent": "ReachX-Agent/0.1 (+https://aogrl.com)"
    }

    all_records = []
    seen = set()

    for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
        url = f"{base}/{letter}"
        print(f"[agent_harvest] Fetching {url} ...")
        try:
            resp = requests.get(url, headers=headers, timeout=25)
            if resp.status_code != 200:
                print(f"[agent_harvest] Skipping {url} (status {resp.status_code})")
                continue
            soup = BeautifulSoup(resp.text, "html.parser")
            text = soup.get_text("\n", strip=True)
            page_records = parse_business_directory_page(text)
            print(f"[agent_harvest] {letter}: found {len(page_records)} records.")
            for r in page_records:
                key = (r["company_name"], r["email"], r["phone"])
                if key not in seen:
                    seen.add(key)
                    all_records.append(r)
            time.sleep(0.6)
        except Exception as e:
            print(f"[agent_harvest] ERROR for {url}: {e}")

    return all_records


def write_csv(records):
    if not records:
        print("[agent_harvest] No records to write.")
        return

    fieldnames = [
        "company_name",
        "industry",
        "country",
        "city",
        "email",
        "phone",
        "website",
        "source",
        "sector_raw",
        "sector_group",
    ]

    with OUT_CSV.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in records:
            writer.writerow(r)

    print(f"[agent_harvest] Wrote {len(records)} records to {OUT_CSV}")


def main():
    print("=== ReachX Agent Harvest: Mauritius IFC ===")
    records = scrape_mauritius_ifc()
    print(f"[agent_harvest] Total unique records: {len(records)}")
    write_csv(records)
    print("=== ReachX Agent Harvest: DONE ===")


if __name__ == "__main__":
    sys.exit(main() or 0)
