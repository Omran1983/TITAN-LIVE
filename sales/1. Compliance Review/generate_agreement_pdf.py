import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Frame, PageTemplate
from reportlab.lib.units import inch
from datetime import datetime

class AgreementGenerator:
    def __init__(self, output_path):
        self.output_path = output_path
        self.styles = getSampleStyleSheet()
        self._setup_custom_styles()

    def _setup_custom_styles(self):
        # Use a unique name to avoid collision with getSampleStyleSheet defaults
        self.styles.add(ParagraphStyle(
            name='AgreementTitle',
            parent=self.styles['Heading1'],
            fontSize=24,
            spaceAfter=20,
            alignment=1, # Center
            textColor=colors.HexColor('#1f2937')
        ))
        self.styles.add(ParagraphStyle(
            name='SectionHeader',
            parent=self.styles['Heading2'],
            fontSize=14,
            spaceBefore=12,
            spaceAfter=6,
            textColor=colors.HexColor('#111827'),
            borderPadding=(0, 0, 5, 0),
            borderWidth=0,
            borderColor=colors.white
        ))
        self.styles.add(ParagraphStyle(
            name='AgreementBody',
            parent=self.styles['Normal'],
            fontSize=10,
            leading=14,
            textColor=colors.HexColor('#374151')
        ))
        self.styles.add(ParagraphStyle(
            name='FinePrint',
            parent=self.styles['Normal'],
            fontSize=8,
            textColor=colors.HexColor('#9ca3af'),
            alignment=1
        ))

    def generate(self):
        doc = SimpleDocTemplate(
            self.output_path,
            pagesize=A4,
            rightMargin=50, leftMargin=50,
            topMargin=50, bottomMargin=50
        )
        
        story = []
        
        # --- Header ---
        story.append(Spacer(1, 0.5*inch))
        story.append(Paragraph("COMPLIANCE SERVICES AGREEMENT", self.styles['AgreementTitle']))
        story.append(Spacer(1, 0.2*inch))
        
        # --- Parties ---
        story.append(Paragraph("<b>BETWEEN:</b>", self.styles['AgreementBody']))
        story.append(Spacer(1, 4))
        story.append(Paragraph("<b>Service Provider:</b> A-One Global Resourcing Ltd (BRN: C22185206 | TAN: 28006142)", self.styles['AgreementBody']))
        story.append(Paragraph("Email: compliance@aogrl.com", self.styles['AgreementBody']))
        story.append(Spacer(1, 8))
        story.append(Paragraph("<b>AND Client:</b> ______________________________________________________", self.styles['AgreementBody']))
        story.append(Spacer(1, 0.4*inch))

        # --- Sections ---
        sections = [
            ("1. PURPOSE", 
             "Provider will deliver compliance assurance reporting and documentation support for the Client's private-sector employment obligations, based on information supplied by Client. Provider does not provide legal advice and does not act as a law firm. Provider provides reporting, templates, and operational guidance."),
             
            ("2. SCOPE OF SERVICES (SELECTED MODULES)", 
             "Client selects one or more modules ('Scope'):\n"
             "A) Remuneration Regulations/Order mapping and payroll checks\n"
             "B) Minimum wage validation (as applicable)\n"
             "C) Working hours / overtime risk checks (as applicable)\n"
             "D) HR documentation checklist and templates pack\n"
             "E) Statutory obligations tracker (NPF/NSF/PRGF)\n"
             "F) Inspector-ready audit pack (PDF) and audit trail ID\n\n"
             "Final selected Scope is confirmed in writing (email/WhatsApp) before first report."),
             
            ("3. CLIENT RESPONSIBILITIES", 
             "3.1 Client warrants that the data provided is accurate, complete, and up to date.\n"
             "3.2 Client is responsible for all payroll decisions, payments, and filings.\n"
             "3.3 Client must provide requested supporting documents (where selected)."),
             
            ("4. DELIVERY & TURNAROUND", 
             "4.1 Standard turnaround: within 48 business hours after receiving complete inputs for that reporting cycle.\n"
             "4.2 Provider may request clarifications; turnaround pauses until Client responds."),
             
            ("5. FEES & PAYMENT", 
             "5.1 Setup fee: MUR 5,000 (one-off) for mapping Client payroll sheet, onboarding, and initial configuration.\n"
             "5.2 Monthly subscription fees per selected tier (employee count band) as per invoice or pricing schedule.\n"
             "5.3 Invoices are payable in advance unless agreed otherwise."),
             
            ("6. SERVICE GUARANTEE (BOUNDED)", 
             "6.1 If Provider misses an in-scope check due to Provider’s process (and Client provided accurate data), Provider will re-run the report within 48 business hours and refund one (1) month of the monthly subscription fee.\n"
             "6.2 This guarantee does not apply where errors arise from incomplete/incorrect data, unselected modules, or changes in law/regulation."),
             
            ("7. CONFIDENTIALITY & DATA PROTECTION", 
             "7.1 Each party will keep Confidential Information confidential.\n"
             "7.2 Provider will process personal data only for compliance reporting and related support ('purpose-limited').\n"
             "7.3 Provider will implement access controls and client-dedicated storage.\n"
             "7.4 Client chooses retention: (a) delete-after-report; or (b) archive for audit trail."),
             
            ("8. LIMITATION OF LIABILITY", 
             "8.1 Provider’s liability is limited to fees paid by Client in the preceding one (1) month for the relevant service period, except where prohibited by law.\n"
             "8.2 Provider is liable for indirect or consequential losses, including penalties, business interruption, or disputes."),
             
            ("9. TERMINATION", 
             "Either party may terminate with 14 days’ written notice. No refund for paid periods already started, except under Clause 6.")
        ]

        for title, text in sections:
            story.append(Paragraph(title, self.styles['SectionHeader']))
            story.append(Paragraph(text, self.styles['AgreementBody']))
            story.append(Spacer(1, 0.1*inch))

        # --- Signatures ---
        story.append(Spacer(1, 0.5*inch))
        story.append(Paragraph("<b>IN WITNESS WHEREOF</b>, the parties have executed this Agreement.", self.styles['AgreementBody']))
        story.append(Spacer(1, 0.4*inch))
        
        story.append(Paragraph("<b>Signed for A-One Global Resourcing Ltd:</b>", self.styles['AgreementBody']))
        story.append(Spacer(1, 0.3*inch))
        story.append(Paragraph("__________________________________________ &nbsp;&nbsp;&nbsp; Date: _______________", self.styles['AgreementBody']))
        story.append(Spacer(1, 0.3*inch))
        
        story.append(Paragraph("<b>Signed for Client:</b>", self.styles['AgreementBody']))
        story.append(Spacer(1, 0.3*inch))
        story.append(Paragraph("__________________________________________ &nbsp;&nbsp;&nbsp; Date: _______________", self.styles['AgreementBody']))
        
        # --- Footer ---
        story.append(Spacer(1, 0.8*inch))
        story.append(Paragraph("A-One Global Resourcing Ltd | BRN: C22185206 | Mauritius", self.styles['FinePrint']))
        
        doc.build(story)
        print(f"Agreement PDF generated at: {self.output_path}")

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.abspath(__file__))
    output_file = os.path.join(base_dir, "Client_Compliance_Agreement.pdf")
    generator = AgreementGenerator(output_file)
    generator.generate()
