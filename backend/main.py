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

class OcrPayload(BaseModel):
    text: str

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
