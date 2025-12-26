import sys
import json
import os

# For now, this wraps the Control Plane's notify_user intent via direct DB insert or similar
# OR just a mock for Phase 1. 
# Better: It's a tool that Agents call to send formal emails.
# Using standard print/log for simulation until SMTP credentials provided.

def send_email(to: str, subject: str, body: str):
    # Mock sending
    print(f"--- EMAIL SIMULATION ---")
    print(f"To: {to}")
    print(f"Subject: {subject}")
    print(f"Body: {body[:50]}...")
    print(f"------------------------")
    
    # In real world: smtplib or SendGrid API
    
    return {"status": "sent", "provider": "mock"}

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(json.dumps({"error": "Usage: email_atom.py <to> <subject> <body>"}))
        sys.exit(1)
        
    to = sys.argv[1]
    subject = sys.argv[2]
    body = sys.argv[3]
    
    result = send_email(to, subject, body)
    print(json.dumps(result))
