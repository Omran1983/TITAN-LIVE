import sys, json, time

def main():
    raw = sys.stdin.read()
    cmd = json.loads(raw)

    # v1: stub “site health”
    result = {
        "ok": True,
        "agent": "Inspector",
        "ts": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "human_summary": "Inspector ran basic checks (stub). No issues detected in stub mode.",
        "verify_required": False,
        "findings": [],
        "actions": [],
        "evidence": [],
        "metrics": {"pages_visited": 0, "stub": True}
    }

    print(json.dumps(result))

if __name__ == "__main__":
    main()
