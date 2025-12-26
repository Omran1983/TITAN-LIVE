import sys
import json
import asyncio
from playwright.async_api import async_playwright

async def browse(url: str, action: str = "content"):
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        try:
            await page.goto(url, timeout=30000)
            
            result = {"url": url, "status": "ok"}
            
            if action == "content":
                result["content"] = await page.content()
                result["title"] = await page.title()
            elif action == "screenshot":
                path = f"screenshot_{int(asyncio.get_event_loop().time())}.png"
                await page.screenshot(path=path)
                result["screenshot_path"] = path
            
            print(json.dumps(result))
            
        except Exception as e:
            print(json.dumps({"status": "error", "error": str(e)}))
        finally:
            await browser.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: browser_atom.py <url> [action]"}))
        sys.exit(1)
        
    url = sys.argv[1]
    action = sys.argv[2] if len(sys.argv) > 2 else "content"
    
    asyncio.run(browse(url, action))
