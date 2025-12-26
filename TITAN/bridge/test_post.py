import requests
import json
from pathlib import Path

payload_path = Path(r"F:\AION-ZERO\TITAN\io\work\task_020_payload.json")
payload = json.loads(payload_path.read_text())

try:
    r = requests.post("http://127.0.0.1:7788/v1/tasks", json=payload)
    print(f"Status: {r.status_code}")
    print(r.json())
except Exception as e:
    print(f"Error: {e}")
