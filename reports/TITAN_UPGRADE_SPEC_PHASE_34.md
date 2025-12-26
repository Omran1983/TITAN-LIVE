# 🧬 AION-ZERO – TITAN UPGRADE SPEC (PHASE 34)

**Scope:** Convert AION-ZERO from “Prototype Class” to “Operational Titan Class” by wiring missing links between Brain, Citadel, Agents, Mesh, Memory, and Reflex.

**Core Files Involved (current state):**

* `F:\AION-ZERO\citadel\server.py` 
* `F:\AION-ZERO\py\jarvis_brain_local.py` 
* `F:\AION-ZERO\py\jarvis_vision.py` 
* `F:\AION-ZERO\citadel\static\index.html` 

---

## 1. INTELLIGENCE BOOST (Brain Upgrade)

### 🎯 Goal

Make Jarvis “not dumb”: stronger reasoning, fewer JSON failures, better task handling.

### 🔍 Current State

* Local model: `phi3:mini` (too weak for JSON ReAct). 
* Cloud path (Gemini) exists but is secondary and noisy.
* Memory is saved but not heavily used for reasoning.

### 🛠️ Implementation Steps

**1.1 Model Upgrade**

In `jarvis_brain_local.py`:

* Change default model:

```python
MODEL_NAME = os.environ.get("AZ_LOCAL_MODEL", "qwen2.5-coder:7b")
```

* Set this env in your system so no code changes required later:

  * `AZ_LOCAL_MODEL=qwen2.5-coder:7b`

**1.2 Tighten Conversation Prompt**

In `converse()`:

* Ensure `system` prompt is concise and control-plane specific, e.g.:

```python
"system": "You are AION-ZERO, the control-plane brain. Respond concisely, with actions and next steps."
```

**1.3 Memory-Aware Context**

Before calling Gemini or Ollama:

* Fetch last N memories from `az_chat_history` + all from `az_context` using existing helpers: `get_memories()` and `get_context_items()` 
* Inject a compact summary into the prompt:

> “KNOWN FACTS: …
> RECENT DIALOGUE: …”

This turns memory from “write-only” into **live context**.

---

## 2. DIRECT CHAT PATH (`/api/chat/direct`)

### 🎯 Goal

Have one **fast, intelligent** chat route that bypasses slow task loops & voice.

### 🔍 Current State

* `/api/chat` → `JarvisBrain.solve()` + speech via `Jarvis-Voice.ps1`. 
* Heavy ReAct logic runs even for simple questions → slow.

### 🛠️ Implementation Steps

**2.1 Add New Endpoint**

In `server.py`:

```python
@app.route('/api/chat/direct', methods=['POST'])
def chat_direct():
    try:
        data = request.json or {}
        user_msg = data.get("message", "")
        if not user_msg:
            return jsonify({"reply": "No input received."})

        print(f"[DIRECT CHAT] {user_msg}")
        final_reply = GLOBAL_BRAIN.converse(user_msg)
        return jsonify({"reply": final_reply})
    except Exception as e:
        print(f"[DIRECT CHAT ERROR] {e}")
        return jsonify({"reply": f"Error: {str(e)}"}), 500
```

**2.2 Citadel UI Switch Option**

In `index.html`, optionally:

* Either change `/api/chat` → `/api/chat/direct`
* Or add a toggle later (“Agent Mode vs Direct Mode”).

This gives you a **high-IQ fast lane** while keeping the agent path intact.

---

## 3. MESH NETWORK ACTIVATION

### 🎯 Goal

Turn the Mesh panel from “fake” into a **live map of running agents**.

### 🔍 Current State

* `/api/mesh/status` in `server.py` calls `GLOBAL_BRAIN.get_mesh_state()`. 
* `JarvisBrain.get_mesh_state()` reads `az_mesh_agents` & `az_mesh_endpoints`. 
* No agent currently writes to those tables → UI shows empty “Initializing Mesh...”.

### 🛠️ Implementation Steps

**3.1 DB Schema**

