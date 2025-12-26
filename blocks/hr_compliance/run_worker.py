"""
TITAN HR - Run Worker (The Engine)
CSV -> Validator -> JSON -> PDF -> Audit

Folder model:
F:/AION-ZERO/data/clients/<CID>/
  inbox/
  working/<YYYY-MM>/
  outputs/<YYYY-MM>/
  audit/events.jsonl
"""

import json
from pathlib import Path
from datetime import datetime
from uuid import uuid4
import pandas as pd

from audit import log_event
from pdf_generator import CompliancePDFGenerator

# Import your validator module (the one containing run_validation + load_rules)
# Adjust this import path if your file name differs.
from validate_employees import load_rules, run_validation  # <-- your validator file


DATA_ROOT = Path("F:/AION-ZERO/data")
RULES_FILE = Path("F:/AION-ZERO/blocks/hr_compliance/prb_2026.json")


def _require_month(month: str) -> str:
    # strict: YYYY-MM
    try:
        datetime.strptime(month, "%Y-%m")
        return month
    except Exception:
        raise ValueError("month must be 'YYYY-MM' (example: 2025-12)")


def _client_dirs(client_cid: str, month: str):
    client_dir = DATA_ROOT / "clients" / client_cid
    inbox_dir = client_dir / "inbox"
    working_dir = client_dir / "working" / month
    outputs_dir = client_dir / "outputs" / month
    audit_dir = client_dir / "audit"
    return client_dir, inbox_dir, working_dir, outputs_dir, audit_dir


def _build_pdf_data(validation_result: dict, month: str) -> dict:
    """
    Convert validator JSON -> pdf_generator input contract.
    """
    salary_violations = []
    leave_violations = []
    other_violations = []
    warnings = []

    details = validation_result.get("details") or []
    total_employees = int(validation_result.get("total_employees", 0) or 0)

    # Build violations from FAIL checks
    for emp_res in details:
        name = emp_res.get("name") or emp_res.get("employee_name") or emp_res.get("full_name") or "Unknown"
        role = emp_res.get("designation") or emp_res.get("job_grade") or "-"
        contract = emp_res.get("contract_type") or ""
        role_str = f"{role}\n({contract})" if contract else str(role)

        hire_date_str = emp_res.get("hire_date") or ""
        tenure = "-"
        try:
            if hire_date_str:
                h_date = datetime.strptime(str(hire_date_str)[:10], "%Y-%m-%d")
                report_date = datetime.strptime(month, "%Y-%m")
                years = (report_date.year - h_date.year) + (report_date.month - h_date.month) / 12
                tenure = f"{years:.1f} yrs"
        except Exception:
            pass

        for chk in (emp_res.get("checks") or []):
            verdict = chk.get("verdict")
            rule_id = chk.get("rule_id", "")
            rule_name = chk.get("rule_name", "-")
            evidence = chk.get("evidence")

            if verdict == "FAIL":
                actual = "N/A"
                expected = "N/A"
                fix = "Review rule & correct data."

                if isinstance(evidence, dict):
                    if "employee_salary" in evidence:
                        actual = f"Rs {evidence.get('employee_salary')}"
                        expected = f"Rs {evidence.get('floor_required')}"
                        gap = evidence.get("gap")
                        fix = f"Increase salary by Rs {gap}" if gap else "Increase salary to meet floor."
                    elif "taken" in evidence:
                        actual = str(evidence.get("taken"))
                        expected = str(evidence.get("limit"))
                        gap = evidence.get("gap")
                        fix = f"Correct leave record (excess {gap})" if gap else "Correct leave record."
                    else:
                        # generic dict
                        actual = json.dumps(evidence)

                elif isinstance(evidence, str):
                    fix = evidence

                row = {
                    "employee": name,
                    "role": role_str,
                    "tenure": tenure,
                    "clause": rule_id or "-",
                    "rule": rule_name,
                    "actual": actual,
                    "expected": expected,
                    "fix": fix,
                }

                if "PRB26-SAL" in rule_id or "PRB26-PMS" in rule_id:
                    salary_violations.append(row)
                elif "WRA" in rule_id:
                    leave_violations.append(row)
                else:
                    other_violations.append(row)

            elif verdict == "WARNING":
                warnings.append({
                    "rule": rule_name,
                    "message": evidence if isinstance(evidence, str) else json.dumps(evidence),
                    "citation": rule_id
                })

    # Score heuristic: percent employees without any FAIL (simple + honest)
    failures = int(validation_result.get("failures", 0) or 0)
    if total_employees <= 0:
        score = 100
    else:
        score = int(((total_employees - failures) / total_employees) * 100)

    return {
        "compliance_score": score,
        "total_employees": total_employees,
        "salary_violations": salary_violations,
        "leave_violations": leave_violations,
        "other_violations": other_violations,
        "warnings": warnings,
    }


