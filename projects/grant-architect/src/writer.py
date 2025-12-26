import json
import subprocess
import argparse
from pathlib import Path

def draft_chapter(section_name: str, context: dict, output_path: Path):
    """
    Generates prose for a specific chapter based on the Research Brief.
    """
    print(f"[WRITER] Drafting '{section_name}'...")
    
    prompt = f"""
    You are a Professional Technical Writer for a grant proposal.
    Context (Research Brief):
    {json.dumps(context, indent=2)}
    
    Task: Write the full content for the section: "{section_name}".
    
    Guidelines:
    - Use Markdown formatting (headers, bold, lists).
    - Be detailed and specific.
    - If writing "Financials", create a Markdown Table.
    - If writing "Methodology", break it down into phases.
    - Do NOT output JSON. Output pure Markdown text.
    """
    
    cmd = ["ollama", "run", "qwen2.5-coder:7b", prompt]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
        if result.returncode != 0:
            print(f"[FAIL] Writer Failed: {result.stderr}")
            return
            
        content = result.stdout
        
        # Save
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(content, encoding="utf-8")
        print(f"[SUCCESS] Chapter '{section_name}' saved to {output_path}")
        
    except Exception as e:
        print(f"[FAIL] Writer Exception: {e}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--section", required=True)
    ap.add_argument("--context", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    
    with open(args.context, 'r', encoding="utf-8") as f:
        ctx = json.load(f)
        
    draft_chapter(args.section, ctx, Path(args.out))

if __name__ == "__main__":
    main()
