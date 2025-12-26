import sys
import os

# Add root to path
sys.path.append("F:\\AION-ZERO\\TITAN")

print(">>> TITAN v2 PROOF OF LIFE <<<")

try:
    print("[1/7] Import Core Dispatcher...", end=" ")
    from wildfire.core.dispatcher import WildfireDispatcher
    d = WildfireDispatcher()
    print(f"OK. Loaded {len(d.manifests)} manifests.")
except Exception as e:
    print(f"FAIL: {e}")

try:
    print("[2/7] Import Context Assembler...", end=" ")
    from wildfire.modules.context_assembler.main import ContextAssembler
    a = ContextAssembler()
    print(f"OK. Agent ID: {a.agent_id}")
except Exception as e:
    print(f"FAIL: {e}")

try:
    print("[3/7] Import Inspector...", end=" ")
    from wildfire.modules.inspector.main import InspectorAgent
    i = InspectorAgent()
    print(f"OK. Agent ID: {i.agent_id}")
except Exception as e:
    print(f"FAIL: {e}")

try:
    print("[4/7] Import Workflow Conductor...", end=" ")
    from wildfire.modules.workflow_conductor.main import WorkflowConductor
    w = WorkflowConductor()
    print(f"OK. Agent ID: {w.agent_id}")
except Exception as e:
    print(f"FAIL: {e}")

try:
    print("[5/7] Import Ingestion Hydra...", end=" ")
    from wildfire.modules.ingestion_hydra.main import IngestionHydra
    h = IngestionHydra()
    print(f"OK. Agent ID: {h.agent_id}")
except Exception as e:
    print(f"FAIL: {e}")

try:
    print("[6/7] Import BitNet Router...", end=" ")
    from wildfire.modules.bitnet_router.main import BitNetRouter
    b = BitNetRouter()
    print(f"OK. Agent ID: {b.agent_id}")
except Exception as e:
    print(f"FAIL: {e}")

try:
    print("[7/7] Check Atoms...", end=" ")
    if os.path.exists("F:\\AION-ZERO\\TITAN\\wildfire\\modules\\atoms\\browser_atom.py") and \
       os.path.exists("F:\\AION-ZERO\\TITAN\\wildfire\\modules\\atoms\\email_atom.py"):
       print("OK. Atoms present.")
    else:
       print("FAIL. Missing atoms.")
except Exception as e:
    print(f"FAIL: {e}")

print("\n>>> VERIFICATION COMPLETE <<<")
