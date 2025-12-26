"""
JARVIS PUPPET (PHASE 21)
------------------------
Browser Automation Module.
Role: "The Hands" on the Web.
Safety: VISIBLE MODE ONLY (headless=False).
"""

import sys
import time
from playwright.sync_api import sync_playwright

def run_puppet(url="https://google.com"):
    print(f"--- PUPPET MASTER INITIATED ---")
    print(f"Target: {url}")
    print("Safety Protocol: WINDOW VISIBLE (User Override Active)")
    
    # FINANCIAL FIREWALL
    BLACKLIST = [
        "bank", "chase.com", "wellsfargo", "citi.com", "americanexpress", 
        "capitalone", "hsbc", "paypal", "stripe", "revolut", "wise.com",
        "login.yahoo", "login.live", "accounts.google" # Generic high-risk logins
    ]
    
    for term in BLACKLIST:
        if term in url.lower():
            print(f"!!! SAFETY BLOCK !!!")
            print(f"Prevented access to Restricted Financial Domain: '{term}'")
            return

    with sync_playwright() as p:
        # Launch visible browser
        browser = p.chromium.launch(headless=False)
        context = browser.new_context()
        page = context.new_page()
        
        try:
            print(" -> Navigating...")
            page.goto(url)
            print(" -> Page Loaded.")
            
            # Example Interaction (Search if Google)
            if "google" in url:
                try:
                    page.fill('textarea[name="q"]', "AION-ZERO Autonomous System")
                    page.press('textarea[name="q"]', "Enter")
                    print(" -> Performed Search.")
                except:
                    print(" -> Could not auto-search (Selector mismatch or captcha).")

            print("WAITING FOR USER INPUT...")
            print("(Close the browser window to end session)")
            
            # Keep alive until user closes
            try:
                page.wait_for_timeout(9999999) 
            except:
                print(" -> Session Ended by User.")
                
        except Exception as e:
            print(f"[ERROR] Puppet Failed: {e}")
        finally:
            browser.close()

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "https://google.com"
    run_puppet(target)
