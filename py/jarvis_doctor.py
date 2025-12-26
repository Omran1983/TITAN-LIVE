"""
JARVIS DOCTOR (PHASE 25)
------------------------
The "Field Medic" for AION-ZERO source code.
L4 Autonomy: Diagnoses logic errors and applies patches autonomously.

USAGE:
    python jarvis_doctor.py --diagnose "ERROR_TRACE..." --file "F:/..."
    python jarvis_doctor.py --auto-heal (Monitors logs)
"""

import os
import sys
import time
import json
import traceback
from jarvis_brain_local import JarvisBrain

# LOGS TO WATCH
WATCH_LIST = [
    r"F:\AION-ZERO\scripts\Jarvis-CommandsApi.log",
    r"F:\AION-ZERO\citadel\static\citadel_errors.log"
]

class JarvisDoctor:
    def __init__(self):
        self.brain = JarvisBrain()
        self.history = []

    def load_file(self, path):
        if not os.path.exists(path): return None
        try:
            with open(path, 'r', encoding='utf-8') as f:
                return f.read()
        except: return None

    def apply_patch(self, file_path, original_block, replacement_block):
        """Surgical intervention."""
        content = self.load_file(file_path)
        if not content: return False, "File not found"
        
        # Normalize line endings
        content = content.replace("\r\n", "\n")
        original_block = original_block.replace("\r\n", "\n").strip()
        replacement_block = replacement_block.replace("\r\n", "\n")
        
        # Backup
        backup_path = file_path + ".bak"
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(content)
            
        if original_block not in content:
            # Fuzzy match attempt (simple whitespace normalization)
            # This is risky, so we fail safe for now
            return False, "Original block not found exactly in file."
            
        new_content = content.replace(original_block, replacement_block)
        
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True, "Patch applied successfully."
        except Exception as e:
            return False, f"Write failed: {e}"

    def run_diagnosis(self, error_trace, file_path):
        print(f"[DOCTOR] paging Dr. Jarvis to {file_path}...")
        
        source = self.load_file(file_path)
        if not source:
            return {"error": "Source file inaccessible"}
            
        # 1. Diagnosis
        print("[DOCTOR] Analyzing symptoms (Error Trace + Source)...")
        diagnosis = self.brain.diagnose_error(error_trace, source)
        
        if not diagnosis or "root_cause" not in diagnosis:
            return {"error": "Brain failed to diagnose."}
            
        print(f"[DOCTOR] Diagnosis: {diagnosis.get('root_cause')}")
        print(f"[DOCTOR] Confidence: {diagnosis.get('confidence')}%")
        
        # 2. Patch Generation
        if diagnosis.get('confidence', 0) > 70:
            print("[DOCTOR] Confidence high. Preparing surgery (Genering Patch)...")
            patch = self.brain.generate_patch(source, diagnosis.get('fix_suggestion'))
            
            if patch and "original_block" in patch:
                return {
                    "diagnosis": diagnosis,
                    "patch": patch,
                    "file_path": file_path
                }
        
        return {"diagnosis": diagnosis, "status": "Observation only (Low Confidence)"}

if __name__ == "__main__":
    doc = JarvisDoctor()
    
    # CLI Mode
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--diagnose", help="Error trace string")
    parser.add_argument("--file", help="Path to faulting file")
    args = parser.parse_args()
    
    if args.diagnose and args.file:
        result = doc.run_diagnosis(args.diagnose, args.file)
        print(json.dumps(result, indent=2))
    else:
        print("[DOCTOR] Standing by.")
