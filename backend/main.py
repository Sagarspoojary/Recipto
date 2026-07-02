import uvicorn
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image
import pytesseract
import httpx
import json
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = FastAPI(title="Receipto OCR & Gemini AI Engine")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Cross-platform: Point to brew path on Mac, use standard path on Linux/Render
mac_tesseract_path = '/opt/homebrew/bin/tesseract'
if os.path.exists(mac_tesseract_path):
    pytesseract.pytesseract.tesseract_cmd = mac_tesseract_path
    print(f"Using Mac local Tesseract: {mac_tesseract_path}")
else:
    print("Using system default Tesseract path (Linux/Docker/Render)")

# Fetch Gemini Configurations
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GEMINI_MODEL   = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

# Brevo (formerly Sendinblue) — free, 300 emails/day, sends to ANY email, no domain needed
BREVO_API_KEY      = os.getenv("BREVO_API_KEY", "")       # Get from brevo.com → SMTP & API → API Keys
BREVO_SENDER_EMAIL = os.getenv("BREVO_SENDER_EMAIL", "") # Verified sender email on Brevo


# ─── Pydantic Models ────────────────────────────────────────────────────────

class OcrPayload(BaseModel):
    text: str

class WarrantyEmailPayload(BaseModel):
    user_email: str
    merchant: str
    product_names: list[str] = []
    expiry_date: str
    days_remaining: int   # 0 = expiring today, 3 = 3 days left, negative = already expired


# ─── Email Helper ────────────────────────────────────────────────────────────

def _build_email_html(merchant: str, product_names: list, expiry_date: str, days_remaining: int) -> tuple[str, str]:
    """Returns (subject, html_body) for the warranty notification email."""

    products_html = "".join(
        f"<li style='margin:4px 0;color:#c9d1d9;'>• {p}</li>"
        for p in product_names
    ) if product_names else "<li style='color:#c9d1d9;'>• (Product details unavailable)</li>"

    if days_remaining <= 0:
        subject    = f"⚠️ Warranty Expired — {merchant}"
        headline   = "Your Warranty Has Expired"
        badge_color = "#FF4444"
        badge_text  = "EXPIRED"
        message    = (
            f"The warranty for your purchase from <strong>{merchant}</strong> "
            f"expired on <strong>{expiry_date}</strong>. "
            "If you need support, please contact the merchant directly."
        )
        cta = "Unfortunately this warranty is no longer active."
    else:
        subject    = f"🔔 Warranty Expiring in {days_remaining} Day{'s' if days_remaining != 1 else ''} — {merchant}"
        headline   = f"Warranty Expiring in {days_remaining} Day{'s' if days_remaining != 1 else ''}!"
        badge_color = "#FFB300"
        badge_text  = f"{days_remaining} DAYS LEFT"
        message    = (
            f"Your warranty for a purchase from <strong>{merchant}</strong> will expire on "
            f"<strong>{expiry_date}</strong>. "
            "Act now if you need to raise a warranty claim."
        )
        cta = "Contact the merchant or service centre before your warranty expires."

    products_section = (
        f"<p style='margin:16px 0 8px;font-size:10px;letter-spacing:2px;"
        f"color:#8b949e;font-weight:600;'>PRODUCTS UNDER WARRANTY</p>"
        f"<ul style='margin:0;padding:0;list-style:none;'>{products_html}</ul>"
    ) if product_names else ""

    html = f"""<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#0d1117;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#0d1117;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="560" cellpadding="0" cellspacing="0"
               style="background:#161b22;border-radius:16px;overflow:hidden;border:1px solid #30363d;">

          <!-- Header gradient -->
          <tr>
            <td style="background:linear-gradient(135deg,#00c8ff,#7b2ff7);padding:32px 36px;text-align:center;">
              <p style="margin:0;font-size:13px;letter-spacing:3px;color:rgba(255,255,255,0.7);font-weight:600;">RECEIPTO</p>
              <h1 style="margin:8px 0 0;font-size:26px;color:#ffffff;font-weight:800;">{headline}</h1>
            </td>
          </tr>

          <!-- Status badge -->
          <tr>
            <td style="padding:28px 36px 0;text-align:center;">
              <span style="display:inline-block;background:{badge_color}22;border:1px solid {badge_color}66;
                           color:{badge_color};border-radius:20px;padding:6px 20px;
                           font-size:12px;font-weight:700;letter-spacing:2px;">
                ⏱ {badge_text}
              </span>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:24px 36px;">
              <p style="color:#c9d1d9;font-size:15px;line-height:1.7;margin:0 0 20px;">{message}</p>

              <!-- Details box -->
              <div style="background:#0d1117;border-radius:12px;padding:20px 24px;border:1px solid #30363d;margin:0 0 20px;">
                <p style="margin:0 0 12px;font-size:10px;letter-spacing:2px;color:#8b949e;font-weight:600;">WARRANTY DETAILS</p>
                <table width="100%" cellpadding="0" cellspacing="0">
                  <tr>
                    <td style="color:#8b949e;font-size:13px;padding:4px 0;width:140px;">Merchant</td>
                    <td style="color:#e6edf3;font-size:13px;font-weight:600;">{merchant}</td>
                  </tr>
                  <tr>
                    <td style="color:#8b949e;font-size:13px;padding:4px 0;">Expiry Date</td>
                    <td style="color:{badge_color};font-size:13px;font-weight:700;">{expiry_date}</td>
                  </tr>
                </table>
                {products_section}
              </div>

              <p style="color:#8b949e;font-size:13px;line-height:1.6;margin:0;">{cta}</p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:20px 36px 28px;border-top:1px solid #21262d;">
              <p style="margin:0;font-size:11px;color:#484f58;text-align:center;">
                This email was sent by <strong style="color:#7b2ff7;">Receipto</strong> because
                you have an active warranty tracked in the app.<br>
                Open the Receipto app to view full receipt details.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>"""

    return subject, html


