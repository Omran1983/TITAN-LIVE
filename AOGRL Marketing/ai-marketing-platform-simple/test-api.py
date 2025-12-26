import requests
import json

url = "http://localhost:3003/api/generate-image"
payload = {
    "prompt": "a beautiful landscape with mountains and lake"
}
headers = {
    "Content-Type": "application/json"
}

try:
    response = requests.post(url, data=json.dumps(payload), headers=headers)
    print("Status Code:", response.status_code)
    print("Response:", response.json())
except Exception as e:
    print("Error:", str(e))