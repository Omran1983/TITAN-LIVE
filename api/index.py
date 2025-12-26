import sys
from pathlib import Path

# Add bridge directory to path so imports work
current_dir = Path(__file__).parent.resolve()
root_dir = current_dir.parent
sys.path.append(str(root_dir / "bridge"))

# Import the FastAPI app
try:
    from bridge.bridge_api import app
except ImportError:
    # Fallback if Vercel path structure is flat
    sys.path.append(str(root_dir))
    from bridge.bridge_api import app
