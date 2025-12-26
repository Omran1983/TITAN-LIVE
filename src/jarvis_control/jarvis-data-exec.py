import argparse
import json
import os
import sys
from typing import Any, Dict

import requests  # local-only HTTP call to Ollama

from config_loader import get_prompt_block


# Defaults for local Ollama
DEFAULT_OLLAMA_URL = os.getenv("OLLAMA_URL", "http://127.0.0.1:11434")
DEFAULT_OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "deepseek-r1:14b")


MODES = ["auto_sql", "etl_cleaner", "insight_report", "pipeline_scaffolder", "doc_bot"]


def build_payload(mode: str, query: str) -> Dict[str, str]:
    """
    Build a generic LLM payload using TOML-defined prompts.

    Result structure:
    {
      "mode": "<mode>",
      "system": "<system prompt>",
      "user": "<user query>"
    }
    """
    key = f"prompt.{mode}"
    block = get_prompt_block(key)

    if not block:
        raise RuntimeError(f"Prompt block not found for key: {key}")

    system_prompt = (block.get("instruction") or "").strip()
    if not system_prompt:
        raise RuntimeError(f"No 'instruction' field found in config for {key}")

    return {
        "mode": mode,
        "system": system_prompt,
        "user": query,
    }


def call_ollama(payload: Dict[str, str]) -> str:
    """
    Call a local Ollama server via its /api/chat endpoint.

    Uses:
      - DEFAULT_OLLAMA_URL   -> base URL (e.g. http://127.0.0.1:11434)
      - DEFAULT_OLLAMA_MODEL -> model name (e.g. deepseek-r1:14b)

    Expects Ollama to return a JSON object like:
      {
        "model": "...",
        "message": {"role": "assistant", "content": "..."},
        ...
      }
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

    # Try standard Ollama chat format
    try:
        return data["message"]["content"]
    except Exception:
        # Fallback: dump the whole JSON
        return json.dumps(data, indent=2, ensure_ascii=False)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Jarvis Data Executor – builds payload from TOML and calls local Ollama."
    )
    parser.add_argument(
        "--mode",
        required=True,
        choices=MODES,
        help="Which prompt to use (auto_sql, etl_cleaner, insight_report, pipeline_scaffolder, doc_bot).",
    )
    parser.add_argument(
        "--query",
        required=True,
        help="User query / instruction to feed to the LLM.",
    )
    parser.add_argument(
        "--show-payload",
        action="store_true",
        help="Print the payload JSON before calling Ollama.",
    )

    args = parser.parse_args()

    try:
        payload = build_payload(args.mode, args.query)
    except Exception as e:
        print(f"[ERROR] Failed to build payload: {e}", file=sys.stderr)
        sys.exit(1)

    if args.show_payload:
        print("=== PAYLOAD ===")
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        print("================\n")

    try:
        reply = call_ollama(payload)
    except Exception as e:
        print(f"[ERROR] Ollama call failed: {e}", file=sys.stderr)
        sys.exit(1)

    print("=== LLM REPLY (Ollama) ===")
    print(reply)


if __name__ == "__main__":
    main()
