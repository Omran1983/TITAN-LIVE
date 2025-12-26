import uvicorn
from fastapi import FastAPI, HTTPException, Body
from pydantic import BaseModel
from typing import List, Optional
import json

app = FastAPI(title="Global Employment Compliance Scanner", version="1.0.0")

# --- Data Models ---

class EmployeeRecord(BaseModel):
    id: str
    annual_salary: float
    currency: str = "USD"
    hours_per_week: float
    has_written_contract: bool
    role: str

class ComplianceRequest(BaseModel):
    jurisdiction: str = "Generic (ILO Principles)"
    employees: List[EmployeeRecord]

class RiskItem(BaseModel):
    severity: str  # HIGH, MEDIUM, LOW
    rule_violated: str
    affected_employees: List[str]
    description: str
    potential_penalty: str

class ComplianceVerdict(BaseModel):
    overall_risk: str # CRITICAL, ELEVATED, SAFE
    risk_score: int # 0-100
    summary: str
    risks: List[RiskItem]
    audit_recommendation: str

# --- Logic Engine (The "Wedge") ---

def _analyze_generic_compliance(data: ComplianceRequest) -> ComplianceVerdict:
    risks = []
    score = 0
    total_emps = len(data.employees)
    
    # Rule 1: Written Contracts (Universal)
    missing_contracts = [e.id for e in data.employees if not e.has_written_contract]
    if missing_contracts:
        risks.append(RiskItem(
            severity="HIGH",
            rule_violated="Universal Requirement: Written Particulars of Employment",
            affected_employees=missing_contracts,
            description="Employees found without written contracts. This violates basic labor laws in 95% of jurisdictions.",
            potential_penalty="Fines up to $5,000 per violation + Unfair Dismissal liability."
        ))
        score += 50

    # Rule 2: Excessive Hours (Generic ILO Std: 48h)
    overworked = [e.id for e in data.employees if e.hours_per_week > 48]
    if overworked:
        risks.append(RiskItem(
            severity="MEDIUM",
            rule_violated="ILO C001: Hours of Work (Industry) Convention",
            affected_employees=overworked,
            description=f"Employees working > 48 hours/week. Check overtime payments or opt-out agreements.",
            potential_penalty="Back-pay liability + Regulatory Fines."
        ))
        score += 30

    # Rule 3: Minimum Wage Check (Heuristic)
    # Assuming $15k/yr is a generic 'safe' floor for Western SMEs, obviously simplistic but illustrates the logic
    underpaid = [e.id for e in data.employees if e.annual_salary < 15000 and e.currency == "USD"]
    if underpaid:
        risks.append(RiskItem(
            severity="HIGH",
            rule_violated="Minimum Wage Threshold (Estimated)",
            affected_employees=underpaid,
            description="Salary detected below common Western minimum wage floors ($15,000/yr). Verify immediately.",
            potential_penalty="Wage theft lawsuits + Back-pay x3."
        ))
        score += 40

    # Verdict Logic
    final_risk = "SAFE"
    if score > 60: final_risk = "CRITICAL"
    elif score > 20: final_risk = "ELEVATED"

    rec = "Audit PASSED."
    if final_risk == "CRITICAL":
        rec = "IMMEDIATE ACTION REQUIRED. Do not terminate any staff before legal review. Download full audit packet."
    elif final_risk == "ELEVATED":
        rec = "Review contracts and working hours. Consider updating employee handbook."

    return ComplianceVerdict(
        overall_risk=final_risk,
        risk_score=min(score, 100),
        summary=f"Scanned {total_emps} employees under '{data.jurisdiction}'. Found {len(risks)} distinct risk categories.",
        risks=risks,
        audit_recommendation=rec
    )

# --- Endpoints ---

@app.post("/scan", response_model=ComplianceVerdict, operation_id="scan_compliance")
def scan_compliance(request: ComplianceRequest = Body(...)):
    """
    Analyzes a list of employee records against standard employment laws (Generic/International Principles).
    Returns a Risk Score, detailed violations, and specific penalties.
    """
    try:
        # In a real app, we would load jurisdiction-specific rules here
        return _analyze_generic_compliance(request)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/legal/terms", operation_id="get_terms")
def get_terms():
    """Returns the legal disclaimer for the compliance scanner."""
    return {
        "disclaimer": "This tool provides information for educational and preliminary audit purposes only. It is NOT legal advice. An attorney-client relationship is not formed. Users should consult local counsel before taking adverse employment actions."
    }

if __name__ == "__main__":
    # For local testing
    uvicorn.run(app, host="0.0.0.0", port=8000)
