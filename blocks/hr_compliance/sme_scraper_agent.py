"""
TITAN SME Scraper Agent
Target: smesdb.govmu.org
Goal: Continuously scrape SME contact details for Leads DB.
"""

import requests
from bs4 import BeautifulSoup
import csv
import time
import random
from pathlib import Path
import logging

# Setup Logger
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

BASE_URL = "https://smesdb.govmu.org"
DIRECTORY_URL = "https://smesdb.govmu.org/smesdb/index.php/directory-smes_e_direc/"

# Target Categories (URL encoded)
# Construction Works: ?filter_field_categories[]=Construction%20Works
# Manufacturing: ?filter_field_categories[]=Manufacturing
CATEGORIES = [
    "Construction%20Works",
    "Manufacturing",
    "ICT",
    "Security" # Try generic search if category filter fails
]

OUTPUT_FILE = Path("F:/AION-ZERO/sales/sme_sales_leads.csv")

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
}

def get_soup(url):
    try:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code == 200:
            return BeautifulSoup(response.content, 'html.parser')
        logger.error(f"Failed to fetch {url}: {response.status_code}")
    except Exception as e:
        logger.error(f"Error fetching {url}: {e}")
    return None

def scrape_sector(sector):
    logger.info(f"🚀 Starting scrape for sector: {sector}")
    page = 1
    has_next = True
    
    leads = []
    
    while has_next:
        # Construct URL with pagination
        # Note: The actual URL structure might need adjustment based on real browser observation (e.g. &page=2)
        url = f"{DIRECTORY_URL}?filter_field_categories[]={sector}&filter=1&sort=post_title&num=20&page={page}"
        logger.info(f"Scanning Page {page}...")
        
        soup = get_soup(url)
        if not soup:
            break
            
        # The site uses specific classes for listings. Based on observation:
        # Listings usually are in 'drts-view-entities-container'
        # Individual items might be articles or divs
        
        # NOTE: This is a robust heuristic. We look for the entity links.
        # Class '.drts-entity-permalink' was seen in browser agent logs.
        links = soup.select('.drts-entity-permalink')
        
        if not links:
            logger.info("No more listings found (or layout changed). Stopping.")
            break
            
        logger.info(f"Found {len(links)} companies on page {page}.")
        
        for link in links:
            company_name = link.get_text(strip=True)
            detail_url = link.get('href')
            
            if not company_name:
                continue
                
            # Deep dive for Email
            email = "N/A"
            sector_val = sector.replace("%20", " ")
            
            # Rate limit politeness
            time.sleep(random.uniform(0.5, 1.5))
            
            detail_soup = get_soup(detail_url)
            if detail_soup:
                # Look for email patterns or specific classes
                # Often in 'drts-entity-field-value' or mailto links
                mailto = detail_soup.select_one('a[href^="mailto:"]')
                if mailto:
                    email = mailto.get('href').replace('mailto:', '').strip()
                else:
                    # Try text search if no mailto
                    text = detail_soup.get_text()
                    import re
                    emails = re.findall(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', text)
                    if emails:
                        # Filter out generic site emails if possible, but take first usually
                        email = emails[0]

            logger.info(f"  - {company_name}: {email}")
            
            leads.append({
                "Company Name": company_name,
                "Industry": sector_val,
                "Email": email,
                "Source": "SME Directory Scraper"
            })
            
        # Save page results immediately (Streaming Mode)
        if leads:
            save_leads(leads)
            leads = [] # Clear buffer after save
            logger.info(f"💾 Flushed page data to {OUTPUT_FILE}")
            
        page += 1
        # Safety break for demo
        if page > 100: 
            has_next = False
            
    return leads

def save_leads(leads):
    # Check if file exists to determine if header is needed
    file_exists = OUTPUT_FILE.exists()
    
    with open(OUTPUT_FILE, 'a', newline='', encoding='utf-8') as f:
        fieldnames = ["Company Name", "Industry", "Email", "Source"]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        
        if not file_exists:
            writer.writeheader()
            
        for lead in leads:
            # Simple dedup based on email if valid
            if lead['Email'] != "N/A":
                writer.writerow(lead)

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="TITAN SME Scraper")
    parser.add_argument("--sector", type=str, help="Specific sector to scrape", default=None)
    parser.add_argument("--outfile", type=str, help="Output CSV file", default="F:/AION-ZERO/sales/sme_sales_leads.csv")
    args = parser.parse_args()
    
    # Update global output file
    OUTPUT_FILE = Path(args.outfile)
    
    logger.info(f"🤖 TITAN SME Scraper Agent Initialized")
    logger.info(f"🎯 Target: {args.sector if args.sector else 'ALL'}")
    logger.info(f"Tb 💾 Output: {OUTPUT_FILE}")
    
    sectors_to_scrape = [args.sector] if args.sector else CATEGORIES
    
    for sector in sectors_to_scrape:
        scrape_sector(sector)
        
    logger.info("✅ Scraping Mission Complete.")
