import os
import time
import json
import argparse
import requests

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--agent_id", required=True)
    ap.add_argument("--control_plane_url", default=os.environ.get("CONTROL_PLANE_URL", "http://localhost:8010"))
    ap.add_argument("--token", default=os.environ.get("CONTROL_PLANE_TOKEN", ""))
    ap.add_argument("--interval", type=int, default=30)
    args = ap.parse_args()

    headers = {"Content-Type": "application/json"}
    if args.token:
        headers["Authorization"] = f"Bearer {args.token}"

    status = "IDLE"
    current_command_id = None
    last_error = None

    while True:
        payload = {
            "source": args.agent_id,
            "command_id": current_command_id,
            "severity": "info",
            "event_type": "heartbeat",
            "message": f"Heartbeat from {args.agent_id}",
            "payload": {
                "status": status,
                "current_command_id": current_command_id,
                "last_error": last_error,
                "metrics": {
                    "ts_unix": int(time.time())
                }
            }
        }

        try:
            r = requests.post(f"{args.control_plane_url}/v1/events/agent", headers=headers, data=json.dumps(payload), timeout=10)
            if r.status_code >= 300:
                print("Heartbeat failed:", r.status_code, r.text[:200])
        except Exception as e:
            print("Heartbeat exception:", str(e)[:200])

        time.sleep(args.interval)

if __name__ == "__main__":
    main()
