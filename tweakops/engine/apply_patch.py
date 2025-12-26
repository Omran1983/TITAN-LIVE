import sys, json, pathlib, difflib, re

def load_text(p): 
    p = pathlib.Path(p)
    try: return p.read_text(encoding="utf-8")
    except UnicodeDecodeError: return p.read_text(encoding="utf-8", errors="ignore")

def save_text(p, s):
    p = pathlib.Path(p); p.parent.mkdir(parents=True, exist_ok=True); p.write_text(s, encoding="utf-8")

def extract_discount(intent: str, default=10):
    m = re.search(r'(\d+)\s*%(\s*off)?', (intent or "").lower())
    return int(m.group(1)) if m else default

def plan_from_intent(intent: str, targets):
    pct  = extract_discount(intent, default=10)
    dash = " – "
    target_cta = f"Shop Now{dash}{pct}% OFF"
    ops = []
    for f in targets:
        fl = f.lower()
        if fl.endswith((".jsx",".tsx",".js",".html")):
            ops.append({"file": f, "action": "jsx_cta", "target": target_cta})
        if ("styles" in fl) or fl.endswith(".css"):
            ops.append({"file": f, "action": "ensure_css_rule",
                        "selector": ".btn-primary:hover", "body": "filter: brightness(0.9);"})
    return {"ops": ops}

def apply_ops(root: pathlib.Path, plan, patch_dir: pathlib.Path):
    diffs, changed = [], 0
    for op in plan["ops"]:
        fp = root / op["file"]
        if not fp.exists(): continue
        before = load_text(fp)
        after  = before

        if op["action"] == "jsx_cta":
            target = op["target"]
            # Replace label inside button tags
            after = re.sub(r'(<button[^>]*>)(.*?)(</button>)',
                           lambda m: m.group(1) + re.sub(r'Shop Now(?:\s*[–-]\s*\d+\s*%?\s*OFF)?',
                                                          target, m.group(2)) + m.group(3),
                           after, flags=re.IGNORECASE|re.DOTALL)
            # Fallback: bare “Shop Now …” anywhere
            after = re.sub(r'Shop Now(?:\s*[–-]\s*\d+\s*%?\s*OFF)?', target, after)
        elif op["action"] == "ensure_css_rule":
            sel, body = op["selector"], op["body"]
            if sel not in after:
                after += f"\n{sel} {{ {body} }}\n"

        if after != before:
            changed += 1
            diff = "\n".join(difflib.unified_diff(before.splitlines(True),
                                                  after.splitlines(True),
                                                  fromfile=str(fp), tofile=str(fp), n=3))
            diffs.append(diff)
            save_text(fp, after)

    if changed:
        patch_dir.mkdir(parents=True, exist_ok=True)
        (patch_dir / "diff.patch").write_text("\n\n".join(diffs), encoding="utf-8")
    return changed

def main():
    if len(sys.argv) < 5:
        print("usage: apply_patch.py <patch_dir> <project_root> <intent> <targets_json>"); sys.exit(2)
    patch_dir    = pathlib.Path(sys.argv[1])
    project_root = pathlib.Path(sys.argv[2])
    intent       = sys.argv[3]
    raw_targets  = sys.argv[4] if len(sys.argv) > 4 else "[]"
    try: targets = [] if not raw_targets.strip() else json.loads(raw_targets)
    except Exception: targets = []
    if targets is None: targets = []
    if isinstance(targets, str): targets = [targets]

    changed = apply_ops(project_root, plan_from_intent(intent, targets), patch_dir)
    status = "APPLIED" if changed else "NO_CHANGES"
    patch_dir.mkdir(parents=True, exist_ok=True)
    (patch_dir / "status.txt").write_text(status, encoding="utf-8")
    print(status)
    (patch_dir / "args.txt").write_text(f"intent={intent}\nraw_targets={raw_targets}\nparsed_targets={targets}\nengine=jsx-aware-1\n", encoding="utf-8")

if __name__ == "__main__":
    main()
