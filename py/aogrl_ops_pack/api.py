from fastapi import FastAPI, Query
from fastapi.responses import JSONResponse
import requests
from bs4 import BeautifulSoup

app = FastAPI()

@app.get("/health.json")
def health_check():
    return {"status": "ok", "uptime": "test-mode"}

@app.get("/search")
def search_google(q: str = Query(...)):
    url = f"https://www.google.com/search?q={q}"
    headers = {"User-Agent": "Mozilla/5.0"}
    res = requests.get(url, headers=headers)
    
    soup = BeautifulSoup(res.text, "html.parser")
    results = []
    for g in soup.select("div.g a"):
        href = g.get("href")
        if href and href.startswith("http") and "google" not in href:
            results.append(href)
        if len(results) == 5:
            break
    return {"query": q, "results": results}
