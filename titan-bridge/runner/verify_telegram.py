import os
import httpx
import asyncio

# Hardcoded for the verification step since environment might be issue
TOKEN = "8284941437:AAElTu-RcyN3dNv5jcrhJpknRgz4_akuPeI"

async def check_bot():
    print(f"Checking Bot Token: {TOKEN[:5]}...")
    async with httpx.AsyncClient() as client:
        try:
            # 1. Get Me (Verify Token)
            resp = await client.get(f"https://api.telegram.org/bot{TOKEN}/getMe")
            print(f"getMe Status: {resp.status_code}")
            print(f"getMe Body: {resp.text}")
            
            if resp.status_code == 200:
                print("✅ Token is VALID.")
            # 2. Set Webhook
            print("\nSetting Webhook...")
            WEBHOOK_URL = "https://control-plane-omran-ahmads-projects.vercel.app/telegram/webhook"
            print(f"Target URL: {WEBHOOK_URL}")
            resp = await client.post(f"https://api.telegram.org/bot{TOKEN}/setWebhook", json={"url": WEBHOOK_URL})
            print(f"SetWebhook Response: {resp.text}")

            # 3. Test Webhook Manually
            print(f"\nTesting Manual POST to {WEBHOOK_URL}...")
            test_payload = {
                "update_id": 12345,
                "message": {
                    "message_id": 1,
                    "from": {"id": 999, "is_bot": False, "first_name": "Tester"},
                    "chat": {"id": 999, "type": "private"},
                    "date": 123456,
                    "text": "/status"
                }
            }
            resp = await client.post(WEBHOOK_URL, json=test_payload)
            print(f"Manual POST Status: {resp.status_code}")
            print(f"Manual POST Body: {resp.text}")

            # 4. Get Webhook Info
            print("\nChecking Webhook Info...")
            resp = await client.get(f"https://api.telegram.org/bot{TOKEN}/getWebhookInfo")
            info = resp.json() 
            if info.get("ok"):
                res = info.get("result", {})
                print(f"URL: {res.get('url')}")
                print(f"Last Error: {res.get('last_error_message')}")
            else:
                print(f"❌ Failed to get info: {info}")

        except Exception as e:
            print(f"❌ Connection Error: {e}")

if __name__ == "__main__":
    asyncio.run(check_bot())
