import sys
import os
from pathlib import Path

# Add current dir to path to find local modules
sys.path.append(str(Path(__file__).parent))

from run_worker import process_run

cid = "AOGRL-001"
# Ensure the path is correct relative to where we run or absolute
csv_path = "F:/AION-ZERO/data/clients/AOGRL-001/inbox/aogrl_test_data_210.csv"
month = "2025-12"

print(f"🚀 Starting Debug Run for {cid}...")
result = process_run(cid, csv_path, month)

print("--- Result ---")
print(result)

if result['status'] == 'SUCCESS':
    print(f"✅ PDF Generated: {result['pdf_path']}")
else:
    print(f"❌ Failed: {result.get('error')}")
