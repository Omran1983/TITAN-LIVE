"""
Extract PRB-2026 rules and salary tables from official PDF report
"""
import pdfplumber
import json
import re
from pathlib import Path

def extract_prb_2026_data(pdf_path):
    """Extract salary tables and rules from PRB-2026 PDF"""
    
    results = {
        "salary_tables": [],
        "rules": [],
        "key_findings": []
    }
    
    with pdfplumber.open(pdf_path) as pdf:
        print(f"PDF has {len(pdf.pages)} pages")
        
        for page_num, page in enumerate(pdf.pages, 1):
            print(f"\nProcessing page {page_num}...")
            
            # Extract text
            text = page.extract_text()
            
            # Extract tables
            tables = page.extract_tables()
            if tables:
                print(f"  Found {len(tables)} tables")
                for table_idx, table in enumerate(tables):
                    results["salary_tables"].append({
                        "page": page_num,
                        "table_index": table_idx,
                        "data": table
                    })
            
            # Look for key rules
            if text:
                # Salary floor
                if "16,500" in text or "16500" in text:
                    results["key_findings"].append({
                        "page": page_num,
                        "type": "salary_floor",
                        "text": "Found Rs 16,500 reference"
                    })
                
                # Increment rules
                if "increment" in text.lower():
                    results["key_findings"].append({
                        "page": page_num,
                        "type": "increment",
                        "snippet": text[:200]
                    })
                
                # Performance requirements
                if "performance" in text.lower():
                    results["key_findings"].append({
                        "page": page_num,
                        "type": "performance",
                        "snippet": text[:200]
                    })
    
    return results

if __name__ == "__main__":
    pdf_path = Path("F:/AION-ZERO/blocks/hr_compliance/docs/PRB_2026_Official_Report.pdf")
    
    if not pdf_path.exists():
        print(f"ERROR: PDF not found at {pdf_path}")
        exit(1)
    
    print(f"Extracting data from: {pdf_path}")
    data = extract_prb_2026_data(pdf_path)
    
    # Save results
    output_path = Path("F:/AION-ZERO/blocks/hr_compliance/docs/extracted_data.json")
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Extraction complete!")
    print(f"   Salary tables found: {len(data['salary_tables'])}")
    print(f"   Key findings: {len(data['key_findings'])}")
    print(f"   Saved to: {output_path}")
