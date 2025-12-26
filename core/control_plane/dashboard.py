import streamlit as st
import time
import uuid
import sys
import json
from pathlib import Path

# Add core to path so we can import titan_kernel
sys.path.append(str(Path(__file__).parent.parent.parent))

from core.governance.titan_kernel import AuthorityLevel, ActionType, Requestor, Decree, ExecutionPermitGateway, TitanExecutionEngine

# --- CONFIG & STYLING ---
st.set_page_config(page_title="TITAN Control Plane", layout="wide", page_icon="⚡")

# Custom CSS
st.markdown("""
<style>
    /* Global Theme */
    .stApp { background-color: #f8fafc; }
    h1, h2, h3 { font-family: 'Outfit', sans-serif; color: #0f172a; }
    
    /* Card Styling */
    .css-card {
        background: white; border-radius: 12px; padding: 20px;
        box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1); border: 1px solid #e2e8f0; margin-bottom: 1rem;
    }
    
    .status-badge {
        display: inline-block; padding: 4px 8px; border-radius: 4px;
        font-size: 0.75rem; font-weight: 600; text-transform: uppercase;
    }
    .status-active { background: #dcfce7; color: #166534; }
    
    /* Hierarchy Lines */
    .connector-v { width: 2px; background: #cbd5e1; margin: 0 auto; height: 20px; }
    
    /* TITAN Core Box */
    .titan-core {
        background: linear-gradient(135deg, #2563eb, #1e40af); color: white;
        padding: 20px; border-radius: 12px; text-align: center;
        box-shadow: 0 10px 15px -3px rgb(37 99 235 / 0.3);
    }
    
    /* Director Box */
    .director-box {
        background: white; border-left: 4px solid #3b82f6;
        padding: 15px; border-radius: 8px;
        box-shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1);
    }
</style>
""", unsafe_allow_html=True)

# --- LOAD STATE ---
STATE_FILE = Path(__file__).parent.parent / "state" / "system_state.json"
QUEUE_FILE = Path(__file__).parent.parent / "state" / "mission_queue.json"

def load_system_state():
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except:
            return None
    return None

def load_mission_queue():
    if QUEUE_FILE.exists():
        try:
            return json.loads(QUEUE_FILE.read_text())
        except:
            return []
    return []

state = load_system_state()
last_update = state["last_updated"] if state else "OFFLINE"
system_status = state["status"] if state else "OFFLINE"

# --- SIDEBAR: MISSION CONTROL ---
st.sidebar.title("🎮 Mission Control")

# 1. Select Operation Mode
mode = st.sidebar.radio("Mode", ["Monitoring", "Dispatch", "Queue"], index=1)

if mode == "Dispatch":
    st.sidebar.markdown("### 🚀 Launch New Mission")
    
    # Get Bot List from State
    bot_options = {}
    if state and "bots" in state:
        for b in state["bots"]:
            # Label: "GrowthBot (L3) - ONLINE"
            label = f"{b['name']} ({b['level']})"
            bot_options[label] = b['id']
    
    selected_label = st.sidebar.selectbox("Select Agent/Bot", list(bot_options.keys()))
    mission_brief = st.sidebar.text_area("Mission Brief", placeholder="e.g., Scrape 50 leads from LinkedIn")
    budget = st.sidebar.number_input("Allocated Budget ($)", min_value=0.0, value=0.0, step=10.0)
    
    if st.sidebar.button("🔴 DISPATCH MISSION", type="primary"):
        if selected_label and mission_brief:
            bot_id = bot_options[selected_label]
            
            # Create Mission Object
            mission = {
                "id": str(uuid.uuid4())[:8],
                "timestamp": time.strftime("%H:%M:%S"),
                "bot_id": bot_id,
                "bot_name": selected_label,
                "content": mission_brief,
                "amount": budget,
                "status": "QUEUED"
            }
            
            # Write to Mission Queue
            current_queue = load_mission_queue()
            current_queue.append(mission)
            QUEUE_FILE.write_text(json.dumps(current_queue, indent=2))
            st.sidebar.success(f"Mission #{mission['id']} Queued!")
        else:
            st.sidebar.error("Please select a bot and define a mission.")

elif mode == "Queue":
    st.sidebar.markdown("### ⏳ Mission Queue")
    q = load_mission_queue()
    if q:
        for m in q:
            st.sidebar.markdown(f"**{m['bot_name']}**")
            st.sidebar.caption(f"{m['content']} (${m['amount']})")
            st.sidebar.markdown("---")
    else:
        st.sidebar.info("Queue Empty")

# --- MAIN LAYOUT ---

# 1. HEADER (L0)
st.markdown("<h1 style='text-align: center;'>TITAN AI CONTROL PLANE</h1>", unsafe_allow_html=True)
st.markdown(f"<p style='text-align: center; color: #64748b;'>System Status: <b>{system_status}</b> | Last Pulse: {last_update}</p>", unsafe_allow_html=True)

