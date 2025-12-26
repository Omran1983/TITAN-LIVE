import json
import csv
import sys
from pathlib import Path
from typing import List, Dict, Any
from datetime import datetime, timezone
from decimal import Decimal

# --- Configuration ---
BLOCK_DIR = Path(__file__).resolve().parent
RULES_FILE = BLOCK_DIR / "rules.json"
OUTPUT_DIR = BLOCK_DIR / "reports"

# Add Root to Path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.append(str(PROJECT_ROOT))

from core.autonomy import gate, AutonomyLevel  # noqa: E402

# Import PDF Reporter
try:
    from core.reporting.pdf_reporter import generate_compliance_report
except ImportError:
    generate_compliance_report = None
    print("⚠️ PDF Reporter not found. PDF output disabled.")

def load_rules(path: Path) -> Dict[str, Any]:
    if not path.exists():
        print(f"❌ Critical: Rules file missing at {path}")
        sys.exit(1)
    return json.loads(path.read_text(encoding="utf-8"))

def load_data(path: Path) -> List[Dict[str, str]]:
    if not path.exists():
        print(f"❌ Input file missing: {path}")
        return []
    with open(path, mode='r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        return list(reader)

def validate_consumption(item: Dict[str, str], rule: Dict[str, Any]) -> Dict[str, Any]:
    # Logic: Check if item category matches and if value <= limit
    # For MVP, assume item row is: category, amount, unit, date
    
    category = item.get("category", "").lower()
    rule_cat = rule["parameters"]["category"].lower()
    
    if category != rule_cat:
        return None  # Not applicable to this row

    amount = Decimal(str(item.get("amount", 0)))
    limit = Decimal(str(rule.get("value", 0)))
    passed = amount <= limit
    
    return {
        "rule_id": rule["id"],
        "rule_name": rule["name"],
        "verdict": "PASS" if passed else "FAIL",
        "evidence": {
            "consumed": str(amount),
            "limit": str(limit),
            "unit": rule["parameters"]["unit"],
            "excess": "0" if passed else str(amount - limit)
        }
    }

def validate_permit(item: Dict[str, str], rule: Dict[str, Any]) -> Dict[str, Any]:
    # Logic: Check permit status and expiry
    permit_type = item.get("type", "").lower() # e.g. "eia_license"
    status = item.get("status", "").lower()
    
    # Simple check: is it active?
    passed = status == rule["parameters"]["required_status"]
    
    return {
        "rule_id": rule["id"],
        "rule_name": rule["name"],
        "verdict": "PASS" if passed else "FAIL",
        "evidence": {
            "permit_type": permit_type,
            "status": status,
            "required": rule["parameters"]["required_status"]
        }
    }

def run_validation(data: List[Dict[str, str]], rules_doc: Dict[str, Any]) -> Dict[str, Any]:
    results = {
        "schema_version": "1.0",
        "block": "TITAN-ENV",
        "block_version": "0.1.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "total_items": len(data),
        "failures": 0,
        "details": []
    }
    
    rules = {r["id"]: r for r in rules_doc["rules"]}
    
    for row in data:
        row_id = row.get("id", "UNKNOWN")
        row_results = []
        has_failure = False
        
        # 1. Check Plastics (ENV26-PLASTICS-001)
        if "ENV26-PLASTICS-001" in rules:
            res = validate_consumption(row, rules["ENV26-PLASTICS-001"])
            if res:
                row_results.append(res)
                if res["verdict"] == "FAIL":
                    has_failure = True
        
        # 2. Check Permit (ENV26-PERMIT-001) - Context aware
        if row.get("category") == "license" and "ENV26-PERMIT-001" in rules:
             res = validate_permit(row, rules["ENV26-PERMIT-001"])
             if res:
                row_results.append(res)
                if res["verdict"] == "FAIL":
                    has_failure = True
        
        if row_results:
             if has_failure:
                 results["failures"] += 1
             results["details"].append({
                "subject_id": row_id,
                "name": row.get("description", row.get("category")),
                "checks": row_results
             })
             
    return results

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    args = parser.parse_args()
    
    # Enforce Autonomy
    gate.enforce(AutonomyLevel.L1_ADVISOR, "TITAN-ENV Validation Run")
    
    print("🔹 TITAN-ENV: Starting Compliance Check...")
    
    rules = load_rules(RULES_FILE)
    data = load_data(Path(args.input))
    
    if not data:
        print("⚠️ No data found.")
        return

    report = run_validation(data, rules)
    
    OUTPUT_DIR.mkdir(exist_ok=True)
    report_file = OUTPUT_DIR / f"env_report_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}.json"
    report_file.write_text(json.dumps(report, indent=2))
    
    # PDF Generation
    if generate_compliance_report:
        pdf_path = OUTPUT_DIR / f"env_report_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}.pdf"
        generate_compliance_report(report, pdf_path, block_name="TITAN-ENV Compliance", version="0.1.0")

    print(f"\n✅ Validation Complete. Failures: {report['failures']}")
    if report['failures'] > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()
