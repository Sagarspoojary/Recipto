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
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

class ReceiptMeta(BaseModel):
    invoiceNumber: str | None = None
    merchant: str | None = None
    total: float | None = None

class OcrPayload(BaseModel):
    text: str
    existing_receipts: list[ReceiptMeta] = []
    ocr_confidence: float = 1.0

@app.post("/ocr")
async def perform_ocr(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        
        # Save temp file
        temp_path = "temp_receipt.jpg"
        with open(temp_path, "wb") as f:
            f.write(contents)
            
        # Run Tesseract OCR on the image
        extracted_text = pytesseract.image_to_string(Image.open(temp_path))
        
        # Clean up temp file
        if os.path.exists(temp_path):
            os.remove(temp_path)
            
        if not extracted_text.strip():
            return {"text": "No text could be extracted from this image. Please check image quality."}
            
        return {"text": extracted_text}
        
    except Exception as e:
        return {"error": str(e)}

def run_receipt_verification(data: dict, existing_receipts: list, ocr_confidence: float) -> dict:
    trust_score = 100
    checks = {
        "duplicateInvoice": False,
        "gstValid": True,
        "totalValid": True,
        "dateValid": True,
        "merchantValid": True,
        "ocrConfidenceHigh": True,
        "warrantyValid": True,
        "negativePriceValid": True,
        "currencyValid": True,
        "completenessValid": True
    }

    # 1. Invoice Duplicate Check
    merchant = data.get("merchant")
    invoice = data.get("invoiceNumber")
    total = data.get("total")
    
    if invoice and merchant and total is not None:
        for r in existing_receipts:
            if (r.invoiceNumber == invoice and 
                r.merchant == merchant and 
                abs((r.total or 0.0) - total) < 0.01):
                checks["duplicateInvoice"] = True
                trust_score -= 25
                break

    # 2. Total Verification
    products = data.get("products") or []
    calculated_total = sum((p.get("totalPrice") or 0.0) for p in products)
    if total is not None and abs(calculated_total - total) < 0.1:
        trust_score += 15
    else:
        checks["totalValid"] = False
        trust_score -= 20

    # 3. GST Verification
    subtotal = data.get("subtotal") or 0.0
    gst = data.get("gst") or 0.0
    if total is not None and abs((subtotal + gst) - total) < 0.1:
        trust_score += 10
    else:
        checks["gstValid"] = False
        trust_score -= 15

    # 4. Purchase Date Validation
    purchase_date_str = data.get("purchaseDate")
    date_valid = True
    if purchase_date_str:
        from datetime import date
        try:
            # Format expected: YYYY-MM-DD
            p_date = date.fromisoformat(purchase_date_str)
            if p_date > date.today():
                date_valid = False
            if p_date.year < 2000:
                date_valid = False
        except ValueError:
            date_valid = False
    else:
        date_valid = False

    if date_valid:
        trust_score += 5
    else:
        checks["dateValid"] = False
        trust_score -= 10

    # 5. Warranty Validation
    warranty_months = data.get("warrantyMonths")
    warranty_expiry = data.get("warrantyExpiry")
    warranty_valid = True
    if warranty_months is not None:
        if purchase_date_str and warranty_expiry:
            from datetime import date
            try:
                p_date = date.fromisoformat(purchase_date_str)
                exp_date = date.fromisoformat(warranty_expiry)
                if exp_date <= p_date:
                    warranty_valid = False
            except ValueError:
                warranty_valid = False
        else:
            warranty_valid = False

    if warranty_valid:
        trust_score += 5
    else:
        checks["warrantyValid"] = False
        trust_score -= 5

    # 6. OCR Confidence Check
    conf_pct = ocr_confidence * 100
    if conf_pct >= 95:
        trust_score += 10
    elif conf_pct >= 90:
        trust_score += 5
    elif conf_pct >= 80:
        pass
    else:
        checks["ocrConfidenceHigh"] = False
        trust_score -= 10

    # 7. Merchant Validation
    if merchant and invoice and purchase_date_str and total is not None:
        trust_score += 5
    else:
        checks["merchantValid"] = False
        trust_score -= 5

    # 8. Negative Price Validation
    has_negative = False
    for p in products:
        if (p.get("unitPrice") or 0.0) < 0.0 or (p.get("totalPrice") or 0.0) < 0.0:
            has_negative = True
            break
    if total is not None and total < 0.0:
        has_negative = True
    if has_negative:
        checks["negativePriceValid"] = False
        trust_score -= 20

    # 9. Currency Validation
    currency = data.get("currency")
    if currency in ["INR", "USD", "EUR"]:
        pass
    else:
        checks["currencyValid"] = False
        trust_score -= 5

    # 10. Completeness Check
    if not merchant or not purchase_date_str or total is None or not invoice:
        checks["completenessValid"] = False
        trust_score -= 15

    # Bound trust score
    trust_score = max(0, min(100, trust_score))

    # Determine status
    if trust_score >= 90:
        status = "Verified"
    elif trust_score >= 70:
        status = "Review"
    else:
        status = "Not Verified"

    from datetime import datetime
    return {
        "trustScore": trust_score,
        "status": status,
        "verifiedAt": datetime.utcnow().isoformat() + "Z",
        "checks": checks
    }

@app.post("/ai-extract")
async def extract_receipt_ai(payload: OcrPayload):
    ocr_text = payload.text
    if not ocr_text.strip():
        raise HTTPException(status_code=400, detail="OCR Text cannot be empty")
        
    # Check configuration validity
    if not GEMINI_API_KEY or GEMINI_API_KEY.startswith("your_gemini_api_key"):
        raise HTTPException(
            status_code=401,
            detail="Invalid API Configuration: GEMINI_API_KEY is not configured or is a placeholder in backend env."
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
            "contents": [
                {
                    "parts": [
                        {"text": f"{system_prompt}\n\nRaw OCR Text:\n{ocr_text}"}
                    ]
                }
            ],
            "generationConfig": {
                "responseMimeType": "application/json"
            }
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
                # Parse to ensure it is valid JSON
                structured_data = json.loads(text_response)
                
                # Execute Python Rule-Based Verification Engine
                verification_result = run_receipt_verification(
                    structured_data,
                    payload.existing_receipts,
                    payload.ocr_confidence
                )
                
                # Store verification in response
                structured_data["verification"] = verification_result
                return structured_data
            elif response.status_code in (400, 403):
                # API Key authentication errors
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
