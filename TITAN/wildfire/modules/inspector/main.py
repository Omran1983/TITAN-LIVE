import os
import sys
import time
import httpx

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.append(PROJECT_ROOT)

from wildfire.core.utils import SupabaseClient, now_iso

class InspectorAgent:
    def __init__(self):
        self.sb = SupabaseClient()
        self.agent_id = "AGENT_INSPECTOR"

    def inspect_url(self, url: str) -> list:
        findings = []
        try:
            r = httpx.get(url, timeout=10)
            if r.status_code >= 400:
                findings.append({
                    "type": "http_status",
                    "severity": "high",
                    "evidence": {"status": r.status_code, "url": url}
                })
        except Exception as e:
            findings.append({
                "type": "connection_error",
                "severity": "critical",
                "evidence": {"error": str(e), "url": url}
            })
        return findings

    def execute(self, cmd: dict):
        cid = cmd['command_id']
        inputs = cmd.get('inputs', {})
        target_url = inputs.get('url', 'http://localhost:3000')

        print(f"[{self.agent_id}] Inspecting {target_url} for {cid}...")
        
        self.sb.patch("az_commands", f"command_id=eq.{cid}", {
            "state": "RUNNING",
            "progress": 10
        })

        findings = self.inspect_url(target_url)

        report = {
            "report_id": f"rep_{int(time.time())}",
            "request_id": cid,
            "summary": f"Inspection of {target_url} complete. Found {len(findings)} issues.",
            "findings": findings,
            "signed": True,
            "signature": {"mock": "sig_confirmed"}
        }

        self.sb.insert("az_inspect_reports", report)
        self.sb.emit_event(self.agent_id, "inspection_complete", report['summary'], command_id=cid, payload=report)

        self.sb.patch("az_commands", f"command_id=eq.{cid}", {
            "state": "DONE",
            "result": {"report_id": report['report_id'], "issues": len(findings)}
        })

    def run_poll(self):
        print(f"{self.agent_id} Polling...")
        while True:
            time.sleep(5)

if __name__ == "__main__":
    InspectorAgent().run_poll()
