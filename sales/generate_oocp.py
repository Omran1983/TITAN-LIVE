import pandas as pd
import os

# Define the Output Path
output_dir = r"F:\AION-ZERO\sales\Client_Control_Plane"
os.makedirs(output_dir, exist_ok=True)
output_file = os.path.join(output_dir, "Client_Control_Panel.xlsx")

# 1. Clients Tab (Master Data)
clients_data = {
    "Client_ID": ["C001", "C002"],
    "Client_Name": ["Acme Ltd", "Global Hotels"],
    "Email": ["finance@acme.mu", "accounts@global.mu"],
    "WhatsApp": ["+23057654321", "+23051234567"],
    "Payment_Terms": ["30 Days", "14 Days"],
    "Active": ["YES", "YES"]
}
df_clients = pd.DataFrame(clients_data)

# 2. Invoices Tab (Finance Ops Control)
invoices_data = {
    "Invoice_ID": ["INV-1001", "INV-1002"],
    "Client_ID": ["C001", "C002"],
    "Invoice_Date": ["2025-01-20", "2025-01-25"],
    "Due_Date": ["2025-02-20", "2025-02-08"],
    "Amount": [25000, 10000],
    "Currency": ["MUR", "MUR"],
    "Description": ["Consulting Jan", "Retainer Jan"],
    "Status": ["SENT", "APPROVED"]
}
df_invoices = pd.DataFrame(invoices_data)

# 3. Payments Tab (The Stop Switch)
payments_data = {
    "Invoice_ID": [],
    "Payment_Date": [],
    "Amount": [],
    "Proof_Link": []
}
df_payments = pd.DataFrame(payments_data)

# 4. Statutory Tab (The Penalty Shield)
statutory_data = {
    "Code": ["PAYE-M1", "VAT-M1", "TDS-M1", "RO-26"],
    "Task": ["PAYE Return (Jan)", "VAT Return (Jan)", "TDS Return (Jan)", "RO Annual Return"],
    "Due_Date": ["2026-02-28", "2026-02-28", "2026-02-28", "2026-07-31"],
    "Applies": ["YES", "YES", "NO", "YES"],
    "Owner_Action": ["DONE", "IN_PROGRESS", "NONE", "NONE"],
    "Status": ["COMPLIED", "UPCOMING", "SKIPPED", "UPCOMING"],
    "Evidence_Link": ["drive.google.com/receipt.pdf", "", "", ""]
}
df_statutory = pd.DataFrame(statutory_data)

# Write to Excel with Multiple Tabs
with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
    df_clients.to_excel(writer, sheet_name='Clients', index=False)
    df_invoices.to_excel(writer, sheet_name='Invoices', index=False)
    df_payments.to_excel(writer, sheet_name='Payments', index=False)
    df_statutory.to_excel(writer, sheet_name='Statutory', index=False)

print(f"OOCP Generated: {output_file}")
