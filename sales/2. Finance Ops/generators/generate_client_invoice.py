import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from reportlab.lib.units import inch, mm
from datetime import datetime

class ClientInvoiceGenerator:
    def __init__(self, output_path, provider_details, client_details, invoice_data):
        self.output_path = output_path
        self.provider = provider_details
        self.client = client_details
        self.data = invoice_data
        self.styles = getSampleStyleSheet()
        self._setup_styles()

    def _setup_styles(self):
        # Neutral Professional Colors
        self.color_primary = colors.HexColor('#1e293b') # Slate 800
        self.color_secondary = colors.HexColor('#64748b') # Slate 500
        self.color_accent = colors.HexColor('#3b82f6') # Blue 500

        self.styles.add(ParagraphStyle(
            name='InvTitle',
            parent=self.styles['Heading1'],
            fontSize=24,
            textColor=self.color_primary,
            alignment=2 # Right
        ))
        self.styles.add(ParagraphStyle(
            name='ProviderInfo',
            parent=self.styles['Normal'],
            fontSize=10,
            leading=14,
            textColor=self.color_primary,
            alignment=2 # Right
        ))
        self.styles.add(ParagraphStyle(
            name='ClientInfo',
            parent=self.styles['Normal'],
            fontSize=10,
            leading=14,
            textColor=self.color_primary
        ))

    def generate(self):
        doc = SimpleDocTemplate(
            self.output_path,
            pagesize=A4,
            rightMargin=40, leftMargin=40,
            topMargin=40, bottomMargin=40
        )
        story = []

        # --- HEADER ---
        # Left: Logo (Placeholder) | Right: Provider Details
        p_text = f"<b>{self.provider['name']}</b><br/>{self.provider['address']}<br/>BRN: {self.provider['brn']} | TAN: {self.provider['tan']}<br/>{self.provider['website']}"
        
        header_data = [
            [Paragraph("<b>LOGO</b>", self.styles['Heading2']), Paragraph(p_text, self.styles['ProviderInfo'])]
        ]
        t_head = Table(header_data, colWidths=[3*inch, 4*inch])
        t_head.setStyle(TableStyle([
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('ALIGN', (1,0), (1,0), 'RIGHT'),
        ]))
        story.append(t_head)
        story.append(Spacer(1, 0.5*inch))

        # --- TITLE & META ---
        story.append(Paragraph("INVOICE", self.styles['InvTitle']))
        story.append(Spacer(1, 0.2*inch))

        meta_data = [
            ["Invoice No:", self.data['number']],
            ["Date:", self.data['date']],
            ["Due Date:", self.data['due_date']]
        ]
        t_meta = Table(meta_data, colWidths=[5.5*inch, 1.5*inch])
        t_meta.setStyle(TableStyle([
            ('ALIGN', (0,0), (-1,-1), 'RIGHT'),
            ('FONTNAME', (0,0), (0,-1), 'Helvetica-Bold'),
            ('TEXTCOLOR', (0,0), (-1,-1), self.color_secondary),
        ]))
        story.append(t_meta)
        story.append(Spacer(1, 0.4*inch))

        # --- BILL TO ---
        story.append(Paragraph("<b>BILL TO:</b>", self.styles['Normal']))
        c_text = f"<b>{self.client['name']}</b><br/>{self.client['address']}<br/>BRN: {self.client['brn']}"
        story.append(Paragraph(c_text, self.styles['ClientInfo']))
        story.append(Spacer(1, 0.4*inch))

        # --- ITEMS ---
        # Data Structure: [Desc, Qty, Rate, Amount]
        items = [['Description', 'Qty', 'Rate', 'Amount (MUR)']]
        total = 0
        for item in self.data['items']:
            amt = item['qty'] * item['rate']
            total += amt
            items.append([
                item['desc'],
                str(item['qty']),
                f"{item['rate']:,.2f}",
                f"{amt:,.2f}"
            ])
        
        # Totals
        items.append(['', '', 'Subtotal:', f"{total:,.2f}"])
        vat = total * 0.15 if self.provider['vat_registered'] else 0
        items.append(['', '', 'VAT (15%):', f"{vat:,.2f}"])
        items.append(['', '', 'Total:', f"{total + vat:,.2f}"])

        t_items = Table(items, colWidths=[4*inch, 0.7*inch, 1.1*inch, 1.2*inch])
        t_items.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#f8fafc')), # Header Grey
            ('TEXTCOLOR', (0,0), (-1,0), self.color_primary),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('ALIGN', (1,0), (-1,-1), 'RIGHT'), # Numbers right
            ('ALIGN', (0,0), (0,-1), 'LEFT'), # Desc Left
            ('GRID', (0,0), (-1,-3), 0.5, colors.HexColor('#e2e8f0')), # Grid for items
            ('LINEBELOW', (0,-3), (-1,-3), 1, self.color_primary), # Line before totals
            ('FONTNAME', (-2,-1), (-1,-1), 'Helvetica-Bold'), # Bold Total
            ('TEXTCOLOR', (-1,-1), (-1,-1), self.color_primary),
            ('TOPPADDING', (0,0), (-1,-1), 10),
            ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ]))
        story.append(t_items)
        story.append(Spacer(1, 0.5*inch))

        # --- FOOTER / PAYMENT ---
        story.append(Paragraph("<b>Payment Details:</b>", self.styles['Normal']))
        bank_text = f"""
        Bank: <b>{self.provider['bank_name']}</b><br/>
        Account Name: <b>{self.provider['bank_account_name']}</b><br/>
        Account Number: <b>{self.provider['bank_account_number']}</b>
        """
        story.append(Paragraph(bank_text, self.styles['Normal']))
        story.append(Spacer(1, 0.2*inch))
        
        story.append(Paragraph(f"<b>Terms:</b> {self.data['terms']}", self.styles['Normal']))
        
        doc.build(story)
        print(f"Invoice generated: {self.output_path}")

if __name__ == "__main__":
    # Test Data (Mock Client Context)
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    #Provider = The User's Client (e.g., a Logistics Company)
    provider = {
        "name": "Eagle Logistics Ltd",
        "address": "Zone 4, Mer Rouge, Port Louis",
        "brn": "C12345678",
        "tan": "12345678",
        "website": "www.eaglelogistics.mu",
        "vat_registered": True,
        "bank_name": "MCB",
        "bank_account_name": "Eagle Logistics Ltd",
        "bank_account_number": "000444555666"
    }

    #Client = The Customer of the Logistics Company
    client = {
        "name": "Super Retailers Ltd",
        "address": "Phoenix Mall, Phoenix",
        "brn": "C87654321"
    }

    invoice_data = {
        "number": "INV-2025-0812",
        "date": datetime.now().strftime("%d %b %Y"),
        "due_date": "30 Jan 2026",
        "terms": "Please pay within 15 days.",
        "items": [
            {"desc": "Container Transport (Port to Phoenix)", "qty": 2, "rate": 8500.00},
            {"desc": "Handling Fees", "qty": 1, "rate": 2000.00}
        ]
    }

    gen = ClientInvoiceGenerator(os.path.join(base_dir, "Sample_Client_Invoice.pdf"), provider, client, invoice_data)
    gen.generate()
