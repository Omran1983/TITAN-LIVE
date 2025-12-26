import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.units import inch
from datetime import datetime

class FinanceDocGenerator:
    def __init__(self, output_path, doc_type="INVOICE"):
        self.output_path = output_path
        self.doc_type = doc_type
        self.styles = getSampleStyleSheet()
        self._setup_custom_styles()

    def _setup_custom_styles(self):
        self.styles.add(ParagraphStyle(
            name='FinanceTitle',
            parent=self.styles['Heading1'],
            fontSize=24,
            spaceAfter=20,
            textColor=colors.HexColor('#1f2937'),
            alignment=2 # Right aligned for modern look
        ))
        self.styles.add(ParagraphStyle(
            name='CompanyHeader',
            parent=self.styles['Normal'],
            fontSize=10,
            leading=14,
            textColor=colors.HexColor('#374151'),
            alignment=2
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
        # Logo placeholder (left) vs Company Info (right)
        company_info = [
            Paragraph("<b>A-One Global Resourcing Ltd</b>", self.styles['CompanyHeader']),
            Paragraph("BRN: C22185206 | TAN: 28006142", self.styles['CompanyHeader']),
            Paragraph("Ebene, Mauritius", self.styles['CompanyHeader']),
            Paragraph("compliance@aogrl.com", self.styles['CompanyHeader'])
        ]
        
        # Use a table for the header layout
        header_table_data = [[ "", company_info ]] # Left cell empty for where logo would be
        t_header = Table(header_table_data, colWidths=[3*inch, 3*inch])
        t_header.setStyle(TableStyle([
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('ALIGN', (1,0), (1,0), 'RIGHT'),
        ]))
        story.append(t_header)
        story.append(Spacer(1, 0.5*inch))

        # --- Title & Meta ---
        story.append(Paragraph(self.doc_type, self.styles['FinanceTitle']))
        
        meta_data = []
        if self.doc_type == "INVOICE":
            meta_data = [
                ["Invoice No:", "INV-2025-001"],
                ["Date:", datetime.now().strftime('%d %b %Y')],
                ["Due Date:", "Upon Receipt"]
            ]
        else:
            meta_data = [
                ["Receipt No:", "REC-2025-001"],
                ["Date Paid:", datetime.now().strftime('%d %b %Y')],
                ["Payment Method:", "Bank Transfer"]
            ]

        t_meta = Table(meta_data, colWidths=[5*inch, 1.5*inch])
        t_meta.setStyle(TableStyle([
            ('ALIGN', (0,0), (-1,-1), 'RIGHT'),
            ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
            ('TEXTCOLOR', (0,0), (-1,-1), colors.HexColor('#4b5563')),
        ]))
        story.append(t_meta)
        story.append(Spacer(1, 0.5*inch))

        # --- Bill To ---
        story.append(Paragraph("<b>Bill To:</b>", self.styles['Normal']))
        story.append(Paragraph("[Client Company Name]", self.styles['Normal']))
        story.append(Paragraph("[Client Address]", self.styles['Normal']))
        story.append(Spacer(1, 0.3*inch))

        # --- Line Items ---
        items = [
            ["Description", "Qty", "Amount (MUR)"]
        ]
        
        if self.doc_type == "INVOICE":
            items.append(["New Client Setup & Mapping (One-time)", "1", "5,000.00"])
            items.append(["Employment Compliance Suite (Tier 2)", "1", "9,000.00"])
            items.append(["", "Total:", "14,000.00"])
        else:
            items.append(["Payment for Invoice #INV-2025-001", "1", "13,000.00"])
            items.append(["", "Total Paid:", "13,000.00"])

        t_items = Table(items, colWidths=[4*inch, 0.8*inch, 1.5*inch])
        
        # Style the table
        style = [
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#f3f4f6')),
            ('TEXTCOLOR', (0,0), (-1,0), colors.HexColor('#1f2937')),
            ('ALIGN', (0,0), (-1,-1), 'LEFT'),
            ('ALIGN', (2,0), (2,-1), 'RIGHT'),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('BOTTOMPADDING', (0,0), (-1,0), 12),
            ('TOPPADDING', (0,0), (-1,0), 12),
            ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#e5e7eb')),
        ]
        
        # Bold total row
        style.append(('FONTNAME', (0,-1), (-1,-1), 'Helvetica-Bold'))
        style.append(('BACKGROUND', (0,-1), (-1,-1), colors.HexColor('#f9fafb')))
        
        t_items.setStyle(TableStyle(style))
        story.append(t_items)
        story.append(Spacer(1, 0.5*inch))

        # --- Footer Notes ---
        if self.doc_type == "INVOICE":
            story.append(Paragraph("<b>Payment Details:</b>", self.styles['Normal']))
            story.append(Paragraph("Bank: <b>MCB (Mauritius Commercial Bank)</b>", self.styles['Normal']))
            story.append(Paragraph("Account Name: <b>A-One Global Resourcing Ltd</b>", self.styles['Normal']))
            story.append(Paragraph("Account Number: <b>[ENTER ACCOUNT NUMBER]</b>", self.styles['Normal']))
        else:
            story.append(Paragraph("Thank you for your business.", self.styles['Normal']))

        doc.build(story)
        print(f"{self.doc_type} PDF generated at: {self.output_path}")

if __name__ == "__main__":
    # Determine script directory
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Generate Invoice
    inv_path = os.path.join(base_dir, "AOGRL_Invoice_Template.pdf")
    inv_gen = FinanceDocGenerator(inv_path, "INVOICE")
    inv_gen.generate()
    
    # Generate Receipt
    rec_path = os.path.join(base_dir, "AOGRL_Receipt_Template.pdf")
    rec_gen = FinanceDocGenerator(rec_path, "RECEIPT")
    rec_gen.generate()
