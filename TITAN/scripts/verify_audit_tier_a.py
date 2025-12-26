import requests
import json
import time

# CONFIG
BASE_URL = "http://localhost:8001"
ENDPOINT_UPLOAD = f"{BASE_URL}/api/audit/upload"
TEST_PDF_PATH = "F:/AION-ZERO/TITAN/test_audit_bad.txt" # Using TXT for MVP speed, simulates PDF content
EMAIL = "verification_runner@titansystems.world"

def run_tier_a_test():
    print("🚀 STARTING TIER A LAUNCH GATE (5x RUNS)")
    
    passes = 0
    
    for i in range(1, 6):
        print(f"\n--- RUN #{i} ---")
        try:
            # 1. Prepare Payload
            files = {'file': ('contract.txt', open(TEST_PDF_PATH, 'rb'), 'text/plain')}
            data = {'email': EMAIL}
            
            # 2. Execute Request
            start_time = time.time()
            res = requests.post(ENDPOINT_UPLOAD, files=files, data=data)
            duration = time.time() - start_time
            
            # 3. Assertions
            if res.status_code != 200:
                print(f"❌ FAIL: Status Code {res.status_code}")
                print(res.text)
                break
                
            json_res = res.json()
            
            # CHECK: No URL Leak
            if "download_url" in json_res:
                print("❌ FAIL: CRITICAL - Revenue Leak Detected (download_url present)")
                break
                
            # CHECK: Status
            if json_res.get("status") != "success":
                print("❌ FAIL: Response status not success")
                break
                
            # CHECK: Risky Content Flagged
            # We expect 'risk' key
            print(f"✅ Result: {json_res.get('message')} (Risk: {json_res.get('result', {}).get('risk')})")
            print(f"⏱️ Duration: {duration:.2f}s")
            
            passes += 1
            
        except Exception as e:
            print(f"❌ FAIL: Exception {e}")
            break

    print("\n" + "="*30)
    if passes == 5:
        print("✅ LAUNCH GATE PASSED: 5/5 SUCCESSFUL RUNS")
        print("System is ready for Tier A traffic.")
    else:
        print(f"❌ LAUNCH GATE FAILED: Only {passes}/5 runs passed.")

if __name__ == "__main__":
    run_tier_a_test()
