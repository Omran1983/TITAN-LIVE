# Bridge v3 Deployment Guide

## 1. Commit to Git (Optional but Recommended)
cd F:\AION-ZERO\titan-bridge
git add .
git commit -m "feat: Add Titan Bridge v3 (Telegram Control Plane)"
git push

## 2. Deploy to Vercel (Required)
You must deploy the `control_plane` folder.

1.  Open Terminal in `F:\AION-ZERO\titan-bridge\control_plane`
2.  Run: `vercel deploy --prod`
3.  Follow the prompts (say "Yes" to everything).
4.  **IMPORTANT**: Go to the Vercel Dashboard for this project -> Settings -> Environment Variables.
5.  Add these (copy from your `setup_env.bat` or `runner.py`):
    *   `TELEGRAM_BOT_TOKEN`
    *   `SUPABASE_URL`
    *   `SUPABASE_SERVICE_ROLE_KEY`
    *   `TELEGRAM_WEBHOOK_SECRET` (Create a random string, e.g., "mysecret123")
6.  Redeploy if needed (Vercel usually needs a redeploy after env vars change).

## 3. Set Webhook
Once deployed, get the URL (e.g., `https://titan-bridge-zeta.vercel.app`).
Run this in your browser:
https://api.telegram.org/bot<YOUR_TOKEN>/setWebhook?url=https://<YOUR_VERCEL_URL>/api/webhook&secret_token=<YOUR_SECRET>
