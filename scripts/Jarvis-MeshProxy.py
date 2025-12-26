#!/usr/bin/env python
"""
Jarvis-MeshProxy.py
Lightweight mesh-style proxy for AION-ZERO.

- Reads routing rules from Supabase (az_mesh_routes, az_mesh_endpoints)
- Applies retries, timeout, basic circuit breaking
- Forwards JSON payloads to target agent HTTP endpoints
"""

import json
import os
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse
import requests
from datetime import datetime, timedelta

from supabase import create_client, Client  # pip install supabase

# Support both naming conventions for safety
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_SERVICE_KEY")

PORT = int(os.getenv("JARVIS_MESH_PROXY_PORT", "5055"))

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[MESH] FATAL: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is missing.")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# in-memory circuit breaker state (per route_key)
CIRCUIT_STATE = {}  # { route_key: { "open_until": datetime | None, "fail_count": int } }


def get_route_config(source_agent: str, route_key: str):
    # 1) fetch route row
    route_resp = supabase.table("az_mesh_routes").select("*") \
        .eq("source_agent", source_agent) \
        .eq("route_key", route_key) \
        .eq("is_enabled", True) \
        .execute()

    if not route_resp.data:
        return None, None

    route = route_resp.data[0]

    # 2) fetch endpoints for target_agent
    ep_resp = supabase.table("az_mesh_endpoints").select("*") \
        .eq("agent_name", route["target_agent"]) \
        .eq("is_healthy", True) \
        .execute()

    endpoints = ep_resp.data or []
    return route, endpoints


def is_circuit_open(route_key: str, route):
    state = CIRCUIT_STATE.get(route_key)
    if not state:
        return False

    open_until = state.get("open_until")
    if open_until and datetime.utcnow() < open_until:
        return True

    # circuit expired → reset
    CIRCUIT_STATE[route_key] = {"fail_count": 0, "open_until": None}
    return False


def record_failure(route_key: str, route):
    threshold = route.get("circuit_breaker_threshold", 5)
    state = CIRCUIT_STATE.setdefault(route_key, {"fail_count": 0, "open_until": None})
    state["fail_count"] += 1

    if state["fail_count"] >= threshold:
        # open circuit for 30s (can tune later)
        state["open_until"] = datetime.utcnow() + timedelta(seconds=30)


def record_success(route_key: str):
    CIRCUIT_STATE[route_key] = {"fail_count": 0, "open_until": None}


def forward_with_retries(route, endpoints, payload):
    retries = route.get("max_retries", 2)
    timeout_ms = route.get("timeout_ms", 30000)
    backoff = route.get("backoff_strategy", "exponential")

    timeout_sec = timeout_ms / 1000.0
    route_key = route["route_key"]

    if not endpoints:
        raise RuntimeError("No healthy endpoints for route")

    last_err = None

    for attempt in range(retries + 1):
        for ep in endpoints:
            url = ep["endpoint_url"]
            try:
                resp = requests.post(
                    url,
                    json=payload,
                    timeout=timeout_sec
                )
                if resp.status_code >= 200 and resp.status_code < 300:
                    record_success(route_key)
                    return resp.status_code, resp.json()
                else:
                    last_err = RuntimeError(f"HTTP {resp.status_code}: {resp.text}")
            except Exception as e:
                last_err = e

        # all endpoints failed this round
        record_failure(route_key, route)

        if attempt < retries:
            # backoff
            if backoff == "exponential":
                time.sleep(2 ** attempt)
            else:
                time.sleep(1)

    raise last_err or RuntimeError("All retries failed")


class MeshHandler(BaseHTTPRequestHandler):
    def _send_json(self, status_code, body):
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(body).encode("utf-8"))

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path != "/route":
            self._send_json(404, {"ok": False, "error": "not_found"})
            return

        try:
            length = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(length)
            data = json.loads(raw.decode("utf-8"))
        except Exception as e:
            self._send_json(400, {"ok": False, "error": f"invalid_json: {e}"})
            return

        source_agent = data.get("source_agent")
        route_key = data.get("route_key")
        payload = data.get("payload")

        if not source_agent or not route_key:
            self._send_json(400, {"ok": False, "error": "source_agent and route_key required"})
            return

        # circuit breaker check
        dummy_route = {"route_key": route_key}
        if is_circuit_open(route_key, dummy_route):
            self._send_json(503, {"ok": False, "error": "circuit_open"})
            return

        route, endpoints = get_route_config(source_agent, route_key)
        if not route:
            self._send_json(404, {"ok": False, "error": "route_not_found"})
            return

        try:
            status, resp_json = forward_with_retries(route, endpoints, payload)
            self._send_json(200, {"ok": True, "status": status, "response": resp_json})
        except Exception as e:
            self._send_json(502, {"ok": False, "error": f"upstream_failed: {e}"})


def run_server():
    server = HTTPServer(("0.0.0.0", PORT), MeshHandler)
    print(f"[MeshProxy] LISTEN ON PORT {PORT}")
    server.serve_forever()


if __name__ == "__main__":
    run_server()
