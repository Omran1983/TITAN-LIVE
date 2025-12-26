"""
CITADEL SERVER (PHASE 19)
-------------------------
Serves the Glass Citadel Dashboard.
Exposes System Vital Signs via JSON API.
"""

import os
import json
import os
import sys
import json
import subprocess
from flask import Flask, jsonify, send_from_directory, request
from flask_cors import CORS

# Load .env manually for robustness (ensure API keys are present)
env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.env')
if os.path.exists(env_path):
    print(f"[CITADEL] Loading .env from {env_path}")
    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip().strip('"').strip("'")
                if key not in os.environ:
                    os.environ[key] = value

# path hack to import from ../py
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'py')))
from jarvis_brain_local import JarvisBrain

app = Flask(__name__, static_folder='static')
CORS(app)

# LOG PATHS
WATCHDOG_LOG = r"F:\AION-ZERO\scripts\Jarvis-Watchdog.log"
REFLEX_LOG_DIR = r"F:\AION-ZERO\logs\reflex"
OKASINA_WEBHOOK_SECRET = os.getenv("OKASINA_WEBHOOK_SECRET", "")

# --- Titan Command: Active business selection ---
ACTIVE_BUSINESS_SLUG = "aogrl_deliveries"  # change this to switch business

def get_active_business_id(db):
    """
    Look up active business from 'az_businesses' table.
    """
    res = db.table("az_businesses") \
        .select("id, slug") \
        .eq("slug", ACTIVE_BUSINESS_SLUG) \
        .single() \
        .execute()
    return res.data["id"]

def get_business_id_by_slug(db, slug: str) -> int:
    res = db.table("az_businesses") \
        .select("id,slug") \
        .eq("slug", slug) \
        .single() \
        .execute()
    return res.data["id"]

def get_endpoint_health_summary():
    """Return a compact view of az_mesh_endpoints for the status API."""
    try:
        rows = GLOBAL_BRAIN.db.table("az_mesh_endpoints") \
            .select("name,status,latency_ms,last_checked") \
            .order("last_checked", desc=True) \
            .limit(20) \
            .execute()
        return rows.data or []
    except Exception as e:
        print(f"[STATUS] endpoint health fetch failed: {e}")
        return []

def get_reflex_recent_actions(limit: int = 20):
    """Return recent reflex actions from az_reflex_log."""
    try:
        rows = GLOBAL_BRAIN.db.table("az_reflex_log") \
            .select("created_at,agent_name,action,reason") \
            .order("created_at", desc=True) \
            .limit(limit) \
            .execute()
        return rows.data or []
    except Exception as e:
        print(f"[STATUS] reflex log fetch failed: {e}")
        return []

@app.route('/')
def serve_index():
    return send_from_directory('static', 'index.html')

@app.route('/api/status')
def get_status():
    """Aggregates system health metrics."""
    try:
        endpoints = get_endpoint_health_summary()
        reflex    = get_reflex_recent_actions(limit=10)

        data = {
            "status": "ONLINE",
            "timestamp": os.popen("time /t").read().strip(),
            "watchdog": "UNKNOWN",
            "endpoints": endpoints,
            "reflex": reflex
        }
        
        # 1. Check Watchdog Log for Liveness
        try:
            if os.path.exists(WATCHDOG_LOG):
                with open(WATCHDOG_LOG, "r") as f:
                    last_line = f.readlines()[-1].strip()
                data["watchdog"] = "ACTIVE" if "OK" in last_line or "WATCHDOG" in last_line else "WARNING"
                data["watchdog_detail"] = last_line
        except:
             data["watchdog"] = "OFFLINE"
             
        return jsonify(data)

    except Exception as e:
        print(f"[STATUS ERROR] {e}")
        return jsonify({
            "status": "error",
            "time": os.popen("time /t").read().strip(),
            "error": str(e)
        }), 500

@app.route('/api/vision/latest')
def get_vision_feed():
    """Serves the latest visual capture."""
    feed_path = r"F:\AION-ZERO\logs\latest_vision.jpg"
    if os.path.exists(feed_path):
        return send_from_directory(r"F:\AION-ZERO\logs", "latest_vision.jpg")
    return "No Visual Feed", 404

import subprocess