col_sup_1, col_sup_2, col_sup_3 = st.columns([1, 2, 1])
with col_sup_2:
    st.markdown("""
    <div class="titan-core">
        <h2 style='color: white; margin:0;'>OMRAN AHMAD</h2>
        <p style='margin:0; opacity: 0.9;'>SUPREME PRINCIPAL (L0)</p>
    </div>
    <div class="connector-v" style="height: 40px;"></div>
    """, unsafe_allow_html=True)

# 2. THE TRIAD (Core Systems)
c1, c2, c3 = st.columns(3)
with c1:
    st.markdown("""
    <div class="css-card" style="border-top: 4px solid #2563eb;">
        <h3 style="margin:0">⚡ TITAN</h3>
        <p style="font-size:0.8rem; color:#64748b;">DECISION ENGINE</p>
        <div class="status-badge status-active">GOVERNANCE ACTIVE</div>
    </div>
    """, unsafe_allow_html=True)
with c2:
    st.markdown("""
    <div class="css-card" style="border-top: 4px solid #10b981;">
        <h3 style="margin:0">🛠️ JARVIS</h3>
        <p style="font-size:0.8rem; color:#64748b;">EXECUTION LAYER</p>
        <div class="status-badge status-active">JOBS RUNNING: """ + str(state['active_bots'] if state else 0) + """</div>
    </div>
    """, unsafe_allow_html=True)
with c3:
    st.markdown("""
    <div class="css-card" style="border-top: 4px solid #8b5cf6;">
        <h3 style="margin:0">🧠 AION-ZERO</h3>
        <p style="font-size:0.8rem; color:#64748b;">MEMORY CORE</p>
        <div class="status-badge status-active">VECTORS LOADED</div>
    </div>
    """, unsafe_allow_html=True)

st.markdown('<div class="connector-v" style="height: 40px;"></div>', unsafe_allow_html=True)

# 3. DIRECTORS (L1) & MANAGERS (L2)
st.subheader("🏛️ Board of Directors (Layer 1)")

if state:
    directors_ui = [
        {"id": "bod_str", "icon": "♟️", "color": "#3b82f6"},
        {"id": "bod_fin", "icon": "💰", "color": "#f59e0b"},
        {"id": "bod_gro", "icon": "🚀", "color": "#10b981"},
        {"id": "bod_prod", "icon": "📦", "color": "#6366f1"},
        {"id": "bod_leg", "icon": "⚖️", "color": "#8b5cf6"},
        {"id": "bod_sec", "icon": "🛡️", "color": "#ef4444"},
    ]
    
    cols = st.columns(6)
    for i, d_ui in enumerate(directors_ui):
        d_data = next((d for d in state['directors'] if d['id'] == d_ui['id']), None)
        if d_data:
             mgr_data = next((m for m in state['managers'] if m['id'] == d_data['manager_id']), None)
             bot_count = len(mgr_data['bots']) if mgr_data and 'bots' in mgr_data else 0
             mgr_name = mgr_data['name'] if mgr_data else "Vacant"
             director_role = d_data['name'].replace(" Director", "")

             with cols[i]:
                st.markdown(f"""
                <div class="director-box" style="border-left-color: {d_ui['color']}">
                    <div style="font-size: 1.5rem;">{d_ui['icon']}</div>
                    <div style="font-weight: 700; font-size: 0.9rem;">{director_role}</div>
                    <hr style="margin: 8px 0;">
                    <div style="font-size: 0.8rem; color: #64748b;">Mgr: <b>{mgr_name}</b></div>
                    <div style="font-size: 0.7rem; color: #94a3b8;">Bots: {bot_count} (Active)</div>
                </div>
                """, unsafe_allow_html=True)
else:
    st.warning("SYSTEM OFFLINE")

# 4. EXECUTION PERMIT GATEWAY (Live Log)
st.markdown("---")
st.subheader("🔒 Execution Permit Gateway (Real-Time Logs)")

# Show recent log from state if available, or just the queue status
# Ideally watcher writes execution logs to state. We'll implement that in watcher next.
if state and "logs" in state:
    for log in state["logs"][:5]: # Last 5
        color = "red" if "BLOCK" in log["status"] else "green"
        st.markdown(f"""
        <div style='background: white; padding: 10px; border-radius: 6px; border-left: 4px solid {color}; margin-bottom: 5px; font-family: monospace;'>
            <span style='color: #64748b;'>[{log['timestamp']}]</span> 
            <b>{log['event']}</b> 
            <span style='float: right; font-weight: bold; color: {color}'>{log['status']}</span>
            <br><span style='font-size: 0.8rem; color: #475569;'>{log.get('details', '')}</span>
        </div>
        """, unsafe_allow_html=True)
else:
     st.info("System Idle.")

# 5. AUTONOMY LOOP
st.markdown("---")
st.subheader("🧬 Autonomy Loop (Platform Layer)")
if state and "autonomy_loop" in state:
    ac = st.columns(len(state["autonomy_loop"]))
    for i, bot in enumerate(state["autonomy_loop"]):
        with ac[i]:
            st.button(f"{bot['name']} 🟢", key=bot['name'], use_container_width=True)
