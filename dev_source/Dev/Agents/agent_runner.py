import os, json, pathlib, subprocess, sys, re
from typing import Dict, Any, Optional

# =========================
# Config
# =========================
ALLOWLIST = [r"C:\Dev", r"C:\Users\ICL  ZAMBIA\Desktop\Binance Automation"]
DEFAULT_CWD = r"C:\Dev"
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4o-mini")  # used only if OPENAI_API_KEY exists
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://127.0.0.1:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.1:8b")
REQUIRE_CONFIRM = os.getenv("REQUIRE_CONFIRM", "false").lower() == "true"
DRY_RUN = os.getenv("DRY_RUN", "false").lower() == "true"

def norm(p: str) -> str:
    return pathlib.Path(p).resolve().as_posix().lower()

NORM_ALLOW = [norm(p) for p in ALLOWLIST]

def is_allowed(cwd: str) -> bool:
    try:
        cp = norm(cwd)
        return any(cp.startswith(a) for a in NORM_ALLOW)
    except Exception:
        return False

# PowerShell runner
def shutil_which(cmd: str) -> Optional[str]:
    from shutil import which
    return which(cmd)

def run_powershell(command: str, cwd: str = DEFAULT_CWD) -> Dict[str, Any]:
    if not is_allowed(cwd):
        return {"ok": False, "stdout": "", "stderr": f"cwd '{cwd}' not in allowlist", "rc": 99}
    if DRY_RUN:
        return {"ok": True, "stdout": f"[DRY_RUN] Would run in {cwd}:\n{command}", "stderr": "", "rc": 0}
    exe = os.environ.get("POWERSHELL_EXE", "pwsh")
    if not shutil_which(exe):
        exe = "powershell.exe"
    try:
        proc = subprocess.run(
            [exe, "-NoLogo", "-NoProfile", "-Command", command],
            cwd=cwd, capture_output=True, text=True, timeout=180
        )
        return {
            "ok": proc.returncode == 0,
            "stdout": (proc.stdout or "").strip(),
            "stderr": (proc.stderr or "").strip(),
            "rc": proc.returncode
        }
    except Exception as e:
        return {"ok": False, "stdout": "", "stderr": str(e), "rc": 98}

# Tool schema (OpenAI)
OPENAI_TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "powershell_run",
            "description": "Run a PowerShell command in a given working directory and return stdout/stderr.",
            "parameters": {
                "type": "object",
                "properties": {
                    "command": {"type": "string"},
                    "cwd": {"type": "string", "default": DEFAULT_CWD}
                },
                "required": ["command"]
            },
        },
    }
]

SYSTEM_POLICY = """You are an Autonomy Agent.
POLICY:
- Any request mentioning run/execute, dir/list/Get-ChildItem, python --version, pip, git, or filesystem MUST call the powershell_run tool.
- Do NOT fabricate command output. Only return what the tool returns.
- If cwd is outside allowlist, refuse and ask for a permitted path.
- Keep responses concise and operational.
"""

def must_use_tool(user_msg: str) -> bool:
    s = user_msg.lower()
    triggers = [
        "powershell", "get-childitem", "gci", "dir ",
        "python --version", "pip ", "git ", "run:", "execute", "list the top", "ls "
    ]
    return any(t in s for t in triggers)

def have_openai() -> bool:
    return bool(os.getenv("OPENAI_API_KEY"))

def openai_chat(messages, tools=None, tool_choice="auto"):
    from openai import OpenAI
    client = OpenAI()
    resp = client.chat.completions.create(
        model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
        messages=messages,
        tools=tools or [],
        tool_choice=tool_choice,
        temperature=0.2
    )
    return resp

def handle_openai_tool_call(tc) -> Dict[str, Any]:
    name = tc.function.name
    args = json.loads(tc.function.arguments or "{}")
    if name == "powershell_run":
        return run_powershell(args.get("command", ""), args.get("cwd", DEFAULT_CWD))
    return {"ok": False, "stdout": "", "stderr": f"Unknown tool {name}", "rc": 97}

# Ollama fallback (no tool calls)
def ollama_chat(prompt: str) -> str:
    import requests
    data = {"model": OLLAMA_MODEL, "prompt": prompt, "stream": False}
    r = requests.post(f"{OLLAMA_URL}/api/generate", json=data, timeout=60)
    r.raise_for_status()
    out = r.json()
    return out.get("response", "").strip()

def banner():
    print("=== Autonomy Agent Online ===")
    print(f"- OpenAI model: {os.getenv('OPENAI_MODEL', 'gpt-4o-mini') if have_openai() else 'disabled'}")
    print(f"- Ollama model: {OLLAMA_MODEL} @ {OLLAMA_URL}")
    print(f"- Guardrails: REQUIRE_CONFIRM={REQUIRE_CONFIRM}, DRY_RUN={DRY_RUN}")
    print(f"- Allowlist: {ALLOWLIST}")
    print("-------------------------------------------")

def main():
    banner()
    messages = [{"role": "system", "content": SYSTEM_POLICY}]
    while True:
        try:
            user = input("\nYou> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n[exit]")
            break
        if not user:
            continue
        if user.lower() in ("exit", "quit"):
            print("[bye]")
            break

        if must_use_tool(user):
            import re as _re
            if REQUIRE_CONFIRM:
                print("[CONFIRM] Enter 'y' to execute:")
                if input().strip().lower() != "y":
                    print("[skipped]")
                    continue
            m = _re.search(r"cwd\s*=\s*([^\s]+)", user, _re.IGNORECASE)
            cwd = m.group(1) if m else DEFAULT_CWD

            commands = []
            run_match = _re.search(r"run:\s*(.+)$", user, _re.IGNORECASE)
            if run_match:
                commands.append(run_match.group(1).strip())
            else:
                if "list the top" in user.lower() and "c:\\dev" in user.lower():
                    commands.append(r"Get-ChildItem -Force C:\Dev | Sort-Object LastWriteTime -Descending | Select-Object -First 5 Name,LastWriteTime | Format-Table -AutoSize")
                if "python --version" in user.lower():
                    commands.append("python --version")

            if not commands:
                print("No executable command parsed. Hint: use un: <your command>")
                continue

            for cmd in commands:
                result = run_powershell(cmd, cwd=cwd)
                print("\n[tool:powershell_run]")
                print(f"cwd: {cwd}")
                print(f"cmd: {cmd}")
                print(f"rc : {result['rc']}")
                if result["stdout"]:
                    print("stdout:")
                    print(result["stdout"])
                if result["stderr"]:
                    print("stderr:")
                    print(result["stderr"])
            continue

        if have_openai():
            messages.append({"role": "user", "content": user})
            resp = openai_chat(messages, tools=OPENAI_TOOLS, tool_choice="auto")
            msg = resp.choices[0].message
            if getattr(msg, "tool_calls", None):
                for tc in msg.tool_calls:
                    tool_result = handle_openai_tool_call(tc)
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tc.id,
                        "name": tc.function.name,
                        "content": json.dumps(tool_result)
                    })
                resp2 = openai_chat(messages, tools=OPENAI_TOOLS, tool_choice="none")
                final = resp2.choices[0].message.content
                print(final)
                messages.append({"role": "assistant", "content": final})
            else:
                final = msg.content or ""
                print(final)
                messages.append({"role": "assistant", "content": final})
        else:
            answer = ollama_chat(f"{SYSTEM_POLICY}\nUser: {user}\nAssistant:")
            print(answer)

if __name__ == "__main__":
    main()
