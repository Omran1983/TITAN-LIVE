import json
import argparse
import datetime
from pathlib import Path

# Paths
RULES_PATH = Path("data/obligations.json")

def check_compliance(check_date_str: str, output_path: Path):
    print(f"🛡️  SENTINEL: Checking Compliance for {check_date_str}")
    
    if not RULES_PATH.exists():
        print("❌ Rules file missing.")
        return

    rules = json.loads(RULES_PATH.read_text(encoding="utf-8"))
    
    # Parse Date
    try:
        current_date = datetime.datetime.strptime(check_date_str, "%Y-%m-%d")
    except ValueError:
        current_date = datetime.datetime.now()
        
    day = current_date.day
    month = current_date.month
    year = current_date.year
    
    alerts = []
    
    for rule in rules:
        status = "OK"
        days_left = 999
        
        if rule["frequency"] == "Monthly":
            deadline_day = rule["deadline_day"]
            # Deadline is this month's 20th
            deadline_date = datetime.datetime(year, month, deadline_day)
            
            # If we are past the 20th, the deadline was for *this* month (Overdue) 
            # OR the next deadline is *next* month.
            # Usually compliance is for *previous* month's activity, due *this* month.
            # So if today is 25th, we missed the 20th.
            
            if day > deadline_day:
                 # Overdue for this month
                 days_left = deadline_day - day # Negative
                 status = "OVERDUE"
            else:
                # Upcoming
                days_left = deadline_day - day
                status = "PENDING"
                
            if 0 <= days_left <= 5:
                status = "URGENT"
        
        alerts.append({
            "rule": rule["name"],
            "authority": rule["authority"],
            "days_left": days_left,
            "status": status,
            "penalty": rule["penalty_desc"]
        })

    # Generate Report
    md = f"# 🛡️ Statutory Sentinel Report\n"
    md += f"**Date:** {check_date_str}\n\n"
    md += "| Obligation | Authority | Status | Days Left | Penalty |\n"
    md += "| :--- | :--- | :--- | :--- | :--- |\n"
    
    urgent_count = 0
    
    for a in alerts:
        icon = "✅"
        if a["status"] == "URGENT": icon = "⚠️"; urgent_count += 1
        if a["status"] == "OVERDUE": icon = "🚨"; urgent_count += 1
        
        md += f"| {icon} {a['rule']} | {a['authority']} | **{a['status']}** | {a['days_left']} | {a['penalty']} |\n"
        
    md += "\n---\n"
    if urgent_count == 0:
        md += "**Status:** All Clear. No immediate risks."
    else:
        md += f"**Status:** {urgent_count} Risks Detected. Action Required."
        
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(md, encoding="utf-8")
    print(f"✅ Compliance Report generated: {output_path}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--date", default=datetime.datetime.now().strftime("%Y-%m-%d"))
    ap.add_argument("--out", default="output/Compliance_Report.md")
    args = ap.parse_args()
    
    check_compliance(args.date, Path(args.out))

if __name__ == "__main__":
    main()
