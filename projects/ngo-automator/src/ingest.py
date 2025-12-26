import csv
import json
import argparse
from pathlib import Path

def ingest_financials(file_path: Path) -> dict:
    if not file_path.exists():
        return {"error": f"File not found: {file_path}"}
        
    entries = []
    total_spent = 0.0
    total_pending = 0.0
    currency = "USD"
    
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                amount = float(row.get("Amount", 0))
                status = row.get("Status", "Unknown")
                curr = row.get("Currency", "USD")
                currency = curr # Assume uniform currency for MVP
                
                entry = {
                    "date": row.get("Date"),
                    "activity": row.get("Activity"),
                    "desc": row.get("Description"),
                    "amount": amount,
                    "status": status
                }
                entries.append(entry)
                
                if status.lower() == "completed":
                    total_spent += amount
                elif status.lower() == "pending":
                    total_pending += amount
                    
    except Exception as e:
        return {"error": str(e)}
        
    # Generate Prompt Text for LLM
    prompt_text = f"Financial Report ({currency}):\n"
    prompt_text += f"Total Spent: {total_spent:,.2f} {currency}\n"
    prompt_text += f"Total Pending: {total_pending:,.2f} {currency}\n"
    prompt_text += "Activities:\n"
    for e in entries:
        prompt_text += f"- {e['date']}: {e['activity']} ({e['desc']}) - {e['amount']} {currency} [{e['status']}]\n"
        
    return {
        "ok": True,
        "metrics": {
            "total_spent": total_spent,
            "total_pending": total_pending,
            "currency": currency,
            "count": len(entries)
        },
        "llm_text": prompt_text,
        "entries": entries
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", required=True)
    ap.add_argument("--out", dest="out", required=True)
    args = ap.parse_args()
    
    res = ingest_financials(Path(args.inp))
    
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(res, f, indent=2)
        
    if res.get("ok"):
        print(f"[INGEST] Processed {res['metrics']['count']} rows.")
    else:
        print(f"[FAIL] {res.get('error')}")

if __name__ == "__main__":
    main()
