import subprocess
import argparse
import json
import time
from pathlib import Path

# Sections to generate
SECTIONS = [
    "1. Executive Summary",
    "2. Literature Review & State of the Art",
    "3. Market Gap & Opportunity",
    "4. Detailed Methodology",
    "5. Financials & Budget",
    "6. Impact & Sustainability"
]

def build_project(topic: str, scheme: str, output_dir: Path):
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print(f"🏗️  GRANT ARCHITECT: Building '{topic}' for '{scheme}'")
    
    # 1. Research Phase
    brief_path = output_dir / "brief.json"
    if not brief_path.exists():
        print("🔍 Phase 1: Deep Research...")
        subprocess.run([
            "python", "src/researcher.py",
            "--topic", topic,
            "--scheme", scheme,
            "--out", str(brief_path)
        ], check=False)
    
    if not brief_path.exists():
        print("❌ Research failed. Aborting.")
        return

    # 2. Writing Phase
    full_content = f"# Project Proposal: {topic}\n"
    full_content += f"**Scheme:** {scheme}\n"
    full_content += f"**Date:** {time.strftime('%Y-%m-%d')}\n\n"
    
    for section in SECTIONS:
        print(f"✍️  Phase 2: Drafting '{section}'...")
        sec_filename = section.replace(" ", "_").replace(".", "") + ".md"
        sec_path = output_dir / sec_filename
        
        subprocess.run([
            "python", "src/writer.py",
            "--section", section,
            "--context", str(brief_path),
            "--out", str(sec_path)
        ], check=False)
        
        if sec_path.exists():
            full_content += sec_path.read_text(encoding="utf-8") + "\n\n---\n\n"
        else:
            full_content += f"## {section}\n*(Content Generation Failed)*\n\n"
            
    # 3. Assembly
    final_path = output_dir / f"Project_{scheme}_{topic.replace(' ', '_')}.md"
    final_path.write_text(full_content, encoding="utf-8")
    
    print(f"✅ Project Completed: {final_path}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--topic", required=True)
    ap.add_argument("--scheme", default="TINNS")
    ap.add_argument("--out", default="output")
    args = ap.parse_args()
    
    build_project(args.topic, args.scheme, Path(args.out))

if __name__ == "__main__":
    main()
