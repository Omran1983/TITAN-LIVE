import argparse
import json
import subprocess
import pathlib
import sys

def ollama(prompt: str, model: str) -> str:
    # Adding utf-8 encoding for input and handling output decoding safely
    try:
        p = subprocess.run(
            ["ollama", "run", model], 
            input=prompt.encode("utf-8"),
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE,
            check=False # We handle returncode manually
        )
        if p.returncode != 0:
            raise RuntimeError(p.stderr.decode("utf-8", "ignore"))
        return p.stdout.decode("utf-8", "ignore")
    except FileNotFoundError:
        raise RuntimeError("Ollama executable not found. Is it installed and in PATH?")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", required=True, help="Input text file path")
    ap.add_argument("--out", dest="out", required=True, help="Output JSON file path")
    ap.add_argument("--llm", dest="model", default="qwen2.5-coder:latest", help="Ollama model tag")
    ap.add_argument("--mode", default="executive", help="Summary mode: executive (default), technical, sentiment")
    args = ap.parse_args()

    input_path = pathlib.Path(args.inp)
    if not input_path.exists():
        print(f"Error: Input file {args.inp} not found.")
        sys.exit(1)

    text = input_path.read_text(encoding="utf-8", errors="ignore")
    
    prompt = f"""Return STRICT JSON only.
Schema:
{{"title":string,"summary":string,"bullets":[string],"actions":[string],"risks":[string]}}
Mode: {args.mode}
Text:
{text[:120000]}
"""
    print(f"[OLLAMA] Summarizing {args.inp} using {args.model}...")
    try:
        raw = ollama(prompt, args.model).strip()
        
        # Naive guard for JSON block extraction if model is chatty
        start = raw.find("{")
        end = raw.rfind("}")
        if start != -1 and end != -1:
            raw = raw[start:end+1]
        
        if not (raw.startswith("{") and raw.endswith("}")):
            raise ValueError("LLM did not return strict JSON.")
            
        obj = json.loads(raw)
        
        # Envelope wrapper (Standard Item #0)
        envelope = {
            "ok": True,
            "agent": "SummarizerCLI",
            "model": args.model,
            "human_summary": f"Summarized {len(text)} chars into {len(obj.get('bullets', []))} points.",
            "findings": obj
        }
        
        out_path = pathlib.Path(args.out)
        out_path.write_text(json.dumps(envelope, indent=2), encoding="utf-8")
        print(f"[SUCCESS] Wrote to {args.out}")
        
    except Exception as e:
        print(f"[ERROR] Summarization failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
