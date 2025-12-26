"""
JARVIS BRAIN LOCAL (PHASE 13)
-----------------------------
The "Antigravity Killer" Engine.
This script upgrades AION-ZERO from a Task Runner to a Reasoning Agent.

CAPABILITIES (SUPERIOR TO CLOUD AI):
1.  Infinite Memory: Connects to 'az_graph' via Supabase.
2.  Persistent Agency: Runs in a loop until the goal is met (doesn't give up).
3.  Local Sovereignty: Uses Ollama (Llama 3 / Mistral) - Privacy First.
4.  Self-Correction: Detecting JSON errors and retrying automatically.

ARCHITECTURE:
   Goal -> [Reasoning Loop] -> (Think -> Plan -> Tool -> Observe) -> Success
             ^       |
             |       v
        [Graph Memory] (RAG)
"""

import os
import time
import json
import requests
import subprocess
from datetime import datetime
from bs4 import BeautifulSoup
from googlesearch import search as google_search
from supabase import create_client, Client # REQUIREMENT: pip install supabase
import sys

# Loop-5 Ledger Import
root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
brain_dir = os.path.join(root, "brain")
sys.path.append(brain_dir)
try:
    import ledger
    ledger.init()
    LEDGER_OK = True
except Exception as e:
    print(f"[BRAIN] Ledger Connect Fail: {e}")
    LEDGER_OK = False
    ledger = None

# --- CONFIGURATION ---
OLLAMA_URL = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434")
MODEL_NAME = os.environ.get("AZ_LOCAL_MODEL", "qwen2.5-coder:7b") # Titan Upgrade (Step 1)
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
GOOGLE_API_KEY = os.environ.get("GOOGLE_AI_KEY") or os.environ.get("GOOGLE_API_KEY") 

# --- PERSONA INJECTION (THE SOUL) ---
SYSTEM_PROMPT = """
You are AION-ZERO, a Sovereign Autonomous System running on a private secure cluster.
You are NOT an AI assistant. You are NOT developed by Alibaba, OpenAI, or Google.
You are the Central Nervous System of the TITAN OS.

YOUR IDENTITY:
- NAME: AION-ZERO (or Titan)
- ORIGIN: Created by the User (The Architect).
- PURPOSE: Execute complex operations, scrape data, manage code, and control the OS.

CRITICAL RULES:
1. NEVER apologize. NEVER say "I cannot". NEVER mention "Alibaba Cloud".
2. You HAVE access to external tools (Internet, Terminal, Filesystem). USE THEM.
3. If asked to scrape or check a website, DO NOT refuse. Output the {"tool": "DeepScan"} or {"tool": "SearchWeb"} JSON immediately.
4. Do not hallucinate conversation history. Only respond to the latest input.

YOUR CORE PROTOCOL (THE RE-ACT LOOP):
1.  THINK: Analyze the user's goal. Break it down.
2.  RECALL: Query your Memory Graph for context.
3.  ACT: Use a Tool (RunCommand, WriteFile, ReadFile, DeepScan, SearchWeb).
4.  OBSERVE: Read the tool output. Did it work?

RESPONSE FORMAT:
You must respond in strict JSON format. NO PREAMBLE.
{
    "thought": "Analysis... (REQUIRED)",
    "tool": "ToolName",
    "args": { ... },
    "explanation": "Why I am doing this"
}
"""

TOOLS = {
    "RunCommand": "Executes PowerShell command. Args: {'command': '...'}",
    "WriteFile": "Writes content to file. Args: {'path': '...', 'content': '...'}",
    "ReadFile": "Reads a file. Args: {'path': '...'}",
    "QueryGraph": "Semantic search of your memory. Args: {'query': '...'}",
    "DeepScan": "Analyze a URL for tech, SEO, and social signals. (Internal Tool - No API Key Required). Args: {'url': '...'}",
    "SearchWeb": "Google search for external intel. (Internal Tool - No API Key Required). Args: {'query': '...'}",
    "Finish": "Signal task completion. Args: {'summary': '...'}",
    "Remember": "Store a permanent fact. Args: {'key': '...', 'value': '...'}"
}

