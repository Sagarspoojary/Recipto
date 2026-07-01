import uvicorn
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image
import pytesseract
import httpx
import json
import os

app = FastAPI(title="Receipto OCR & AI Engine")

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

OLLAMA_URL = "http://localhost:11434/api/generate"

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
        
    prompt = f"""
Analyze the following raw OCR text from a shopping/purchase receipt and extract structured fields matching the JSON schema below.

Rules:
1. Return ONLY a valid JSON object.
2. Do not invent details. If any value is missing or not present in the text, return null.
3. Automatically classify category into one of: Electronics, Groceries, Restaurant, Medical, Travel, Fuel, Fashion, Furniture, Books, Entertainment, Home Appliances, Others.
4. Detect warranty period and map warrantyMonths (e.g. 12, 24, 36) or warrantyExpiry (YYYY-MM-DD). If no warranty, return null.

JSON Schema:
{{
  "merchant": "string or null",
  "invoiceNumber": "string or null",
  "purchaseDate": "string or null",
  "purchaseTime": "string or null",
  "products": [
    {{
      "name": "string",
      "brand": "string or null",
      "quantity": int,
      "price": float
    }}
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
}}

Raw OCR Text:
{ocr_text}
"""

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                OLLAMA_URL,
                json={
                    "model": "qwen2.5:7b",
                    "prompt": prompt,
                    "stream": False,
                    "format": "json"
                },
                timeout=60.0
            )
            
            if response.status_code == 200:
                ollama_json_response = response.json().get("response", "{}")
                # Parse to ensure it is valid JSON before returning
                structured_data = json.loads(ollama_json_response)
                return structured_data
            else:
                raise HTTPException(status_code=503, detail="Ollama returned error response")
                
    except httpx.ConnectError:
        raise HTTPException(status_code=503, detail="Ollama is offline or unreachable")
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Failed to parse Ollama output as valid JSON")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
