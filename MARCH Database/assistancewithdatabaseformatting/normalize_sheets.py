import sys, argparse, re, pathlib
import pandas as pd

# --- config: canonical schema + synonyms ---
CANON = {
    "invoice_no": {"invoice no","invoice_no","invoice","no_facture","num_facture","facture","inv","inv_no","numero_facture"},
    "date": {"date","invoice_date","date_facture","date de facture","transaction_date"},
    "client_name": {"client","client_name","customer","customer_name","nom_client","name"},
    "address": {"address","adresse","client_address","billing_address"},
    "sku": {"sku","item","code","product_code","product","article","ref","reference"},
    "qty": {"qty","quantity","qte","quantité","quantity_sold"},
    "unit_price": {"unit_price","price","prix_unitaire","prix","unit cost","cost"},
    "subtotal": {"subtotal","montant_ht","amount_ex_vat","ht"},
    "tax": {"tax","vat","tva","montant_tva"},
    "total": {"total","grand_total","montant_ttc","ttc","amount"}
}

# invert for quick lookup
SYN_TO_CANON = {}
for k, vals in CANON.items():
    for v in vals:
        SYN_TO_CANON[re.sub(r'[^a-z0-9]+','_', v.strip().lower())] = k

def slug(s: str) -> str:
    s = s.strip().lower()
    s = re.sub(r'[^a-z0-9]+','_', s)
    s = re.sub(r'_+','_', s).strip('_')
    return s

def canonicalize_columns(cols):
    out = []
    for c in cols:
        sc = slug(str(c))
        out.append(SYN_TO_CANON.get(sc, sc))
    return out

def coerce_numeric(df, cols):
    for c in cols:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors="coerce")
    return df

def coerce_date(df, col):
    if col in df.columns:
        df[col] = pd.to_datetime(df[col], errors="coerce")
    return df

def compute_totals(df):
    # subtotal = qty * unit_price if missing
    if "subtotal" in df.columns and df["subtotal"].isna().all() and {"qty","unit_price"}.issubset(df.columns):
        df["subtotal"] = df["qty"] * df["unit_price"]
    # total = subtotal + tax if missing
    if "total" in df.columns and df["total"].isna().all():
        if "subtotal" in df.columns and "tax" in df.columns:
            df["total"] = df["subtotal"].fillna(0) + df["tax"].fillna(0)
    return df

def load_any(path: pathlib.Path) -> dict[str,pd.DataFrame]:
    # returns {sheet_name: df}
    if path.suffix.lower() == ".ods":
        # requires odfpy
        xl = pd.read_excel(path, sheet_name=None, engine="odf")
    else:
        xl = pd.read_excel(path, sheet_name=None)  # openpyxl
    return xl

def normalize_df(df: pd.DataFrame, src_file: str, sheet: str) -> pd.DataFrame:
    # header normalization
    df = df.copy()
    df.columns = canonicalize_columns(df.columns)

    # strip whitespace strings
    for c in df.columns:
        if pd.api.types.is_string_dtype(df[c]):
            df[c] = df[c].astype(str).str.strip().replace({"": pd.NA})

    # coerce common types
    df = coerce_date(df, "date")
    df = coerce_numeric(df, ["qty","unit_price","subtotal","tax","total"])

    # compute totals if possible
    for col in ["subtotal","tax","total"]:
        if col not in df.columns:
            df[col] = pd.NA
    df = compute_totals(df)

    # keep only relevant + preserve extras
    preferred = ["invoice_no","date","client_name","address","sku","qty","unit_price","subtotal","tax","total"]
    cols = []
    for c in preferred:
        if c in df.columns:
            cols.append(c)
        else:
            df[c] = pd.NA
            cols.append(c)

    # add provenance
    df.insert(0, "source_file", src_file)
    df.insert(1, "source_sheet", sheet)

    # append any extra columns not in preferred
    extras = [c for c in df.columns if c not in cols and c not in ("source_file","source_sheet")]
    ordered = ["source_file","source_sheet"] + cols + extras
    return df[ordered]

def main():
    ap = argparse.ArgumentParser(description="Normalize multiple spreadsheets into one sheet.")
    ap.add_argument("-o","--output", required=True, help="Output Excel path, e.g. C:\\path\\Normalized.xlsx")
    ap.add_argument("inputs", nargs="+", help="Input files: .xlsx or .ods")
    args = ap.parse_args()

    frames = []
    for p in args.inputs:
        path = pathlib.Path(p)
        if not path.exists():
            print(f"WARNING: missing {p}")
            continue
        try:
            sheets = load_any(path)
        except Exception as e:
            print(f"ERROR reading {p}: {e}")
            continue

        for sheet_name, df in sheets.items():
            if df is None or df.empty:
                continue
            norm = normalize_df(df, str(path), str(sheet_name))
            # drop fully empty rows on key cols
            key_any = ["invoice_no","client_name","sku","total"]
            if any(k in norm.columns for k in key_any):
                norm = norm.dropna(how="all", subset=[k for k in key_any if k in norm.columns])
            frames.append(norm)

    if not frames:
        print("No data found.")
        sys.exit(2)

    combined = pd.concat(frames, ignore_index=True)

    # dedupe obvious duplicates
    dedupe_keys = [c for c in ["invoice_no","date","client_name","sku","total"] if c in combined.columns]
    if dedupe_keys:
        combined = combined.drop_duplicates(subset=dedupe_keys)

    # write to Excel
    out = pathlib.Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    with pd.ExcelWriter(out, engine="openpyxl") as xw:
        combined.to_excel(xw, sheet_name="Normalized", index=False)
    # also write CSV next to it
    combined.to_csv(out.with_suffix(".csv"), index=False, encoding="utf-8-sig")

    print(f"Wrote: {out}")
    print(f"Wrote: {out.with_suffix('.csv')}")

if __name__ == "__main__":
    main()
