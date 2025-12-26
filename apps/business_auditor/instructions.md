# Deploying "Agreement Risk Verdict" (Production V3.2)

You are deploying a **Hardened Audit Engine**.

## 1. Prerequisites
*   **Hosting**: Render / Fly.io (Recommended).
*   **Requirements** (pasted into `requirements.txt`):
    ```
    fastapi
    uvicorn
    pydantic
    fpdf
    ```

## 2. Environment Variables (Critical)
You **MUST** set `PUBLIC_BASE_URL` or downloads will fail.

| Variable | Default | Notes |
| :--- | :--- | :--- |
| `PUBLIC_BASE_URL` | `http://localhost:8000` | **REQUIRED** in Prod (e.g. `https://my-app.com`) |
| `DEBUG` | `0` | Set `1` only to see exception hints in errors. |
| `RATE_LIMIT_PER_MIN` | `60` | Requests per IP per minute. Set `0` to disable. |
| `MAX_TEXT_CHARS` | `200000` | Max chars per scan. |

## 3. Security Notes
*   **Ephemeral Storage**: PDF reports are held in RAM for **30 minutes**, then deleted.
*   **Rate Limits**: IPs are limited to 60 req/min by default (`429 Too Many Requests`).
*   **Limits**: Text > 200k characters will be rejected (`413 Payload Too Large`).

## 4. ChatGPT Configuration
*   **Action Import**: Paste the `openapi.yaml` content.
*   **Instructions**:
    > "You are an Auditor. When a user sends text, classify it (e.g. 'contractor_agreement') and call 'scan_agreement'.
    > Always display the **Verdict Title** and **Risk Score** in Bold at the top.
    > If Verdict is RED, use urgent language.
    > Offer the **PDF Download Link** clearly at the end (it expires in 30 mins)."

**Files Location:** `F:\AION-ZERO\TITAN\apps\business_auditor\`
