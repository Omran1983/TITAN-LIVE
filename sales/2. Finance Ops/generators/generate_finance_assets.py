from reportlab.lib.pagesizes import A4
from reportlab.platypus import BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table, TableStyle, Image, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.units import inch, mm
import os
import datetime

# --- CONFIG ---
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "1_For_Clients_Finance_Pack")
if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

LOGO_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "logo_aogrl.png")

# --- STYLES ---
styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='HeaderMd', fontSize=14, leading=16, fontName='Helvetica-Bold', textColor=colors.HexColor('#1e293b')))
styles.add(ParagraphStyle(name='BodySm', fontSize=10, leading=12, fontName='Helvetica', textColor=colors.HexColor('#475569')))

def draw_header(canvas, doc):
    canvas.saveState()
    # Logo
    if os.path.exists(LOGO_PATH):
        img = Image(LOGO_PATH, width=1.5*inch, height=0.5*inch)
        img.drawOn(canvas, 40, A4[1] - 60)
    
    # Text
    canvas.setFont("Helvetica", 9)
    canvas.setFillColor(colors.HexColor('#64748b'))
    canvas.drawRightString(A4[0] - 40, A4[1] - 40, "DEMO DOCUMENT")
    canvas.drawRightString(A4[0] - 40, A4[1] - 52, "Finance Operations Module")
    
    canvas.setStrokeColor(colors.HexColor('#cbd5e1'))
    canvas.line(40, A4[1] - 70, A4[0] - 40, A4[1] - 70)
    canvas.restoreState()

# --- ASSET 1: DEMO INVOICE ---
def create_demo_invoice():
    pdf_path = os.path.join(OUTPUT_DIR, "2_Sample_Invoice.pdf") # Overwriting the old one or keeping as sample
    doc = BaseDocTemplate(pdf_path, pagesize=A4, topMargin=80)
    frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height - 80)
    template = PageTemplate(id='base', frames=frame, onPage=draw_header)
    doc.addPageTemplates([template])
    
    story = []
    
    story.append(Paragraph("INVOICE #INV-2025-001", styles['Heading1']))
    story.append(Spacer(1, 0.2*inch))
    
    # Bill To / From
    data = [
        [Paragraph("<b>FROM:</b><br/>Acme Construction Ltd<br/>Royal Road, Port Louis<br/>BRN: C12345678", styles['BodySm']),
         Paragraph("<b>BILL TO:</b><br/>Global Hotels Group<br/>Grand Baie<br/>Attn: Accounts Payable", styles['BodySm'])]
    ]
    t = Table(data, colWidths=[3.5*inch, 3.5*inch])
    story.append(t)
    story.append(Spacer(1, 0.3*inch))
    
    # Line Items
    # Helper to create right-aligned paragraph for totals
    style_right = ParagraphStyle(name='RightAlign', parent=styles['BodySm'], alignment=2)
    
    def bold_p(text):
        return Paragraph(f"<b>{text}</b>", style_right)

    items = [
        ["Description", "Qty", "Rate (Rs)", "Amount (Rs)"],
        ["Renovation Works - Grand Baie Site", "1", "150,000.00", "150,000.00"],
        ["Materials (Cement, Paint)", "1", "45,000.00", "45,000.00"],
        ["Labor (10 days)", "10", "2,500.00", "25,000.00"],
        ["", "", bold_p("Subtotal"), bold_p("220,000.00")],
        ["", "", bold_p("VAT (15%)"), bold_p("33,000.00")],
        ["", "", bold_p("TOTAL"), bold_p("253,000.00")]
    ]
    
    t_items = Table(items, colWidths=[4*inch, 0.8*inch, 1.2*inch, 1.2*inch])
    t_items.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#f1f5f9')),
        ('TEXTCOLOR', (0,0), (-1,0), colors.black),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('ALIGN', (1,0), (-1,-1), 'RIGHT'),
        ('GRID', (0,0), (-1,-2), 0.5, colors.grey),
        ('LINEBELOW', (0,-3), (-1,-3), 2, colors.black), # Line before total
    ]))
    story.append(t_items)
    story.append(Spacer(1, 0.5*inch))
    
    story.append(Paragraph("<b>Payment Terms:</b> Net 30 Days", styles['BodySm']))
    story.append(Paragraph("<b>Bank Details:</b> MCB 0000 0000 0000 0000", styles['BodySm']))
    
    doc.build(story)
    print(f"Created {pdf_path}")

