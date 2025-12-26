
import sys
import os
from pathlib import Path

# Setup Paths
TITAN_ROOT = Path(r"F:\AION-ZERO\TITAN")
APPS_DIR = TITAN_ROOT / "apps"
sys.path.append(str(TITAN_ROOT / "bridge"))
sys.path.append(str(APPS_DIR / "grant_writer"))

from tinns_generator import TinnsGenerator
from bridge_api import _extract_text_from_pdf_bytes

# Setup
generator = TinnsGenerator()
print("--- GENERATING TEST PROPOSAL ---")

# Test Case: Small Manufacturer (Logic: 'Lean Upgrade' + 'Made in Moris')
pdf_path = generator.generate_full_application(
    project_name="New manufacturing equipment",
    cost=40000.0,
    company_name="Logic Test Mfg",
    summary="We need to automate our packaging line.",
    eligibility_data={
        "turnover_band": "<50M",
        "sector": "Manufacturing",
        "urgency_level": "High",
        "documentation_ready": "Yes",
        "company_age_years": 5
    }
)
print(f"Artifact created: {pdf_path}")

# Verify Content
print("\n--- EXTRACTING TEXT CONTENT ---")
try:
    with open(pdf_path, "rb") as f:
        content = f.read()
        text = _extract_text_from_pdf_bytes(content)
        
    print(f"PDF Size: {len(content)} bytes")
    print("-" * 30)
    
    # Check for Key Phrases from 'Refined Copy'
    checks = [
        "TITAN PROJECT ARCHITECT",
        "EXECUTIVE SUMMARY",
        "operational need within the business",  # New Copy
        "Made in Moris / Equipment Support",      # Sector Logic
        "Lean Upgrade",                          # Budget Logic
        "Prioritised Speed Strategy",            # Urgency Logic
        "PROJECT PLAN READY FOR SCHEME REVIEW"   # Eligibility Badge
    ]
    
    for phrase in checks:
        if phrase in text:
            print(f"✅ FOUND: '{phrase}'")
        else:
            print(f"❌ MISSING: '{phrase}'")

except Exception as e:
    print(f"Verification Failed: {e}")
