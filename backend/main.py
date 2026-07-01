import uvicorn
from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import pytesseract
import os

app = FastAPI(title="Receipto OCR Engine")

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

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