# --- ASSET 2: DEMO AGING LIST ---
def create_aging_list():
    pdf_path = os.path.join(OUTPUT_DIR, "3_Sample_Aging_List.pdf")
    doc = BaseDocTemplate(pdf_path, pagesize=A4, topMargin=80)
    frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height - 80)
    template = PageTemplate(id='base', frames=frame, onPage=draw_header)
    doc.addPageTemplates([template])
    
    story = []
    
    story.append(Paragraph("WEEKLY DEBTOR REMINDER LOG", styles['Heading1']))
    story.append(Paragraph(f"Date: {datetime.date.today()}", styles['BodySm']))
    story.append(Spacer(1, 0.2*inch))
    
    data = [
        ["Initial Inv Date", "Client", "Amount", "Days Overdue", "Status", "Last Action"],
        ["01-Nov-2025", "Hotel A", "Rs 50,000", "45 Days", "CRITICAL", "Legal Notice Sent"],
        ["15-Nov-2025", "Retailer B", "Rs 12,000", "30 Days", "Overdue", "Call Scheduled"],
        ["01-Dec-2025", "Client C", "Rs 150,000", "14 Days", "Late", "Email Reminder #2"],
        ["10-Dec-2025", "Client D", "Rs 5,000", "4 Days", "Recent", "Email Reminder #1"]
    ]
    
    t = Table(data, colWidths=[1.2*inch, 1.5*inch, 1.2*inch, 1.2*inch, 1.2*inch, 1.5*inch])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#1e293b')),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor('#f8fafc')]),
        ('TEXTCOLOR', (4,1), (4,1), colors.red), # Critical
        ('TEXTCOLOR', (4,2), (4,2), colors.orange), # Overdue
    ]))
    story.append(t)
    
    doc.build(story)
    print(f"Created {pdf_path}")

# --- ASSET 3: WEEKLY CASH SNAPSHOT ---
def create_cash_snapshot():
    pdf_path = os.path.join(OUTPUT_DIR, "4_Weekly_Cash_Snapshot.pdf")
    doc = BaseDocTemplate(pdf_path, pagesize=A4, topMargin=80)
    frame = Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height - 80)
    template = PageTemplate(id='base', frames=frame, onPage=draw_header)
    doc.addPageTemplates([template])
    
    story = []
    story.append(Paragraph("CEO WEEKLY CASH SNAPSHOT", styles['Heading1']))
    story.append(Spacer(1, 0.3*inch))
    
    # 2x2 Grid Simulation
    g_data = [
        [Paragraph("<b>TOTAL INVOICED (This Month)</b>", styles['BodySm']), Paragraph("<b>TOTAL COLLECTED (This Month)</b>", styles['BodySm'])],
        [Paragraph("Rs 1,250,000", styles['Heading2']), Paragraph("Rs 980,000", styles['Heading2'])],
        [Paragraph("<b>OUTSTANDING (>60 Days)</b>", styles['BodySm']), Paragraph("<b>CASH FORECAST (Next 7 Days)</b>", styles['BodySm'])],
        [Paragraph("Rs 250,000 (CRITICAL)", styles['Heading2']), Paragraph("Rs 150,000", styles['Heading2'])]
    ]
    
    t_grid = Table(g_data, colWidths=[3.5*inch, 3.5*inch])
    t_grid.setStyle(TableStyle([
        ('BOX', (0,0), (0,1), 1, colors.grey),
        ('BOX', (1,0), (1,1), 1, colors.grey),
        ('BOX', (0,2), (0,3), 1, colors.red),
        ('BOX', (1,2), (1,3), 1, colors.green),
        ('topPadding', (0,0), (-1,-1), 10),
        ('bottomPadding', (0,0), (-1,-1), 20),
    ]))
    story.append(t_grid)
    story.append(Spacer(1, 0.3*inch))
    
    story.append(Paragraph("<b>Top 3 Blockers (Who owes you most?)</b>", styles['HeaderMd']))
    story.append(Spacer(1, 10))
    story.append(Paragraph("1. Construction Co Ltd - Rs 180,000 (Dispute on quality, resolved)", styles['BodySm']))
    story.append(Paragraph("2. Hotel XYZ - Rs 50,000 (Waiting for signatory)", styles['BodySm']))
    story.append(Paragraph("3. Mr. Smith - Rs 20,000 (No answer)", styles['BodySm']))

    doc.build(story)
    print(f"Created {pdf_path}")

if __name__ == "__main__":
    create_demo_invoice()
    create_aging_list()
    create_cash_snapshot()
