"""
Extract master salary table from PRB 2021 Volume 1
Focus on the Master Conversion Table (Annex)
"""
import pdfplumber
import json
import re
from pathlib import Path

def extract_salary_table(pdf_path):
    """Extract master salary conversion table"""
    
    results = {
        "master_salary_table": [],
        "salary_floor": None,
        "increment_rules": [],
        "key_pages": []
    }
    
    with pdfplumber.open(pdf_path) as pdf:
        print(f"PDF has {len(pdf.pages)} pages")
        
        # Focus on Annex pages (usually at the end)
        # Master Conversion Table is typically in the annex
        start_page = max(0, len(pdf.pages) - 50)  # Check last 50 pages
        
        for page_num in range(start_page, len(pdf.pages)):
            page = pdf.pages[page_num]
            text = page.extract_text()
            
            # Look for Master Conversion Table
            if text and ("master" in text.lower() and "conversion" in text.lower()):
                print(f"\n✓ Found Master Conversion Table on page {page_num + 1}")
                results["key_pages"].append(page_num + 1)
                
                # Extract tables
                tables = page.extract_tables()
                if tables:
                    for table in tables:
                        results["master_salary_table"].append({
                            "page": page_num + 1,
                            "data": table
                        })
            
            # Look for salary floor (16,500)
            if text and ("16,500" in text or "16500" in text):
                print(f"✓ Found Rs 16,500 reference on page {page_num + 1}")
                results["salary_floor"] = {
                    "amount": 16500,
                    "page": page_num + 1,
                    "context": text[:300]
                }
            
            # Look for increment rules
            if text and "increment" in text.lower() and "eligib" in text.lower():
                results["increment_rules"].append({
                    "page": page_num + 1,
                    "snippet": text[:500]
                })
    
    return results

if __name__ == "__main__":
    pdf_path = Path("F:/AION-ZERO/blocks/hr_compliance/docs/PRB_2021_Volume1_General.pdf")
    
    if not pdf_path.exists():
        print(f"ERROR: PDF not found at {pdf_path}")
        exit(1)
    
    print(f"Extracting master salary table from: {pdf_path}")
    data = extract_salary_table(pdf_path)
    
    # Save results
    output_path = Path("F:/AION-ZERO/blocks/hr_compliance/docs/master_salary_table.json")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Extraction complete!")
    print(f"   Master tables found: {len(data['master_salary_table'])}")
    print(f"   Salary floor: {data['salary_floor']}")
    print(f"   Increment rules: {len(data['increment_rules'])}")
    print(f"   Saved to: {output_path}")
