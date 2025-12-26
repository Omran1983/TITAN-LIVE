import os
import zipfile
import datetime

# AION-ZERO MARKETPLACE PACKAGER
# ------------------------------
# Bundles modules into commercial-ready SKUs.

PRODUCTS = {
    "REFLEX_ENGINE_PRO": {
        "files": [
            "py/reflex_engine.py",
            "scripts/Jarvis-ReflexEngine.ps1",
            "sql/az_reflex.sql"
        ],
        "readme": "AION-ZERO Reflex Engine: Self-healing infrastructure for your enterprise."
    },
    "COMMANDER_COO": {
        "files": [
            "scripts/Jarvis-Commander.ps1",
            "scripts/Jarvis-RevenueGenerator.ps1",
        ],
        "readme": "AION-ZERO Commander: Autonomous strategy and revenue generation."
    },
    "CITADEL_UI": {
        "files": [
            "citadel/", # Recursive
            "scripts/Jarvis-Citadel.ps1"
        ],
        "readme": "The Glass Citadel: A futuristic dashboard for AI oversight."
    }
}

OUT_DIR = "F:/AION-ZERO/products"
os.makedirs(OUT_DIR, exist_ok=True)

def package(sku):
    print(f"Packaging {sku}...")
    manifest = PRODUCTS[sku]
    ts = datetime.datetime.now().strftime("%Y%m%d")
    zip_name = f"{sku}_{ts}.zip"
    zip_path = os.path.join(OUT_DIR, zip_name)
    
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as z:
        # Add Files
        for item in manifest['files']:
             # Handle Dir (Recursive)
            path = os.path.join("F:/AION-ZERO", item)
            if os.path.isdir(path):
                for root, dirs, files in os.walk(path):
                    for file in files:
                        abs_path = os.path.join(root, file)
                        rel_path = os.path.relpath(abs_path, "F:/AION-ZERO")
                        if "__pycache__" not in rel_path:
                             z.write(abs_path, arcname=rel_path)
            elif os.path.exists(path):
                z.write(path, arcname=item)
            else:
                print(f"  [WARN] Missing: {item}")
        
        # Add Readme
        z.writestr("README.txt", manifest['readme'])
        z.writestr("LICENSE", "Commercial License - Property of AION-ZERO.")
        
    print(f"  -> Generated: {zip_path}")

if __name__ == "__main__":
    for p in PRODUCTS:
        package(p)
