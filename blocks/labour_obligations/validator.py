import json
import csv
import sys
from pathlib import Path
from typing import List, Dict, Any
from datetime import datetime, timezone
from decimal import Decimal

# Add Root to Path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.append(str(PROJECT_ROOT))

from core.autonomy import gate, AutonomyLevel  # noqa: E402

# --- Configuration ---
BLOCK_DIR = Path(__file__).resolve().parent
RULES_FILE = BLOCK_DIR / "rules.json"
OUTPUT_DIR = BLOCK_DIR / "reports"

def load_rules(path: Path) -> Dict[str, Any]:
    if not path.exists():
        print(f"❌ Critical: Rules file missing at {path}")
        sys.exit(1)
    return json.loads(path.read_text(encoding="utf-8"))

def load_filings(path: Path) -> List[Dict[str, str]]:
    if not path.exists():
        print(f"❌ Input file missing: {path}")
        return []
    
    with open(path, mode='r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        return list(reader)

def check_filing_deadline(filing: Dict[str, str], rule: Dict[str, Any]) -> Dict[str, Any]:
    # Inputs
    filing_type = filing.get("filing_type", "").upper()
    rule_type = rule["parameters"]["filing_type"].upper()
    
    if filing_type != rule_type:
        return None # Not applicable

    due_date_str = filing.get("due_date")
    paid_date_str = filing.get("paid_date")
    paid_status = filing.get("paid", "FALSE").upper() == "TRUE"
    amount = Decimal(str(filing.get("amount_due", 0)))
    
    # Validation
    try:
        due_date = datetime.strptime(due_date_str, "%Y-%m-%d").replace(tzinfo=timezone.utc).date()
    except (ValueError, TypeError):
        return {
            "rule_id": rule["id"],
            "verdict": "FAIL",
            "evidence": f"Invalid due_date: {due_date_str}"
        }

    paid_date = None
    if paid_date_str:
        try:
            paid_date = datetime.strptime(paid_date_str, "%Y-%m-%d").replace(tzinfo=timezone.utc).date()
        except ValueError:
             pass # Treat as not paid effectively or review required

    is_late = False
    
    # Logic: Late IF (Paid AND PaidDate > DueDate) OR (NotPaid AND Now > DueDate)
    if paid_status and paid_date:
        if paid_date > due_date:
            is_late = True
    elif not paid_status:
        # Check against today (UTC)
        today = datetime.now(timezone.utc).date()
        if today > due_date:
            is_late = True

    passed = not is_late

    return {
        "rule_id": rule["id"],
        "rule_name": rule["name"],
        "verdict": "PASS" if passed else "FAIL",
        "evidence": {
            "filing": filing_type,
            "due": due_date_str,
            "paid_on": paid_date_str if paid_status else "NOT PAID",
            "amount": str(amount),
            "status": "LATE" if is_late else ("OK" if paid_status else "PENDING")
        }
    }

def run_validation(filings: List[Dict[str, str]], rules_doc: Dict[str, Any]) -> Dict[str, Any]:
    results = {
        "schema_version": "1.0",
        "block": "TITAN-LABOUR",
        "block_version": "0.1.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "total_items": len(filings),
        "failures": 0,
        "details": [],
        "action_list": []
    }
    
    rules = {r["id"]: r for r in rules_doc["rules"]}
    
    for row in filings:
        row_id = row.get("period", "UNK") + "-" + row.get("filing_type", "UNK")
        row_results = []
        has_failure = False
        
        # Iterate all rules to find match
        for rid, rule in rules.items():
            if rule["type"] == "filing_deadline":
                res = check_filing_deadline(row, rule)
                if res:
                    row_results.append(res)
                    if res["verdict"] == "FAIL":
                        has_failure = True
                        results["action_list"].append({
                            "priority": "HIGH",
                            "item": f"Late/Unpaid {res['evidence']['filing']}",
                            "due": res["evidence"]["due"],
                            "amount": res["evidence"]["amount"]
                        })

        if has_failure:
            results["failures"] += 1
            
        if row_results:
             results["details"].append({
                "subject_id": row_id,
                "name": f"{row.get('filing_type')} ({row.get('period')})",
                "checks": row_results
             })
        
    return results

def main():
    import argparse
    parser = argparse.ArgumentParser(description="TITAN-LABOUR Compliance Validator")
    parser.add_argument("--input", required=True, help="Path to filings CSV")
    args = parser.parse_args()
    
    # Enforce Autonomy
    gate.enforce(AutonomyLevel.L1_ADVISOR, "TITAN-LABOUR Validation Run")
    
    print("🔹 TITAN-LABOUR: Starting Filing Check...")
    
    rules = load_rules(RULES_FILE)
    filings = load_filings(Path(args.input))
    
    if not filings:
        print("⚠️ No filings found.")
        return

    report = run_validation(filings, rules)
    
    OUTPUT_DIR.mkdir(exist_ok=True)
    report_file = OUTPUT_DIR / f"labour_report_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}.json"
    report_file.write_text(json.dumps(report, indent=2))
    
    # --- PDF Generation ---
    try:
        from core.reporting.pdf_reporter import generate_compliance_report
        
        pdf_path = OUTPUT_DIR / f"labour_report_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}.pdf"
        print(f"🔹 Generating PDF Report: {pdf_path}")
        generate_compliance_report(report, pdf_path, block_name="TITAN-LABOUR Obligations", version="0.1.0")
        
    except ImportError as e:
        print(f"⚠️ PDF Reporter not found: {e}")
    except Exception as e:
        print(f"⚠️ PDF Generation Failed: {e}")

    print(f"\n✅ Validation Complete. Failures: {report['failures']}")
    if report['failures'] > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()
