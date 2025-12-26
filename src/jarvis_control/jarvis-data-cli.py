import argparse
import json
from config_loader import get_prompt_block

MODES = ["auto_sql", "etl_cleaner", "insight_report", "pipeline_scaffolder", "doc_bot"]


def build_payload(mode: str, query: str) -> dict:
    """
    Build a generic LLM payload using TOML-defined prompts.

    Result structure:
    {
      "mode": "<mode>",
      "system": "<system prompt>",
      "user": "<user query>",
    }
    """
    key = f"prompt.{mode}"
    block = get_prompt_block(key)

    if not block:
        raise RuntimeError(f"Prompt block not found for key: {key}")

    system_prompt = block.get("instruction", "").strip()

    return {
        "mode": mode,
        "system": system_prompt,
        "user": query,
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Jarvis Data CLI – builds LLM payloads from TOML prompts."
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
        "--pretty",
        action="store_true",
        help="Pretty-print JSON instead of compact output.",
    )

    args = parser.parse_args()

    payload = build_payload(args.mode, args.query)

    if args.pretty:
        print(json.dumps(payload, indent=2, ensure_ascii=False))
    else:
        print(json.dumps(payload, separators=(",", ":"), ensure_ascii=False))

    # NOTE:
    # This CLI only builds the payload.
    # Next step: another layer (Python, Node, PS) takes this JSON
    # and sends it to OpenAI / Ollama / Board LLM server.
    # Keeping this tool side-effect free on purpose.


if __name__ == "__main__":
    main()
