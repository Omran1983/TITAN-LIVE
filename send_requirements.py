
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from pathlib import Path

# Config
SMTP_HOST = "smtp.office365.com"
SMTP_PORT = 587
SMTP_USER = "deals@aogrl.com"
SMTP_PASS = "Letmein2010!"
TO_EMAIL = "Kaamran.ahmad@live.com"
SUBJECT = "Project Requirement Form: CRM + LMS + AI"


# File
FORM_PATH = r"C:\Users\ICL  ZAMBIA\.gemini\antigravity\brain\72813fb4-7694-467c-9923-b03465c25536\requirements_form.html"

def send_email():
    print(f"Preparing to send HTML email to {TO_EMAIL}...")
    
    try:
        # Read content
        # HTML Part
        with open(FORM_PATH, "r", encoding="utf-8") as f:
            html_content = f.read()
            
        # Text Part (Markdown)
        MD_PATH = r"C:\Users\ICL  ZAMBIA\.gemini\antigravity\brain\72813fb4-7694-467c-9923-b03465c25536\project_requirements_form_bilingual.md"
        with open(MD_PATH, "r", encoding="utf-8") as f:
            text_content = f.read()
            
        msg = MIMEMultipart("alternative")
        # Fix 1: Friendly Display Name
        msg["From"] = "Titan Project Team <deals@aogrl.com>" 
        msg["To"] = TO_EMAIL
        msg["Subject"] = SUBJECT
        
        # Fix 2: Technical Headers (Date, Message-ID)
        from email.utils import formatdate, make_msgid
        msg["Date"] = formatdate(localtime=True)
        msg["Message-ID"] = make_msgid(domain="aogrl.com")
        
        # Add body
        # Text part (Markdown content)
        text_part = MIMEText(text_content, "plain")
        # HTML part
        html_part = MIMEText(html_content, "html")
        
        msg.attach(text_part)
        msg.attach(html_part)
        
        # Connect
        print("Connecting to SMTP...")
        context = ssl.create_default_context()
        
        # Office365 requires STARTTLS
        server = smtplib.SMTP(SMTP_HOST, SMTP_PORT)
        server.set_debuglevel(0) 
        server.starttls(context=context)
        server.login(SMTP_USER, SMTP_PASS)
        
        print("Sending...")
        server.sendmail(SMTP_USER, TO_EMAIL, msg.as_string())
        server.quit()
        
        print("Email sent successfully!")
        
    except Exception as e:
        print(f"Failed to send email: {e}")

if __name__ == "__main__":
    send_email()