# ─── Endpoints ───────────────────────────────────────────────────────────────

@app.post("/send-warranty-email")
async def send_warranty_email(payload: WarrantyEmailPayload):
    """Send a warranty expiry / countdown reminder email via Brevo API."""
    if not BREVO_API_KEY or not BREVO_SENDER_EMAIL:
        raise HTTPException(
            status_code=503,
            detail="Brevo credentials not configured. Set BREVO_API_KEY and BREVO_SENDER_EMAIL env vars."
        )

    subject, html_body = _build_email_html(
        merchant=payload.merchant,
        product_names=payload.product_names,
        expiry_date=payload.expiry_date,
        days_remaining=payload.days_remaining,
    )

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://api.brevo.com/v3/smtp/email",
                headers={
                    "api-key": BREVO_API_KEY,
                    "Content-Type": "application/json",
                },
                json={
                    "sender": {
                        "name": "Receipto Alerts",
                        "email": BREVO_SENDER_EMAIL,
                    },
                    "to": [{"email": payload.user_email}],
                    "subject": subject,
                    "htmlContent": html_body,
                },
                timeout=15.0,
            )

        if response.status_code in (200, 201):
            return {"success": True, "message": f"Email sent to {payload.user_email}"}
        else:
            error_detail = response.json().get("message", response.text)
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Brevo API error: {error_detail}"
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")


@app.post("/ocr")
async def perform_ocr(file: UploadFile = File(...)):
    try:
        contents = await file.read()

        temp_path = "temp_receipt.jpg"
        with open(temp_path, "wb") as f:
            f.write(contents)

        extracted_text = pytesseract.image_to_string(Image.open(temp_path))

        if os.path.exists(temp_path):
            os.remove(temp_path)

        if not extracted_text.strip():
            return {"text": "No text could be extracted from this image. Please check image quality."}

        return {"text": extracted_text}

    except Exception as e:
        return {"error": str(e)}


@app.post("/ai-extract")
async def extract_receipt_ai(payload: OcrPayload):
    ocr_text = payload.text
    if not ocr_text.strip():
        raise HTTPException(status_code=400, detail="OCR Text cannot be empty")

    if not GEMINI_API_KEY or GEMINI_API_KEY.startswith("your_gemini_api_key"):
        raise HTTPException(
            status_code=401,
            detail="Invalid API Configuration: GEMINI_API_KEY is not configured."
        )

    system_prompt = """You are an intelligent receipt understanding engine.
Your task is to analyze raw OCR text extracted from receipts and invoices.
Extract only factual information. Never guess. Never hallucinate. If any information is unavailable, return null.

CRITICAL INSTRUCTIONS FOR WARRANTY:
1. Look for a warranty block or keys like "Warranty Period", "Warranty Start Date", "Warranty End Date", "Warranty Expiry", or "Warranty Details".
2. For "warrantyMonths": Convert any warranty period string into total months. E.g., "1 Year" -> 12, "2 Years" -> 24, "6 Months" -> 6. If no warranty is mentioned, return null.
3. For "warrantyExpiry": Extract any specified warranty end date or expiry date. Preserve the raw date string from the receipt (e.g., "02-07-2027").

Return ONLY a valid JSON object matching this schema (with no markdown wrappers or other text):
{
  "merchant": "string or null",
  "invoiceNumber": "string or null",
  "purchaseDate": "string or null",
  "purchaseTime": "string or null",
  "products": [
    {
      "name": "string",
      "brand": "string or null",
      "quantity": int,
      "unitPrice": float,
      "totalPrice": float
    }
  ],
  "subtotal": float,
  "gst": float,
  "discount": float,
  "total": float,
  "currency": "string",
  "paymentMethod": "string or null",
  "category": "string",
  "warrantyMonths": int or null,
  "warrantyExpiry": "string or null",
  "merchantPhone": "string or null",
  "merchantEmail": "string or null",
  "merchantAddress": "string or null",
  "returnDays": int or null,
  "notes": "string or null"
}
"""

    gemini_url = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={GEMINI_API_KEY}"

    try:
        body = {
            "contents": [{"parts": [{"text": f"{system_prompt}\n\nRaw OCR Text:\n{ocr_text}"}]}],
            "generationConfig": {"responseMimeType": "application/json"}
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(
                gemini_url,
                headers={"Content-Type": "application/json"},
                json=body,
                timeout=60.0
            )

            if response.status_code == 200:
                res_data = response.json()
                text_response = res_data["candidates"][0]["content"]["parts"][0]["text"]
                structured_data = json.loads(text_response)
                return structured_data
            elif response.status_code in (400, 403):
                print(f"Gemini API Config Error: {response.text}")
                raise HTTPException(status_code=401, detail="Invalid API Configuration")
            else:
                print(f"Gemini API Error: {response.text}")
                raise HTTPException(status_code=503, detail="AI Service Unavailable")

    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail="No Internet Connection")
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Failed to parse Gemini output as valid JSON")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
