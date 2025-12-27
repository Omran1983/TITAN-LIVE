import sys
import os
import traceback
from pathlib import Path
from fastapi import FastAPI
from fastapi.responses import PlainTextResponse

# Add ROOT directory to path so we can import 'bridge' as a module
current_dir = Path(__file__).parent.resolve()
root_dir = current_dir.parent
sys.path.append(str(root_dir)) # Add root

# Import the FastAPI app
try:
    # Try importing strict package style first
    from bridge.bridge_api import app as titan_app
    app = titan_app
except Exception as e:
    # FALLBACK DEBUG APP
    print(f"CRITICAL IMPORT ERROR: {e}")
    trace = traceback.format_exc()
    
    app = FastAPI()
    
    # Simple Ping to prove life
    @app.get("/ping")
    def ping():
        return {"status": "alive", "message": "Index.py is running, Bridge failed."}

    @app.get("/")
    @app.get("/{catchall:path}")
    def debug_error(catchall: str = ""):
        # List files to prove availability
        files = []
        try:
            for r, d, f in os.walk(str(root_dir)):
                for file in f:
                    files.append(os.path.join(r, file))
        except:
            files = ["Could not walk dirs"]

        return PlainTextResponse(
            f"TITAN BOOT ERROR (500 Caught)\n"
            f"================\n"
            f"{trace}\n\n"
            f"SYS.PATH:\n{sys.path}\n\n"
            f"ROOT DIR: {root_dir}\n"
            f"FILES ON SERVER:\n" + "\n".join(files[:100])
        )