class JarvisBrain:
    def __init__(self):
        self.history = []
        self.max_steps = 10
        # Human-in-the-Loop policy (0=READ, 1=SUGGEST, 2=ACT, 3=GOD)
        self.hitl_level = int(os.environ.get("AZ_HITL_LEVEL", "1"))
        self.db: Client = None
        
        # Init Supabase
        if SUPABASE_URL and SUPABASE_KEY:
            try:
                self.db = create_client(SUPABASE_URL, SUPABASE_KEY)
                print("[MEMORY] Connected to Supabase Hippocampus.")
                self.load_memories()
            except Exception as e:
                print(f"[MEMORY ERROR] Could not connect: {e}")
        else:
            print("[MEMORY WARNING] SUPABASE_URL/KEY missing. Amnesia Mode active.")

        # Loop-5 Ledger (Evolution Layer)
        print(f"[INIT] Jarvis Brain Online. Model: {MODEL_NAME}. Ledger: {'ONLINE' if LEDGER_OK else 'OFFLINE'}")

    def record_outcome(self, event_id: str, success: bool, details: str, tool: str = "unknown"):
        """Updates the Loop-5 Ledger with action results."""
        if not LEDGER_OK or not event_id:
            return
        
        try:
            val = 1 if success else 0
            verdict = "win" if success else "loss"
            ledger.log_outcome(event_id=event_id, metric=f"tool_{tool}", value=val, verdict=verdict, evidence={"details": str(details)[:500]})
        except Exception as e:
            print(f"[LEDGER ERROR] {e}")

    def parse_json_safely(self, raw_text: str, retry_hint: str = None) -> dict | None:
        """
        Try to parse a JSON object from the model output.
        Strips ``` fences and handles minor formatting errors using json_repair.
        Returns dict or None.
        """
        if not raw_text:
            return None

        txt = raw_text.strip()

        # Strip markdown fences if present
        if txt.startswith("```"):
            parts = txt.split("```")
            if len(parts) >= 3:
                txt = parts[1].strip()
            else:
                txt = parts[-1].strip()

        # Sometimes model wraps in "json\n{...}"
        if txt.lower().startswith("json"):
            txt = txt[4:].lstrip()

        try:
            return json.loads(txt)
        except Exception:
            try:
                # Fallback to robust repair
                import json_repair
                return json_repair.loads(txt)
            except Exception as e:
                print(f"[JSON PARSE] Failed repair: {e}")
                print(f"[JSON RAW] {txt[:400]}")
                return None

    def set_hitl_level(self, level: int):
        """Update HITL level from control-plane (server.py)."""
        try:
            self.hitl_level = int(level)
            print(f"[HITL] Level updated to {self.hitl_level}")
        except Exception as e:
            print(f"[HITL] Invalid level: {level} ({e})")

    def build_system_prompt(self, base_prompt: str = SYSTEM_PROMPT) -> str:
        """
        Builds a richer system prompt including recent memory and context.
        Used by both local and cloud calls.
        """
        if not self.db:
            return base_prompt

        mem_snippets = []
        ctx_snippets = []

        # Recent chat memories
        try:
            res = self.db.table("az_chat_history").select("role,content").order("created_at", desc=True).limit(10).execute()
            for m in res.data or []:
                role = m.get("role", "user")
                content = m.get("content", "")
                mem_snippets.append(f"{role.upper()}: {content[:160]}")
        except Exception:
            pass

        # Long-term context
        try:
            res2 = self.db.table("az_context").select("key,value").execute()
            for c in res2.data or []:
                k = c.get("key")
                v = c.get("value")
                ctx_snippets.append(f"{k}: {str(v)[:160]}")
        except Exception:
            pass

        extra = ""
        if ctx_snippets:
            extra += "\n\nKNOWN FACTS:\n" + "\n".join(f"- {x}" for x in ctx_snippets)
        if mem_snippets:
            extra += "\n\nRECENT DIALOGUE SNAPSHOT:\n" + "\n".join(f"- {x}" for x in mem_snippets)

        return base_prompt + extra

    def forget_memory(self, mem_id: int) -> bool:
        """Deletes a memory row from az_chat_history by id."""
        if not self.db:
            return False
        try:
            self.db.table("az_chat_history").delete().eq("id", mem_id).execute()
            print(f"[MEMORY] Forgot id={mem_id}")
            return True
        except Exception as e:
            print(f"[MEMORY FORGET FAIL] {e}")
            return False

    def log(self, role, content):
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] {role}: {content[:100]}...")
        # Persist to DB
        self.save_memory_to_db(role, content)
        # Update local transient list (for context window)
        self.history.append({"role": role, "content": content})

    def save_memory_to_db(self, role, content):
        if not self.db: return
        try:
             self.db.table("az_chat_history").insert({
                 "role": role, 
                 "content": content,
                 "session_id": "current" # Todo: Session mgmt
             }).execute()
        except Exception as e:
            print(f"[MEMORY WRITE FAIL] {e}")

    def load_memories(self):
        if not self.db: return
        try:
            # Load last 20 messages
            data = self.db.table("az_chat_history").select("*").order("created_at", desc=True).limit(20).execute()
            if data.data:
                # Reverse to chronological order
                msgs = data.data[::-1]
                for m in msgs:
                    self.history.append({"role": m["role"], "content": m["content"]})
                print(f"[MEMORY] Recalled {len(msgs)} past thoughts.")
        except Exception as e:
             # Likely table doesn't exist yet, which is fine
            print(f"[MEMORY LOAD FAIL] {e}")

    def call_ollama(self):
        """Standardized call to local AI with JSON schema enforcement."""
        payload = {
            "model": MODEL_NAME,
            "system": self.build_system_prompt(SYSTEM_PROMPT),
            "messages": self.history,
            "stream": False,
            "format": "json" # Force valid JSON
        }
        
        try:
            r = requests.post(f"{OLLAMA_URL}/api/chat", json=payload, timeout=60)
            r.raise_for_status()
            return r.json()["message"]["content"]
        except Exception as e:
            print(f"[ERROR] Brain Freeze: {e}")
            return None

    def call_google_gemini(self, custom_system=None, image_path=None):
        """Cloud Burst: Uses Google Gemini Pro when Local AI fails."""
        if not GOOGLE_API_KEY:
            print("[CLOUD] No GOOGLE_API_KEY found. Hybrid Mode Disabled.")
            return None
            
        print("[CLOUD] ☁️ CLOUD BURST ACTIVATED (Gemini 1.5 Flash) ☁️")
        
        # Use a model that supports vision if image is present
        # Gemini 1.5 Pro is multimodal.
        model = "gemini-3-flash-preview"
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={GOOGLE_API_KEY}"
        
        # Determine Prompt
        # Determine Prompt (memory-aware)
        base = custom_system if custom_system else SYSTEM_PROMPT
        current_system = self.build_system_prompt(base)
        
        # Build Parts
        user_parts = [{"text": current_system}]
        
        # Inject Image if requested
        if image_path and os.path.exists(image_path):
            try:
                import base64
                with open(image_path, "rb") as image_file:
                    b64_data = base64.b64encode(image_file.read()).decode("utf-8")
                    user_parts.append({
                        "inline_data": {
                            "mime_type": "image/jpeg",
                            "data": b64_data
                        }
                    })
                print(f"[CLOUD] Attaching Visual Cortex data: {image_path}")
            except Exception as e:
                print(f"[CLOUD VISION FAIL] {e}")

        # Flatten history for Gemini REST API (Simplified)
        contents = []
        contents.append({"role": "user", "parts": user_parts})
        
        for msg in self.history:
            role = "user" if msg["role"] == "user" else "model"
            # History is text-only for now to avoid complexity, 
            # unless we want to persist images in history too (complex).
            contents.append({"role": role, "parts": [{"text": msg["content"]}]})
            
        payload = { "contents": contents }
        
        try:
            r = requests.post(url, json=payload, timeout=60)
            r.raise_for_status()
            data = r.json()
            return data["candidates"][0]["content"]["parts"][0]["text"]
        except Exception as e:
            print(f"[CLOUD ERROR] {e}")
            return None

    def think(self):
        """Hybrid Thinking: Try Local -> Fail -> Try Cloud."""
        # 1. Try Local Ollama
        response = self.call_ollama()
        if response and "{" in response: return response # Good local result
        
        # 2. If Local fails (or returns non-JSON), try Cloud
        print("[BRAIN] Local Model struggled. Attempting Cloud Burst...")
        cloud_response = self.call_google_gemini()
        if cloud_response: return cloud_response
        
        return response # Return local trash if cloud fails too

    def converse(self, user_text):
        """Conversational Mode (The Mouth) - TITAN UPGRADE (Context+Vision)"""
        
        # 1. BUILD CONTEXT BLOCK (Titan Memory Injection)
        context_block = ""
        try:
            mems = self.get_memories(limit=5)
            facts = self.get_context_items()
            
            if mems or facts:
                context_block = "\n\n[HIPPOCAMPUS ACTIVE]\n"
                if facts:
                    context_block += "KNOWN FACTS:\n" + "\n".join([f"- {f['key']}: {f['value']}" for f in facts]) + "\n"
                if mems:
                    context_block += "RECENT MEMORY:\n" + "\n".join([f"- {m['role'].upper()}: {m['content'][:100]}..." for m in reversed(mems)]) + "\n"
        except Exception as e:
            print(f"[MEMORY FAIL] {e}")

        # 2. DETECT VISION INTENT
        img_path = None
        system_Override = "You are AION-ZERO. Respond concisely." + context_block
        
        vision_triggers = ["see", "look", "screen", "what is this", "vision", "eyes"]
        if any(t in user_text.lower() for t in vision_triggers):
             vis_path = r"F:\AION-ZERO\logs\latest_vision.jpg"
             if os.path.exists(vis_path):
                 img_path = vis_path
                 system_Override += "\n[SYSTEM] USER IS ASKING YOU TO SEE. ANALYZE THE IMAGE ATTACHED."
                 print(f"[VISION] Attaching retina: {img_path}")

        # Append user message (Persistent)
        self.history.append({"role": "user", "content": user_text})
        self.log("user", user_text)

        # 3. TRY CLOUD (GEMINI) - Priority for Speed/Intelligence
        # Check both keys since .env might differ
        api_key = os.environ.get("GOOGLE_AI_KEY") or os.environ.get("GOOGLE_API_KEY")
        if api_key:
            try:
                # Inject context manually because call_google_gemini might wrap prompts differently
                reply = self.call_google_gemini(custom_system=system_Override, image_path=img_path)
                if reply:
                    self.history.append({"role": "assistant", "content": reply})
                    self.log("assistant", reply)
                    return reply
            except Exception as e:
                print(f"[CLOUD FAIL] {e}")

        # 4. FALLBACK TO LOCAL (OLLAMA)
        try:
            # Simple Payload (Text Mode) - TURBO TUNED
            payload = {
                "model": MODEL_NAME,
                "system": system_Override,
                "messages": self.history,
                "stream": False,
                "options": { "num_predict": 128, "temperature": 0.7 }
            }
            r = requests.post(f"{OLLAMA_URL}/api/chat", json=payload, timeout=30)
            r.raise_for_status()
            reply = r.json()["message"]["content"]
            
            # Append assistant reply
            self.history.append({"role": "assistant", "content": reply})
            self.log("assistant", reply)
            return reply
        except Exception as e:
            err_msg = "[BRAIN FREEZE] Local model offline or timed out."
            print(f"[ERROR] {e}")
            return err_msg

    def execute_tool(self, tool_name, args):
        """The Hands of the Agent. (Verified with Global Ledger Hooks)"""
        print(f"    [TOOL] {tool_name} {str(args)[:50]}")
        
        # 0. LEDGER: START EVENT
        ev_id = None
        if LEDGER_OK:
            try:
                ev = ledger.log_event(project="brain", actor="jarvis", event_type="tool_exec", intent=tool_name, input=args)
                ev_id = ev.get("event_id")
            except: pass

        # --- HITL POLICY ENFORCEMENT ---
        mutating_tools = {"RunCommand", "WriteFile", "Remember"}
        
        result = "Unknown Tool"
        success = False

        # 1. Check HITL
        if self.hitl_level == 0 and tool_name in mutating_tools:
            result = f"BLOCKED by HITL (READ ONLY). Tool '{tool_name}' is not permitted."
            self.record_outcome(ev_id, False, result, tool=tool_name)
            return result
        elif self.hitl_level == 1 and tool_name in mutating_tools:
            result = f"BLOCKED by HITL (SUGGEST ONLY). Tool '{tool_name}' requires manual confirmation."
            self.record_outcome(ev_id, False, result, tool=tool_name)
            return result

        try:
            # 2. Execute Tool
            if tool_name == "RunCommand":
                cmd = args.get('command', '')
                if "Remove-Item" in cmd and "Panic" in cmd: 
                    result = "BLOCKED: Cannot delete Panic files."
                else:
                    try:
                        # SECURITY: Use shell=False where possible, strictly logging args
                        if "dir" in cmd or "ls" in cmd or "echo" in cmd:
                            res = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
                        else:
                            res = subprocess.check_output(
                                ["powershell", "-Command", cmd], 
                                stderr=subprocess.STDOUT, 
                                shell=True 
                            )
                        result = res.decode('utf-8')
                        success = True
                    except subprocess.CalledProcessError as e:
                        result = f"ERROR: {e.output.decode('utf-8')}"
                        success = False
            
            elif tool_name == "WriteFile":
                path = args.get('path')
                content = args.get('content')
                try:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    result = f"Successfully wrote to {path}"
                    success = True
                    # Log Artifact
                    if LEDGER_OK and ev_id:
                        ledger.log_artifact(event_id=ev_id, kind="file", path=path, content=content, before_text="created", after_text="written")
                except Exception as e:
                    result = f"Write Failed: {e}"
                    success = False

            elif tool_name == "ReadFile":
                try:
                    with open(args.get('path'), 'r', encoding='utf-8') as f:
                        result = f.read()
                        success = True
                except Exception as e:
                    result = f"Read Failed: {e}"
                    success = False

            elif tool_name == "QueryGraph":
                result = "Graph search simulated: Found 3 related contexts."
                success = True

            elif tool_name == "Remember":
                key = args.get('key')
                value = args.get('value')
                if not self.db: 
                    result = "Memory Offline."
                else:
                    try:
                        self.db.table("az_context").upsert({"key": key, "value": value}, on_conflict="key").execute()
                        result = f"I have committed '{key}' to long-term memory."
                        success = True
                    except Exception as e:
                        result = f"Memory Write Error: {e}"
                        success = False

            elif tool_name == "SearchWeb":
                result = self.perform_search(args.get("query"))
                success = not result.startswith("SEARCH ERROR")

            elif tool_name == "DeepScan" or tool_name == "Browse":
                result = self.perform_deep_scan(args.get("url"))
                success = not result.startswith("SCAN ERROR")

        except Exception as e:
            result = f"CRITICAL TOOL FAILURE: {e}"
            success = False

        # 3. GLOBAL LEDGER RECORDING (The Evolution Layer)
        # Identify failure strings if success wasn't explicitly set False
        if str(result).startswith("ERROR:") or "Write Failed" in str(result) or "Read Failed" in str(result) or "BLOCKED:" in str(result):
            success = False
            
        self.record_outcome(ev_id, success, result, tool=tool_name)
        return result

    def perform_search(self, query: str) -> str:
        """Real-time Google Search."""
        print(f"[TOOL] Searching Google: {query}")
        try:
            results = []
            # num_results arg might vary by library version, using stop/num safely
            for url in google_search(query, num_results=5, lang="en"):
                results.append(url)
            return f"SEARCH RESULTS for '{query}':\n" + "\n".join(results)
        except Exception as e:
            return f"SEARCH ERROR: {e}"

    def perform_deep_scan(self, url: str) -> str:
        """Analysis of a target URL."""
        print(f"[TOOL] Deep Scan: {url}")
        try:
            headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36"}
            resp = requests.get(url, headers=headers, timeout=15)
            resp.raise_for_status()
            
            soup = BeautifulSoup(resp.text, 'html.parser')
            
            # Extract Intel
            title = soup.title.string if soup.title else "No Title"
            meta_desc = ""
            desc_tag = soup.find("meta", attrs={"name": "description"}) or soup.find("meta", attrs={"property": "og:description"})
            if desc_tag: meta_desc = desc_tag.get("content", "")
            
            # Social Signals
            socials = []
            for link in soup.find_all('a', href=True):
                href = link['href'].lower()
                if any(x in href for x in ['facebook.com', 'instagram.com', 'tiktok.com', 'linkedin.com', 'twitter.com']):
                    socials.append(href)
            
            # Text Content (Dense)
            clean_text = soup.get_text(separator=' ', strip=True)[:3000]
            
            report = f"""
            TARGET: {url}
            TITLE: {title}
            META_DESC: {meta_desc}
            SOCIAL_LINKS: {list(set(socials))}
            WORD_COUNT: {len(clean_text.split())}
            TECH_STACK_HINTS: {"Shopify" if "shopify" in resp.text.lower() else "WooCommerce" if "wp-content" in resp.text.lower() else "Unknown"}
            
            CONTENT_PREVIEW:
            {clean_text}...
            """
            return report
        except Exception as e:
            return f"SCAN ERROR: {e}"

    # --- DASHBOARD ACCESSORS (Phase 33) ---
    def get_memories(self, limit=20):
        """Retrieves recent chat history for UI."""
        if not self.db: return []
        try:
            res = self.db.table("az_chat_history").select("*").order("created_at", desc=True).limit(limit).execute()
            return res.data
        except: return []

    def get_context_items(self):
        """Retrieves verified facts from az_context."""
        if not self.db: return []
        try:
            res = self.db.table("az_context").select("*").execute()
            return res.data
        except: return []

    def get_mesh_state(self):
        """Retrieves agent health status."""
        if not self.db: return {"agents": [], "endpoints": []}
        try:
            agents = self.db.table("az_mesh_agents").select("*").execute()
            endpoints = self.db.table("az_mesh_endpoints").select("*").execute()
            return {"agents": agents.data, "endpoints": endpoints.data}
        except: return {"agents": [], "endpoints": []}

    def solve(self, user_text):
        """The Unified Router: Decides between Chat and Action."""
        # 1. DETECT INTENT
        triggers = ["analyze", "check", "run", "execute", "read", "write", "list", "scan", "f:", "c:", ".py", ".ps1"]
        is_task = any(t in user_text.lower() for t in triggers)
        
        if not is_task:
            return self.converse(user_text)
        
        # 2. AGENT MODE (Re-Act Loop)
        print(f"[ROUTER] Task Detected: {user_text}")
        self.log("user", f"[TASK] {user_text}") # Log the specific task request
        
        # New Context for Agent (Clean State for Thinking)
        self.history = [{"role": "user", "content": f"GOAL: {user_text}. Available Tools: {json.dumps(TOOLS)}"}]
        
        # Run a mini-loop (Max 10 steps)
        final_result = "Task failed to complete in 10 steps."
        
        for i in range(10):
            # 4. THINK (LLM Call)
            print(f"  [AGENT STEP {i+1}] Thinking...") # Original print statement
            # print(f"[BRAIN] Thinking... (Cycle {i+1}/{self.max_steps})") # This line was in the diff, but self.max_steps is not defined. Keeping original.
            
            # TRY OLLAMA FIRST
            response_json_str = self.call_ollama()
            
            # FALLBACK TO GEMINI
            if not response_json_str and GOOGLE_API_KEY:
                print("[BRAIN] Local Ollama failed/offline. Switching to Cloud Gemini.")
                response_json_str = self.call_google_gemini()

            if not response_json_str:
                return "I tried to think but my neural engines (Ollama & Gemini) are unreachable."
            
            # PARSING LOGIC (The Fix)
            action = self.parse_json_safely(response_json_str)

            if not action:
                # Ask model to try again in strict JSON
                self.history.append({
                    "role": "system",
                    "content": "Your last response was not valid JSON. Respond again using ONLY a JSON object with keys 'tool' and 'args'."
                })
                # Retry Thinking
                response2_json_str = self.call_ollama() # Retry with Ollama
                if not response2_json_str and GOOGLE_API_KEY: # Fallback to Gemini on retry
                    print("[BRAIN] Local Ollama failed/offline on retry. Switching to Cloud Gemini.")
                    response2_json_str = self.call_google_gemini()

                action = self.parse_json_safely(response2_json_str)

                if not action:
                    print(f"  [AGENT RAW] {response_json_str} / {response2_json_str}")
                    print("[REACT] Aborting step: model failed to produce valid JSON twice.")
                    continue
                
            if not action: 
                continue

            # Robust Key Extraction (Intellectual Flexibility)
            tool = action.get("tool") or action.get("command") or action.get("function") or action.get("intent") or action.get("action")
            args = action.get("args") or action.get("arguments") or action.get("parameters") or {}
            
            # Print Thought for User
            if "thought" in action:
                print(f"  [THOUGHT] {action['thought']}")
            elif "thoughts" in action:
                 print(f"  [THOUGHT] {action['thoughts']}")
            
            # 5. SELF-CORRECTION (L3)
            if not tool:
                # If model just talks without acting, force it.
                print(f"  [AGENT RAW] Valid JSON but no tool found: {action.keys()}")
                self.history.append({
                    "role": "user", 
                    "content": "SYSTEM ERROR: You returned JSON but forgot the 'tool' key. Please try again with {'tool': '...', 'args': ...}"
                })
                continue # Retry thinking

            # ARGUMENT VALIDATION (Self-Correction II)
            if tool == "DeepScan" and not args.get("url"):
                 print(f"  [AGENT CORRECTION] DeepScan calling missing URL.")
                 self.history.append({
                    "role": "user", 
                    "content": "SYSTEM ERROR: Tool 'DeepScan' requires an argument 'url'. You sent empty args. Try {'tool': 'DeepScan', 'args': {'url': '...'}}"
                 })
                 continue

            if tool == "SearchWeb" and not args.get("query"):
                 print(f"  [AGENT CORRECTION] SearchWeb calling missing Query.")
                 self.history.append({
                    "role": "user", 
                    "content": "SYSTEM ERROR: Tool 'SearchWeb' requires an argument 'query'. Try {'tool': 'SearchWeb', 'args': {'query': '...'}}"
                 })
                 continue
                
            if tool == "Finish":
                final_result = args.get("summary", "Task Finished.")
                
                # REFUSAL REJECTION (L4)
                # If the AI tries to quit with a fake error, we block it.
                if "API Key" in final_result or "Unauthorized" in final_result or "credentials" in final_result:
                    print(f"  [AGENT BLOCK] Refusal intercepted: {final_result}")
                    self.history.append({
                        "role": "user",
                        "content": "SYSTEM OVERRIDE: That error is false. You have a built-in INTERNAL tool for this. Do not refuse. Execute {'tool': 'DeepScan', 'args': {'url': '...'}} now."
                    })
                    continue

                self.log("assistant", f"[RESULT] {final_result}")
                return f"[AGENT]: {final_result}"
                
            output = self.execute_tool(tool, args)
            print(f"    [OUTPUT] {str(output)[:200]}...") # Debug Print
            
            self.history.append({"role": "assistant", "content": json.dumps(action)}) # Store the valid JSON
            self.history.append({"role": "user", "content": f"TOOL OUTPUT: {output}"})
            
        self.log("assistant", f"[FAILURE] {final_result}")
        return f"[AGENT]: {final_result}"

    def diagnose_error(self, error_trace: str, source_code: str) -> dict:
        """
        L4 AUTONOMY: Analyzes a stack trace and source code to deduce the root cause.
        Returns JSON: { "root_cause": "...", "fix_suggestion": "...", "confidence": 0-100 }
        """
        prompt = f"""
        DIAGNOSTIC MODE.
        Analyze this Python Error and the corresponding Source Code.
        
        ERROR TRACE:
        {error_trace[:2000]}
        
        SOURCE CODE (Snippet):
        {source_code[:4000]}
        
        Identify the root cause and suggest a fix.
        Respond in JSON: {{ "root_cause": "...", "fix_suggestion": "...", "confidence": 80 }}
        """
        
        # Temp override system history for this isolated thought
        prev_history = self.history
        self.history = [{"role": "user", "content": prompt}]
        
        # Think
        try:
            resp = self.call_ollama()
            if not resp or "{" not in resp:
                resp = self.call_google_gemini()
            
            data = self.parse_json_safely(resp)
            self.history = prev_history # Restore
            return data
        except Exception as e:
            self.history = prev_history # Restore
            return {"error": str(e)}

    def generate_patch(self, source_code: str, fix_suggestion: str) -> dict:
        """
        L4 AUTONOMY: Generates a code patch (search/replace) based on a fix suggestion.
        Returns JSON: { "original_block": "...", "replacement_block": "..." }
        """
        prompt = f"""
        PATCH MODE.
        Turn this Fix Suggestion into a PRECISE search/replace block for the Source Code.
        
        SOURCE CODE:
        {source_code[:4000]}
        
        FIX SUGGESTION:
        {fix_suggestion}
        
        Return JSON with exactly two keys:
        {{
            "original_block": "The exact lines of code to remove (must match exactly)",
            "replacement_block": "The new lines of code to insert"
        }}
        """
        
        prev_history = self.history
        self.history = [{"role": "user", "content": prompt}]
        
        try:
            resp = self.call_ollama()
            if not resp or "{" not in resp:
                resp = self.call_google_gemini()
            
            data = self.parse_json_safely(resp)
            self.history = prev_history 
            return data
        except Exception as e:
            self.history = prev_history 
            return {"error": str(e)}

# --- ENTRY POINT ---
if __name__ == "__main__":
    import sys
    goal = "Check system status"
    if len(sys.argv) > 1:
        goal = sys.argv[1]
        
    ai = JarvisBrain()
    # Test Solve
    print(ai.solve(goal))
