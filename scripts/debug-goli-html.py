import requests

url = "https://goli.com/pages/order"
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
}
resp = requests.get(url, headers=headers)
print(resp.text[:5000]) # First 5000 chars to check if blocked or empty
print("..." * 10)
print(resp.text[-2000:]) # Last 2000 chars to check for script tags
