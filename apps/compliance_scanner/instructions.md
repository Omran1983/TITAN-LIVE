# How to Submit Your "Employment Risk Scanner" to ChatGPT

You have chosen the "Data -> Insight" wedge. This package contains everything you need.

## 1. Hosting the Backend (Technical Prerequisite)
ChatGPT needs a URL to talk to.
1.  **Deploy `server.py`**:
    *   Push execution of `uvicorn server:app` to a public server (Replit, Render, Vercel, or your own VPS).
    *   Ensure it has HTTPS (Cloudflare Tunnel is easiest for local dev).
2.  **Update URLs**:
    *   Open `openapi.yaml`: Replace `https://your-server-url.com` with your actual public URL.
    *   Open `manifest.json`: Replace `https://your-server-url.com/openapi.yaml` with your actual URL.

## 2. OpenAI Dashboard Submission
1.  Go to **[ChatGPT Developer Portal](https://chat.openai.com/gpts/editor)** (or "My GPTs").
2.  Click **"Create a GPT"**.
3.  **Name**: Employment Compliance Scanner
4.  **Description**: Instant audit-readiness checks for SMEs. Detects wage & contract risks.
5.  **Instructions (System Prompt)**:
    > You are an expert Employment Compliance Auditor. Use the 'employment_risk_scanner' action to analyze data provided by the user.
    > When the tool returns a Verdict, explain the risks in PLAIN ENGLISH.
    > Highlight 'Potential Penalties' in bold.
    > Always remind the user this is not legal advice.
6.  **Actions (The Key Step)**:
    *   Click "Add Action".
    *   **Import from OpenAPI**: Paste the content of **`openapi.yaml`** here.
    *   Check for errors. It should show `POST /scan` as an available action.
7.  **Knowledge / Capabilities**:
    *   Disable "Web Browsing" (keeps it focused).
    *   Disable "Image Generation".
    *   Enable "Code Interpreter" (helps with parsing CSV uploads before sending JSON to your API).

## 3. Testing (Before Publishing)
1.  In the Preview panel, say:
    > "I have 3 employees. A: $14k/yr, no contract. B: $50k/yr, 60 hours/week. C: $30k/yr. Audit them."
2.  ChatGPT should:
    *   Convert that text to JSON.
    *   Call your API (`/scan`).
    *   Receive the Risk Report.
    *   Say: **"CRITICAL RISK. Employee A is underpaid and lacks a contract. You face fines up to $5,000."**

## 4. Launch
1.  Click **Save** -> **Everyone (Public)**.
2.  Paste the contents of `legal_disclaimer.txt` into your profile or description if asked for privacy/legal info.

**Files Location:** `F:\AION-ZERO\TITAN\apps\compliance_scanner\`
