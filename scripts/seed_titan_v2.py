import sys
import os
import datetime

# Add 'py' to path to import brain
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'py')))
from jarvis_brain_local import JarvisBrain

def seed():
    print(">>> TITAN V2 AUTO-SEEDER <<<")
    
    try:
        brain = JarvisBrain()
        db = brain.db
        if not db:
            raise RuntimeError("Supabase not connected")
            
        slug = "aogrl_deliveries"
        print(f"Checking business: {slug}...")
        
        # 1. Get/Create Business
        res = db.table("az_businesses").select("id").eq("slug", slug).execute()
        if not res.data:
            print("Business not found. Creating it...")
            res = db.table("az_businesses").insert({
                "slug": slug, 
                "name": "AOGRL Deliveries",
                "currency": "MUR"
            }).execute()
            biz_id = res.data[0]['id']
        else:
            biz_id = res.data[0]['id']
            
        print(f"Business ID: {biz_id}")

        # 2. Clear Today's Data (Idempotency)
        # Note: In real prod we wouldn't delete, but this is a demo/seed tool
        today_str = datetime.date.today().isoformat()
        # Complex deletes might be hard via simple SDK if RLS is on, but let's try
        # Actually, let's just append. It's fine for a demo.
        
        # 3. Insert Sales
        print("Injecting Sales...")
        sales = [
            {"business_id": biz_id, "amount": 2500.00, "type": "service_invoice", "source": "manual", "customer_name": "Grand Baie Resort", "notes": "Logistics Contract #101"},
            {"business_id": biz_id, "amount": 1200.00, "type": "service_invoice", "source": "manual", "customer_name": "Cybercity Office", "notes": "Express Doc Run"},
            {"business_id": biz_id, "amount": 4500.00, "type": "service_invoice", "source": "manual", "customer_name": "Event Planner Ltd", "notes": "Van Hire Full Day"}
        ]
        db.table("az_sales_events").insert(sales).execute()

        # 4. Insert Expenses
        print("Injecting Expenses...")
        expenses = [
            {"business_id": biz_id, "amount": 850.00, "category": "fuel", "notes": "Diesel Van 1"},
            {"business_id": biz_id, "amount": 200.00, "category": "meals", "notes": "Driver Lunch"}
        ]
        db.table("az_expense_events").insert(expenses).execute()
        
        # 5. Insert Deliveries
        print("Injecting Deliveries...")
        delivs = [
            {"business_id": biz_id, "ref_code": "JOB-101", "client_name": "Grand Baie Resort", "address": "Coastal Rd", "status": "delivered"},
            {"business_id": biz_id, "ref_code": "JOB-102", "client_name": "Cybercity Office", "address": "Ebene", "status": "delivered"},
            {"business_id": biz_id, "ref_code": "JOB-103", "client_name": "Private Client", "address": "Flic en Flac", "status": "pending"}
        ]
        db.table("az_deliveries").insert(delivs).execute()

        print(">>> SUCCESS: Data Injected. Check Dashboard.")
        
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    seed()
