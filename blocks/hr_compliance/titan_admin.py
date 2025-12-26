"""
TITAN Admin - The Control Plane 🛡️
Production-Ready Dashboard for Client & Operations Management.
"""
import streamlit as st
import pandas as pd
import json
import os
from datetime import datetime
from pathlib import Path

# Import Titan Core
from audit import get_recent_events
from run_worker import process_run

# Config
DATA_DIR = Path("F:/AION-ZERO/data")
CLIENTS_FILE = DATA_DIR / "clients.json"
BILLING_FILE = DATA_DIR / "billing.json"

st.set_page_config(page_title="TITAN Admin", page_icon="🛡️", layout="wide")

# --- DATA MANAGER ---
def load_clients():
    if not CLIENTS_FILE.exists():
        return {}
    with open(CLIENTS_FILE, 'r') as f:
        return json.load(f)

def save_clients(data):
    CLIENTS_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(CLIENTS_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def create_client_folder(cid, slug):
    path = DATA_DIR / "clients" / cid
    (path / "inbox").mkdir(parents=True, exist_ok=True)
    (path / "working").mkdir(parents=True, exist_ok=True)
    (path / "outputs").mkdir(parents=True, exist_ok=True)
    return path

# --- UI COMPONENTS ---
def sidebar():
    st.sidebar.title("🛡️ TITAN Admin")
    st.sidebar.markdown(f"**Env:** Production\n**User:** Owner")
    st.sidebar.divider()
    page = st.sidebar.radio("Navigation", ["Clients", "Operations", "Billing", "Audit Logs"])
    return page

def page_clients():
    st.title("👥 Client Management")
    
    clients = load_clients()
    
    # Add New Client
    with st.expander("➕ Add New Client"):
        with st.form("new_client"):
            col1, col2 = st.columns(2)
            name = col1.text_input("Company Name")
            cid = col2.text_input("Client ID (CID)", help="Unique ID (e.g. AOGRL-001)")
            email = col1.text_input("Contact Email")
            tier = col2.selectbox("Service Tier", ["Tier 1 (PRB)", "Tier 2 (PRB+Labour)", "Tier 3 (Full)"])
            slug = col1.text_input("Slug (Folder Name)", help="no-spaces-lowercase").lower()
            
            if st.form_submit_button("Create Client"):
                if cid in clients:
                    st.error("Client ID already exists!")
                elif not slug or not name:
                     st.error("Name and Slug are required.")
                else:
                    new_client = {
                        "cid": cid,
                        "name": name,
                        "slug": slug,
                        "email": email,
                        "tier": tier,
                        "joined_date": datetime.now().strftime("%Y-%m-%d"),
                        "status": "Active"
                    }
                    clients[cid] = new_client
                    save_clients(clients)
                    create_client_folder(cid, slug)
                    st.success(f"Client {name} added! Folder created at data/clients/{cid}")
                    st.rerun()

    # Client List
    if clients:
        # Convert dict to list for dataframe
        client_list = list(clients.values())
        df = pd.DataFrame(client_list)
        
        # Reorder columns
        df = df[['cid', 'name', 'tier', 'status', 'email', 'joined_date']]
        
        st.dataframe(
            df,
            column_config={
                "status": st.column_config.SelectboxColumn("Status", options=["Active", "Paused", "Churned"]),
            },
            use_container_width=True,
            hide_index=True
        )
    else:
        st.info("No clients yet. Add one above.")

def page_operations():
    st.title("⚙️ Operations Center")
    st.info("Trigger manual runs for clients who sent data via alternate channels.")
    
    clients = load_clients()
    if not clients:
        st.warning("No clients found. Go to Clients tab to add one.")
        return

    # Select Client
    client_options = {f"{v['name']} ({k})": k for k, v in clients.items()}
    selected_label = st.selectbox("Select Client", list(client_options.keys()))
    selected_cid = client_options[selected_label]
    
    col1, col2 = st.columns([1, 2])
    
    with col1:
        report_month = st.date_input("Report Month").strftime("%Y-%m")
        
    with col2:
        uploaded_file = st.file_uploader("Upload Employee CSV", type=["csv"])
        
    if st.button("🚀 Run Compliance Check", type="primary"):
        if uploaded_file and selected_cid:
            with st.spinner(f"Running compliance engine for {selected_cid}..."):
                # Save uploaded file to Inbox
                client_slug = clients[selected_cid]['slug'] # Actually path uses CID or Slug? Method create_client_folder uses CID.
                # Let's check consistency. admin uses DATA_DIR/clients/CID. run_worker uses DATA_DIR/clients/CID. Ok.
                
                inbox_dir = DATA_DIR / "clients" / selected_cid / "inbox"
                inbox_dir.mkdir(parents=True, exist_ok=True)
                
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                save_path = inbox_dir / f"manual_{timestamp}_{uploaded_file.name}"
                
                with open(save_path, "wb") as f:
                    f.write(uploaded_file.getbuffer())
                
                # CALL THE ENGINE
                result = process_run(selected_cid, save_path, report_month)
                
                if result['status'] == 'SUCCESS':
                    st.success(f"Run Complete! Score: {result['score']}%")
                    st.json(result)
                    
                    # Show PDF Download Link if possible (Streamlit serves generic from static or we assume local usage)
                    st.info(f"PDF Report Generated: {result['pdf_path']}")
                else:
                    st.error(f"Run Failed: {result.get('error')}")
        else:
            st.error("Please select a client and upload a file.")

def page_billing():
    st.title("💰 Billing & Invoices")
    
    col1, col2, col3 = st.columns(3)
    col1.metric("MRR (Monthly)", "Rs 25,000", "+5,000")
    col2.metric("Pending Invoices", "3", "Rs 15,000")
    col3.metric("Active Clients", "5", "+1")
    
    st.divider()
    st.caption("Billing module integration pending (Phase 4)")

def page_audit():
    st.title("📜 Audit Logs (Source of Truth)")
    st.markdown("Live feed from `events.jsonl`")
    
    if st.button("Refresh Logs"):
        st.rerun()
        
    events = get_recent_events(limit=50)
    
    if events:
        df = pd.DataFrame(events)
        # Reorder for readability
        df = df[['timestamp', 'client_cid', 'type', 'status', 'details']]
        
        st.dataframe(
            df,
            column_config={
                "timestamp": st.column_config.DatetimeColumn("Time", format="D MMM, HH:mm:ss"),
                "details": st.column_config.Column("Details", width="large")
            },
            use_container_width=True,
            hide_index=True
        )
    else:
        st.info("No logs found.")

# --- MAIN APP ---
def main():
    page = sidebar()
    
    if page == "Clients":
        page_clients()
    elif page == "Operations":
        page_operations()
    elif page == "Billing":
        page_billing()
    elif page == "Audit Logs":
        page_audit()

if __name__ == "__main__":
    main()
