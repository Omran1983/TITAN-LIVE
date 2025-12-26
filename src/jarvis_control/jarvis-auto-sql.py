import argparse
import json
import os
import re
import sys
from typing import Any, Dict, Optional

import requests

from config_loader import get_prompt_block


# Defaults for local Ollama
DEFAULT_OLLAMA_URL = os.getenv("OLLAMA_URL", "http://127.0.0.1:11434")
DEFAULT_OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.2:1b")


def build_payload(query: str) -> Dict[str, str]:
    """
    Build payload for the AutoSQL prompt.
    """
    key = "prompt.auto_sql"
    block = get_prompt_block(key)

    if not block:
        raise RuntimeError(f"Prompt block not found for key: {key}")

    system_prompt = (block.get("instruction") or "").strip()
    if not system_prompt:
        raise RuntimeError(f"No 'instruction' field found in config for {key}")

    return {
        "mode": "auto_sql",
        "system": system_prompt,
        "user": query,
    }


def call_ollama(payload: Dict[str, str]) -> str:
    """
    Call local Ollama via /api/chat.
    """
    base_url = DEFAULT_OLLAMA_URL.rstrip("/")
    endpoint = f"{base_url}/api/chat"

    body: Dict[str, Any] = {
        "model": DEFAULT_OLLAMA_MODEL,
        "messages": [
            {"role": "system", "content": payload["system"]},
            {"role": "user", "content": payload["user"]},
        ],
        "stream": False,
    }

    resp = requests.post(endpoint, json=body, timeout=600)
    resp.raise_for_status()
    data = resp.json()

    try:
        return data["message"]["content"]
    except Exception:
        return json.dumps(data, indent=2, ensure_ascii=False)


def extract_sql(text: str) -> Optional[str]:
    """
    Try to extract a SQL block from the model reply.

    Strategy:
    1) Look for ```sql ... ``` fenced block.
    2) Otherwise, look for first ``` ... ``` fenced block.
    3) Otherwise, try to grab from first SELECT to the first ';'.
    """
    # 1) ```sql ... ```
    m = re.search(r"```sql(.*?```)", text, flags=re.DOTALL | re.IGNORECASE)
    if m:
        inner = m.group(1)
        inner = inner.replace("```", "")
        return inner.strip()

    # 2) Any ``` ... ```
    m = re.search(r"```(.*?```)", text, flags=re.DOTALL)
    if m:
        inner = m.group(1)
        inner = inner.replace("```", "")
        return inner.strip()

    # 3) From first SELECT to first ;
    m = re.search(r"(SELECT[\s\S]+?;)", text, flags=re.IGNORECASE)
    if m:
        return m.group(1).strip()

    return None


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Jarvis AutoSQL – natural language to SQL using local Ollama + TOML prompts."
    )
    parser.add_argument(
        "query",
        help="Natural language query, e.g. 'Show employers created last 30 days'",
    )
    parser.add_argument(
        "--show-raw",
        action="store_true",
        help="Also print the raw LLM reply for debugging.",
    )

    args = parser.parse_args()

    try:
        payload = build_payload(args.query)
    except Exception as e:
        print(f"[ERROR] Failed to build payload: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        reply = call_ollama(payload)
    except Exception as e:
        print(f"[ERROR] Ollama call failed: {e}", file=sys.stderr)
        sys.exit(1)

    sql = extract_sql(reply)

    if args.show_raw:
        print("=== RAW LLM REPLY ===")
        print(reply)
        print("=====================\n")

    if not sql:
        print("[ERROR] Could not extract SQL from reply.")
        sys.exit(1)

    print("=== SQL ===")
    print(sql)


if __name__ == "__main__":
    main()