From your `sql` pack: ensure tables:

* `az_mesh_agents(agent_name, status, last_seen, latency_ms, extra)`
* `az_mesh_endpoints(name, url, status, last_checked)`

are created and migrated.

**3.2 Agent Heartbeat Helper (PowerShell)**

Create a reusable PS function (e.g. `Jarvis-MeshHeartbeat.ps1`) each agent can call:

* Inputs:

  * `-AgentName`
  * `-LatencyMs`
  * Optional: `-Status`

Action:

* Upsert into `az_mesh_agents` via Supabase REST or PowerShell module.

Each agent (CodeAgent, Watchdog, CommandsApi worker, etc.):

* Calls heartbeat every 10–30 seconds.
* On start: status = `active`
* On graceful stop: status = `offline`

**3.3 Endpoint Health**

A small scheduled worker (Python or PS) pings:

* CommandsApi (port 5051)
* Citadel (port 5000)
* MeshProxy (port 5055)

Writes into `az_mesh_endpoints`.

Result: Citadel’s **Mesh panel** becomes truthful & alive.

---

## 4. RE-ACT AGENT STABILISATION

### 🎯 Goal

Make `JarvisBrain.solve()` actually complete tasks instead of looping/failing. 

### 🔍 Current State

* Response expected as JSON.
* LLM often returns non-JSON → parse fail → nag prompt.
* Local `phi3:mini` struggled; even with better model, need guardrails.

### 🛠️ Implementation Steps

**4.1 JSON Sanitizer Layer**

After `self.think()`:

