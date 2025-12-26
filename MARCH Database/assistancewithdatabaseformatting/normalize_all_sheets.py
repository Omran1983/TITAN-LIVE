# extract_contacts_all_sheets.py

import argparse, pathlib, re, sys
from collections import Counter
import pandas as pd

# --------- Target columns (final order) ----------
FINAL_COLS = [
    "Source",                 # file path
    "Sector",                 # industry
    "Business Name",          # company
    "Email",                  # semicolon-separated
    "Phone number",           # semicolon-separated
    "Address",
    "Name",                   # contact person(s)
    "Title of Contact Person",
    "Website"
]

# --------- Header synonyms -> canonical internal keys ----------
# Internal keys map 1:1 to FINAL_COLS except names use snake_case
SYN_MAP = {
    "sector": {
        "sector","industry","secteur","domaine","industry sector","business sector","activité","activity"
    },
    "business_name": {
        "business name","company","company name","entreprise","raison sociale","societe","société","organisation",
        "organization","firm","brand","business","nom entreprise","nom societe","nom société","establishment","shop name"
    },
    "email": {
        "email","e-mail","courriel","mail","email address","adresse email","adresse e-mail","adresse courriel","emails"
    },
    "phone": {
        "phone","phone number","telephone","téléphone","tel","tél","mobile","gsm","cell","contact number",
        "numéro","numero","numéro de téléphone","num tel","num portable","whatsapp"
    },
    "address": {
        "address","adresse","location","street","rue","quartier","city","ville","adresse complete","address line",
        "postal address","physical address"
    },
    "name": {
        "name","contact","contact name","personne de contact","nom","full name","owner name","manager name",
        "representative","contact person","responsable","proprietor","propriétaire","directeur","manager"
    },
    "title": {
        "title","designation","poste","fonction","role","position","job title","titre","fonction occupée"
    },
    "website": {
        "website","site","site web","url","web","site internet","homepage","web site","siteweb","linkedin","facebook","page"
    },
}

# --------- Utilities ----------
def slug(s: str) -> str:
    return re.sub(r'_+','_', re.sub(r'[^a-z0-9]+','_', str(s).strip().lower())).strip('_')

def map_headers(cols):
    out = []
    for c in cols:
        sc = slug(c)
        mapped = None
        for key, syns in SYN_MAP.items():
            if sc in {slug(x) for x in syns} or sc == key:
                mapped = key
                break
        out.append(mapped if mapped else sc)  # keep unknowns for regex mining
    return out

