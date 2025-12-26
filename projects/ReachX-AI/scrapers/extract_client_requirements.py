import zipfile, re, csv, sys, pathlib

def extract_requirements(docx_path, out_csv):
    # Open DOCX (zip) and read main document XML
    with zipfile.ZipFile(docx_path) as z:
        xml = z.read("word/document.xml").decode("utf-8", errors="ignore")

    # Rough text extraction: break on </w:p> and strip tags
    xml = xml.replace("</w:p>", "\n")
    text = re.sub(r"<.*?>", "", xml)
    lines = [l.strip() for l in text.splitlines() if l.strip()]

    # Expect first 4 lines are headers
    header = [s.lower() for s in lines[:4]]
    expected = ["client name", "country", "contact number", "requirements"]
    if header != expected:
        print("Warning: unexpected header row:", header, file=sys.stderr)

    data_lines = lines[4:]
    remainder = len(data_lines) % 4
    if remainder:
        print(f"Warning: dropping last {remainder} dangling line(s).", file=sys.stderr)
        data_lines = data_lines[:-remainder]

    rows = []
    for i in range(0, len(data_lines), 4):
        client, country, contact, req = data_lines[i:i+4]
        rows.append({
            "employer_name": client,
            "country": country,
            "contact": contact,
            "requirements": req,
            "source": "client_docx_2025-11-28",
        })

    out_path = pathlib.Path(out_csv)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with out_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["employer_name", "country", "contact", "requirements", "source"],
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} rows to {out_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python extract_client_requirements.py <input.docx> <output.csv>")
        sys.exit(1)

    extract_requirements(sys.argv[1], sys.argv[2])
