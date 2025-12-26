import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table, TableStyle, Image, NextPageTemplate, PageBreak
from reportlab.lib.units import inch, mm
from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT, TA_JUSTIFY
from datetime import datetime

class CorporateReportGenerator:
    def __init__(self, output_path, logo_path=None):
        self.output_path = output_path
        self.logo_path = logo_path
        self.styles = getSampleStyleSheet()
        # "Big 4" Style Colors: Deep Navy & Clean Grey
        self.brand_primary = colors.HexColor('#0f172a') 
        self.brand_secondary = colors.HexColor('#334155')
        self.accent_danger = colors.HexColor('#b91c1c')
        self.accent_warning = colors.HexColor('#d97706')
        self.accent_success = colors.HexColor('#059669')
        self._setup_custom_styles()

    def _setup_custom_styles(self):
        self.styles.add(ParagraphStyle(
            name='CoverTitle',
            parent=self.styles['Heading1'],
            fontSize=28,
            leading=32,
            textColor=self.brand_primary,
            fontName='Helvetica-Bold',
            spaceAfter=20
        ))
        self.styles.add(ParagraphStyle(
            name='CoverSub',
            parent=self.styles['Normal'],
            fontSize=12,
            textColor=self.brand_secondary,
            fontName='Helvetica',
            leading=16
        ))
        self.styles.add(ParagraphStyle(
            name='SectionHeader',
            parent=self.styles['Heading2'],
            fontSize=12,
            textColor=self.brand_primary,
            fontName='Helvetica-Bold',
            borderPadding=(0, 0, 8, 0),
            borderColor=colors.HexColor('#e2e8f0'),
            borderWidth=1,
            spaceBefore=20,
            spaceAfter=15,
            textTransform='uppercase'
        ))
        self.styles.add(ParagraphStyle(
            name='NormalJustified',
            parent=self.styles['Normal'],
            alignment=TA_JUSTIFY,
            leading=14,
            textColor=colors.HexColor('#334155')
        ))

    def _cover_page(self, canvas, doc):
        canvas.saveState()
        # Background Content (White)
        canvas.setFillColor(colors.white)
        canvas.rect(0, 0, A4[0], A4[1], fill=1, stroke=0)
        
        # --- LETTERHEAD (Same as Content Pages) ---
        # 1. Logo (Larger, Top Left)
        if self.logo_path and os.path.exists(self.logo_path):
             canvas.drawImage(self.logo_path, 40, A4[1] - 75, width=70*mm, height=25*mm, preserveAspectRatio=True, mask='auto')
        else:
             canvas.setFont("Helvetica-Bold", 18)
             canvas.setFillColor(self.brand_primary)
             canvas.drawString(40, A4[1] - 50, "AOGRL")

        # 2. Company Details (Top Right Block)
        canvas.setFillColor(self.brand_secondary)
        canvas.setFont("Helvetica-Bold", 10)
        canvas.drawRightString(A4[0] - 40, A4[1] - 40, "A-One Global Resourcing Ltd")
        
        canvas.setFont("Helvetica", 8)
        canvas.drawRightString(A4[0] - 40, A4[1] - 52, "BRN: C22185206 | TAN: 28006142")
        canvas.drawRightString(A4[0] - 40, A4[1] - 64, "Port Louis, Mauritius")
        canvas.drawRightString(A4[0] - 40, A4[1] - 76, "compliance@aogrl.com | +230 5250 1234")

        # 3. Header Line (Thick Corporate Blue)
        canvas.setStrokeColor(self.brand_primary)
        canvas.setLineWidth(2)
        canvas.line(40, A4[1] - 85, A4[0] - 40, A4[1] - 85)

        # --- BOTTOM BRAND BAR ---
        canvas.setFillColor(self.brand_primary)
        canvas.rect(0, 0, A4[0], 15*mm, fill=1, stroke=0)
        canvas.setFont("Helvetica", 9)
        canvas.setFillColor(colors.white)
        canvas.drawCentredString(A4[0]/2, 6*mm, "A-One Global Resourcing Ltd | BRN: C22185206 | www.aogrl.com")
        
        canvas.restoreState()

    def _header_footer(self, canvas, doc):
        canvas.saveState()
        
        # --- LETTERHEAD ---
        # 1. Logo (Larger, Top Left)
        if self.logo_path and os.path.exists(self.logo_path):
             # Increased size: width 50mm -> 60mm
             canvas.drawImage(self.logo_path, 40, A4[1] - 65, width=60*mm, height=20*mm, preserveAspectRatio=True, mask='auto')
        else:
             # Fallback
             canvas.setFont("Helvetica-Bold", 18)
             canvas.setFillColor(self.brand_primary)
             canvas.drawString(40, A4[1] - 50, "AOGRL")

        # 2. Company Details (Top Right Block)
        canvas.setFillColor(self.brand_secondary)
        canvas.setFont("Helvetica-Bold", 10)
        canvas.drawRightString(A4[0] - 40, A4[1] - 40, "A-One Global Resourcing Ltd")
        
        canvas.setFont("Helvetica", 8)
        canvas.drawRightString(A4[0] - 40, A4[1] - 52, "BRN: C22185206 | TAN: 28006142")
        canvas.drawRightString(A4[0] - 40, A4[1] - 64, "Port Louis, Mauritius")
        canvas.drawRightString(A4[0] - 40, A4[1] - 76, "compliance@aogrl.com | +230 5250 1234")

        # 3. Header Line (Thick Corporate Blue)
        canvas.setStrokeColor(self.brand_primary)
        canvas.setLineWidth(2)
        canvas.line(40, A4[1] - 85, A4[0] - 40, A4[1] - 85)

        # --- FOOTER ---
        canvas.setStrokeColor(colors.HexColor('#e2e8f0'))
        canvas.setLineWidth(0.5)
        canvas.line(40, 40, A4[0] - 40, 40)
        
        canvas.setFont("Helvetica-Oblique", 7)
        canvas.setFillColor(colors.grey)
        canvas.drawString(40, 25, f"Audit Ref: AOGRL-{datetime.now().strftime('%Y%m')}-001 | Strictly Private & Confidential")
        canvas.drawRightString(A4[0] - 40, 25, f"Page {doc.page} of 3")
        
        canvas.restoreState()

    def generate(self):
        doc = BaseDocTemplate(self.output_path, pagesize=A4, rightMargin=40, leftMargin=40, topMargin=110, bottomMargin=50)
        
        # Frame for Cover
        cover_frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id='cover')
        # Frame for Content (with header space)
        content_frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height - 60, id='content', topPadding=20)
        
        templates = [
            PageTemplate(id='cover', frames=cover_frame, onPage=self._cover_page),
            PageTemplate(id='content', frames=content_frame, onPage=self._header_footer)
        ]
        doc.addPageTemplates(templates)
        
        story = []
        
        # --- COVER PAGE CONTENT ---
        story.append(Spacer(1, 3*inch))
        story.append(Paragraph("EMPLOYMENT COMPLIANCE<br/>AUDIT REPORT", self.styles['CoverTitle']))
        story.append(Spacer(1, 0.2*inch))
        story.append(Paragraph("<b>PREPARED FOR:</b><br/>Sample Construction Ltd<br/>Royal Road, Port Louis", self.styles['CoverSub']))
        story.append(Spacer(1, 0.5*inch))
        story.append(Paragraph(f"<b>Submission Date:</b> {datetime.now().strftime('%d %B %Y')}", self.styles['CoverSub']))
        story.append(NextPageTemplate('content'))
        story.append(PageBreak())

        # --- PAGE 2: EXECUTIVE SUMMARY ---
        story.append(Paragraph("1.0 EXECUTIVE SUMMARY", self.styles['SectionHeader']))
        story.append(Paragraph(
            "We have conducted a compliance review of your payroll and HR records against the <b>Workers' Rights Act 2019</b> "
            "and the <b>Remuneration Regulations 2019 (Construction Industry)</b>.",
            self.styles['NormalJustified']
        ))
        story.append(Spacer(1, 0.1*inch))
        story.append(Paragraph(
            "Our audit highlights critical financial risks related to base salary underpayment and overtime calculation errors. "
            "Please find the summary of risks below.",
            self.styles['NormalJustified']
        ))
        
        story.append(Spacer(1, 0.5*inch))
        story.append(Paragraph("<b>1.1 Compliance Risk Dashboard</b>", self.styles['Heading3']))
        story.append(Spacer(1, 0.2*inch))

        # Risk Dashboard (Spacious)
        risk_data = [
            ['RISK AREA', 'FINDING', 'IMPACT', 'RATING'],
            ['Remuneration Order', 'Base salary below statutory floor', 'Back-pay claims + 5x Penalty', 'CRITICAL'],
            ['Overtime (WRA)', 'Saturday calculation incorrect', 'Arrears due since Jan', 'HIGH'],
            ['Contracts', '2 Files missing signatures', 'Risk of permanent status', 'MEDIUM']
        ]
        # Adjusted widths to fit 7.1 inch print width (40pt margins)
        t_risk = Table(risk_data, colWidths=[1.8*inch, 2.4*inch, 2.0*inch, 1.0*inch])
        t_risk.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), self.brand_primary),
            ('TEXTCOLOR', (0,0), (-1,0), colors.white),
            ('FONTNAME', (0,0), (-1,-1), 'Helvetica-Bold'),
            ('FONTSIZE', (0,0), (-1,-1), 10),
            ('ALIGN', (0,0), (-1,-1), 'LEFT'),
            ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#e2e8f0')),
            ('TOPPADDING', (0,0), (-1,-1), 12), # More padding
            ('BOTTOMPADDING', (0,0), (-1,-1), 12),
            ('BACKGROUND', (3,1), (3,1), self.accent_danger), # Critical
            ('TEXTCOLOR', (3,1), (3,1), colors.white),
             ('BACKGROUND', (3,2), (3,2), self.accent_warning), # High
             ('TEXTCOLOR', (3,2), (3,2), colors.white),
             ('BACKGROUND', (3,3), (3,3), colors.HexColor('#fbbf24')), # Med
        ]))
        story.append(t_risk)
        
        story.append(PageBreak())

        # --- PAGE 3: DETAILED FINDINGS ---
        story.append(Paragraph("2.0 DETAILED FINDINGS & RECTIFICATION", self.styles['SectionHeader']))
        
        # Finding 1
        story.append(Paragraph("<b>Finding 2.1: Base Salary Underpayment (RO Violation)</b>", self.styles['Heading3']))
        story.append(Spacer(1, 0.1*inch))
        story.append(Paragraph(
            "Our audit identified the following employees receiving a basic salary below the <b>Remuneration Regulations 2019</b> statutory floor (Rs 16,500) for their grade.",
            self.styles['NormalJustified']
        ))
        story.append(Spacer(1, 0.2*inch))
        
        # Affected Employees Table
        emp_data = [
            ['Employee Name', 'Role / Grade', 'Current Pay', 'Required', 'Deficit'],
            ['A. Persand', 'Mason (Grade A)', 'Rs 15,000', 'Rs 16,500', '(Rs 1,500)'],
            ['V. Ragoo', 'Mason (Grade A)', 'Rs 15,500', 'Rs 16,500', '(Rs 1,000)'],
            ['S. Lall', 'Carpenter', 'Rs 14,000', 'Rs 16,500', '(Rs 2,500)']
        ]
        t_emp = Table(emp_data, colWidths=[1.8*inch, 1.8*inch, 1.2*inch, 1.2*inch, 1.2*inch], hAlign='LEFT')
        t_emp.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), self.brand_secondary),
            ('TEXTCOLOR', (0,0), (-1,0), colors.white),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#e2e8f0')),
            ('ALIGN', (2,0), (-1,-1), 'RIGHT'), # Align numbers right
            ('TEXTCOLOR', (4,1), (4,-1), self.accent_danger), # Deficits in red
            ('TOPPADDING', (0,0), (-1,-1), 6),
            ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ]))
        story.append(t_emp)
        story.append(Spacer(1, 0.1*inch))
        story.append(Paragraph("<b>Total Monthly Liability: Rs 5,000 (excluding arrears & penalties)</b>", self.styles['Heading4']))
        story.append(Spacer(1, 0.3*inch))

         # Finding 2
        story.append(Paragraph("<b>Finding 2.2: Missing Contracts (WRA Section 8)</b>", self.styles['Heading3']))
        story.append(Spacer(1, 0.1*inch))
        story.append(Paragraph(
            "We could not locate signed 'Statement of Particulars' for the following staff:",
            self.styles['NormalJustified']
        ))
        
        miss_data = [
            ['1. J. Doe (General Worker)', 'Joined: Jan 2024'],
            ['2. M. Smith (Site Clerk)', 'Joined: Mar 2024']
        ]
        t_miss = Table(miss_data, colWidths=[3*inch, 2*inch], hAlign='LEFT')
        t_miss.setStyle(TableStyle([
             ('TEXTCOLOR', (0,0), (-1,-1), self.brand_primary),
             ('FONTNAME', (0,0), (-1,-1), 'Helvetica-Oblique'),
        ]))
        story.append(t_miss)
        
        story.append(Spacer(1, 0.2*inch))
        story.append(Paragraph("<b>Recommendation:</b> Issue the attached 'Standard Employment Contract' immediately.", self.styles['NormalJustified']))

        story.append(PageBreak())

        # --- PAGE 4: LEGAL EXTRACTS ---
        story.append(Paragraph("3.0 LEGAL EXTRACTS & REFERENCES", self.styles['SectionHeader']))
        story.append(Paragraph("The following laws are cited as the basis for the non-compliance findings in this report.", self.styles['Normal']))
        story.append(Spacer(1, 0.2*inch))

        # Citation 1: RO
        story.append(Paragraph("<b>A. Remuneration Regulations 2019 (Construction Industry)</b>", self.styles['Heading4']))
        story.append(Paragraph("<i>First Schedule (Regulation 3) - Monthly Basic Wages</i>", self.styles['Normal']))
        story.append(Spacer(1, 0.1*inch))
        
        ro_text = """
        "Category: Artisan (Grade A) ... Mason ...
        1.0 Years of Service ...
        Minimum Monthly Wage: Rs 16,500"
        """
        story.append(Table([[Paragraph(ro_text, self.styles['Normal'])]], colWidths=[6.5*inch], style=[
            ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#fef3c7')),
            ('BOX', (0,0), (-1,-1), 1, self.accent_warning),
            ('LEFTPADDING', (0,0), (-1,-1), 12),
            ('TOPPADDING', (0,0), (-1,-1), 12),
            ('BOTTOMPADDING', (0,0), (-1,-1), 12),
        ]))
        story.append(Spacer(1, 0.3*inch))

        # Citation 2: WRA Overtime
        story.append(Paragraph("<b>B. Workers' Rights Act 2019 - Section 24 (Overtime)</b>", self.styles['Heading4']))
        w_text = """
        "(2) Where a worker performs work on a public holiday... or in excess of the stipulated hours...
        (a) he shall be remunerated at not less than 1.5 times the notional hourly rate for every hour of work performed."
        """
        story.append(Table([[Paragraph(w_text, self.styles['Normal'])]], colWidths=[6.5*inch], style=[
            ('BACKGROUND', (0,0), (-1,-1), colors.HexColor('#e0f2fe')),
            ('BOX', (0,0), (-1,-1), 1, self.brand_secondary),
            ('LEFTPADDING', (0,0), (-1,-1), 12),
            ('TOPPADDING', (0,0), (-1,-1), 12),
            ('BOTTOMPADDING', (0,0), (-1,-1), 12),
        ]))

        story.append(PageBreak())

        # --- PAGE 5: NEXT STEPS & GLOSSARY ---
        story.append(Paragraph("4.0 NEXT STEPS", self.styles['SectionHeader']))
        
        steps = [
            "1. Update payroll parameters for Oct 2025 to reflect Rs 16,500 base pay.",
            "2. Calculate arrears for Jan-Sep 2025 and propose a repayment plan to staff.",
            "3. Issue missing contracts using the templates provided in the Compliance Pack.",
            "4. Monitor attendance this month using the new Excel Register."
        ]
        for step in steps:
            story.append(Paragraph(step, self.styles['Normal']))
            story.append(Spacer(1, 0.1*inch))

        story.append(Spacer(1, 1*inch))
        story.append(Paragraph("<b>End of Report</b>", self.styles['BodyText']))
        
        doc.build(story)
        print(f"Corporate Report generated at: {self.output_path}")

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.abspath(__file__))
    output_file = os.path.join(base_dir, "ComplianceOps_Sample_Report.pdf")
    logo = os.path.join(base_dir, "logo_aogrl.png")
    generator = CorporateReportGenerator(output_file, logo)
    generator.generate()
