"""
TITAN HR - Compliance Admin Dashboard
The Control Plane for the Managed Service.
"""
import streamlit as st
import pandas as pd
import json
import os
from datetime import datetime
from pathlib import Path

# Config
DATA_DIR = Path("F:/AION-ZERO/data")
CLIENTS_FILE = DATA_DIR / "clients.json"
BILLING_FILE = DATA_DIR / "billing.json"

st.set_page_config(page_title="TITAN Admin", page_icon="🛡️", layout="wide")

# --- DATA MANAGER ---
def load_data(file_path, default):
    if not file_path.exists():
        return default
    with open(file_path, 'r') as f:
        return json.load(f)

def save_data(file_path, data):
    file_path.parent.mkdir(parents=True, exist_ok=True)
    with open(file_path, 'w') as f:
        json.dump(data, f, indent=2)

# --- UI COMPONENTS ---
def sidebar():
    st.sidebar.title("🛡️ TITAN Admin")
    page = st.sidebar.radio("Navigation", ["Clients", "Operations", "Billing", "Audit Logs"])
    return page

def page_clients():
    st.title("👥 Client Management")
    
    clients = load_data(CLIENTS_FILE, [])
    
    # Add New Client
    with st.expander("➕ Add New Client"):
        with st.form("new_client"):
            col1, col2 = st.columns(2)
            name = col1.text_input("Company Name")
            cid = col2.text_input("Client ID (CID)", help="e.g. AOGRL-001")
            email = col1.text_input("Contact Email")
            tier = col2.selectbox("Service Tier", ["Tier 1 (PRB)", "Tier 2 (PRB+Labour)", "Tier 3 (Full)"])
            
            if st.form_submit_button("Create Client"):
                new_client = {
                    "cid": cid,
                    "name": name,
                    "email": email,
                    "tier": tier,
                    "joined_date": datetime.now().strftime("%Y-%m-%d"),
                    "status": "Active"
                }
                clients.append(new_client)
                save_data(CLIENTS_FILE, clients)
                st.success(f"Client {name} added!")
                st.rerun()

    # Client List
    if clients:
        df = pd.DataFrame(clients)
        st.dataframe(
            df,
            column_config={
                "status": st.column_config.SelectboxColumn("Status", options=["Active", "Paused", "Churned"]),
            },
            use_container_width=True,
            hide_index=True
        )
    else:
        st.info("No clients yet.")

def page_operations():
    st.title("⚙️ Operations Center")
    st.info("Upload client CSVs here to trigger manual runs.")
    
    clients = load_data(CLIENTS_FILE, [])
    client_names = [c["name"] for c in clients]
    
    col1, col2 = st.columns([1, 2])
    
    with col1:
        selected_client = st.selectbox("Select Client", client_names) if client_names else None
        report_month = st.date_input("Report Month").strftime("%Y-%m")
        
    with col2:
        uploaded_file = st.file_uploader("Upload Employee CSV", type=["csv"])
        
    if st.button("🚀 Run Compliance Check", type="primary"):
        if uploaded_file and selected_client:
            st.toast(f"Running compliance check for {selected_client}...", icon="⏳")
            # TODO: Call Validation Engine
            # TODO: Call PDF Generator
            st.success("Report generated! (Simulation)")
            st.json({
                "status": "PASS",
                "score": 95,
                "report": f"HR_Compliance_{selected_client}_{report_month}.pdf"
            })
        else:
            st.error("Please select a client and upload a file.")

def page_billing():
    st.title("💰 Billing & Invoices")
    
    col1, col2, col3 = st.columns(3)
    col1.metric("MRR (Monthly)", "Rs 25,000", "+5,000")
    col2.metric("Pending Invoices", "3", "Rs 15,000")
    col3.metric("Active Clients", "5", "+1")
    
    st.divider()
    
    # Mock Billing Data
    billing_data = [
        {"Invoice": "INV-001", "Client": "Demo Ltd", "Amount": "Rs 5,000", "Status": "Paid", "Date": "2025-12-01"},
        {"Invoice": "INV-002", "Client": "ABC Corp", "Amount": "Rs 8,000", "Status": "Pending", "Date": "2025-12-05"},
    ]
    st.table(billing_data)

def page_audit():
    st.title("📜 Audit Logs")
    st.markdown("Track every report generation and email sent.")
    
    # Mock Logs
    logs = [
        {"Time": "2025-12-21 09:00", "Event": "Email Received", "Client": "Demo Ltd", "Status": "Success"},
        {"Time": "2025-12-21 09:01", "Event": "Report Generated", "Client": "Demo Ltd", "Status": "Success"},
        {"Time": "2025-12-21 09:02", "Event": "Email Sent", "Client": "Demo Ltd", "Status": "Sent"},
        {"Time": "2025-12-21 10:15", "Event": "Data Error", "Client": "ABC Corp", "Status": "Failed (Invalid CSV)"},
    ]
    st.dataframe(logs, use_container_width=True)

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
