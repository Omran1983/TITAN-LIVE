"""
Generate Synthetic Employee Data for AOGRL
150 Locals, 60 Imported Labor.
Injects controlled violations for PRB/Labour Law testing.
"""
import csv
import random
from faker import Faker
from datetime import datetime, timedelta

fake = Faker()

# Custom Name Banks for Authenticity
LOCAL_FIRST = ["Rajesh", "Marie", "Jean-Claude", "Fatima", "Kevin", "Aarav", "Priya", "Stephan", "Yusuf", "Vidya", "Kinsley", "Anoushka", "Devaraj", "Clara"]
LOCAL_LAST = ["Moutou", "Sharma", "Dupont", "Khan", "Li", "Appadoo", "Payet", "Singh", "Pillay", "Lecordier", "Gobin", "Ramgoolam"]

EXPAT_FIRST = ["Mamun", "Rafiq", "Andry", "Solofo", "Kumar", "Wei", "Zhang", "Ravi", "Mamadou", "Sanjay"]
EXPAT_LAST = ["Hossain", "Islam", "Rakoto", "Rajaonarivelo", "Patel", "Chen", "Wu", "Gupta", "Diallo", "Mishra"]

EASTER_EGGS = ["Tony Stark", "Bruce Wayne", "Clark Kent", "Diana Prince", "Wade Wilson"]

def get_creative_name(is_local=True):
    if random.random() < 0.02: # 2% chance of Easter Egg
        return random.choice(EASTER_EGGS)
    
    if is_local:
        return f"{random.choice(LOCAL_FIRST)} {random.choice(LOCAL_LAST)}"
    else:
        return f"{random.choice(EXPAT_FIRST)} {random.choice(EXPAT_LAST)}"

OUTPUT_FILE = "F:/AION-ZERO/data/clients/AOGRL-001/inbox/aogrl_test_data_210.csv"

def generate_data():
    employees = []
    
    # 1. Locals (150)
    for i in range(150):
        # 10% chance of salary violation (below 16500)
        is_violation_salary = random.random() < 0.1
        salary = random.randint(15500, 16400) if is_violation_salary else random.randint(17000, 45000)
        
        # 10% chance of leave violation (> 21 days)
        leave = random.randint(22, 30) if random.random() < 0.1 else random.randint(0, 21)
        
        employees.append({
            "employee_id": f"LOC-{i+1:03d}",
            "full_name": get_creative_name(is_local=True),
            "hire_date": fake.date_between(start_date='-5y', end_date='-1y'),
            "salary": salary, 
            "job_grade": random.choice(["G1", "G2", "G3", "Manager"]),
            "contract_type": "Permanent",
            "performance_status": random.choice(["Satisfactory", "Good", "Excellent"]),
            "increment_proposed": "True",  # Matches schema value type (boolean string)
            "leave_taken_annual": leave, # Matches schema
            "leave_taken_sick": random.randint(0, 10), # Matches schema
            "overtime_hours": random.randint(0, 20)
        })

    # 2. Imported Labor (60)
    for i in range(60):
        # Expats usually strictly managed
        leave = random.randint(22, 40) if random.random() < 0.05 else random.randint(0, 21)
        
        employees.append({
            "employee_id": f"EXP-{i+1:03d}",
            "full_name": get_creative_name(is_local=False), # Expat names
            "hire_date": fake.date_between(start_date='-2y', end_date='today'),
            "salary": random.randint(25000, 80000), 
            "job_grade": "Specialist",
            "contract_type": "Fixed-Term", # Expat
            "performance_status": "Good",
            "increment_proposed": "False",
            "leave_taken_annual": leave,
            "leave_taken_sick": random.randint(0, 5),
            "overtime_hours": random.randint(0, 50) 
        })
        
    # Write CSV (Strict Schema)
    with open(OUTPUT_FILE, 'w', newline='') as f:
        fieldnames = ["employee_id", "full_name", "salary", "performance_status", 
                      "increment_proposed", "hire_date", "job_grade", "contract_type",
                      "leave_taken_annual", "leave_taken_sick", "overtime_hours"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(employees)
        
    print(f"Generated {len(employees)} rows at {OUTPUT_FILE}")

if __name__ == "__main__":
    generate_data()
