import os
import sys
import time

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.append(PROJECT_ROOT)

from wildfire.core.utils import SupabaseClient, now_iso

class IngestionHydra:
    def __init__(self):
        self.sb = SupabaseClient()
        self.agent_id = "AGENT_INGESTION_HYDRA"
        self.inbox_path = os.path.join(PROJECT_ROOT, "wildfire", "inbox")
        os.makedirs(self.inbox_path, exist_ok=True)

    def ingest(self, cmd: dict):
        cid = cmd['command_id']
        payload = cmd.get('payload', {})
        source_url = payload.get('url')
        
        print(f"[{self.agent_id}] Ingesting {source_url} for {cid}...")
        
        self.sb.patch("az_commands", f"command_id=eq.{cid}", {
            "state": "RUNNING",
            "progress": 5
        })

        # 1. Download / Acquire
        # Mock download
        doc_name = source_url.split('/')[-1] if source_url else f"doc_{cid}.pdf"
        local_path = os.path.join(self.inbox_path, doc_name)
        
        # 2. Pipeline: OCR -> Markdown
        self.sb.emit_event(self.agent_id, "pipeline_start", "Starting OCR process", command_id=cid)
        time.sleep(1) # Simulation
        
        extracted_text = f"# Extracted Content from {doc_name}\n\n[MOCK CONTENT: This would be the OCR result.]"
        
        # 3. Store Artifact
        artifact_id = f"art_{int(time.time())}"
        self.sb.insert("az_artifacts", {
            "artifact_id": artifact_id,
            "job_id": cid,
            "type": "markdown",
            "content": extracted_text,
            "metadata": {"source": source_url}
        })

        self.sb.patch("az_commands", f"command_id=eq.{cid}", {
            "state": "DONE",
            "result": {"artifact_id": artifact_id, "status": "processed"}
        })
        print(f"[{self.agent_id}] Ingestion complete.")

    def run_poll(self):
        print(f"{self.agent_id} Polling...")
        while True:
            time.sleep(5)

if __name__ == "__main__":
    IngestionHydra().run_poll()
