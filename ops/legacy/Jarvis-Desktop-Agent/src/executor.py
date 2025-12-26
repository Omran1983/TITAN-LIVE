import json
from pathlib import Path

from controller import move_and_click, type_text

BASE_DIR = Path(__file__).resolve().parent.parent
WORKFLOW_DIR = BASE_DIR / "workflows"

def execute_workflow(name: str = "demo_click") -> None:
    wf_path = WORKFLOW_DIR / f"{name}.json"
    if not wf_path.exists():
        raise FileNotFoundError(f"Workflow not found: {wf_path}")

    data = json.loads(wf_path.read_text(encoding="utf-8"))
    steps = data.get("steps", [])
    print(f"[executor] Running workflow {data.get('name', name)!r} with {len(steps)} steps")

    for i, step in enumerate(steps, start=1):
        action = step.get("action")
        print(f"[executor] Step {i}: {step}")

        if action == "click":
            x = int(step["x"])
            y = int(step["y"])
            move_and_click(x, y)
        elif action == "type":
            text = step["text"]
            type_text(text)
        else:
            print(f"[executor] Unknown action: {action}, skipping")

    print("[executor] Workflow complete.")

if __name__ == "__main__":
    execute_workflow()