def coalesce_duplicate_columns(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    vc = pd.Series(out.columns, dtype="object").value_counts()
    for name, cnt in vc.items():
        if cnt > 1:
            cols = [c for c in out.columns if c == name]
            s = out.loc[:, cols].bfill(axis=1).iloc[:, 0]
            out = out.drop(columns=cols)
            out[name] = s
    return out

def make_unique_columns(df: pd.DataFrame) -> pd.DataFrame:
    seen, new = {}, []
    for c in df.columns:
        if c not in seen:
            seen[c] = 0; new.append(c)
        else:
            seen[c] += 1; new.append(f"{c}_{seen[c]}")
    df.columns = new
    return df

def read_all_sheets(path: pathlib.Path):
    if path.suffix.lower() == ".ods":
        return pd.read_excel(path, sheet_name=None, header=None, dtype=str, engine="odf")
    return pd.read_excel(path, sheet_name=None, header=None, dtype=str)  # openpyxl

def find_header_row(df: pd.DataFrame, lookahead=25) -> int:
    best_i, best = -1, -1
    for i in range(min(len(df), lookahead)):
        row = [str(x) for x in df.iloc[i].tolist()]
        score = 0
        for x in row:
            sx = slug(x)
            for syns in SYN_MAP.values():
                if sx in {slug(t) for t in syns}:
                    score += 1
                    break
        if score > best:
            best, best_i = score, i
    return best_i

def norm_space(s: str) -> str:
    return re.sub(r'\s+', ' ', s).strip()

def dedup_semicolon(s: str) -> str:
    parts = [p.strip() for p in (s or "").split(";") if p.strip()]
    seen, out = set(), []
    for p in parts:
        if p.lower() not in seen:
            seen.add(p.lower()); out.append(p)
    return "; ".join(out)

# --------- Regex extractors ----------
EMAIL_RE = re.compile(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', re.I)
# Keep +, digits, (), spaces, dashes. Accept international formats.
PHONE_RE = re.compile(r'(?:(?:\+?\d{1,3}[\s-]?)?(?:\(?\d{2,4}\)?[\s-]?)?\d{3,4}[\s-]?\d{3,4}(?:[\s-]?\d{0,4})?)')
URL_RE = re.compile(r'\b((?:https?://)?(?:www\.)?[a-z0-9-]+(?:\.[a-z0-9-]+)+[^\s,;]*)', re.I)

def clean_phone(p: str) -> str:
    # collapse spaces; keep + and digits
    p = re.sub(r'[^\d+]+', '', p)
    # basic sanity
    return p if len(p) >= 7 else ""

def extract_list(pattern, text: str) -> list:
    if not text: return []
    return [m.group(0) if isinstance(m, re.Match) else m for m in pattern.finditer(str(text))]

def harvest_from_row(row: pd.Series, cols_all: list) -> dict:
    # start with direct columns if present
    val = lambda key: row[key] if key in row and pd.notna(row[key]) else ""
    out = {
        "Sector": norm_space(str(val("sector"))),
        "Business Name": norm_space(str(val("business_name"))),
        "Email": norm_space(str(val("email"))),
        "Phone number": norm_space(str(val("phone"))),
        "Address": norm_space(str(val("address"))),
        "Name": norm_space(str(val("name"))),
        "Title of Contact Person": norm_space(str(val("title"))),
        "Website": norm_space(str(val("website"))),
    }
    # Mine additional emails/phones/websites from every cell if missing or to augment
    text_blob = " ; ".join([str(row[c]) for c in cols_all if c in row and pd.notna(row[c])])
    # Emails
    emails = set(e.lower() for e in EMAIL_RE.findall(text_blob))
    if out["Email"]:
        emails.update(x.strip().lower() for x in out["Email"].split(";") if x.strip())
    out["Email"] = "; ".join(sorted(emails))
    # Phones
    phones_raw = [x for x in PHONE_RE.findall(text_blob) if isinstance(x, str)]
    phones = set()
    for p in phones_raw + out["Phone number"].split(";"):
        p = clean_phone(str(p))
        if p: phones.add(p)
    out["Phone number"] = "; ".join(sorted(phones))
    # Websites
    urls = set()
    for u in URL_RE.findall(text_blob):
        u = u[0] if isinstance(u, tuple) else u
        u = u.strip().rstrip(').,;')
        if not u.lower().startswith(("http://","https://")):
            u = "http://" + u
        urls.add(u.lower())
    if out["Website"]:
        urls.add(out["Website"].lower())
    out["Website"] = "; ".join(sorted(urls))
    return out

def normalize_sheet(raw: pd.DataFrame, source_file: str) -> pd.DataFrame | None:
    if raw is None or raw.empty: return None
    h = find_header_row(raw)
    if h < 0: return None
    headers = raw.iloc[h].tolist()
    data = raw.iloc[h+1:].reset_index(drop=True)
    data.columns = map_headers(headers)
    data = coalesce_duplicate_columns(data)
    data = make_unique_columns(data)
    # drop fully empty cols
    data = data.dropna(axis=1, how="all")

    # trim strings
    for c in data.columns:
        if data[c].dtype == "object":
            data[c] = data[c].astype(str).str.strip().replace({"": pd.NA})

    # Build output rows
    cols_all = list(data.columns)  # for mining
    rows = []
    for _, r in data.iterrows():
        # skip fully empty lines
        if all(pd.isna(x) or str(x).strip()=="" for x in r.tolist()):
            continue
        rec = harvest_from_row(r, cols_all)
        # at least one key present
        if any(rec[k] for k in ["Business Name","Email","Phone number","Website","Address","Name"]):
            rec["Source"] = source_file
            rows.append(rec)
    if not rows: return None
    df = pd.DataFrame(rows, columns=FINAL_COLS)
    # clean cell values
    for col in ["Email","Phone number","Website"]:
        df[col] = df[col].fillna("").map(dedup_semicolon)
    for col in FINAL_COLS:
        df[col] = df[col].fillna("").map(lambda s: norm_space(str(s)))
    return df

def dedupe_contacts(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    # helper keys
    def first_token(s: str) -> str:
        if not s: return ""
        for tok in [t.strip() for t in s.split(";") if t.strip()]:
            return tok.lower()
        return ""
    out["_email_primary"] = out["Email"].map(first_token)
    out["_phone_primary"] = out["Phone number"].map(first_token)
    out["_website_primary"] = out["Website"].map(first_token)
    out["_biz_norm"] = out["Business Name"].str.lower().str.replace(r'[^a-z0-9]+','', regex=True)

    # stable keep-first
    out = out.drop_duplicates(subset=["_email_primary"], keep="first")
    out = out.drop_duplicates(subset=["_phone_primary"], keep="first")
    out = out.drop_duplicates(subset=["_biz_norm","_website_primary","Address"], keep="first")

    out = out.drop(columns=[c for c in out.columns if c.startswith("_")])
    return out

def main():
    ap = argparse.ArgumentParser(description="Extract and normalize contact data from ALL sheets of many spreadsheets.")
    ap.add_argument("-o","--output", required=True, help="Output Excel path (e.g., Contacts.xlsx)")
    ap.add_argument("inputs", nargs="+", help="Input files (.xlsx, .ods)")
    args = ap.parse_args()

    all_rows = []
    report = []
    for f in args.inputs:
        p = pathlib.Path(f)
        if not p.exists():
            report.append((str(p),"*","MISSING",0,0)); continue
        try:
            book = read_all_sheets(p)
        except Exception as e:
            report.append((str(p),"*","READ_ERROR:"+str(e),0,0)); continue

        for sheet, raw in book.items():
            try:
                df = normalize_sheet(raw, str(p))
                if df is None or df.empty:
                    report.append((str(p), str(sheet), "NO_HEADER_MATCH_OR_EMPTY", len(raw), 0))
                else:
                    all_rows.append(df)
                    report.append((str(p), str(sheet), "OK", len(raw), len(df)))
            except Exception as e:
                report.append((str(p), str(sheet), "ERROR:"+str(e), len(raw), 0))

    if not all_rows:
        print("No rows extracted. See report.csv.")
        pd.DataFrame(report, columns=["file","sheet","status","rows_in","rows_out"]).to_csv("report.csv", index=False)
        sys.exit(2)

    combined = pd.concat(all_rows, ignore_index=True)
    combined = combined[FINAL_COLS]
    combined = dedupe_contacts(combined)

    out = pathlib.Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    with pd.ExcelWriter(out, engine="openpyxl") as xw:
        combined.to_excel(xw, sheet_name="Contacts", index=False)
        pd.DataFrame(report, columns=["file","sheet","status","rows_in","rows_out"]).to_excel(xw, sheet_name="Report", index=False)

    combined.to_csv(out.with_suffix(".csv"), index=False, encoding="utf-8-sig")
    pd.DataFrame(report, columns=["file","sheet","status","rows_in","rows_out"]).to_csv("report.csv", index=False)
    print(f"Wrote: {out}")
    print(f"Wrote: {out.with_suffix('.csv')}")
    print("Per-sheet log written to 'Report' sheet and report.csv")

if __name__ == "__main__":
    pd.options.display.width = 200
    main()