@app.route('/api/execute', methods=['POST'])
def execute_command():
    from flask import request
    cmd = request.json.get('command')
    args = request.json.get('args', "")
    
    print(f"[CITADEL] Executing: {cmd}")
    
    try:
        if cmd == "vision_scan":
            # Run vision in background
            subprocess.Popen(["python", r"F:\AION-ZERO\py\jarvis_vision.py", "--save"])
            return jsonify({"status": "Scanning..."})
            
        elif cmd == "voice_speak":
            # Speak text
            subprocess.Popen(["powershell", "-ExecutionPolicy", "Bypass", "-File", r"F:\AION-ZERO\scripts\Jarvis-Voice.ps1", "-Text", f'"{args}"'])
            return jsonify({"status": "Speaking..."})
            
        elif cmd == "launch_puppet":
            # Run Puppet
            subprocess.Popen(["powershell", "-ExecutionPolicy", "Bypass", "-File", r"F:\AION-ZERO\scripts\Jarvis-Puppet.ps1"])
            return jsonify({"status": "Launching Puppet..."})

        elif cmd == "kill_switch":
            subprocess.Popen(["powershell", "-ExecutionPolicy", "Bypass", "-File", r"F:\AION-ZERO\scripts\Panic-Stop.ps1"])
            return jsonify({"status": "EMERGENCY STOP TRIGGERED"})
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500
        
    return jsonify({"error": "Unknown Command"}), 400

# GLOBAL BRAIN INSTANCE (Short-term Conversation Memory)
GLOBAL_BRAIN = JarvisBrain()

@app.route('/api/chat', methods=['POST'])
def chat_endpoint():
    try:
        data = request.json
        user_msg = data.get("message", "")
        if not user_msg:
            return jsonify({"reply": "Silence received."})
            
        print(f"[CHAT] Users says: {user_msg}")
        
        # 1. Think (Using Persistent Brain)
        # Unified Router (Chat vs Agent)
        final_speech = GLOBAL_BRAIN.solve(user_msg)
        print(f"[BRAIN REPLY]: {final_speech}")

        # 2. Speak (Mouth)
        # Sanitize for PowerShell
        safe_reply = str(final_speech).replace('"', "'").replace("\n", " ")[:200]
        subprocess.Popen(["powershell", "-ExecutionPolicy", "Bypass", "-File", r"F:\AION-ZERO\scripts\Jarvis-Voice.ps1", "-Text", f'"{safe_reply}"'])
        
        return jsonify({"reply": final_speech})
        
    except Exception as e:
        print(f"[CHAT ERROR] {e}")
        return jsonify({"reply": f"Error: {str(e)}"}), 500

@app.route('/api/chat/direct', methods=['POST'])
def chat_direct():
    """Fast, direct conversational path (no agent loop, no voice)."""
    try:
        data = request.get_json(silent=True) or {}
        msg = data.get("message", "")
        if not msg:
            return jsonify({"reply": "No input received."}), 400

        print(f"[DIRECT CHAT] {msg}")
        reply = GLOBAL_BRAIN.converse(msg)
        return jsonify({"reply": reply})
    except Exception as e:
        print(f"[DIRECT CHAT ERROR] {e}")
        return jsonify({"reply": f"Error: {str(e)}"}), 500

# --- CITADEL V2 API ENDPOINTS (Phase 33) ---

@app.route('/api/mesh/status', methods=['GET'])
def mesh_status():
    """Returns the state of the Agent Mesh."""
    # Call Brain's accessor
    data = GLOBAL_BRAIN.get_mesh_state()
    return jsonify(data)

@app.route('/api/memory/recent', methods=['GET'])
def memory_recent():
    """Returns recent chat history (Long Term)."""
    limit = request.args.get('limit', 20)
    data = GLOBAL_BRAIN.get_memories(limit=int(limit))
    return jsonify(data)

