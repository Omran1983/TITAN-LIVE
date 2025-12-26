from reportlab.lib.pagesizes import A4
from reportlab.platypus import BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table, TableStyle, Image, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.units import inch, mm
import os

class PremiumSalesSheet:
    def __init__(self, output_path, logo_path):
        self.output_path = output_path
        self.logo_path = logo_path
        self.styles = getSampleStyleSheet()
        self._setup_styles()
        self.primary_color = colors.HexColor('#1e293b') # Slate 800
        self.accent_color = colors.HexColor('#3b82f6') # Blue 500
        self.bg_color = colors.HexColor('#f8fafc') # Slate 50

    def _setup_styles(self):
        self.styles.add(ParagraphStyle(
            name='HeroTitle',
            parent=self.styles['Heading1'],
            fontSize=32,
            leading=38,
            textColor=colors.HexColor('#1e293b'),
            fontName='Helvetica-Bold',
            spaceAfter=20
        ))
        self.styles.add(ParagraphStyle(
            name='HeroSub',
            parent=self.styles['Heading2'],
            fontSize=16,
            leading=22,
            textColor=colors.HexColor('#64748b'), # Slate 500
            fontName='Helvetica',
            spaceAfter=30
        ))
        self.styles.add(ParagraphStyle(
            name='SectionHeader',
            parent=self.styles['Heading2'],
            fontSize=14,
            leading=18,
            textColor=colors.HexColor('#3b82f6'), # Blue
            fontName='Helvetica-Bold',
            spaceBefore=20,
            spaceAfter=10,
            textTransform='uppercase'
        ))
        self.styles.add(ParagraphStyle(
            name='BoxTitle',
            parent=self.styles['Normal'],
            fontSize=12,
            leading=14,
            textColor=colors.white,
            fontName='Helvetica-Bold',
            alignment=1 # Center
        ))
        self.styles.add(ParagraphStyle(
            name='BoxText',
            parent=self.styles['Normal'],
            fontSize=10,
            leading=14,
            textColor=colors.HexColor('#334155'),
            alignment=1 # Center
        ))
        self.styles.add(ParagraphStyle(
            name='ListText',
            parent=self.styles['Normal'],
            fontSize=11,
            leading=16,
            textColor=colors.HexColor('#334155'),
            spaceAfter=5
        ))
        self.styles.add(ParagraphStyle(
            name='PriceBig',
            parent=self.styles['Normal'],
            fontSize=24,
            leading=28,
            textColor=colors.HexColor('#1e293b'),
            fontName='Helvetica-Bold',
            alignment=1
        ))

    def header_footer(self, canvas, doc):
        canvas.saveState()
        
        # --- HEADER ---
        # Logo
        if os.path.exists(self.logo_path):
            img = Image(self.logo_path, width=2*inch, height=0.7*inch)
            img.drawOn(canvas, 40, A4[1] - 80)
        
        # Company Info Top Right
        canvas.setFont("Helvetica", 9)
        canvas.setFillColor(colors.HexColor('#64748b'))
        canvas.drawRightString(A4[0] - 40, A4[1] - 50, "A-One Global Resourcing Ltd")
        canvas.drawRightString(A4[0] - 40, A4[1] - 62, "Employment & Operations Compliance")
        
        # Decorative Blue Line
        canvas.setStrokeColor(self.accent_color)
        canvas.setLineWidth(3)
        canvas.line(40, A4[1] - 90, A4[0] - 40, A4[1] - 90)

        # --- FOOTER ---
        canvas.setStrokeColor(colors.HexColor('#e2e8f0'))
        canvas.setLineWidth(1)
        canvas.line(40, 50, A4[0] - 40, 50)
        
        canvas.setFont("Helvetica", 8)
        canvas.setFillColor(colors.HexColor('#94a3b8'))
        canvas.drawString(40, 35, "BRN: C22185206 | TAN: 28006142")
        canvas.drawRightString(A4[0] - 40, 35, "www.aone-global.com | compliance@aogrl.com")
        
        canvas.restoreState()

    def create_pdf(self):
        doc = BaseDocTemplate(
            self.output_path,
            pagesize=A4,
            rightMargin=40, leftMargin=40,
            topMargin=100, bottomMargin=60
        )
        
        frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id='normal')
        template = PageTemplate(id='sales_sheet', frames=frame, onPage=self.header_footer)
        doc.addPageTemplates([template])
        
        story = []

        # HERO
        story.append(Paragraph("Stop chasing money.<br/>Start collecting it.", self.styles['HeroTitle']))
        story.append(Paragraph("We generate your invoices, chase your debtors, and recover your cash—so you don't have to be the 'Bad Cop'.", self.styles['HeroSub']))
        
        story.append(Spacer(1, 0.2*inch))

        # --- PROBLEM GRID ---
        story.append(Paragraph("THE PROBLEM", self.styles['SectionHeader']))
        
        # 3 Boxes for Problems
        p_data = [
            [Paragraph("LATE INVOICES", self.styles['BoxTitle']), 
             Paragraph("AWKWARD FOLLOW-UPS", self.styles['BoxTitle']), 
             Paragraph("IGNORED", self.styles['BoxTitle'])],
            
            [Paragraph("You're too busy to invoice. Every day waited is cash lost.", self.styles['BoxText']),
             Paragraph("'I don't want to nag.' You stay silent to keep friends.", self.styles['BoxText']),
             Paragraph("Clients pay whoever shouts the loudest.", self.styles['BoxText'])]
        ]
        
        t_probs = Table(p_data, colWidths=[2.3*inch, 2.3*inch, 2.3*inch])
        t_probs.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (0,0), colors.HexColor('#ef4444')), # Red
            ('BACKGROUND', (1,0), (1,0), colors.HexColor('#f59e0b')), # Orange
            ('BACKGROUND', (2,0), (2,0), colors.HexColor('#64748b')), # Grey
            ('BACKGROUND', (0,1), (-1,1), colors.HexColor('#f1f5f9')), # Light Grey bg for text
            ('TOPPADDING', (0,0), (-1,0), 8),
            ('BOTTOMPADDING', (0,0), (-1,0), 8),
            ('TOPPADDING', (0,1), (-1,1), 12),
            ('BOTTOMPADDING', (0,1), (-1,1), 12),
            ('GRID', (0,0), (-1,-1), 1, colors.white),
            ('ROUNDEDCORNERS', [5, 5, 5, 5])
        ]))
        story.append(t_probs)
        story.append(Spacer(1, 0.3*inch))

        # --- SOLUTION ---
        story.append(Paragraph("THE SOLUTION", self.styles['SectionHeader']))
        story.append(Paragraph("We become your Finance Ops Team. You stay the 'Good Guy'.", self.styles['HeroSub']))
        
        # Feature List with Icons (Bullet points simulated)
        features = [
            ["01", "Professional Invoicing", "We generate clean, compliant PDF invoices on your letterhead."],
            ["02", "Silent Chasing", "Our system sends polite nudges (Day 1), firm reminders (Day 7), and official notices (Day 14)."],
            ["03", "Owner Clarity", "You get a weekly 'Money In / Money Out' snapshot. No jargon."]
        ]
        
        f_table_data = []
        for f in features:
            f_table_data.append([
                Paragraph(f"<b>{f[0]}</b>", self.styles['ListText']),
                Paragraph(f"<b>{f[1]}</b><br/>{f[2]}", self.styles['ListText'])
            ])
            
        t_feat = Table(f_table_data, colWidths=[0.5*inch, 6*inch])
        t_feat.setStyle(TableStyle([
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('TEXTCOLOR', (0,0), (0,-1), self.accent_color),
            ('SIZE', (0,0), (0,-1), 14),
            ('BOTTOMPADDING', (0,0), (-1,-1), 12),
        ]))
        story.append(t_feat)
        story.append(Spacer(1, 0.3*inch))

        # --- PRICING BOX ---
        story.append(Paragraph("SIMPLE PRICING", self.styles['SectionHeader']))
        
        price_data = [
            [Paragraph("FINANCE OPS REVIEW", self.styles['BoxTitle'])],
            [Paragraph("Rs 5,000", self.styles['PriceBig'])],
            [Paragraph("One-off Setup Fee", self.styles['BoxText'])],
            [Paragraph("Then Rs 2,500 / month", self.styles['BoxText'])],
            [Paragraph("Includes 50 Invoices + Unlimited Chasers", self.styles['BoxText'])]
        ]
        
        t_price = Table(price_data, colWidths=[4*inch])
        t_price.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (0,0), self.accent_color), # header blue
            ('BACKGROUND', (0,1), (0,-1), colors.HexColor('#eff6ff')), # Light blue body
            ('ALIGN', (0,0), (-1,-1), 'CENTER'),
            ('TOPPADDING', (0,0), (0,0), 10),
            ('BOTTOMPADDING', (0,-1), (0,-1), 15),
            ('BOX', (0,0), (-1,-1), 2, self.accent_color),
        ]))
        story.append(t_price)

        story.append(Spacer(1, 0.3*inch))
        story.append(Paragraph("Reply 'FINANCE' to start collecting.", self.styles['HeroSub']))

        doc.build(story)
        print(f"Premium PDF Generated: {self.output_path}")

if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.abspath(__file__))
    # Go up one level to find logo
    root_dir = os.path.dirname(base_dir) 
    logo_path = os.path.join(root_dir, "logo_aogrl.png")
    output_path = os.path.join(root_dir, "1_For_Clients_Finance_Pack", "1_Sales_Sheet.pdf")
    
    generator = PremiumSalesSheet(output_path, logo_path)
    generator.create_pdf()
