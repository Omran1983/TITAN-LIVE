import sys, json, pathlib, difflib
from datetime import datetime

def load_text(p: pathlib.Path):
    try:
        return p.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return p.read_text(encoding="utf-8", errors="ignore")

def save_text(p: pathlib.Path, s: str):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding="utf-8")

def plan_from_intent(intent: str, targets):
    plan = {"ops": []}
    t = intent.lower()
    if "change cta" in t and "shop now" in t:
        # Replace common CTA text patterns
        for f in targets:
            if f.lower().endswith((".jsx", ".tsx", ".js", ".html")):
                plan["ops"].append({
                    "file": f,
                    "action": "replace",
                    "find": ["Shop Now", "SHOP NOW", "Shop now"],
                    "replace": "Shop Now – 10% OFF"
                })
            if "styles" in f.lower() or f.lower().endswith(".css"):
                plan["ops"].append({
                    "file": f,
                    "action": "ensure_css_rule",
                    "selector": ".btn-primary:hover",
                    "body": "filter: brightness(0.9);"
                })
    # Extend with more heuristic rules as needed
    return plan

def apply_ops(root: pathlib.Path, plan, patch_dir: pathlib.Path):
    diffs = []
    changed = 0
    for op in plan["ops"]:
        fp = root / op["file"]
        if not fp.exists():
            continue
        before = load_text(fp).splitlines(keepends=True)
        after_lines = before[:]
        if op["action"] == "replace":
            text = "".join(after_lines)
            for needle in op["find"]:
                text = text.replace(needle, op["replace"])
            after_lines = text.splitlines(keepends=True)
        elif op["action"] == "ensure_css_rule":
            text = "".join(after_lines)
            selector = op["selector"]
            body = op["body"]
            if selector not in text:
                block = f"\n{selector} {{ {body} }}\n"
                text = text + block
            after_lines = text.splitlines(keepends=True)
        if after_lines != before:
            changed += 1
            diff = difflib.unified_diff(before, after_lines, fromfile=str(fp), tofile=str(fp), n=3)
            diffs.append("".join(diff))
            save_text(fp, "".join(after_lines))
    if changed:
        patch_dir.mkdir(parents=True, exist_ok=True)
        (patch_dir / "diff.patch").write_text("\n\n".join(diffs), encoding="utf-8")
    return changed

def main():
    # args: patch_dir, project_root, intent, targets_json
    if len(sys.argv) < 5:
        print("usage: apply_patch.py <patch_dir> <project_root> <intent> <targets_json>")
        sys.exit(2)
    patch_dir = pathlib.Path(sys.argv[1])
    project_root = pathlib.Path(sys.argv[2])
    intent = sys.argv[3]
    targets = json.loads(sys.argv[4])  # list
    patch_dir.mkdir(parents=True, exist_ok=True)
    plan = plan_from_intent(intent, targets)
    changed = apply_ops(project_root, plan, patch_dir)
    status = "APPLIED" if changed else "NO_CHANGES"
    (patch_dir / "status.txt").write_text(status, encoding="utf-8")
    (patch_dir / "plan.json").write_text(json.dumps(plan, indent=2), encoding="utf-8")
    print(status)

if __name__ == "__main__":
    main()
