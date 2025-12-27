import sys
from pathlib import Path

# Add ROOT directory to path so we can import 'bridge' as a module
current_dir = Path(__file__).parent.resolve()
root_dir = current_dir.parent
sys.path.append(str(root_dir)) # Add F:/AION-ZERO

# Import the FastAPI app
try:
    from bridge.bridge_api import app
except ImportError as e:
    print(f"Start Error: {e}")
    raise e

