import email
from email import generator
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import os

def create_eml():
    # Email Configuration
    sender_email = "compliance@aogrl.com"
    to_email = "vayid.wimacon@gmail.com"
    cc_emails = "omranahmad@yahoo.com"
    bcc_emails = "deals@aogrl.com, compliance@aogrl.com"
    subject = "AOGRL ComplianceOps: Sales & Operational Package (Review Required)"

    # Email Body (HTML for professional look)
    html_content = """
    <html>
      <body style="font-family: Arial, sans-serif; color: #333;">
        <p>Dear Mr. Vayid,</p>
        
        <p>We have pivoted the ComplianceOps product to target the <strong>Private Sector</strong> (SMEs), removing all PRB references.</p>
        
        <p>The new "Employment Compliance Suite" checks against:</p>
        <ul>
            <li><strong>Workers' Rights Act (WRA)</strong></li>
            <li><strong>Semuneration Orders (RO)</strong> for specific sectors</li>
            <li><strong>Statutory Obligations</strong> (NPF/NSF/PRGF)</li>
        </ul>
        
        <p>Below is the summary of the attached deployment package and the immediate next steps:</p>
        
        <h3 style="color: #2c3e50;">📦 1. Sales & Marketing Assets (Attached in Folder)</h3>
        <ul>
            <li><strong>Sales Landing Page:</strong> Local version available in <code>sales</code> (Ready for Vercel deployment).</li>
            <li><strong>Sample Compliance Report:</strong> A mockup PDF (PDF attached).</li>
            <li><strong>Client Agreement:</strong> Standard service contract (PDF attached) - WRA aligned.</li>
            <li><strong>Invoice Template:</strong> Setup + Monthly Fee invoice (PDF attached).</li>
        </ul>

        <h3 style="color: #2c3e50;">⚙️ 2. Operational Readiness</h3>
        <ul>
            <li><strong>Intake Process:</strong> The new web form collects leads directly to your email (<code>compliance@aogrl.com</code>).</li>
            <li><strong>Grants:</strong> We have identified the <strong>TINNS Scheme (80% refund)</strong> as a key opportunity for funding this digitization.</li>
        </ul>

        <h3 style="color: #2c3e50;">🚀 Immediate Actions Required</h3>
        <ol>
            <li><strong>Bank Details:</strong> Add your actual account number to the Invoice Template.</li>
            <li><strong>Deploy:</strong> Upload the <code>sales</code> folder to your static host (Vercel/Netlify).</li>
            <li><strong>Activate Form:</strong> Submit one test lead and click "Confirm" in the email received.</li>
        </ol>

        <p>The system is designed to be "excel-in, pdf-out" to minimize operational overhead.</p>

        <p>Regards,</p>
        <p><strong>TITAN AI</strong><br>
        <em>On behalf of A-One Global Resourcing Ltd</em></p>
      </body>
    </html>
    """

    # Create Message
    msg = MIMEMultipart('alternative')
    msg['Subject'] = subject
    msg['From'] = sender_email
    msg['To'] = to_email
    msg['Cc'] = cc_emails
    msg['Bcc'] = bcc_emails
    msg.add_header('X-Unsent', '1')  # Marks as draft/unsent

    # Attach Body
    part1 = MIMEText(html_content, 'html')
    msg.attach(part1)

    # Output File
    output_path = r"F:\AION-ZERO\sales\Ready_To_Send_Draft.eml"
    
    with open(output_path, 'w') as outfile:
        gen = generator.Generator(outfile)
        gen.flatten(msg)
    
    print(f"Draft created: {output_path}")

if __name__ == "__main__":
    create_eml()
