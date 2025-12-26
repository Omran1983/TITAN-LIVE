import os
import re
from pathlib import Path
from datetime import datetime
from typing import List, Tuple

from pydantic import BaseModel
from fpdf import FPDF

# --- CONFIGURATION ---
# Base constants (can be overridden by logic map)
GRANT_CAP = 150000.0
REFUND_RATE = 0.80

# FPDF core fonts (Helvetica) are Latin-1; avoid unicode that can crash rendering.
def _latin1_safe(text: str) -> str:
    if text is None:
        return ""
    # Replace common "smart quotes" or bullets
    text = text.replace("“", '"').replace("”", '"').replace("’", "'").replace("–", "-")
    return text.encode("latin-1", "replace").decode("latin-1")

def _safe_slug(s: str) -> str:
    s = (s or "").strip()
    s = re.sub(r"\s+", "_", s)
    s = re.sub(r"[^A-Za-z0-9_\-]+", "", s)
    return s[:60] or "company"

def _io_root() -> Path:
    return Path(os.environ.get("TITAN_IO_ROOT", r"F:\AION-ZERO\TITAN\io"))

def _outbox() -> Path:
    p = _io_root() / "outbox"
    p.mkdir(parents=True, exist_ok=True)
    return p

class GrantScenario(BaseModel):
    project_type: str
    cost: float
    narrative_strength: str

class Outcome(BaseModel):
    scenario: str
    refund_amount: float
    probability_of_approval: float
    risk_factors: List[str]
    recommendation: str

