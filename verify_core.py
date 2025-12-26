
import sys
import os
from pathlib import Path

# Setup Paths
TITAN_ROOT = Path(r"F:\AION-ZERO\TITAN")
APPS_DIR = TITAN_ROOT / "apps"
sys.path.append(str(TITAN_ROOT / "bridge"))
sys.path.append(str(APPS_DIR / "grant_writer"))
sys.path.append(str(APPS_DIR / "audit"))

def check_component(name, import_fn):
    print(f"[*] Checking {name}...", end=" ", flush=True)
    try:
        import_fn()
        print("OK")
        return True
    except Exception as e:
        print(f"FAILED")
        print(f"    Error: {e}")
        return False

def verify_bridge():
    import bridge_api
    # Check if app is defined
    if not hasattr(bridge_api, 'app'):
        raise ImportError("bridge_api module missing 'app' instance")

def verify_grant_writer():
    from tinns_generator import TinnsGenerator
    # Instantiate to check init logic
    gen = TinnsGenerator()
    if not gen:
        raise ValueError("TinnsGenerator instantiation failed")

def verify_audit_engine():
    from audit_engine import ContractAuditor
    auditor = ContractAuditor()
    if not auditor:
        raise ValueError("ContractAuditor instantiation failed")

def main():
    print("=== TITAN SYSTEM DIAGNOSTIC ===")
    
    results = {
        "TITAN Bridge (API Layer)": check_component("Bridge API", verify_bridge),
        "JARVIS (Grant Writer)": check_component("Grant Writer Engine", verify_grant_writer),
        "TITAN (Audit Engine)": check_component("Audit Engine", verify_audit_engine)
    }
    
    print("-" * 30)
    success = all(results.values())
    if success:
        print("✅ ALL SYSTEMS OPERATIONAL")
        sys.exit(0)
    else:
        print("❌ SYSTEM FAILURES DETECTED")
        sys.exit(1)

if __name__ == "__main__":
    main()
