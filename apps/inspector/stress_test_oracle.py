import sys
import os
import json
import random
from pathlib import Path

# Add Apps to Path
sys.path.append(str(Path(r"F:\AION-ZERO\apps\inspector").resolve()))
from readiness_generator import ReadinessGenerator

def run_stress_test():
    print("⚔️ TITAN ORACLE PROTOCOL: 5-POINT STRESS TEST")
    print("==============================================")
    
    generator = ReadinessGenerator()
    results = []

    # --- TEST CASES (PERSONAS) ---
    personas = [
        {
            "id": "CASE-UK-001",
            "company": "Hydra CyberSec Ltd",
            "jurisdiction": "UK G-Cloud",
            "score": 85,
            "band": "Audit-Resilient",
            "percentile": "Top 5%",
            "fail_rate": "12%",
            "cost": "£0 (Optimized)",
            "insights": [
                 {"text": "Data Sovereignty: <strong>Top 1%</strong> (Excellent)", "icon": "✓"},
                 {"text": "liability Cap: <strong>Standard</strong>", "icon": "✓"}
            ]
        },
        {
            "id": "CASE-UK-002",
            "company": "BioGen Labs",
            "jurisdiction": "UK Innovate",
            "score": 48,
            "band": "High Risk",
            "percentile": "Bottom 20%",
            "fail_rate": "68%",
            "cost": "£45,000",
            "insights": [
                 {"text": "IP Assignment: <strong>Missing</strong> (Critical)", "icon": "⚠️"},
                 {"text": "Data Governance: <strong>Non-Compliant</strong>", "icon": "⚠️"}
            ]
        },
        {
            "id": "CASE-MU-003",
            "company": "Phoenix Textiles Ltd",
            "jurisdiction": "Mauritius SME",
            "score": 62,
            "band": "Conditional",
            "percentile": "Top 55%",
            "fail_rate": "35%",
            "cost": "Rs 85,000",
            "insights": [
                 {"text": "MRA Clearance: <strong>Pending</strong> (Delay Risk)", "icon": "⏳"},
                 {"text": "Energy Audit: <strong>Valid</strong>", "icon": "✓"}
            ]
        },
        {
            "id": "CASE-MU-004",
            "company": "Azure FinTech",
            "jurisdiction": "Mauritius FSA",
            "score": 92,
            "band": "Fund-Ready",
            "percentile": "Top 2%",
            "fail_rate": "5%",
            "cost": "Rs 0",
            "insights": [
                 {"text": "AML Framework: <strong>Robust</strong>", "icon": "✓"},
                 {"text": "Cyber Insurance: <strong>Active</strong>", "icon": "✓"}
            ]
        },
        {
            "id": "CASE-UK-005",
            "company": "GovCorp Logistics",
            "jurisdiction": "UK Public Sector",
            "score": 72,
            "band": "Defensible",
            "percentile": "Top 22%",
            "fail_rate": "25%",
            "cost": "£12,000",
            "insights": [
                 {"text": "Modern Slavery Statement: <strong>Draft</strong> (Gap)", "icon": "⚠️"},
                 {"text": "Social Value: <strong>Strong</strong>", "icon": "✓"}
            ]
        }
    ]

    for p in personas:
        print(f"Running Simulation: {p['company']} ({p['jurisdiction']})...")
        try:
            path = generator.generate_report(
                company_name=p['company'],
                jurisdiction=p['jurisdiction'],
                score=p['score'],
                band=p['band'],
                percentile=p['percentile'],
                fail_rate=p['fail_rate'],
                cost_total=p['cost'],
                insights=p['insights']
            )
            print(f"✅ Generated: {path}")
            results.append({
                "case": p['id'],
                "company": p['company'],
                "status": "SUCCESS",
                "path": path,
                "value": "High" if p['score'] < 50 else "Medium" # Logic: More risk = Higher Urgency Value
            })
        except Exception as e:
            print(f"❌ Failed: {e}")
            results.append({"case": p['id'], "status": "FAILED", "error": str(e)})

    # Save Report
    report_path = r"F:\AION-ZERO\apps\inspector\TITAN_STRESS_TEST_LOG.json"
    with open(report_path, "w") as f:
        json.dump(results, f, indent=2)
    
    print("\n--- TEST COMPLETE ---")
    print(f"Log saved to: {report_path}")

if __name__ == "__main__":
    run_stress_test()
