import sys, json, time

def main():
    raw = sys.stdin.read()
    cmd = json.loads(raw)

    # v1: stub “patch plan”
    objective = cmd.get("objective", "")
    result = {
        "ok": True,
        "agent": "Doctor",
        "ts": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "human_summary": f"Doctor reviewed objective and produced a patch plan (stub). Objective: {objective[:160]}",
        "verify_required": True,
        "findings": [{"type": "stub", "note": "Replace with real patcher: git branch, patch, tests, rerun inspector."}],
        "actions": [{"type": "plan", "steps": ["locate failing route", "patch config", "run tests", "rerun inspector"]}],
        "evidence": [],
        "metrics": {"simulated": True}
    }

    print(json.dumps(result))

if __name__ == "__main__":
    main()
