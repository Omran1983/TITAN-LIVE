import requests
import re
import base64
import json

url = "https://goli.com/pages/order"
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
}

print(f"Fetching {url}...")
resp = requests.get(url, headers=headers)
html = resp.text

# Look for base64String assignment
# Pattern might be: const base64String = "..." or var base64String = "..."
# The debug output showed: jsonString = atob(base64String);
# So we look for where base64String is defined.

matches = re.findall(r'base64String\s*=\s*["\']([^"\']+)["\']', html)

if matches:
    print(f"Found {len(matches)} candidate strings.")
    for i, b64 in enumerate(matches):
        try:
            decoded = base64.b64decode(b64).decode('utf-8')
            print(f"\n--- Candidate {i} Decoded (First 500 chars) ---")
            print(decoded[:500])
            
            # Try parsing JSON
            data = json.loads(decoded)
            print("\n--- JSON Keys ---")
            print(data.keys())
            
            # Check for products
            if "products" in data:
                print(f"\nFOUND PRODUCTS: {len(data['products'])}")
                print(json.dumps(data['products'][0], indent=2))
        except Exception as e:
            print(f"Error decoding candidate {i}: {e}")
else:
    print("No 'base64String' assignment found using regex.")
    # Dump regular searching for 'products'
    if "products" in html:
        print("\n'products' string found in HTML, but regex failed.")
