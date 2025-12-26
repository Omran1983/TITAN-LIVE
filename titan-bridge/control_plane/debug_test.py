import os

# Set Env Vars directly
os.environ["SUPABASE_URL"] = "https://abkprecmhitqmmlzxfad.supabase.co"
os.environ["SUPABASE_SERVICE_ROLE_KEY"] = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFia3ByZWNtaGl0cW1tbHp4ZmFkIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTk0NzY1OSwiZXhwIjoyMDc1NTIzNjU5fQ.-NrAHBNJOefsKpN_UIKhHNSukh7-ABO13IQjfNLswY4"
os.environ["TELEGRAM_BOT_TOKEN"] = "8284941437:AAElTu-RcyN3dNv5jcrhJpknRgz4_akuPeI"
os.environ["TELEGRAM_WEBHOOK_SECRET"] = ""

from app import app
from fastapi.testclient import TestClient

client = TestClient(app)

print("--- Sending /status ---")
try:
    response = client.post(
        "/telegram/webhook",
        json={"message": {"chat": {"id": "123"}, "text": "/status"}}
    )
    print(f"Status: {response.status_code}")
    print(f"Body: {response.text}")
except Exception as e:
    import traceback
    traceback.print_exc()

print("\n--- Sending /run inspect ---")
try:
    response = client.post(
        "/telegram/webhook",
        json={"message": {"chat": {"id": "123"}, "text": "run inspect"}}
    )
    print(f"Status: {response.status_code}")
    print(f"Body: {response.text}")
except Exception as e:
    import traceback
    traceback.print_exc()