class TinnsGenerator:
    """
    Core Engine for TINNS Grants (Logic Map v1.0).
    Implements deterministic routing and human-refined copy.
    """

    def __init__(self):
        self.rules = {
            "Hardware":   {"risk": "Low",    "bias": 0.92},
            "Software":   {"risk": "Medium", "bias": 0.86},
        }

    # --- LOGIC MAP IMPLEMENTATION ---

    def _evaluate_eligibility(self, data: dict) -> dict:
        """
        Rule Group 1: SME Eligibility & Rule Group 4: Documentation Readiness
        """
        checklist = []
        status = "ELIGIBLE"
        
        # 1. Turnover Band (The Gate)
        turnover = data.get("turnover_band", "") # Expecting ">50M" or "<50M" from UI
        if turnover == ">50M":
            status = "INELIGIBLE"
            checklist.append(("Annual Turnover", "> Rs 50M (Exceeds SME Limit)", "FAIL"))
        elif turnover:
            checklist.append(("Annual Turnover", f"Confirmed SME Bracket ({turnover})", "PASS"))
        else:
            checklist.append(("Annual Turnover", "Not provided", "WARN"))

        # 2. Company Age
        try:
            age = float(data.get("company_age_years", 0))
        except:
            age = 0
            
        if age < 1:
            if status != "INELIGIBLE": status = "CONDITIONAL"
            checklist.append(("Business Maturity", "Startup < 1yr (Additional Justification Required)", "WARN"))
        else:
            checklist.append(("Business Maturity", f"Established ({age} years)", "PASS"))

        # 3. Documentation Readiness
        doc_ready = data.get("documentation_ready", "No") # Yes / Partial / No
        if doc_ready == "No":
            checklist.append(("Documentation", "Gap Warnings Active (Draft Status)", "WARN"))
        elif doc_ready == "Partial":
            checklist.append(("Documentation", "Assumptions Included (Client Confirmation Req)", "WARN"))
        else:
            checklist.append(("Documentation", "Submission-Ready status", "PASS"))

        return {"status": status, "checklist": checklist, "doc_ready": doc_ready}

    def recommend_scheme(self, data: dict) -> dict:
        """
        Rule Group 2: Sector Routing
        """
        sector = data.get("sector", "Other")
        
        if sector == "Agriculture":
            return {
                "name": "Agricultural Equipment Grant (FAREI)",
                "rate": 0.50,
                "cap": 350000,
                "template_set": "AGRI"
            }
        elif sector == "Manufacturing":
            return {
                "name": "Made in Moris / Equipment Support",
                "rate": 1.0,
                "cap": 50000,
                "template_set": "MANUFACTURING"
            }
        else:
            # Default to TINNS
            return {
                "name": "Technology & Innovation Scheme (TINNS)",
                "rate": 0.80,
                "cap": 150000,
                "template_set": "ICT_STANDARD"
            }

    def determine_strategy(self, budget: float, scheme_cap: float) -> dict:
        """
        Rule Group 3: Budget & Strategy Selection
        """
        strategy = ""
        tone = ""
        
        if budget <= 50000:
            strategy = "Lean Upgrade"
            tone = "Efficiency / Compliance"
        elif budget <= 150000:
            strategy = "Core Digital Transformation"
            tone = "Productivity / ROI"
        else:
            # Budget > 150k (likely over cap depending on scheme)
            if budget > scheme_cap:
                 strategy = "Phased Implementation"
                 tone = "Split into Grant Phase + Client Phase"
            else:
                 strategy = "Core Digital Transformation"
                 tone = "Productivity / ROI"
                 
        return {"strategy": strategy, "tone": tone}

    def generate_full_application(self, project_name: str, cost: float, company_name: str, 
                                  eligibility_data: dict = None, summary: str = None, timeline: str = "ASAP") -> str:
        """
        Generates the PDF artifact using Refined Human Copy.
        """
        if cost < 0: raise ValueError("cost must be >= 0")
        
        eligibility_data = eligibility_data or {}
        
        # Run Logic Gates
        elig_result = self._evaluate_eligibility(eligibility_data)
        scheme = self.recommend_scheme(eligibility_data)
        strat = self.determine_strategy(cost, scheme["cap"])
        
        # Meta Data
        company_name = (company_name or "Company").strip()
        project_name = (project_name or "Project").strip()
        urgency = eligibility_data.get("urgency_level", "Normal")
        
        # Refund Math
        refund_amount = min(cost * scheme["rate"], scheme["cap"])
        client_contrib = cost - refund_amount

        # --- REFINED COPY BLOCKS ---
        
        # A. Executive Summary
        # Use provided summary if strong, else use Template
        if not summary or len(summary) < 50:
            exec_summary = (
                "This project addresses a clearly identified operational need within the business and proposes a structured, "
                "cost-controlled upgrade using appropriate technology.\n\n"
                "The objective is to improve efficiency, reduce manual workload, and strengthen long-term sustainability "
                f"while remaining aligned with the funding priorities of the {scheme['name']}."
            )
        else:
            # If user provided raw text, we wrap it in professional framing? 
            # For now, let's stick to the generated professional copy as the "Abstract" 
            # and append user specifics if needed. Ideally, we replace robotic text.
            exec_summary = (
                "This project addresses a clearly identified operational need within the business and proposes a structured, "
                "cost-controlled upgrade using appropriate technology.\n\n"
                "The objective is to improve efficiency, reduce manual workload, and strengthen long-term sustainability "
                f"while remaining aligned with the funding priorities of the {scheme['name']}."
            )

        # B. Strategic Alignment
        strat_align_text = (
            f"The proposed initiative is consistent with the objectives of the {scheme['name']}, "
            "particularly in supporting SME productivity, operational modernisation, and responsible adoption of technology.\n\n"
            "The project scope has been deliberately defined to remain practical, achievable, and proportionate "
            "to the size and maturity of the business."
        )

        # C. Timeline
        timeline_intro = (
            "The project will be implemented in clearly defined phases to minimise disruption to daily operations "
            "and ensure accountability at each stage."
        )
        
        # Impact of Urgency
        if urgency == "High":
            timeline_intro += " (Prioritised Speed Strategy applied)."

        timeline_steps = [
            "Procurement & Vendor Finalisation",
            "Installation & Configuration",
            "Training & User Acceptance",
            "Deployment & Sign-off"
        ]

        # D. Financial Justification
        fin_just_text = (
            "The financial structure of the project reflects a balanced cost-sharing approach between the applicant "
            "and the funding scheme.\n\n"
            "All cost assumptions are based on prevailing market rates and can be substantiated by quotations at submission stage."
        )

        # E. Disclaimer
        disclaimer_text = (
            "This assessment is based on information provided by the applicant and publicly available scheme guidelines. "
            "Final eligibility remains subject to the funding authority's independent review."
        )

         # F. Verdict Badge Text
        estatus = elig_result["status"]
        if estatus == "ELIGIBLE":
            badge_text = "PROJECT PLAN READY FOR SCHEME REVIEW"
            badge_color = (220, 255, 220) # Light Green
            text_color = (25, 135, 84)    # Dark Green
            
        elif estatus == "CONDITIONAL":
            badge_text = "PROJECT PLAN REQUIRES ADDITIONAL INFORMATION"
            badge_color = (255, 243, 205) # Light Yellow
            text_color = (133, 100, 4)    # Dark Yellow
        else:
            badge_text = "PROJECT DOES NOT MEET CURRENT SCHEME CRITERIA"
            badge_color = (255, 220, 220) # Light Red
            text_color = (220, 53, 69)    # Dark Red


        # --- PDF GENERATION ---
        pdf = FPDF()
        pdf.set_auto_page_break(auto=True, margin=15)
        pdf.add_page()

        # Header
        pdf.set_font("Helvetica", "B", 18)
        pdf.cell(0, 10, _latin1_safe("TITAN PROJECT ARCHITECT"), ln=True, align='C')
        pdf.set_font("Helvetica", "", 11)
        pdf.cell(0, 6, _latin1_safe(f"Prepared for: {company_name}"), ln=True, align='C')
        pdf.cell(0, 6, _latin1_safe(f"Scheme: {scheme['name']}"), ln=True, align='C')
        pdf.ln(8)

        # 1. Executive Summary Box
        pdf.set_fill_color(240, 248, 255) # AliceBlue
        pdf.rect(10, pdf.get_y(), 190, 35, 'F')
        pdf.set_font("Helvetica", "B", 12)
        pdf.cell(0, 8, "  EXECUTIVE SUMMARY", ln=True)
        pdf.set_font("Helvetica", "", 10)
        pdf.set_x(12)
        pdf.multi_cell(186, 5, _latin1_safe(exec_summary))
        pdf.ln(10)

        # 2. Strategic Alignment
        pdf.set_font("Helvetica", "B", 12)
        pdf.cell(0, 8, "1. STRATEGIC ALIGNMENT", ln=True)
        pdf.set_font("Helvetica", "", 10)
        pdf.multi_cell(0, 5, _latin1_safe(strat_align_text))
        pdf.ln(2)
        pdf.set_font("Helvetica", "I", 9)
        pdf.cell(0, 5, _latin1_safe(f"Selected Strategy: {strat['strategy']} ({strat['tone']})"), ln=True)
        pdf.ln(6)

        # 3. Implementation Timeline
        pdf.set_font("Helvetica", "B", 12)
        pdf.cell(0, 8, "2. IMPLEMENTATION TIMELINE", ln=True)
        pdf.set_font("Helvetica", "", 10)
        pdf.multi_cell(0, 5, _latin1_safe(timeline_intro))
        pdf.ln(2)
        for step in timeline_steps:
             pdf.cell(6, 5, chr(149), ln=0)
             pdf.cell(0, 5, _latin1_safe(step), ln=True)
        pdf.ln(6)

        # 4. Financial Plan
        pdf.set_font("Helvetica", "B", 12)
        pdf.cell(0, 8, "3. FINANCIAL PLAN", ln=True)
        pdf.set_font("Helvetica", "", 10)
        pdf.multi_cell(0, 5, _latin1_safe(fin_just_text))
        pdf.ln(4)

        # Financial Table
        pdf.set_fill_color(240, 240, 240)
        pdf.set_font("Helvetica", "B", 10)
        pdf.cell(100, 8, "Component", 1, 0, 'L', True)
        pdf.cell(50, 8, "Amount (MUR)", 1, 1, 'R', True)
        
        pdf.set_font("Helvetica", "", 10)
        pdf.cell(100, 8, "Total Project Cost", 1, 0)
        pdf.cell(50, 8, f"{cost:,.2f}", 1, 1, 'R')
        
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color(25, 135, 84) 
        pdf.cell(100, 8, f"Grant Refund ({scheme['rate']*100:.0f}%)", 1, 0)
        pdf.cell(50, 8, f"{refund_amount:,.2f}", 1, 1, 'R')
        pdf.set_text_color(0, 0, 0)

        pdf.cell(100, 8, "Net Cost to Client", 1, 0)
        pdf.cell(50, 8, f"{client_contrib:,.2f}", 1, 1, 'R')
        pdf.ln(8)

        # 5. Eligibility Audit
        pdf.set_font("Helvetica", "B", 12)
        pdf.cell(0, 8, "4. ELIGIBILITY AUDIT", ln=True)
        pdf.set_font("Helvetica", "I", 9)
        pdf.multi_cell(0, 5, _latin1_safe(disclaimer_text))
        pdf.ln(2)

        pdf.set_font("Helvetica", "B", 9)
        pdf.set_fill_color(240, 240, 240)
        pdf.cell(50, 7, "Criterion", 1, 0, 'L', True)
        pdf.cell(100, 7, "Observation", 1, 0, 'L', True)
        pdf.cell(40, 7, "Status", 1, 1, 'C', True)

        pdf.set_font("Helvetica", "", 9)
        for crit, obs, stat in elig_result["checklist"]:
            pdf.cell(50, 7, _latin1_safe(crit), 1)
            pdf.cell(100, 7, _latin1_safe(obs), 1)
            
            if stat == "PASS": pdf.set_text_color(25, 135, 84)
            elif stat == "FAIL": pdf.set_text_color(220, 53, 69)
            else: pdf.set_text_color(200, 150, 0)
            
            pdf.cell(40, 7, stat, 1, 1, 'C')
            pdf.set_text_color(0, 0, 0)
        pdf.ln(8)

        # Outcome Badge
        pdf.set_fill_color(*badge_color)
        pdf.set_text_color(*text_color)
        pdf.set_font("Helvetica", "B", 11)
        pdf.cell(0, 10, badge_text, 1, 1, 'C', True)
        pdf.set_text_color(0, 0, 0)

        # G. Global Footer
        pdf.set_y(-25)
        pdf.set_font("Helvetica", "", 8)
        pdf.multi_cell(0, 4, 
            "This document has been prepared as a structured project plan to support a funding application. "
            "It does not constitute a guarantee of approval, nor does it represent submission on behalf of the applicant.", 
            align='C'
        )

        stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"TITAN_PLAN_{_safe_slug(company_name)}_{stamp}.pdf"
        out_path = (_outbox() / filename).resolve()
        pdf.output(str(out_path))
        return str(out_path)

    def simulate_scenarios(self, base_cost: float) -> List[Outcome]:
        # Keeps legacy method for compatibility if needed, but redirects logic
        return []
