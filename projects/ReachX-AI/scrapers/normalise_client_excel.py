import sys
import pandas as pd

if len(sys.argv) != 3:
    print("Usage: normalise_client_excel.py INPUT_XLSX OUTPUT_CSV")
    sys.exit(1)

src = sys.argv[1]
dst = sys.argv[2]

df = pd.read_excel(src)

# Map exact Excel headers → Supabase column names
df = df.rename(columns={
    "CLIENT NAME": "employer_name",
    "COUNTRY": "country",
    "CONTACT NUMBER ": "contact",   # note the space in original header
    "REQUIREMENTS": "requirements",
})

# Drop rows with no employer_name
df = df.dropna(subset=["employer_name"])

# Add source tag
df["source"] = "client_excel_upload"

# Trim whitespace
for col in ["employer_name", "country", "contact", "requirements"]:
    df[col] = df[col].astype(str).str.strip()

df.to_csv(dst, index=False)
print(f"Wrote {len(df)} rows to {dst}")
