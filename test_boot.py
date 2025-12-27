import sys
from pathlib import Path
import os

# Emulate Vercel Path Setup
root = Path(os.getcwd())
sys.path.append(str(root))

print(f"Checking imports from {root}...")

try:
    import bridge
    print("✅ Bridge package found.")
except ImportError as e:
    print(f"❌ Failed to find bridge package: {e}")

try:
    from bridge.bridge_api import app
    print("✅ Bridge API imported successfully.")
except Exception as e:
    print(f"❌ Failed to import Bridge API: {e}")
    import traceback
    traceback.print_exc()

print("Boot Test Complete.")
