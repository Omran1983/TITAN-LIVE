from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, ListFlowable, ListItem
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
import markdown
import re

def create_sales_pdf(output_path):
    doc = SimpleDocTemplate(output_path, pagesize=A4, rightMargin=50, leftMargin=50, topMargin=50, bottomMargin=50)
    styles = getSampleStyleSheet()
    story = []

    # Custom Styles
    if 'SalesTitle' not in styles:
        styles.add(ParagraphStyle(name='SalesTitle', parent=styles['Heading1'], fontSize=24, textColor=colors.HexColor('#1e293b'), spaceAfter=20))
    if 'SalesSub' not in styles:
        styles.add(ParagraphStyle(name='SalesSub', parent=styles['Heading2'], fontSize=16, textColor=colors.HexColor('#334155'), spaceAfter=15))
    if 'BodyText' not in styles:
        styles.add(ParagraphStyle(name='BodyText', parent=styles['Normal'], fontSize=11, leading=16, textColor=colors.HexColor('#475569')))
    else:
        styles['BodyText'].fontSize = 11
        styles['BodyText'].textColor = colors.HexColor('#475569')
    
    # Title
    story.append(Paragraph("Finance Operations Review Module", styles['SalesTitle']))
    story.append(Paragraph('"Stop leaking cash. Invoice faster."', styles['SalesSub']))
    story.append(Spacer(1, 15))

    # Problem Section
    story.append(Paragraph("The Problem", styles['Heading3']))
    story.append(Paragraph("You did the work. You delivered the goods. But the cash isn't in the bank because:", styles['BodyText']))
    
    problems = [
        "Invoices go out late (or get forgotten).",
        "Follow-ups are awkward ('I don't want to nag').",
        "Clients prioritize who shouts loudest."
    ]
    p_list = ListFlowable([ListItem(Paragraph(p, styles['BodyText'])) for p in problems], bulletType='bullet')
    story.append(p_list)
    story.append(Spacer(1, 15))

    # Solution Section
    story.append(Paragraph("The Solution: We become your 'Bad Cop'", styles['Heading3']))
    story.append(Paragraph("We take over your Accounts Receivable process. You stay the 'Good Guy.'", styles['BodyText']))
    
    solutions = [
        "<b>Professional Invoicing:</b> Clean, compliant PDFs on your letterhead.",
        "<b>Silent Chasing:</b> Automated nudges (Day 1), reminders (Day 7), and escalation (Day 14).",
        "<b>Owner Clarity:</b> Weekly 'Money In / Money Out' snapshot."
    ]
    s_list = ListFlowable([ListItem(Paragraph(s, styles['BodyText'])) for s in solutions], bulletType='bullet')
    story.append(s_list)
    story.append(Spacer(1, 15))

    # Pricing Section
    story.append(Paragraph("Pricing", styles['Heading3']))
    story.append(Paragraph("<b>Setup (One-Off):</b> Rs 5,000", styles['BodyText']))
    story.append(Paragraph("<b>Monthly Fee:</b> Rs 2,500 – 7,500 (Depending on volume)", styles['BodyText']))
    story.append(Spacer(1, 20))

    story.append(Paragraph("<b>Reply 'FINANCE' to start.</b>", styles['SalesSub']))

    doc.build(story)
    print(f"PDF generated: {output_path}")

if __name__ == "__main__":
    create_sales_pdf(r"F:\AION-ZERO\sales\2. Finance Ops\1_For_Clients_Finance_Pack\1_Sales_Sheet.pdf")