def process_run(client_cid: str, csv_path: str, month: str) -> dict:
    month = _require_month(month)
    run_id = str(uuid4())

    client_dir, inbox_dir, working_dir, outputs_dir, _ = _client_dirs(client_cid, month)
    inbox_dir.mkdir(parents=True, exist_ok=True)
    working_dir.mkdir(parents=True, exist_ok=True)
    outputs_dir.mkdir(parents=True, exist_ok=True)

    log_event(
        data_root=str(DATA_ROOT),
        event_type="RUN_STARTED",
        client_cid=client_cid,
        run_id=run_id,
        payload={"csv_path": str(csv_path), "month": month},
        status="OK"
    )

    try:
        # 1) Load rules
        rules_doc = load_rules(RULES_FILE)
        log_event(
            data_root=str(DATA_ROOT),
            event_type="RULES_LOADED",
            client_cid=client_cid,
            run_id=run_id,
            payload={"rules_version": rules_doc.get("version"), "rules_count": len(rules_doc.get("rules", []))},
            status="OK"
        )

        # 2) Read CSV robustly
        df = pd.read_csv(csv_path, encoding="utf-8-sig")
        employees = df.to_dict(orient="records")

        # 3) Validate
        validation_result = run_validation(employees, rules_doc)

        json_path = working_dir / "validation.json"
        json_path.write_text(json.dumps(validation_result, indent=2, ensure_ascii=False), encoding="utf-8")

        log_event(
            data_root=str(DATA_ROOT),
            event_type="VALIDATION_COMPLETE",
            client_cid=client_cid,
            run_id=run_id,
            payload={
                "total_employees": validation_result.get("total_employees"),
                "failures": validation_result.get("failures"),
                "json_path": str(json_path)
            },
            status="OK"
        )

        # 4) Build PDF data + generate PDF
        pdf_data = _build_pdf_data(validation_result, month)

        pdf_gen = CompliancePDFGenerator(str(outputs_dir))
        pdf_filename = f"HR_Compliance_Report_{client_cid}_{month}.pdf"
        pdf_path = pdf_gen.generate_report(client_cid, month, pdf_data, filename=pdf_filename)

        log_event(
            data_root=str(DATA_ROOT),
            event_type="REPORT_GENERATED",
            client_cid=client_cid,
            run_id=run_id,
            payload={"pdf_path": str(pdf_path), "score": pdf_data.get("compliance_score")},
            status="OK"
        )

        log_event(
            data_root=str(DATA_ROOT),
            event_type="RUN_FINISHED",
            client_cid=client_cid,
            run_id=run_id,
            payload={"status": "SUCCESS"},
            status="OK"
        )

        return {
            "status": "SUCCESS",
            "run_id": run_id,
            "month": month,
            "score": pdf_data.get("compliance_score"),
            "validation_json": str(json_path),
            "pdf_path": str(pdf_path),
        }

    except Exception as e:
        log_event(
            data_root=str(DATA_ROOT),
            event_type="RUN_FAILED",
            client_cid=client_cid,
            run_id=run_id,
            payload={"error": str(e)},
            status="FAIL"
        )
        return {"status": "FAIL", "run_id": run_id, "error": str(e)}


if __name__ == "__main__":
    # Quick test
    res = process_run(
        client_cid="TEST-001",
        csv_path="F:/AION-ZERO/blocks/hr_compliance/templates/employee_schema.csv",
        month="2025-12",
    )
    print(res)
