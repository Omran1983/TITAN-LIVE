import streamlit as st
import pandas as pd
import io

# Page Config
st.set_page_config(
    page_title="OORP Client Portal",
    page_icon="🛡️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main_header {font-size: 2.5rem; font-weight: 800; color: #4B5563;}
    .sub_header {font-size: 1.5rem; color: #6B7280; margin-bottom: 2rem;}
    .card {background-color: #F3F4F6; padding: 1.5rem; border-radius: 10px; border: 1px solid #E5E7EB;}
    .stat-val {font-size: 2rem; font-weight: 700; color: #111827;}
    .stat-label {font-size: 0.875rem; color: #6B7280; text-transform: uppercase;}
    .verified {color: #059669; font-weight: bold;}
    .warning {color: #D97706; font-weight: bold;}
    .danger {color: #DC2626; font-weight: bold;}
    
    /* Hide Streamlit Branding */
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
</style>
""", unsafe_allow_html=True)

# --- MOCK DATA ---
if 'invoices' not in st.session_state:
    st.session_state.invoices = pd.DataFrame([
        {"ID": "INV-1001", "Client": "Acme Ltd", "Amount": 25000, "Due": "2025-02-20", "Status": "SENT"},
        {"ID": "INV-1002", "Client": "Global Hotels", "Amount": 10000, "Due": "2025-01-28", "Status": "APPROVED"},
        {"ID": "INV-1003", "Client": "Retail Plus", "Amount": 5000, "Due": "2025-01-05", "Status": "PAID"},
    ])

if 'compliance' not in st.session_state:
    st.session_state.compliance = pd.DataFrame([
        {"Obligation": "VAT Return (Jan)", "Due": "2026-02-28", "Description": "Value Added Tax (15%)", "Applies": False, "Status": "SKIPPED", "Evidence": False},
        {"Obligation": "PAYE Return (Jan)", "Due": "2026-02-28", "Description": "Employee Tax Deductions", "Applies": True, "Status": "COMPLIED", "Evidence": True},
        {"Obligation": "TDS Return", "Due": "2026-02-28", "Description": "Tax Deduction at Source (Services/Rent)", "Applies": False, "Status": "SKIPPED", "Evidence": False},
        {"Obligation": "RO Annual Return", "Due": "2026-07-31", "Description": "Statement of Income", "Applies": True, "Status": "UPCOMING", "Evidence": False},
    ])

# Sidebar
with st.sidebar:
    st.image("https://via.placeholder.com/150x50?text=AOGRL+CLIENT", use_column_width=True)
    st.markdown("### Control Plane")
    page = st.radio("Navigate", ["Dashboard", "Invoices (CashGuard)", "Compliance (Sentinel)"])
    st.markdown("---")
    st.info("🟢 TITAN Active\n\nSystems Normal")

# --- MAIN CONTENT ---

if page == "Dashboard":
    st.markdown('<div class="main_header">Welcome back, Client User</div>', unsafe_allow_html=True)
    st.markdown('<div class="sub_header">Your Operations Command Center</div>', unsafe_allow_html=True)

    # Top Stats
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.markdown('<div class="card"><div class="stat-label">Cash In (Mtd)</div><div class="stat-val">Rs 155k</div></div>', unsafe_allow_html=True)
    with col2:
        st.markdown('<div class="card"><div class="stat-label">Outstanding</div><div class="stat-val">Rs 45k</div></div>', unsafe_allow_html=True)
    with col3:
        st.markdown('<div class="card"><div class="stat-label">Next Deadline</div><div class="stat-val warning">7 Days</div></div>', unsafe_allow_html=True)
    with col4:
        st.markdown('<div class="card"><div class="stat-label">Compliance Score</div><div class="stat-val verified">95%</div></div>', unsafe_allow_html=True)

    st.markdown("### 📢 Activity Feed")
    st.info("ℹ️ **TITAN**: Sent Chaser #1 to Acme Ltd (INV-1001) this morning.")
    st.success("✅ **TITAN**: Verified January PAYE Return receipt.")

elif page == "Invoices (CashGuard)":
    st.markdown('<div class="main_header">Invoice Control</div>', unsafe_allow_html=True)
    st.markdown("Manage your sales ledger. TITAN acts based on 'Status'.")
    
    # Action Bar: Import / Export
    # Action Bar: Import / Export
    with st.container():
        st.markdown("#### 📂 Data Tools")
        c1, c2, c3 = st.columns([1, 1, 2])
        with c1:
            # Generate Excel with Intro Page
            buffer = io.BytesIO()
            with pd.ExcelWriter(buffer, engine='xlsxwriter') as writer:
                # Tab 1: Instructions
                df_intro = pd.DataFrame({
                    "Step": ["1. Fill Data", "2. Upload", "3. TITAN ACTS"],
                    "Action": ["Go to 'Invoices' tab. Add rows.", "Save file. Upload here.", "TITAN reads Status."],
                    "Valid Statuses": ["DRAFT (Ignored)", "APPROVED (Sends)", "PAID (Stops)"]
                })
                df_intro.to_excel(writer, sheet_name='START HERE', index=False)
                
                # Tab 2: Template
                df_template = pd.DataFrame(columns=["Client", "Amount", "Due_Date", "Status"])
                df_template.loc[0] = ["Example Corp", 15000, "2025-02-28", "APPROVED"]
                df_template.to_excel(writer, sheet_name='Invoices', index=False)
                
                # Formatting (Optional but nice)
                workbook = writer.book
                worksheet = writer.sheets['START HERE']
                format_header = workbook.add_format({'bold': True, 'font_color': 'white', 'bg_color': '#4B5563'})
                worksheet.write('A1', 'HOW TO USE THIS TEMPLATE', format_header)
                worksheet.write('A2', '1. Go to the "Invoices" tab.', workbook.add_format({'bold': True}))
                worksheet.write('A3', '2. Fill in your invoice details.', workbook.add_format({'bold': True}))
                worksheet.write('A4', '3. Upload this file to the Portal.', workbook.add_format({'bold': True}))

            
            st.download_button(
                label="📄 Get Official Invoice Template",
                data=buffer.getvalue(),
                file_name="invoice_import_template.xlsx",
                mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                help="Download the Excel template with instructions.",
                type="primary" 
            )
        with c2:
            # Import
            uploaded_file = st.file_uploader("Upload Excel/CSV", type=['csv', 'xlsx'], label_visibility="collapsed")
        if uploaded_file:
            try:
                if uploaded_file.name.endswith('.csv'):
                    df_new = pd.read_csv(uploaded_file)
                else:
                    df_new = pd.read_excel(uploaded_file)
                
                # Basic validation simulation
                if 'Client' in df_new.columns:
                    # Append strictly for demo
                    df_new['ID'] = [f"INV-{1005+i}" for i in range(len(df_new))]
                    if 'Status' not in df_new.columns:
                        df_new['Status'] = 'DRAFT'
                    
                    st.session_state.invoices = pd.concat([st.session_state.invoices, df_new], ignore_index=True)
                    st.toast(f"Imported {len(df_new)} invoices!")
                else:
                    st.error("Invalid Format. Please use the Template.")
            except Exception as e:
                st.error(f"Error reading file: {e}")

    st.divider()

    # The Table
    edited_df = st.data_editor(
        st.session_state.invoices,
        column_config={
            "Status": st.column_config.SelectboxColumn(
                "Status",
                help="Changing this triggers TITAN",
                width="medium",
                options=["DRAFT", "APPROVED", "SENT", "PAID", "DISPUTED"],
            ),
            "Amount": st.column_config.NumberColumn(
                "Amount", format="Rs %d"
            )
        },
        num_rows="dynamic",
        use_container_width=True
    )
    
    if not edited_df.equals(st.session_state.invoices):
        st.session_state.invoices = edited_df
        st.success("Changes Saved. TITAN notified.")

elif page == "Compliance (Sentinel)":
    st.markdown('<div class="main_header">Statutory Sentinel</div>', unsafe_allow_html=True)
    st.markdown("Your Penalty Shield.")

    # Activate All Button
    col_act, _ = st.columns([1, 4])
    with col_act:
        if st.button("✅ Activate All Obligations"):
            st.session_state.compliance['Applies'] = True
            # Update status logic: If Applies=True and Status was SKIPPED -> UPCOMING
            mask = (st.session_state.compliance['Status'] == 'SKIPPED')
            st.session_state.compliance.loc[mask, 'Status'] = 'UPCOMING'
            st.rerun()

    st.divider()

    # Table View
    for index, row in st.session_state.compliance.iterrows():
        with st.container():
            c1, c2, c3, c4 = st.columns([3, 2, 2, 2])
            with c1:
                # Title + Tooltip for TDS
                title = row['Obligation']
                if "TDS" in title:
                    st.subheader(title, help="Tax Deduction at Source: You must deduct tax (3-10%) from payments to professionals/landlords and pay MRA.")
                else:
                    st.subheader(title, help=row['Description'])
                
                st.caption(f"Due: {row['Due']}")

            with c2:
                # Status Logic Visuals
                status = row['Status']
                if not row['Applies']:
                     st.markdown('<span style="color:gray">Inactive (Not Applicable)</span>', unsafe_allow_html=True)
                elif status == 'COMPLIED':
                    st.markdown('<span class="verified">✅ COMPLIED</span>', unsafe_allow_html=True)
                elif status == 'UPCOMING':
                    st.markdown('<span class="warning">⚠️ UPCOMING</span>', unsafe_allow_html=True)
                else:
                    st.markdown(f'<span style="color:red">{status}</span>', unsafe_allow_html=True)
            
            with c3:
                # Toggle Applies
                if st.checkbox("Applies to me", value=row['Applies'], key=f"applies_{index}"):
                     if not row['Applies']:
                         st.session_state.compliance.at[index, 'Applies'] = True
                         st.session_state.compliance.at[index, 'Status'] = 'UPCOMING'
                         st.rerun()
                else:
                    if row['Applies']:
                        st.session_state.compliance.at[index, 'Applies'] = False
                        st.session_state.compliance.at[index, 'Status'] = 'SKIPPED'
                        st.rerun()

            with c4:
                # Evidence
                if row['Applies']:
                    if not row['Evidence']:
                        if st.button("⬆️ Upload Proof", key=f"up_{index}"):
                             st.toast("Simulating Upload... TITAN Verify started.")
                             st.session_state.compliance.at[index, 'Evidence'] = True
                             st.session_state.compliance.at[index, 'Status'] = 'COMPLIED'
                             st.rerun()
                    else:
                        st.button("📄 View Receipt", key=f"view_{index}")

            st.markdown("---")
