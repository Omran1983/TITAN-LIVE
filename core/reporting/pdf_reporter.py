from fpdf import FPDF
from pathlib import Path
import json
import abc
import hashlib
from datetime import datetime, timezone

class ReportGenerator(abc.ABC):
    @abc.abstractmethod
    def generate(self, data: dict, output_path: Path):
        pass

class CommercialPDFReporter(ReportGenerator):
    """
    Standard Commercial-Grade PDF Reporter for TITAN Blocks.
    Produces Inspector-Ready Compliance Reports.
    """
    def __init__(self, block_name: str, version: str):
        self.block_name = block_name
        self.version = version
        self.primary_color = (0, 0, 0) # Black
        self.accent_color = (13, 110, 253) # Bootstrap Blue
        self.fail_color = (220, 53, 69) # Red
        self.pass_color = (25, 135, 84) # Green

    def generate(self, data: dict, output_path: Path):
        # Calculate Audit Hash (Tamper-Evident)
        payload = json.dumps(data, sort_keys=True, ensure_ascii=False).encode("utf-8")
        audit_hash = hashlib.sha256(payload).hexdigest()[:16]

        pdf = FPDF()
        pdf.add_page()
        
        # Calculate Audit Hash (Tamper-Evident)
        payload = json.dumps(data, sort_keys=True, ensure_ascii=False).encode("utf-8")
        audit_hash = hashlib.sha256(payload).hexdigest()[:16]

        # --- Header ---
        pdf.set_font("helvetica", "B", 16)
        pdf.cell(0, 10, f"TITAN COMPLIANCE REPORT: {self.block_name.upper()}", new_x="LMARGIN", new_y="NEXT", align="C")
        
        pdf.set_font("helvetica", "I", 10)
        pdf.cell(0, 8, f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')} | Version: {self.version}", new_x="LMARGIN", new_y="NEXT", align="C")
        pdf.ln(5)

        # ... (rest of the content generation) ...
        # Note: I need to be careful not to overwrite the middle content. 
        # The replace_file_content tool replaces a chunk. 
        # I should output the Header part first, then the Footer part separately since they are far apart in the file.
        # But wait, looking at the code structure... generate() creates pdf... logic flows linearly.
        # The tool asks for TargetContent.
        # I will split this into two replacements if needed or verify location.
        # Let's do Header update first.

        # --- Executive Summary ---
        pdf.set_font("helvetica", "B", 12)
        pdf.set_fill_color(240, 240, 240)
        pdf.cell(0, 10, " EXECUTIVE SUMMARY", fill=True, new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("helvetica", "", 10)
        pdf.ln(3)
        
        failures = data.get("failures", 0)
        total = data.get("total_subjects", data.get("total_employees", data.get("total_items", 0)))
        
        if failures == 0:
            pdf.set_text_color(*self.pass_color)
            verdict = "COMPLIANT"
        else:
            pdf.set_text_color(*self.fail_color)
            verdict = "NON-COMPLIANT (RISK DETECTED)"
            
        pdf.cell(50, 8, "Overall Verdict:", border=0)
        pdf.set_font("helvetica", "B", 11)
        pdf.cell(0, 8, verdict, new_x="LMARGIN", new_y="NEXT", border=0)
        
        pdf.set_text_color(0, 0, 0)
        pdf.set_font("helvetica", "", 10)
        pdf.cell(50, 8, "Total Subjects Checked:", border=0)
        pdf.cell(0, 8, str(total), new_x="LMARGIN", new_y="NEXT", border=0)
        
        pdf.cell(50, 8, "Compliance Gaps:", border=0)
        pdf.cell(0, 8, str(failures), new_x="LMARGIN", new_y="NEXT", border=0)
        pdf.ln(5)

        # --- Detailed Findings ---
        pdf.set_font("helvetica", "B", 12)
        pdf.cell(0, 10, " DETAILED FINDINGS", fill=True, new_x="LMARGIN", new_y="NEXT")
        pdf.ln(3)

        pdf.set_font("helvetica", "B", 9)
        # Table Header
        col_w = [30, 40, 90, 30] # ID, Subject, Rule/Gap, Verdict
        pdf.set_fill_color(230, 230, 230)
        pdf.cell(col_w[0], 8, "Subject ID", 1, 0, 'C', True)
        pdf.cell(col_w[1], 8, "Name", 1, 0, 'C', True)
        pdf.cell(col_w[2], 8, "Rule / Evidence", 1, 0, 'C', True)
        pdf.cell(col_w[3], 8, "Verdict", 1, 1, 'C', True)

        pdf.set_font("helvetica", "", 8)
        
        # Data Rows
        details = data.get("details", [])
        for item in details:
            # Generic Subject ID resolution
            subject_id = str(item.get("subject_id", item.get("employee_id", item.get("id", "N/A"))))
            subject_name = str(item.get("subject_name", item.get("name", "N/A")))
            checks = item.get("checks", [])
            
            for check in checks:
                check_verdict = check.get("verdict", "UNKNOWN")
                rule_id = check.get("rule_id", "?")
                evidence = check.get("evidence", {})
                
                # Format Evidence Text
                evidence_text = f"{rule_id}: "
                if isinstance(evidence, dict):
                    gaps = [f"{k}={v}" for k, v in evidence.items()]
                    evidence_text += ", ".join(gaps)
                else:
                    evidence_text += str(evidence)
                
                # Dynamic Height Calculation using multi_cell logic if needed, 
                # but for simplicity using fixed cell with truncation or simple logic.
                # Actually, evidence might be long. Let's truncate or allow multi-line conceptually.
                # using multi_cell for the evidence column is better.
                
                # Save Start Position
                x_start = pdf.get_x()
                y_start = pdf.get_y()
                
                # Calculate max height
                # We need to simulate the multi_cell height
                # This is tricky in FPDF 1.7/2 without some math. 
                # Let's simplify: Standard 1 line unless evidence is long.
                
                pdf.cell(col_w[0], 8, subject_id, 1, 0)
                pdf.cell(col_w[1], 8, subject_name, 1, 0)
                
                # Evidence Cell (Truncated for strict MVP table)
                # In prod, we'd wrap.
                evidence_text_short = (evidence_text[:50] + '..') if len(evidence_text) > 50 else evidence_text
                pdf.cell(col_w[2], 8, evidence_text_short, 1, 0)
                
                # Verdict Cell
                if check_verdict == "FAIL":
                    pdf.set_text_color(*self.fail_color)
                    pdf.set_font("helvetica", "B", 8)
                elif check_verdict == "PASS":
                    pdf.set_text_color(*self.pass_color)
                    pdf.set_font("helvetica", "B", 8)
                else: 
                     pdf.set_text_color(0,0,0)
                     
                pdf.cell(col_w[3], 8, check_verdict, 1, 1, 'C')
                
                # Reset
                pdf.set_text_color(0, 0, 0)
                pdf.set_font("helvetica", "", 8)

        pdf.ln(10)
        
        # --- Footer / Signature ---
        pdf.set_y(-30)
        pdf.set_font("helvetica", "I", 8)
        pdf.cell(0, 5, "Generated automatically by TITAN-OS. This document serves as a compliance artifact.", 0, 1, 'C')
        pdf.cell(0, 5, f"Audit Hash: {audit_hash}", 0, 1, 'C')

        pdf.output(output_path)
        print(f"✅ PDF Generated: {output_path}")

def generate_compliance_report(json_data: dict, output_path: Path, block_name="Generic", version="1.0"):
    reporter = CommercialPDFReporter(block_name, version)
    reporter.generate(json_data, output_path)
