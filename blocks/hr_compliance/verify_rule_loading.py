import json
from pathlib import Path

def main() -> None:
    here = Path(__file__).resolve().parent
    path = here / "prb_2026.json"
    doc = json.loads(path.read_text(encoding="utf-8"))

    rules = doc.get("rules", [])
    print(f"Loaded {len(rules)} rules | version={doc.get('version')} | effective={doc.get('effective_date')}")
    for r in rules:
        print(f"- {r.get('id')} [{r.get('type')}] {r.get('name')}")

if __name__ == "__main__":
    main()
