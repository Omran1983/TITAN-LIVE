from config_loader import get_prompt_block


def print_prompt(key: str) -> None:
    """Helper to print a prompt block nicely."""
    block = get_prompt_block(key)
    if not block:
        print(f"[ERROR] No config found for key: {key}")
        return

    print(f"=== {key} ===")
    print("Name      :", block.get("name"))
    print("Version   :", block.get("version"))
    print("Desc      :", block.get("description"))
    instr = block.get("instruction", "")
    print("\nInstruction (first 400 chars):")
    print(instr[:400] + ("..." if len(instr) > 400 else ""))
    print("\n")


if __name__ == "__main__":
    # Test a few core prompts
    keys = [
        "prompt.auto_sql",
        "prompt.etl_cleaner",
        "prompt.insight_report",
        "prompt.pipeline_scaffolder",
        "prompt.doc_bot",
    ]

    for k in keys:
        print_prompt(k)
