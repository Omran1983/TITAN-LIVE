import json
import argparse
from pathlib import Path

# Simple Red Flag Dictionary
RISK_PATTERNS = {
    "indemnity": {
        "score": 15,
        "warning": "Indemnification Clause detected. Ensure mutual indemnification."
    },
    "unlimited liability": {
        "score": 25,
        "warning": "Unlimited Liability detected. Capping is recommended."
    },
    "termination for convenience": {
        "score": 10,
        "warning": "Termination for Convenience found. Negotiate notice period."
    },
    "jurisdiction": {
        "score": 5,
        "warning": "Check Jurisdiction clause. Ensure it is neutral."
    },
    "liquidated damages": {
        "score": 10,
        "warning": "Liquidated Damages detected. Verify cap amounts."
    },
    "non-compete": {
        "score": 20,
        "warning": "Non-Compete clause found. Verify duration and scope."
    }
}

def analyze_contract(text_path: Path, output_path: Path):
    print(f"[RISK] Analyzing {text_path}...")
    
    if not text_path.exists():
        return {"error": "File not found"}
        
    text = text_path.read_text(encoding="utf-8").lower()
    
    findings = []
    total_risk_score = 0
    
    for phrase, info in RISK_PATTERNS.items():
        if phrase in text:
            findings.append({
                "type": phrase,
                "warning": info["warning"],
                "impact": info["score"]
            })
            total_risk_score += info["score"]
            
    # Normalize score (0-100)
    risk_level = "LOW"
    if total_risk_score > 30: risk_level = "MEDIUM"
    if total_risk_score > 60: risk_level = "HIGH"
    if total_risk_score > 80: risk_level = "CRITICAL"
    
    result = {
        "ok": True,
        "risk_level": risk_level,
        "risk_score": total_risk_score,
        "findings": findings,
        "clause_count_analyzed": len(text.split('.')) # Approx sentence count
    }
    
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(f"[SUCCESS] Risk Analysis saved to {output_path}")
    return result

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", required=True)
    ap.add_argument("--out", dest="out", required=True)
    args = ap.parse_args()
    
    analyze_contract(Path(args.inp), Path(args.out))

if __name__ == "__main__":
    main()
