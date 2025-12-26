import json
import subprocess
import argparse
from pathlib import Path
import sys

# Constants
UTILS_PATH = Path("F:/AION-ZERO/TITAN/apps/utils/summarize_cli.py")

def conduct_research(topic: str, scheme: str, output_path: Path):
    """
    Simulates a deep research session using the LLM.
    Generates a Research Brief.
    """
    print(f"[RESEARCHER] Studying '{topic}' for scheme '{scheme}'...")
    
    # We construct a prompt that asks the LLM to act as a Subject Matter Expert
    prompt = f"""
    You are a Lead Researcher for a grant proposal under the '{scheme}' scheme.
    Topic: {topic}
    
    Perform a comprehensive analysis and output a detailed JSON object with the following structure:
    {{
        "title": "Project Title",
        "domain": "Industry Domain (e.g. AgriTech)",
        "problem_statement": "Detailed description of the problem...",
        "state_of_art": "Current existing solutions...",
        "market_gap": "Why existing solutions fail...",
        "solution_concept": "Our proposed innovation...",
        "technical_approach": ["Step 1...", "Step 2..."],
        "impact_metrics": ["Metric 1", "Metric 2"],
        "budget_estimate_usd": 50000
    }}
    
    Ensure the tone is academic, professional, and convincing.
    """
    
    # We'll use a temporary file to pass the prompt to summarize_cli (which we'll abuse as a generic LLM caller)
    # Actually, summarize_cli expects "Input Text" to summarize.
    # We might need a direct generation script if summarize_cli is too specific.
    # Let's check summarize_cli.py. It takes --in file.
    # If we pass the prompt as the input file, and tell it to "summarize" (or just generating), we effectively get generation.
    # But summarize_cli wraps the prompt in "Summarize this:".
    # I should write a simple 'generate.py' or modify researcher to call ollama directly using subprocess for raw generation.
    # Direct subprocess is better for this specific "Creative Generation" task.
    
    cmd = [
        "ollama", "run", "qwen2.5-coder:7b",
        prompt
    ]
    
    try:
        # Run Ollama
        result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
        if result.returncode != 0:
            print(f"[FAIL] Ollama Failed: {result.stderr}")
            return None
            
        raw_output = result.stdout
        # Attempt to extract JSON
        try:
            # Find first { and last }
            start = raw_output.find("{")
            end = raw_output.rfind("}") + 1
            if start != -1 and end != -1:
                json_str = raw_output[start:end]
                data = json.loads(json_str)
                
                # Save
                output_path.parent.mkdir(parents=True, exist_ok=True)
                output_path.write_text(json.dumps(data, indent=2), encoding="utf-8")
                print(f"[SUCCESS] Research Brief saved to {output_path}")
                return data
            else:
                print("[FAIL] Could not find JSON in LLM output.")
                print(raw_output[:500] + "...")
                return None
        except json.JSONDecodeError:
            print("[FAIL] JSON Decode Error.")
            return None
            
    except Exception as e:
        print(f"[FAIL] Exception: {e}")
        return None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--topic", required=True)
    ap.add_argument("--scheme", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    
    conduct_research(args.topic, args.scheme, Path(args.out))

if __name__ == "__main__":
    main()
