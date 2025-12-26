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
RULES_FILE = BLOCK_DIR / "prb_2026.json"
OUTPUT_DIR = BLOCK_DIR / "reports"

def load_rules(path: Path) -> Dict[str, Any]:
    if not path.exists():
        print(f"❌ Critical: Rules file missing at {path}")
        sys.exit(1)
    return json.loads(path.read_text(encoding="utf-8"))

def load_employees(path: Path) -> List[Dict[str, str]]:
    if not path.exists():
        print(f"❌ Input file missing: {path}")
        return []
    
    with open(path, mode='r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        return list(reader)

def validate_salary_floor(employee: Dict[str, str], rule: Dict[str, Any]) -> Dict[str, Any]:
    emp_salary = Decimal(str(employee.get("base_salary", 0)))
    floor_value = Decimal(str(rule.get("value", 0)))
    
    passed = emp_salary >= floor_value
    
    return {
        "rule_id": rule["id"],
        "rule_name": rule["name"],
        "verdict": "PASS" if passed else "FAIL",
        "evidence": {
            "employee_salary": str(emp_salary),
            "floor_required": str(floor_value),
            "gap": "0" if passed else str(floor_value - emp_salary)
        }
    }

def validate_increment_policy(employee: Dict[str, str], rule: Dict[str, Any]) -> Dict[str, Any]:
    status = employee.get("performance_status", "").lower()
    increment_proposed = employee.get("increment_proposed", "false").lower() == "true"
    
    required = rule["parameters"]["required_status"]
    
    # If increment is NOT proposed, rule is effectively skipped/passed regarding "granting"
    if not increment_proposed:
         return {
            "rule_id": rule["id"],
            "rule_name": rule["name"],
            "verdict": "PASS",
            "evidence": "No increment proposed, policy constraint not triggered."
        }

    passed = status in required
    
    return {
        "rule_id": rule["id"],
        "rule_name": rule["name"],
        "verdict": "PASS" if passed else "FAIL",
        "evidence": {
            "performance_status": status,
            "increment_proposed": increment_proposed,
            "allowed_statuses": required
        }
    }

def run_validation(employees: List[Dict[str, str]], rules_doc: Dict[str, Any]) -> Dict[str, Any]:
    results = {
        "schema_version": "1.0",
        "block": "TITAN-HR",
        "block_version": "1.0.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "total_employees": len(employees),
        "failures": 0,
        "details": []
    }
    
    rules = {r["id"]: r for r in rules_doc["rules"]}
    
    for emp in employees:
        emp_id = emp.get("employee_id", "UNKNOWN")
        emp_results = []
        has_failure = False
        
        # 1. Check Salary Floor (PRB26-SAL-001)
        if "PRB26-SAL-001" in rules:
            res = validate_salary_floor(emp, rules["PRB26-SAL-001"])
            emp_results.append(res)
            if res["verdict"] == "FAIL":
                has_failure = True
            
        # 2. Check Increment Policy (PRB26-PMS-001)
        if "PRB26-PMS-001" in rules:
            res = validate_increment_policy(emp, rules["PRB26-PMS-001"])
            emp_results.append(res)
            if res["verdict"] == "FAIL":
                has_failure = True
            
        # Add more implementations here map by ID
        
        if has_failure:
            results["failures"] += 1
            
        results["details"].append({
            "employee_id": emp_id,
            "name": emp.get("name"),
            "checks": emp_results
        })
        
    return results

def main():
    import argparse
    parser = argparse.ArgumentParser(description="TITAN-HR Compliance Validator")
    parser.add_argument("--input", required=True, help="Path to employee CSV")
    args = parser.parse_args()
    
    # Enforce Autonomy
    gate.enforce(AutonomyLevel.L1_ADVISOR, "TITAN-HR Validation Run")
    
    print("🔹 TITAN-HR: Starting Validation Sequence...")
    
    rules = load_rules(RULES_FILE)
    print(f"🔹 Loaded Rules: {rules['version']} ({len(rules['rules'])} rules)")
    
    employees = load_employees(Path(args.input))
    print(f"🔹 Loaded Employees: {len(employees)}")
    
    if not employees:
        print("⚠️ No employees found or file empty.")
        return

    report = run_validation(employees, rules)
    
    OUTPUT_DIR.mkdir(exist_ok=True)
    report_file = OUTPUT_DIR / f"compliance_report_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}.json"
    report_file.write_text(json.dumps(report, indent=2))
    
    # --- PDF Generation (Shared Service Integration) ---
    try:
        # Add Root to Path to find 'core'
        PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
        if str(PROJECT_ROOT) not in sys.path:
            sys.path.append(str(PROJECT_ROOT))
            
        from core.reporting.pdf_reporter import generate_compliance_report
        
        pdf_path = OUTPUT_DIR / f"compliance_report_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}.pdf"
        print(f"🔹 Generating PDF Report: {pdf_path}")
        generate_compliance_report(report, pdf_path, block_name="TITAN-HR Compliance", version="1.0.0")
        
    except ImportError as e:
        print(f"⚠️ PDF Reporter not found or failed: {e}")
    except Exception as e:
        print(f"⚠️ PDF Generation Failed: {e}")

    print("\n✅ Validation Complete.")
    print(f"   Failures Detected: {report['failures']}")
    print(f"   Report Saved (JSON): {report_file}")
    
    if report['failures'] > 0:
        sys.exit(1) # Signal failure to runner

if __name__ == "__main__":
    main()
