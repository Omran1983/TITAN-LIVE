
import os
import sys
import json
import time
import shutil
import glob
from pathlib import Path
from datetime import datetime

# CONFIG PATHS
RUNNER_ROOT = Path(__file__).parent.parent
INBOX = RUNNER_ROOT / "io" / "inbox"
OUTBOX = RUNNER_ROOT / "io" / "outbox"
WORK = RUNNER_ROOT / "io" / "work"
ARTIFACTS = RUNNER_ROOT / "io" / "artifacts"
LOGS = RUNNER_ROOT / "runner" / "logs"
POLICIES = RUNNER_ROOT / "policies"

# Ensure dirs
for p in [INBOX, OUTBOX, WORK, ARTIFACTS, LOGS]:
    p.mkdir(parents=True, exist_ok=True)

class TitanRunner:
    def __init__(self):
        self.allowlist = self._load_allowlist()
        self.log_file = LOGS / "runner.log"

    def _log(self, msg):
        ts = datetime.now().isoformat()
        entry = f"[{ts}] {msg}"
        print(entry)
        with open(self.log_file, "a", encoding="utf-8") as f:
            f.write(entry + "\n")

    def _load_allowlist(self):
        path = POLICIES / "tool_allowlist.json"
        if not path.exists():
            print(f"CRITICAL: Policy file missing at {path}")
            sys.exit(1)
        return json.loads(path.read_text())

    def validate_task_schema(self, task_data):
        # In a real impl, use jsonschema lib. For now, basic check.
        required = ["task_id", "request", "limits"]
        for r in required:
            if r not in task_data:
                return False, f"Missing field: {r}"
        return True, ""

    def process_task(self, task_path):
        task_id = "unknown"
        started_at = datetime.now().isoformat()
        
        try:
            # 1. READ
            try:
                task_data = json.loads(task_path.read_text())
                task_id = task_data.get("task_id", "unknown")
            except Exception as e:
                self._log(f"ERROR: Failed to parse {task_path.name}: {e}")
                shutil.move(str(task_path), str(INBOX / f"{task_path.name}.failed"))
                return

            self._log(f"STARTING Task: {task_id} ({task_path.name})")

            # 2. VALIDATE
            valid, err = self.validate_task_schema(task_data)
            if not valid:
                self._fail_task(task_data, f"Schema Violation: {err}", started_at)
                shutil.move(str(task_path), str(INBOX / f"{task_path.name}.invalid"))
                return

            # 3. PREPARE WORKSPACE
            job_work_dir = WORK / task_id
            job_work_dir.mkdir(parents=True, exist_ok=True)

            # 4. EXECUTE (Real Tool Logic)
            task_req = task_data.get("request", {})
            task_type = task_req.get("type", "")
            
            # Import Tools Dynamically (or hardcode for now)
            try:
                from tools.http_get import run_http_get
            except ImportError:
                # Fallback if run as module
                from runner.tools.http_get import run_http_get
            
            audit_events = []
            status = "success"
            summary_text = "Task Execution Complete"
            key_outputs = []
            artifacts_list = []

            # --- LOGIC: PLAN EXECUTION ---
            plan = task_data.get("plan", [])
            if not plan:
                 # Fallback: check inside request
                 plan = task_req.get("plan", [])

            if plan:
                self._log(f"Executing Plan with {len(plan)} steps.")
                for step in plan:
                    tool_name = step.get("tool", "")
                    tool_args = step.get("action", {})
                    step_id = step.get("step_id", str(step.get("step", 0)))
                    
                    self._log(f"Step {step_id}: {tool_name}")
                    
                    tool_res = {"ok": False, "error": "Unknown tool"}

                    # Dispatcher
                    if tool_name == "http.get":
                        t_start = datetime.now().isoformat()
                        # Map args: clean architecture uses 'url'
                        tool_res = run_http_get(tool_args, self.allowlist)
                        t_end = datetime.now().isoformat()
                        
                        audit_events.append({
                            "tool": "http.get",
                            "ok": tool_res["ok"],
                            "started_at": t_start,
                            "finished_at": t_end,
                            "error": tool_res.get("error"),
                            "details": f"Status: {tool_res.get('status_code')}"
                        })
                        
                        if tool_res["ok"]:
                            # Auto-save HTML artifacts
                            fn = f"step_{step_id}_artifact.html"
                            art_path = ARTIFACTS / fn
                            try:
                                text_content = tool_res.get("text", "")
                                art_path.write_text(text_content, encoding="utf-8")
                                artifacts_list.append({
                                    "path": str(art_path),
                                    "label": f"Step {step_id} Output",
                                    "mime": "text/html",
                                    "bytes": len(text_content)
                                })
                                key_outputs.append(str(art_path))
                            except Exception as e:
                                self._log(f"Failed to save artifact: {e}")
                    
                    elif tool_name == "file.write":
                        path = tool_args.get("path")
                        content = tool_args.get("content")
                        if path and content:
                             # Basic implementation logic
                             pass
                    
                    elif tool_name == "python.run":
                        # Placeholder for future implementation
                        pass

                    elif tool_name == "browser.open":
                        res = self._exec_browser_open(tool_args)
                        audit_events.append({"tool": tool_name, "ok": True, "result": res})

                summary_text = f"Executed {len(plan)} steps."
            
            # --- LOGIC: WEBSITE REVIEW (Legacy Support) ---
            elif task_type == "website_review":
                # ... (keep existing logic) ...
                url = target.get("url")
                
                self._log(f"Running Website Review for: {url}")
                
                # Check 1: HTTP GET
                t_start = datetime.now().isoformat()
                http_result = run_http_get({"url": url}, self.allowlist)
                t_end = datetime.now().isoformat()
                
                audit_events.append({
                    "tool": "http.get",
                    "ok": http_result["ok"],
                    "started_at": t_start,
                    "finished_at": t_end,
                    "error": http_result.get("error"),
                    "details": f"Status: {http_result.get('status_code')}"
                })
                
                if http_result["ok"]:
                    # Create Artifact
                    fn = f"audit_{task_id}.html"
                    art_path = ARTIFACTS / fn
                    try:
                        # Write raw text (HTML)
                        text_content = http_result.get("text", "")
                        art_path.write_text(text_content, encoding="utf-8")
                        
                        artifacts_list.append({
                            "path": str(art_path),
                            "label": "Raw HTML Source",
                            "mime": "text/html",
                            "bytes": len(text_content)
                        })
                        key_outputs.append(str(art_path))
                        summary_text = f"Successfully crawled {url}. Size: {len(text_content)} bytes."
                    except Exception as e:
                        summary_text = f"Crawled {url} but failed to save artifact: {e}"
                        status = "partial"
                else:
                    status = "failed"
                    summary_text = f"Failed to fetch {url}: {http_result.get('error')}"

            # --- LOGIC: HEALTH CHECK (Legacy) ---
            elif "healthcheck" in task_id:
                 # ... existing healthcheck logic ...
                self._log("Running Internal Health Check...")
                audit_events.append({
                    "tool": "policy.check",
                    "ok": True,
                    "started_at": datetime.now().isoformat(),
                    "finished_at": datetime.now().isoformat(),
                    "details": "Allowlist loaded successfully"
                })
                hello_file = ARTIFACTS / "hello.txt"
                hello_file.write_text(f"Hello from TITAN! Task ID: {task_id}")
                audit_events.append({
                    "tool": "file.write",
                    "ok": True,
                    "started_at": datetime.now().isoformat(),
                    "finished_at": datetime.now().isoformat(),
                    "details": str(hello_file)
                })
                summary_text = "Health Check Passed."
                key_outputs.append(str(hello_file))


            # 5. WRITE RESULT
            finished_at = datetime.now().isoformat()
            result = {
                "version": "1.0",
                "task_id": task_id,
                "status": status,
                "started_at": started_at,
                "finished_at": finished_at,
                "summary": {
                    "what_happened": summary_text,
                    "key_outputs": key_outputs,
                    "next_actions": []
                },
                "artifacts": artifacts_list,
                "audit": {
                    "tool_calls": audit_events,
                    "warnings": [],
                    "policy_violations": []
                }
            }


            out_path = OUTBOX / f"result_{task_id}.json"
            out_path.write_text(json.dumps(result, indent=2))
            
            # 6. ARCHIVE INPUT
            shutil.move(str(task_path), str(INBOX / f"{task_path.name}.done"))
            self._log(f"COMPLETED Task: {task_id}. Result: {out_path}")

        except Exception as e:
            self._log(f"CRITICAL ERROR processing {task_id}: {e}")
            # Try to write failure result
    
    def _exec_browser_open(self, action: dict) -> str:
        """Opens a URL in the default system browser."""
        import webbrowser
        url = action.get("url")
        if not url:
            raise ValueError("browser.open requires 'url'")
        
        self._log(f"Opening Browser: {url}")
        webbrowser.open(url)
        return "Browser opened."

    def _fail_task(self, task_data, reason, started_at):
        # Implementation to write failed result.json
        pass

    def run(self):
        self._log("TITAN RUNNER vNext (Laptop-First) Online. Polling Inbox...")
        try:
            while True:
                # Poll Inbox
                tasks = list(INBOX.glob("*.json"))
                # Filter out .done, .failed, .invalid if glob picks them up (it shouldn't if named properly)
                # Convention: task_XYZ.json
                
                active_tasks = [t for t in tasks if not t.name.endswith(".done") and not t.name.endswith(".failed") and not t.name.endswith(".invalid")]
                
                if active_tasks:
                    self._log(f"Found {len(active_tasks)} pending tasks.")
                    for t in active_tasks:
                        self.process_task(t)
                
                time.sleep(2)
        except KeyboardInterrupt:
            self._log("Runner Stopping...")

if __name__ == "__main__":
    runner = TitanRunner()
    runner.run()