* Strip ```json fences
* Attempt `json.loads`
* If fail:

  * Append an explicit correction message into history:

    > “SYSTEM: That was not valid JSON. Respond ONLY with a JSON object: { ... }”

  * Retry up to N times.

**4.2 Strict Tool White-list**

In `execute_tool()`:

* Enforce a safe set of commands and directories.
* Hard reject anything that attempts dangerous operations outside whitelisted paths.

**4.3 Step Logging**

Each agent step:

* Logs `{step, thought, tool, args_summary}`
* Writes optional audit row to `az_agent_traces` (future).

This makes agent runs **debbugable and auditable**.

---

## 5. LIVE VISION FEED (REAL “EYES”)

### 🎯 Goal

Upgrade from “single screenshot” to a **live feed** for Citadel.

### 🔍 Current State

* `jarvis_vision.py` captures one screenshot, saves `latest_vision.jpg`, optionally analyzes, and exits. 
* Citadel refreshes `/api/vision/latest` every few seconds. 

### 🛠️ Implementation Steps

**5.1 Add Loop Mode**

In `jarvis_vision.py`:

* Add a `--loop` flag.
* When `--loop` passed:

  * Capture screenshot
  * Save to `latest_vision.jpg`
  * (Optionally) skip heavy analysis to avoid cost
  * Sleep 1–3 seconds
  * Repeat until a stop signal (e.g. panic lock file) is seen.

**5.2 Background Task**

Citadel `/api/execute` already supports `vision_scan` launch: 

* Update your scheduled tasks or a simple “VisionRunner.ps1” that runs `jarvis_vision.py --loop` at startup (or when enabled).

Result: Citadel Vision panel becomes **actually live**, not static.

---

## 6. MEMORY STREAM + FORGET

### 🎯 Goal

Make the Hippocampus panel truly reflect **chat history and key context**.

### 🔍 Current State

* `JarvisBrain.save_memory_to_db()` writes into `az_chat_history`. 
* `get_memories()` returns last N entries.
* `/api/memory/recent` returns that list. 
* Citadel UI already queries `/api/memory/recent?limit=10` and renders entries. 
* Missing: proper `az_chat_history` table in DB, and “Forget” action.

### 🛠️ Implementation Steps

**6.1 Ensure `az_chat_history` Schema**

Columns: `id, created_at, role, content, session_id`.

**6.2 Add Forget Endpoint**

In `server.py`:

```python
@app.route('/api/memory/forget', methods=['POST'])
def memory_forget():
    try:
        mem_id = request.json.get("id")
        if not mem_id:
            return jsonify({"error": "Missing id"}), 400
        ok = GLOBAL_BRAIN.forget_memory(mem_id)
        return jsonify({"status": "ok" if ok else "not_found"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
```

In `JarvisBrain`, add `forget_memory(id)` that deletes from `az_chat_history`.

**6.3 UI “Forget” Button**

In `index.html`, for each memory entry, add an icon/button that posts to `/api/memory/forget` and refreshes the panel.

---

## 7. AUTONOMY LEVEL ENFORCEMENT

### 🎯 Goal

Make the slider **actually change behavior**, not just UI. 

### 🔍 Current State

* `HITL_LEVEL` global in `server.py` with `/api/settings/autonomy` GET/POST.
* UI updates & polls this level. 
* No agent reads this level.

### 🛠️ Implementation Steps

**7.1 Expose HITL to Agents**

Options:

* Store in Supabase table `az_settings` (`key="HITL_LEVEL"`).
* Or expose via `/api/settings/autonomy` and let agents poll it.

**7.2 Enforce in `JarvisBrain` and PS Agents**

Rules:

* Level 0 (READ ONLY):

  * `execute_tool` returns “Blocked by HITL policy” for all mutating tools.
* Level 1 (SUGGEST):

  * Agent produces plans but does not call dangerous tools automatically.
* Level 2 (ACT):

  * Tools allowed on whitelisted paths and known-safe commands.
* Level 3 (GOD):

  * Full power (subject to hard safety rules only).

Result: Slider becomes a **real control-plane policy**, not cosmetics.

---

## 8. REFLEX ENGINE (SELF-HEALING)

### 🎯 Goal

Let the system auto-recover from common failures.

### 🔍 Current State

* Watchdog log exists.
* Panic-Stop exists.
* No automatic “if X breaks → restart Y” logic.

### 🛠️ Implementation Steps

**8.1 Reflex Rules Table** (optional but nice)

Define `az_reflex_rules` with conditions and actions like:

* Condition: `agent_offline > 60s` → Action: `restart_agent("CodeAgent")`
* Condition: `Panic lock present` → Action: `stop_all_agents()`

**8.2 Reflex Worker**

A simple loop:

* Reads health signals (mesh + watchdog + endpoints).
* Matches against rules.
* Executes scripts (e.g., `Jarvis-StartCodeAgent.ps1`, `Panic-Stop.ps1`).

**8.3 Citadel View**

Later, show last N reflex actions in the UI (Reflex panel).

---

## 9. CITADEL UI TRUTH ALIGNMENT

### 🎯 Goal

Make the dashboard **honest**: visuals match real backend capability.

### 🔍 Current State

* Visually: 10/10.
* Data-wise: 5/10 (lots of placeholders). 

### 🛠️ Implementation Steps

* Ensure:

  * `/api/status` truly reflects Watchdog and core health. 
  * `/api/mesh/status` returns real agents.
  * `/api/memory/recent` returns recent chat data.
  * Autonomy slider affects behavior as per HITL.
  * Vision feed updates frequently via `latest_vision.jpg`.

Once the backend pieces above are wired, the UI becomes **a real cockpit, not a trailer.**

---

## 10. PERFORMANCE & SAFETY PASS

### 🎯 Goal

Prevent “slow and dumb” or “crash on small issues” behavior.

### 🔍 Implementation Summary

* Turn off `debug=True` in production for `server.py`. 
* Add timeouts & exception logging around all external calls (Ollama, Gemini, Supabase).
* Use shorter context windows where possible.
* Trim chat history to last N messages per session.
* Add `Panic-Stop` lock-checks in:

  * CommandsApi
  * Agents
  * Vision loop

---

## 🏁 FINAL STATUS LINE

After implementing this spec, AION-ZERO moves from:

> **“Prototype with a gorgeous UI” → “Real control-plane with live agents, memory, vision, and enforceable autonomy.”**