@app.route('/api/memory/forget', methods=['POST'])
def memory_forget():
    """Forget a single memory row by id."""
    try:
        data = request.get_json(silent=True) or {}
        mem_id = data.get("id")
        if mem_id is None:
            return jsonify({"error": "Missing id"}), 400

        ok = GLOBAL_BRAIN.forget_memory(mem_id)
        return jsonify({"status": "ok" if ok else "not_found"})
    except Exception as e:
        print(f"[MEMORY FORGET ERROR] {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/memory/context', methods=['GET'])
def memory_context():
    """Returns key-value context facts."""
    data = GLOBAL_BRAIN.get_context_items()
    return jsonify(data)

@app.route('/api/reflex/logs', methods=['GET'])
def api_reflex_logs():
    """Expose recent reflex actions for Citadel panels."""
    try:
        limit = int(request.args.get("limit", 50))
        data = get_reflex_recent_actions(limit=limit)
        return jsonify({"items": data})
    except Exception as e:
        print(f"[REFLEX LOGS ERROR] {e}")
        return jsonify({"error": str(e)}), 500

# --- PHASE 37: BUSINESS COCKPIT APIs (V2 - AZ NATIVE) ---

@app.route('/api/biz/kpis', methods=['GET'])
def api_biz_kpis():
    """
    Finance + Sales snapshot for TODAY, scoped to ACTIVE_BUSINESS_SLUG.
    Uses tables:
      - az_sales_events (Unified Revenue)
      - az_expense_events (Unified Costs)
    """
    try:
        db = GLOBAL_BRAIN.db
        if not db:
            raise RuntimeError("Supabase client not configured in GLOBAL_BRAIN.")

        biz_id = get_active_business_id(db)

        from datetime import datetime, timezone
        now = datetime.now(timezone.utc)
        today_str = now.strftime("%Y-%m-%d")

        # --- Revenue (az_sales_events) ---
        sales_res = db.table("az_sales_events") \
            .select("amount, type, created_at") \
            .eq("business_id", biz_id) \
            .gte("date", today_str) \
            .execute()

        sales = sales_res.data or []
        today_revenue = 0.0
        orders_today = len(sales)

        for s in sales:
            try:
                today_revenue += float(s.get("amount") or 0)
            except:
                pass

        avg_order_value = today_revenue / orders_today if orders_today > 0 else 0.0

        # --- Expenses (az_expense_events) ---
        exp_res = db.table("az_expense_events") \
            .select("amount, created_at") \
            .eq("business_id", biz_id) \
            .gte("date", today_str) \
            .execute()

        expenses_rows = exp_res.data or []
        expenses_today = 0.0
        for e in expenses_rows:
            try:
                expenses_today += float(e.get("amount") or 0)
            except:
                pass

        approx_profit_today = today_revenue - expenses_today
        refunds_today = 0  # To be implemented if 'type=refund' exists in events

        data = {
            "today_revenue": round(today_revenue, 2),
            "orders_today": orders_today,
            "avg_order_value": round(avg_order_value, 2),
            "refunds_today": refunds_today,
            "expenses_today": round(expenses_today, 2),
            "approx_profit_today": round(approx_profit_today, 2),
        }
        return jsonify(data)
    except Exception as e:
        print(f"[BIZ KPIS ERROR] {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/biz/ops', methods=['GET'])
def api_biz_ops():
    """
    Operations timeline for TODAY using 'az_deliveries' and 'az_ops_tickets'.
    """
    try:
        db = GLOBAL_BRAIN.db
        if not db:
            raise RuntimeError("Supabase client not configured in GLOBAL_BRAIN.")

        biz_id = get_active_business_id(db)

        from datetime import datetime, timezone
        now = datetime.now(timezone.utc)
        today_str = now.strftime("%Y-%m-%d")

        # 1. Deliveries
        deliv_res = db.table("az_deliveries") \
            .select("ref_code, client_name, status, created_at") \
            .eq("business_id", biz_id) \
            .gte("created_at", today_str) \
            .order("created_at", desc=True) \
            .limit(20) \
            .execute()
        
        deliveries = deliv_res.data or []

        # 2. Tickets
        ticket_res = db.table("az_ops_tickets") \
            .select("title, type, status, created_at") \
            .eq("business_id", biz_id) \
            .gte("created_at", today_str) \
            .order("created_at", desc=True) \
            .limit(20) \
            .execute()
            
        tickets = ticket_res.data or []

        items = []

        # Merge Deliveries
        for d in deliveries:
            created = d.get("created_at") or ""
            ref = d.get("ref_code") or "?"
            client = d.get("client_name") or "Unknown"
            status = str(d.get("status")).upper()
            
            try:
                dt = datetime.fromisoformat(str(created).replace("Z", "+00:00"))
                time_str = dt.strftime("%H:%M")
            except:
                time_str = str(created)[:16]

            ev = f"Delivery [{ref}] for {client}: {status}"
            items.append({"time": time_str, "event": ev, "level": "info"})

        # Merge Tickets
        for t in tickets:
            created = t.get("created_at") or ""
            title = t.get("title")
            ttype = t.get("type")
            
            try:
                dt = datetime.fromisoformat(str(created).replace("Z", "+00:00"))
                time_str = dt.strftime("%H:%M")
            except:
                time_str = str(created)[:16]
                
            ev = f"Ticket ({ttype}): {title}"
            items.append({"time": time_str, "event": ev, "level": "warning"})

        # Sort combined list by time desc (simple string sort approximation or we rely on client)
        # For now, just sending back mixed list, user sees recent stuff.
        
        return jsonify({"items": items})
    except Exception as e:
        print(f"[BIZ OPS ERROR] {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/biz/ops/kpis', methods=['GET'])
def api_biz_ops_kpis():
    """
    Operations KPIs for TODAY from 'az_deliveries'.
    """
    try:
        db = GLOBAL_BRAIN.db
        if not db:
            raise RuntimeError("Supabase client not configured in GLOBAL_BRAIN.")
        
        biz_id = get_active_business_id(db)

        from datetime import datetime, timezone
        now = datetime.now(timezone.utc)
        today_str = now.strftime("%Y-%m-%d")

        res = db.table("az_deliveries") \
            .select("status, created_at") \
            .eq("business_id", biz_id) \
            .gte("created_at", today_str) \
            .execute()

        rows = res.data or []
        total = len(rows)
        # Simplified metrics for V2 start
        delivered = [r for r in rows if "delivered" in str(r.get("status")).lower()]

        data = {
            "deliveries_today": total,
            "delivered_on_time": len(delivered),
            "delivered_late": 0, # Add delay tracking to schema later
            "avg_delay_minutes": 0.0
        }
        return jsonify(data)
    except Exception as e:
        print(f"[BIZ OPS KPIS ERROR] {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/biz/customers', methods=['GET'])
def api_biz_customers():
    """
    CRM Snapshot from 'az_customers' (Just recent ones for now).
    """
    try:
        db = GLOBAL_BRAIN.db
        if not db:
            raise RuntimeError("Supabase client not configured in GLOBAL_BRAIN.")

        biz_id = get_active_business_id(db)
        
        res = db.table("az_customers") \
            .select("name, city, created_at") \
            .eq("business_id", biz_id) \
            .order("created_at", desc=True) \
            .limit(10) \
            .execute()

        rows = res.data or []
        items = []
        for r in rows:
            name = r.get("name")
            city = r.get("city") or "Unknown City"
            items.append({
                "time": "New Client",
                "text": f"{name} joined from {city}",
                "sentiment": "positive"
            })
            
        return jsonify({"items": items})
    except Exception as e:
        print(f"[BIZ CUSTOMERS ERROR] {e}")
        return jsonify({"error": str(e)}), 500


# Autonomy Global State
HITL_LEVEL = 1 # 0=Read, 1=Suggest, 2=Act, 3=God

@app.route('/api/settings/autonomy', methods=['GET', 'POST'])
def autonomy_settings():
    global HITL_LEVEL
    if request.method == 'POST':
        data = request.json or {}
        HITL_LEVEL = int(data.get("level", 1))
        print(f"[AUTONOMY] Level set to {HITL_LEVEL}")
        try:
            GLOBAL_BRAIN.set_hitl_level(HITL_LEVEL)
        except Exception as e:
            print(f"[AUTONOMY] Failed to sync HITL to brain: {e}")
        return jsonify({"level": HITL_LEVEL})
    else:
        return jsonify({"level": HITL_LEVEL})
    
    return jsonify({"level": HITL_LEVEL, "description": ["Read-Only", "Suggest", "Act", "God Mode"][HITL_LEVEL]})


@app.route('/api/integrations/okasina/order', methods=['POST'])
def okasina_order_webhook():
    """
    Webhook endpoint for okasinatrading.com -> TITAN V2 (AZ-NATIVE)
    Writes to: az_sales_events, az_deliveries, az_ops_tickets
    """
    try:
        db = GLOBAL_BRAIN.db
        if not db:
            raise RuntimeError("Supabase client not configured in GLOBAL_BRAIN.")

        # 1) Check secret
        sent_secret = request.headers.get("X-OKASINA-SECRET", "")
        if not OKASINA_WEBHOOK_SECRET or sent_secret != OKASINA_WEBHOOK_SECRET:
            return jsonify({"error": "unauthorized"}), 401

        payload = request.get_json(force=True, silent=True) or {}

        # 2) Extract Fields
        order_ref = payload.get("order_id")
        created_at = payload.get("created_at")
        status = (payload.get("status") or "paid").lower()
        source = payload.get("source") or "okasina_web"
        note = payload.get("note")

        # Customer Parsing
        cust_node = payload.get("customer") or {}
        customer_name = cust_node.get("name") or payload.get("customer_name")
        delivery_address = cust_node.get("address") or payload.get("delivery_address")

        # Totals Parsing
        totals_node = payload.get("totals") or {}
        grand_total = totals_node.get("grand_total_mur") or payload.get("total_amount")

        if not order_ref or grand_total is None:
            return jsonify({"error": "missing order_id or grand_total"}), 400

        # 3) Get Business ID (az_businesses)
        biz_id = get_business_id_by_slug(db, "okasina")

        # 4) Log Sale (az_sales_events)
        sale_data = {
            "business_id": biz_id,
            "type": "product_sale",
            "source": source,
            "external_ref": order_ref,
            "amount": float(grand_total),
            "customer_name": customer_name,
            "notes": f"Status: {status}",
            "created_at": created_at or "now()"
        }
        db.table("az_sales_events").insert(sale_data).execute()

        # 5) Log Delivery (az_deliveries)
        if delivery_address:
            deliv_data = {
                "business_id": biz_id,
                "ref_code": order_ref,
                "client_name": customer_name,
                "address": delivery_address,
                "status": "pending",
                "created_at": created_at or "now()"
            }
            db.table("az_deliveries").insert(deliv_data).execute()

        # 6) Log Note/Feedback (az_ops_tickets)
        if note:
            ticket_data = {
                "business_id": biz_id,
                "title": f"Order Note [{order_ref}]: {note}",
                "type": "customer_note",
                "status": "open",
                "created_at": created_at or "now()"
            }
            db.table("az_ops_tickets").insert(ticket_data).execute()

        return jsonify({"ok": True, "msg": "TITAN_V2_EVENT_LOGGED"})

    except Exception as e:
        print(f"[OKASINA WEBHOOK ERROR] {e}")
        return jsonify({"error": str(e)}), 500


# --- CITADEL FORGE APIs (Phase 40) ---

FORGE_ROOT = r"F:\AION-ZERO"
ALLOWED_EXTENSIONS = {'.py', '.js', '.html', '.css', '.json', '.md', '.txt', '.xml', '.ps1', '.sql'}

@app.route('/api/forge/tree', methods=['GET'])
def forge_tree():
    """Returns a flat list of editable files in FORGE_ROOT."""
    files = []
    try:
        for root, _, filenames in os.walk(FORGE_ROOT):
            if "node_modules" in root or ".git" in root or "__pycache__" in root:
                continue
            for name in filenames:
                _, ext = os.path.splitext(name)
                if ext.lower() in ALLOWED_EXTENSIONS:
                    # Make path relative to FORGE_ROOT or keep absolute?
                    # Frontend expects something it can pass back to read.
                    # Let's use relative path for display if we want, but simple walk usually gives full path if constructed that way.
                    # actually os.walk(FORGE_ROOT) gives absolute if FORGE_ROOT is absolute.
                    
                    full_path = os.path.join(root, name)
                    rel_path = os.path.relpath(full_path, FORGE_ROOT)
                    files.append(rel_path)
        return jsonify(files)
    except Exception as e:
        print(f"[FORGE TREE ERROR] {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/forge/read', methods=['POST'])
def forge_read():
    try:
        data = request.json or {}
        rel_path = data.get("path")
        if not rel_path:
            return jsonify({"error": "No path provided"}), 400
            
        # Security check (simple)
        if ".." in rel_path:
             return jsonify({"error": "Invalid path"}), 403
             
        full_path = os.path.join(FORGE_ROOT, rel_path)
        
        if not os.path.exists(full_path):
            return jsonify({"error": "File not found"}), 404
            
        with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            
        return jsonify({"content": content})
    except Exception as e:
         return jsonify({"error": str(e)}), 500

@app.route('/api/forge/save', methods=['POST'])
def forge_save():
    try:
        data = request.json or {}
        rel_path = data.get("path")
        content = data.get("content")
        
        if not rel_path:
            return jsonify({"error": "No path provided"}), 400
            
        full_path = os.path.join(FORGE_ROOT, rel_path)
        
        # Backup first? (Optional improvement)
        
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(content)
            
        return jsonify({"status": "saved"})
    except Exception as e:
         return jsonify({"error": str(e)}), 500

@app.route('/api/forge/run', methods=['POST'])
def forge_run():
    try:
        data = request.json or {}
        task_id = data.get("task_id")
        target = data.get("target") # can be file path or args
        
        cmd = []
        cwd = FORGE_ROOT
        
        if task_id == "run_script":
            # Determine runner based on extension
            if target.endswith(".py"):
                cmd = ["python", target]
            elif target.endswith(".ps1"):
                cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", target]
            elif target.endswith(".js"):
                cmd = ["node", target]
            else:
                 return jsonify({"error": "Unknown script type"}), 400
                 
            # If target is relative, make sure we find it
            if not os.path.isabs(target):
                cmd[-1] = os.path.join(FORGE_ROOT, target)

        elif task_id == "shell_cmd":
            # BE CAREFUL
            cmd = ["powershell", "-Command", target]
            
        elif task_id == "git_status":
             cmd = ["git", "status"]
             
        elif task_id == "git_add_commit":
             # target is commit msg
             subprocess.run(["git", "add", "."], cwd=cwd, shell=True)
             cmd = ["git", "commit", "-m", target or "Update from Forge"]
             
        elif task_id == "npm_run":
             cmd = ["npm", "run", target]
             
        elif task_id == "pip_install":
             cmd = ["pip", "install", target]
        
        else:
             return jsonify({"error": "Unknown task"}), 400

        # Run it
        print(f"[FORGE EXEC] {cmd}")
        res = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=60)
        
        return jsonify({
            "stdout": res.stdout,
            "stderr": res.stderr,
            "returncode": res.returncode
        })
        
    except subprocess.TimeoutExpired:
        return jsonify({"error": "Timeout"}), 408
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/doctor/diagnose', methods=['POST'])
def doctor_diagnose():
    """L4 Autonomy: Trigger a diagnosis on a file/error."""
    try:
        from jarvis_doctor import JarvisDoctor
        doc = JarvisDoctor()
        data = request.json or {}
        
        err = data.get("error")
        path = data.get("file_path")
        
        if not err or not path:
             return jsonify({"error": "Missing error or file_path"}), 400
             
        # Normalize Windows paths
        path = path.replace("\\", "/") # Simple norm
        
        result = doc.run_diagnosis(err, path)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/doctor/heal', methods=['POST'])
def doctor_heal():
    """L4 Autonomy: Apply a patch."""
    try:
        from jarvis_doctor import JarvisDoctor
        doc = JarvisDoctor()
        data = request.json or {}
        
        path = data.get("file_path")
        patch = data.get("patch") # {original_block, replacement_block}
        
        if not path or not patch:
             return jsonify({"error": "Missing path or patch data"}), 400
             
        success, msg = doc.apply_patch(path, patch.get("original_block"), patch.get("replacement_block"))
        return jsonify({"success": success, "message": msg})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
@app.route('/ledger.html')
def serve_ledger():
    return send_from_directory('static', 'ledger.html')

@app.route('/api/chat/history', methods=['GET'])
def api_chat_history():
    """Returns the short-term conversation history from the Brain."""
    return jsonify({"history": GLOBAL_BRAIN.history})

# --- RESOURCES API ---
RESOURCES_FILE = r"F:\AION-ZERO\data\resources.json"

def load_resources():
    if not os.path.exists(RESOURCES_FILE): return []
    try:
        with open(RESOURCES_FILE, 'r') as f: return json.load(f)
    except: return []

def save_resources(data):
    os.makedirs(os.path.dirname(RESOURCES_FILE), exist_ok=True)
    with open(RESOURCES_FILE, 'w') as f: json.dump(data, f, indent=2)

@app.route('/api/resources', methods=['GET', 'POST'])
def api_resources():
    if request.method == 'POST':
        new_item = request.json
        items = load_resources()
        items.append(new_item)
        save_resources(items)
        return jsonify({"status": "saved"})
    return jsonify(load_resources())

# --- AGENTS API ---
@app.route('/api/agents', methods=['GET'])
def api_agents():
    """Lists available agents and their status."""
    import glob
    import psutil
    
    agent_dir = r"F:\AION-ZERO\py"
    files = glob.glob(os.path.join(agent_dir, "jarvis_*.py"))
    
    agents = []
    # Get running python processes once
    running_pids = {}
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            if "python" in proc.info['name'].lower():
                cmd = proc.info['cmdline'] or []
                for arg in cmd:
                    if arg.endswith(".py"):
                        name = os.path.basename(arg)
                        running_pids[name] = proc.info['pid']
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass

    for f in files:
        name = os.path.basename(f)
        pid = running_pids.get(name)
        status = "active" if pid else "stopped"
        
        agents.append({
            "name": name,
            "description": "Autonomous Agent", # Could parse docstring
            "status": status,
            "pid": pid,
            "role": "Autonomous Unit"
        })
    return jsonify(agents)

@app.route('/api/agents/control', methods=['POST'])
def api_agents_control():
    data = request.json or {}
    name = data.get("name")
    action = data.get("action")
    
    if action == "start":
        path = os.path.join(r"F:\AION-ZERO\py", name)
        subprocess.Popen(["python", path])
        return jsonify({"message": f"Deployed {name}"})
        
    elif action == "stop":
        # Kill by Name (Hard kill for now)
        # In prod, use PID
        os.system(f"taskkill /f /fi \"WINDOWTITLE eq {name}\"") # Attempt window title match?
        # Or loop psutil
        import psutil
        killed = False
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                cmd = proc.info['cmdline'] or []
                if any(name in arg for arg in cmd):
                     proc.kill()
                     killed = True
            except: pass
        if killed: return jsonify({"message": f"Terminated {name}"})
        return jsonify({"message": f"Could not find running process for {name}"})

    return jsonify({"error": "Invalid action"}), 400

# --- LEDGER API ---
@app.route('/api/ledger/daily', methods=['GET'])
def api_ledger_daily():
    """Daily financial snapshot for Ledger UI."""
    try:
        db = GLOBAL_BRAIN.db
        if not db: return jsonify({})

        from datetime import datetime
        today = datetime.now().strftime("%Y-%m-%d")
        
        # 1. Okasina Revenue
        res = db.table("az_sales_events").select("amount") \
            .eq("business_id", get_business_id_by_slug(db, "okasina")) \
            .gte("created_at", today).execute()
        
        rows = res.data or []
        rev = sum(float(r.get("amount") or 0) for r in rows)
        
        # 2. Finance Net (Placeholder / Aggregate)
        # Just summing all revenue for now
        
        return jsonify({
            "okasina": { "revenue": rev, "count": len(rows) },
            "finance": { "net": rev }
        })
    except Exception as e:
        print(f"[LEDGER ERROR] {e}")
        return jsonify({})

@app.route('/api/ledger/recent', methods=['GET'])
def api_ledger_recent():
    """Recent logic events."""
    # Since we don't have a generic logic event table shown in schema above (only sales/ops/reflex),
    # checking index.html 'renderEvents' expects { events: [ { type, intent, status, verdict, score, ts } ] }
    # We will map 'az_reflex_log' to this format.
    try:
        db = GLOBAL_BRAIN.db
        limit = 50
        res = db.table("az_reflex_log").select("*").order("created_at", desc=True).limit(limit).execute()
        
        events = []
        for r in res.data or []:
            events.append({
                "ts": r.get("created_at"),
                "type": "REFLEX",
                "intent": r.get("action"),
                "status": "success", # Assumed
                "verdict": "win",    # Assumed
                "score": 100,
                "risk": "low",
                "output": r.get("reason"),
                "input": r.get("agent_name")
            })
        return jsonify({"events": events})
    except Exception as e:
        return jsonify({"events": []})


if __name__ == '__main__':
    print(">>> CITADEL SERVER ONLINE on http://127.0.0.1:5000 <<<")
    app.run(host='127.0.0.1', port=5000, debug=True)
